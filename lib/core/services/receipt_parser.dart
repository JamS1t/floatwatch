import 'package:floatwatch/core/constants/app_constants.dart';
import 'package:floatwatch/core/services/ocr_result.dart';

/// Parses raw OCR text from GCash receipts into structured [OcrResult] data.
///
/// Extracts amounts, reference numbers, phone numbers, and date/time.
/// Classifies Cash In / Cash Out by checking whether the owner's GCash
/// number appears in the receipt:
///   • Owner's number found  → Cash Out (customer sent GCash to owner)
///   • Other number(s) found → Cash In  (owner sent GCash to customer)
///   • No phone at all       → unknown, needs manual review
class ReceiptParser {
  // ── Amount patterns (ordered by priority) ─────────────────────────────────

  // Label and amount on the SAME line: "Amount ₱500.00"
  static final _labeledAmountSameLineRe = RegExp(
    r'(?:amount|total|paid|sent|received|load)\s*[:\-]?\s*(?:₱|php)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Label on one line, amount on the NEXT — common GCash receipt layout:
  //   Amount
  //   ₱500.00
  static final _labeledAmountNextLineRe = RegExp(
    r'(?:amount|total)\s*\n\s*(?:₱|P(?=[\d\s]))\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Standalone ₱ symbol
  static final _pesoSymbolRe = RegExp(
    r'₱\s*([\d,]+(?:\.\d{1,2})?)',
  );

  // PHP prefix
  static final _phpPrefixRe = RegExp(
    r'(?:php)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Capital P as OCR artifact for ₱ — only match when followed by digits+decimal
  // e.g. "P500.00" but NOT "PHP" or words starting with P
  static final _capitalPRe = RegExp(
    r'(?<![A-Za-z])P\s*([\d,]+\.\d{2})(?!\d)',
  );

  // Plain decimal amounts (e.g., "99.00", "3.00") — used by extractAllAmounts
  // for load receipts where Amount and Convenience Fee are bare numbers.
  static final _plainDecimalRe = RegExp(
    r'(?:^|[\s,])(\d+\.\d{2})(?:$|[\s,])',
    multiLine: true,
  );

  // ── Reference number pattern ──────────────────────────────────────────────

  // Primary: label then digits on same/next line (flexible separator absorbs
  // icon characters, non-breaking spaces, or any OCR artifacts between label
  // and number — e.g. copy icon 📋 read as a character by ML Kit).
  static final _referenceRe = RegExp(
    r'ref(?:erence)?\.?\s*(?:no|number|#)?\.?[^\d]{0,10}([\d][\d\s]{6,19})',
    caseSensitive: false,
  );

  // Fallback: standalone 7–13 digit number on its own line, possibly followed
  // by a single character (ML Kit reads the copy icon as "0" or "O").
  // Used when ML Kit splits "Reference No." and the number into separate
  // text blocks with ad text in between.
  static final _referenceStandaloneRe = RegExp(
    r'(?:^|\n)\s*(\d{7,13})\s*\S?\s*(?:$|\n)',
  );

  // ── Phone number pattern ──────────────────────────────────────────────────

  // [\s\-]* (zero-or-more) instead of [\s\-]? (zero-or-one) so OCR artifacts
  // like "0917  123  4567" (extra spaces) still match.
  static final _phoneRe = RegExp(
    r'(?:\+?63|0)[\s\-]*(9\d{2})[\s\-]*(\d{3})[\s\-]*(\d{4})',
  );

  // ── Date/time patterns (ordered by specificity) ───────────────────────────

  // "Mar 01, 2026 3:45 PM" or "March 1, 2026, 3:45:30 PM" or "Feb 26,2026 6:02 PM"
  static final _dateMonthNameTimeRe = RegExp(
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\.?\s+(\d{1,2}),?\s*(\d{4}),?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)',
    caseSensitive: false,
  );

  // "03/01/2026 3:45 PM"
  static final _dateSlashTimeRe = RegExp(
    r'(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})\s*(AM|PM)',
    caseSensitive: false,
  );

  // "2026-03-01 15:45"
  static final _dateIsoRe = RegExp(
    r'(\d{4})-(\d{2})-(\d{2})\s+(\d{1,2}):(\d{2})',
  );

  // Date only: "Mar 01, 2026" or "Feb 26,2026" (no time)
  static final _dateOnlyRe = RegExp(
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\.?\s+(\d{1,2}),?\s*(\d{4})',
    caseSensitive: false,
  );

  // ── Month name lookup ─────────────────────────────────────────────────────

  static const _monthNames = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
    'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
    'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  // ══════════════════════════════════════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════════════════════════════════════

  /// Parse raw OCR text from a receipt image into a structured [OcrResult].
  OcrResult parse({
    required String imagePath,
    required String rawText,
    required String ownerGcashNumber,
  }) {
    var amount = extractAmount(rawText);
    final refNo = extractReferenceNumber(rawText);
    final dateTime = extractDateTime(rawText);
    final phones = extractPhoneNumbers(rawText);

    final type = classifyType(rawText, phones, ownerGcashNumber);

    // For load/bills receipts with convenience fee, use triplet sum to find
    // the correct total — avoids picking up ad amounts that ML Kit reads
    // before the actual receipt values.
    if ((type == AppConstants.txLoadOthers ||
            type == AppConstants.txBillsPayment) &&
        _convenienceFeeRe.hasMatch(rawText)) {
      final loadTotal = _extractLoadTotal(rawText);
      if (loadTotal != null) amount = loadTotal;
    }

    final confidence = calculateConfidence(
      amount: amount,
      type: type,
      dateTime: dateTime,
      refNo: refNo,
      sender: phones.isNotEmpty ? phones.first : null,
    );

    final needsReview =
        dateTime == null || type == null || amount == null || confidence < 0.6;

    return OcrResult(
      imagePath: imagePath,
      rawText: rawText,
      transactionType: type,
      amountCentavos: amount,
      referenceNumber: refNo,
      transactionDateTime: dateTime,
      confidence: confidence,
      needsManualReview: needsReview,
      reviewReason: needsReview
          ? _buildReviewReason(amount, type, dateTime, confidence)
          : null,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Extraction methods (visible for testing)
  // ══════════════════════════════════════════════════════════════════════════

  /// Extract the transaction amount in centavos. Returns null if not found.
  int? extractAmount(String text) {
    // 1. Label + amount on same line: "Amount ₱500.00"
    var match = _labeledAmountSameLineRe.firstMatch(text);
    if (match != null) return _parseAmountMatch(match.group(1)!);

    // 2. Label on one line, amount on next line (common GCash layout)
    match = _labeledAmountNextLineRe.firstMatch(text);
    if (match != null) return _parseAmountMatch(match.group(1)!);

    // 3. Standalone ₱ symbol anywhere
    match = _pesoSymbolRe.firstMatch(text);
    if (match != null) return _parseAmountMatch(match.group(1)!);

    // 4. PHP prefix
    match = _phpPrefixRe.firstMatch(text);
    if (match != null) return _parseAmountMatch(match.group(1)!);

    // 5. Capital P as OCR artifact for ₱ (e.g. "P500.00")
    match = _capitalPRe.firstMatch(text);
    if (match != null) return _parseAmountMatch(match.group(1)!);

    return null;
  }

  /// Extract the reference number. Returns null if not found.
  ///
  /// Tries labeled pattern first ("Ref No. 123456789"), then falls back to
  /// standalone 9–13 digit number on its own line (for when ML Kit puts the
  /// label and number in separate text blocks).
  String? extractReferenceNumber(String text) {
    // Primary: labeled pattern — works when label and number are adjacent
    final match = _referenceRe.firstMatch(text);
    if (match != null) {
      return match.group(1)!.replaceAll(RegExp(r'\s'), '');
    }

    // Fallback: standalone 7-13 digit number on its own line, only if
    // the text also contains "ref" somewhere (avoids false positives).
    // Handles ML Kit splitting label and number into separate text blocks
    // with ad text in between.
    if (RegExp(r'ref', caseSensitive: false).hasMatch(text)) {
      final fallback = _referenceStandaloneRe.firstMatch(text);
      if (fallback != null) {
        return fallback.group(1)!.replaceAll(RegExp(r'\s'), '');
      }
    }

    return null;
  }

  /// Extract all Philippine mobile numbers, normalized to 09XXXXXXXXX format.
  List<String> extractPhoneNumbers(String text) {
    final matches = _phoneRe.allMatches(text);
    return matches
        .map((m) => '0${m.group(1)}${m.group(2)}${m.group(3)}')
        .toSet() // deduplicate (same number in +63 and 09 form)
        .toList();
  }

  // ── Keyword lists for bills / load classification ─────────────────────────

  static const _billsKeywords = [
    'bills payment', 'pay bills', 'biller',
    'meralco', 'manila water', 'maynilad', 'pldt', 'converge',
    'globe broadband', 'smart bro', 'cignal', 'sss', 'pagibig',
    'pag-ibig', 'philhealth', 'national grid',
  ];

  static const _loadKeywords = [
    'buy load', 'prepaid load', 'load to', 'regular load',
    'smart prepaid', 'globe prepaid', 'tm prepaid', 'dito prepaid',
    'gomo', 'smart load', 'globe load', 'tnt load',
  ];

  // ── Load-specific indicators from real GCash receipts ───────────────────

  /// "Schedule for Autoload" button text — only appears on load receipts.
  static final _scheduleAutoloadRe = RegExp(
    r'schedule\s+for\s+autoload',
    caseSensitive: false,
  );

  /// "Convenience Fee" line — appears on load receipts (not on send money).
  static final _convenienceFeeRe = RegExp(
    r'convenience\s+fee',
    caseSensitive: false,
  );

  /// Telco promo name patterns that appear as the receipt title for load.
  /// These are very distinctive and never appear on send-money receipts.
  static const _loadPromoKeywords = [
    // Globe / TM promos
    'power all', 'all access', 'gosurf', 'go surf', 'easysurf',
    'easy surf', 'godata', 'go data', 'gocombo', 'go combo',
    'all-net surf', 'all net surf', 'funaliw',
    // Smart / TNT promos
    'magic data', 'giga', 'surf plus', 'all data', 'panalo',
    // DITO promos
    'dito level', 'level-up', 'level up',
    // ML / Gaming load
    'ml 1', 'ml 5', 'ml 10', 'ml 15', 'ml 20', 'ml 50', 'ml 100',
    // Generic load promo patterns
    'tiktok 99', 'tiktok 149', 'fb 99', 'fb 149',
  ];

  /// "Paid via GCash" — appears on load and bills payment receipts.
  static final _paidViaGcashRe = RegExp(
    r'paid\s+via\s+gcash',
    caseSensitive: false,
  );

  /// "Sent via GCash" — appears on send-money receipts (cash in / cash out).
  static final _sentViaGcashRe = RegExp(
    r'sent\s+via\s+gcash',
    caseSensitive: false,
  );

  /// "Total Amount Sent" — only appears on send-money receipts, never on load.
  static final _totalAmountSentRe = RegExp(
    r'total\s+amount\s+sent',
    caseSensitive: false,
  );

  /// Classify the transaction type using a layered approach.
  ///
  /// **Layer 1** — Receipt verb: "Paid via GCash" vs "Sent via GCash"
  ///   • "Paid via GCash"  → payment transaction (load or bills)
  ///   • "Sent via GCash"  → send money transaction (cash in or cash out)
  ///
  /// **Layer 2a** — For "Paid via GCash":
  ///   1. Bills payment keywords → txBillsPayment
  ///   2. Load indicators (autoload, convenience fee, promo names) → txLoadOthers
  ///   3. Default for "paid" receipts → txLoadOthers (paid = purchase)
  ///
  /// **Layer 2b** — For "Sent via GCash" (or "Total Amount Sent"):
  ///   1. Owner's number found → txCashOut
  ///   2. Other number found → txCashIn
  ///   3. No phones → null (needs review, but flagged as send-money)
  ///
  /// **Fallback** — No "paid"/"sent" keyword found:
  ///   1. Bills keywords → txBillsPayment
  ///   2. Load keywords or indicators → txLoadOthers
  ///   3. Owner number → txCashOut
  ///   4. Other phone → txCashIn
  ///   5. null → needs manual review
  String? classifyType(
    String rawText,
    List<String> phones,
    String ownerGcashNumber,
  ) {
    final lower = rawText.toLowerCase();
    final isPaid = _paidViaGcashRe.hasMatch(rawText);
    final isSent = _sentViaGcashRe.hasMatch(rawText) ||
        _totalAmountSentRe.hasMatch(rawText);

    // ── Layer 1 + 2a: "Paid via GCash" → bills or load ──────────────────
    if (isPaid) {
      // Bills payment keywords still take priority
      if (_billsKeywords.any((k) => lower.contains(k))) {
        return AppConstants.txBillsPayment;
      }
      // Everything else paid via GCash is load/others
      return AppConstants.txLoadOthers;
    }

    // ── Layer 1 + 2b: "Sent via GCash" → cash in or cash out ────────────
    if (isSent) {
      return _classifySendMoney(phones, ownerGcashNumber);
    }

    // ── Fallback: no "paid"/"sent" verb found — use keyword heuristics ───

    // 1. Bills payment
    if (_billsKeywords.any((k) => lower.contains(k))) {
      return AppConstants.txBillsPayment;
    }

    // 2. Load indicators: explicit keywords, autoload, convenience fee, promos
    if (_loadKeywords.any((k) => lower.contains(k)) ||
        _scheduleAutoloadRe.hasMatch(rawText) ||
        _convenienceFeeRe.hasMatch(rawText) ||
        _loadPromoKeywords.any((k) => lower.contains(k))) {
      return AppConstants.txLoadOthers;
    }

    // 3 & 4. Cash Out / Cash In — phone number comparison
    return _classifySendMoney(phones, ownerGcashNumber);
  }

  /// Classify a send-money receipt as cash in or cash out based on phone numbers.
  String? _classifySendMoney(List<String> phones, String ownerGcashNumber) {
    final ownerNorm = _normalizeDigits(ownerGcashNumber);
    if (ownerNorm.isNotEmpty) {
      for (final phone in phones) {
        if (_normalizeDigits(phone) == ownerNorm) return AppConstants.txCashOut;
      }
    }
    if (phones.isNotEmpty) return AppConstants.txCashIn;
    return null;
  }

  /// Strip all non-digit characters and convert +63XXXXXXXXXX → 09XXXXXXXXXX.
  String _normalizeDigits(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    // +63917... (12 digits) → 09...
    if (digits.length == 12 && digits.startsWith('63')) {
      return '0${digits.substring(2)}';
    }
    return digits;
  }

  /// Extract date/time from receipt text. Returns null if not found.
  DateTime? extractDateTime(String text) {
    // Pattern 1: Month name with time — "Mar 01, 2026 3:45 PM"
    var match = _dateMonthNameTimeRe.firstMatch(text);
    if (match != null) {
      final month = _monthNames[match.group(1)!.substring(0, 3).toLowerCase()]!;
      final day = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      var hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
      final amPm = match.group(7)!.toUpperCase();
      hour = _to24Hour(hour, amPm);
      return DateTime(year, month, day, hour, minute, second);
    }

    // Pattern 2: Slash date with time — "03/01/2026 3:45 PM"
    match = _dateSlashTimeRe.firstMatch(text);
    if (match != null) {
      final month = int.parse(match.group(1)!);
      final day = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      var hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final amPm = match.group(6)!.toUpperCase();
      hour = _to24Hour(hour, amPm);
      return DateTime(year, month, day, hour, minute);
    }

    // Pattern 3: ISO-ish — "2026-03-01 15:45"
    match = _dateIsoRe.firstMatch(text);
    if (match != null) {
      return DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
      );
    }

    // Pattern 4: Date only (no time) — "Mar 01, 2026"
    match = _dateOnlyRe.firstMatch(text);
    if (match != null) {
      final month = _monthNames[match.group(1)!.substring(0, 3).toLowerCase()]!;
      final day = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }

    return null;
  }

  /// Calculate a confidence score (0.0–1.0) based on which fields were extracted.
  double calculateConfidence({
    required int? amount,
    required String? type,
    required DateTime? dateTime,
    required String? refNo,
    String? sender,
    String? recipient,
  }) {
    var score = 0.0;
    if (amount != null) score += 0.30;
    if (type != null) score += 0.30;
    if (dateTime != null) score += 0.20;
    if (refNo != null) score += 0.10;
    if (sender != null || recipient != null) score += 0.10;
    return score;
  }

  /// Sort a list of OcrResults chronologically (earliest first).
  /// Results without dates are placed at the end.
  static List<OcrResult> sortChronologically(List<OcrResult> results) {
    final withDate = results.where((r) => r.transactionDateTime != null).toList()
      ..sort((a, b) => a.transactionDateTime!.compareTo(b.transactionDateTime!));
    final withoutDate =
        results.where((r) => r.transactionDateTime == null).toList();
    return [...withDate, ...withoutDate];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Load/bills amount correction
  // ══════════════════════════════════════════════════════════════════════════

  /// Extract ALL amounts (in centavos) found anywhere in the text.
  /// Used by [_extractLoadTotal] to find the correct total via triplet sum.
  List<int> extractAllAmounts(String text) {
    final amounts = <int>[];

    // ₱-prefixed amounts
    for (final m in _pesoSymbolRe.allMatches(text)) {
      final v = _parseAmountMatch(m.group(1)!);
      if (v != null) amounts.add(v);
    }

    // PHP-prefixed amounts
    for (final m in _phpPrefixRe.allMatches(text)) {
      final v = _parseAmountMatch(m.group(1)!);
      if (v != null) amounts.add(v);
    }

    // Capital P as OCR artifact
    for (final m in _capitalPRe.allMatches(text)) {
      final v = _parseAmountMatch(m.group(1)!);
      if (v != null) amounts.add(v);
    }

    // Plain decimal amounts (e.g., "99.00", "3.00")
    for (final m in _plainDecimalRe.allMatches(text)) {
      final v = _parseAmountMatch(m.group(1)!);
      if (v != null) amounts.add(v);
    }

    return amounts;
  }

  /// For load/bills receipts with "Convenience Fee", find the correct Total
  /// by looking for three amounts where Amount + Fee = Total.
  ///
  /// This is immune to ad noise because random ad amounts won't satisfy
  /// the mathematical relationship A + B = C.
  int? _extractLoadTotal(String text) {
    final amounts = extractAllAmounts(text);
    if (amounts.length < 2) return null;

    final unique = amounts.toSet().toList();

    // Find A + B = C — the sum is the Total
    for (var i = 0; i < unique.length; i++) {
      for (var j = i + 1; j < unique.length; j++) {
        final sum = unique[i] + unique[j];
        if (unique.contains(sum)) {
          return sum;
        }
      }
    }

    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Private helpers
  // ══════════════════════════════════════════════════════════════════════════

  int? _parseAmountMatch(String raw) {
    final cleaned = raw.replaceAll(',', '');
    final pesos = double.tryParse(cleaned);
    if (pesos == null || pesos <= 0) return null;
    return (pesos * 100).round();
  }

  int _to24Hour(int hour, String amPm) {
    if (amPm == 'AM') {
      return hour == 12 ? 0 : hour;
    } else {
      return hour == 12 ? 12 : hour + 12;
    }
  }

  String _buildReviewReason(
    int? amount,
    String? type,
    DateTime? dateTime,
    double confidence,
  ) {
    final reasons = <String>[];
    if (amount == null) reasons.add('Could not extract amount');
    if (type == null) reasons.add('Could not determine transaction type');
    if (dateTime == null) reasons.add('Could not extract date/time');
    if (confidence < 0.6 && reasons.isEmpty) reasons.add('Low confidence score');
    return reasons.join('; ');
  }
}
