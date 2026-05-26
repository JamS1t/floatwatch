import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/models/batch_item_analysis.dart';
import '../core/services/ocr_result.dart';
import '../core/services/receipt_parser.dart';
import '../core/services/receipt_storage_service.dart';
import '../core/services/security_service.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/markup_calculator.dart';
import '../data/models/markup_settings_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/interfaces/i_daily_float_repository.dart';
import '../data/repositories/interfaces/i_transaction_repository.dart';

/// TransactionProvider manages transaction data for the current day.
class TransactionProvider extends ChangeNotifier {
  final ITransactionRepository _txRepo;
  // ignore: unused_field
  final SecurityService _security;

  TransactionProvider({
    required ITransactionRepository transactionRepo,
    required SecurityService securityService,
  })  : _txRepo = transactionRepo,
        _security = securityService;

  // ── State ─────────────────────────────────────────────────────────────────
  List<TransactionModel> _transactions = [];
  Map<String, int> _dailyTotals = {};
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  Map<String, int> get dailyTotals => Map.unmodifiable(_dailyTotals);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalMarkupEarned => _dailyTotals['total_markup_earned'] ?? 0;
  int get totalGrossAmount => _dailyTotals['total_gross_amount'] ?? 0;
  int get transactionCount => _dailyTotals['total_transactions'] ?? 0;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadTransactionsForDay(int dailyFloatId) async {
    _setLoading(true);
    try {
      _transactions = await _txRepo.getTransactionsByDailyFloat(dailyFloatId);
      _dailyTotals = await _txRepo.getDailyTotals(dailyFloatId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load transactions.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshTotals(int dailyFloatId) async {
    _dailyTotals = await _txRepo.getDailyTotals(dailyFloatId);
    notifyListeners();
  }

  Future<Map<String, int>> getDailyTotalsForFloat(int dailyFloatId) =>
      _txRepo.getDailyTotals(dailyFloatId);

  // ── Add transaction ───────────────────────────────────────────────────────

  /// Create a new transaction, automatically calculating markup earned.
  Future<bool> addTransaction({
    required int storeId,
    required int dailyFloatId,
    required String transactionType,
    required int amountCentavos,
    required MarkupSettingsModel markupSettings,
    required String entryMethod,
    required String enteredByRole,
    int? enteredByStaffId,
    String? referenceNumber,
    String? receiptImagePath,
    String? missingReceiptReason,
    double? ocrConfidenceScore,
    bool oneTimePinUsed = false,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      // Calculate markup earned using snapshot of current settings
      final markupEarned = MarkupCalculator.calculate(
        amount: amountCentavos,
        rateType: markupSettings.rateType,
        rateValue: markupSettings.rateValue,
        bracketSize: markupSettings.bracketSize,
      );

      final now = DateFormatter.nowDb();
      final tx = TransactionModel(
        storeId: storeId,
        dailyFloatId: dailyFloatId,
        transactionType: transactionType,
        amount: amountCentavos,
        // Snapshot markup settings — never changes after creation
        markupRateTypeSnapshot: markupSettings.rateType,
        markupRateValueSnapshot: markupSettings.rateValue,
        markupBracketSizeSnapshot: markupSettings.bracketSize,
        markupEarned: markupEarned,
        referenceNumber: referenceNumber,
        receiptImagePath: receiptImagePath,
        entryMethod: entryMethod,
        enteredByRole: enteredByRole,
        enteredByStaffId: enteredByStaffId,
        missingReceiptReason: missingReceiptReason,
        ocrConfidenceScore: ocrConfidenceScore,
        oneTimePinUsed: oneTimePinUsed ? 1 : 0,
        createdAt: now,
        updatedAt: now,
        syncId: const Uuid().v4(),
      );

      final id = await _txRepo.createTransaction(tx);
      final saved = tx.copyWith(id: id);
      _transactions = [saved, ..._transactions];

      // Refresh aggregates
      _dailyTotals = await _txRepo.getDailyTotals(dailyFloatId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to save transaction. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Batch OCR save ────────────────────────────────────────────────────────

  /// Save a batch of OCR-processed receipts in chronological order.
  /// Uses the receipt's extracted date/time as [createdAt] (not system time).
  /// Returns the count of successfully saved transactions.
  Future<int> addBatchTransactions({
    required int storeId,
    required int dailyFloatId,
    required List<OcrResult> results,
    required Map<String, MarkupSettingsModel> markupByType,
    required String enteredByRole,
    required ReceiptStorageService receiptStorage,
    int? enteredByStaffId,
    Set<int> skipIndices = const {},
    Map<int, int> dailyFloatOverrides = const {},
  }) async {
    // Note: markup overrides ride along inside each OcrResult.markupOverrideCentavos.
    _setLoading(true);
    _clearError();
    var savedCount = 0;
    try {
      final sorted = ReceiptParser.sortChronologically(results);
      for (var idx = 0; idx < sorted.length; idx++) {
        if (skipIndices.contains(idx)) continue;
        final result = sorted[idx];
        try {
          final markup = markupByType[result.transactionType!]!;
          final calculatedMarkup = MarkupCalculator.calculate(
            amount: result.amountCentavos!,
            rateType: markup.rateType,
            rateValue: markup.rateValue,
            bracketSize: markup.bracketSize,
          );
          final overridden = result.markupOverrideCentavos != null;
          final markupEarned =
              overridden ? result.markupOverrideCentavos! : calculatedMarkup;

          final syncId = const Uuid().v4();

          String? permanentPath;
          if (result.imagePath.isNotEmpty) {
            try {
              permanentPath =
                  await receiptStorage.saveReceipt(result.imagePath, syncId);
            } catch (_) {
              permanentPath = result.imagePath;
            }
          }

          // Use receipt's extracted date/time, not system time
          final receiptTs =
              DateFormatter.toDbDateTime(result.transactionDateTime!);

          final effectiveFloatId = dailyFloatOverrides[idx] ?? dailyFloatId;

          final tx = TransactionModel(
            storeId: storeId,
            dailyFloatId: effectiveFloatId,
            transactionType: result.transactionType!,
            amount: result.amountCentavos!,
            markupRateTypeSnapshot: markup.rateType,
            markupRateValueSnapshot: markup.rateValue,
            markupBracketSizeSnapshot: markup.bracketSize,
            markupEarned: markupEarned,
            markupOverridden: overridden ? 1 : 0,
            referenceNumber: result.referenceNumber,
            receiptImagePath: permanentPath,
            entryMethod: AppConstants.entryBatchOcr,
            enteredByRole: enteredByRole,
            enteredByStaffId: enteredByStaffId,
            ocrConfidenceScore: result.confidence,
            createdAt: receiptTs,
            updatedAt: receiptTs,
            syncId: syncId,
          );

          final id = await _txRepo.createTransaction(tx);
          // Only surface in the current view if it belongs to today's float.
          if (effectiveFloatId == dailyFloatId) {
            _transactions = [tx.copyWith(id: id), ..._transactions];
          }
          savedCount++;
        } catch (_) {
          // Skip failed individual transactions, continue the batch
        }
      }
      // Refresh totals for today's float (the primary view).
      _dailyTotals = await _txRepo.getDailyTotals(dailyFloatId);
      notifyListeners();
      return savedCount;
    } catch (e) {
      _setError('Failed to save batch transactions. Please try again.');
      return savedCount;
    } finally {
      _setLoading(false);
    }
  }

  // ── Duplicate detection ──────────────────────────────────────────────────

  /// Check if a transaction with the same composite key already exists.
  /// Returns the existing [TransactionModel] or null.
  Future<TransactionModel?> checkDuplicate({
    required int storeId,
    required String referenceNumber,
    required int amountCentavos,
    required String transactionType,
  }) {
    return _txRepo.findDuplicate(
      storeId: storeId,
      referenceNumber: referenceNumber,
      amount: amountCentavos,
      transactionType: transactionType,
    );
  }

  /// Analyze a batch of OCR results for duplicates and cross-date issues.
  ///
  /// Checks:
  /// 1. Within-batch duplicates (same ref+amount+type appearing twice).
  /// 2. DB duplicates via [findDuplicate].
  /// 3. Cross-date: receipt date differs from [todayDate].
  Future<List<BatchItemAnalysis>> analyzeBatch({
    required int storeId,
    required List<OcrResult> items,
    required String todayDate,
    required IDailyFloatRepository floatRepo,
  }) async {
    final results = <BatchItemAnalysis>[];
    // Track composite keys seen within the batch for within-batch dedup.
    final seenKeys = <String>{};

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final ref = item.referenceNumber;
      final amount = item.amountCentavos;
      final type = item.transactionType;

      // Items without ref numbers can't be deduped — always ready.
      if (ref == null || ref.isEmpty || amount == null || type == null) {
        results.add(BatchItemAnalysis(index: i, status: BatchItemStatus.ready));
        continue;
      }

      final key = '$ref|$amount|$type';

      // Within-batch duplicate (second occurrence).
      if (seenKeys.contains(key)) {
        results.add(BatchItemAnalysis(
          index: i,
          status: BatchItemStatus.duplicate,
        ));
        continue;
      }
      seenKeys.add(key);

      // DB duplicate check.
      final existing = await _txRepo.findDuplicate(
        storeId: storeId,
        referenceNumber: ref,
        amount: amount,
        transactionType: type,
      );
      if (existing != null) {
        results.add(BatchItemAnalysis(
          index: i,
          status: BatchItemStatus.duplicate,
          existingTxId: existing.id,
        ));
        continue;
      }

      // Cross-date check.
      if (item.transactionDateTime != null) {
        final receiptDate = DateFormatter.toDb(item.transactionDateTime!);
        if (receiptDate != todayDate) {
          final targetFloat =
              await floatRepo.getDailyFloatByDate(storeId, receiptDate);
          final isClosed = targetFloat?.closed ?? false;
          results.add(BatchItemAnalysis(
            index: i,
            status: isClosed
                ? BatchItemStatus.crossDateClosed
                : BatchItemStatus.crossDate,
            receiptDate: receiptDate,
            dayIsClosed: isClosed,
          ));
          continue;
        }
      }

      results.add(BatchItemAnalysis(index: i, status: BatchItemStatus.ready));
    }

    return results;
  }

  // ── Flag / unflag ─────────────────────────────────────────────────────────

  Future<void> flagTransaction(int transactionId, String reason) async {
    await _txRepo.flagTransaction(transactionId, reason);
    final idx = _transactions.indexWhere((t) => t.id == transactionId);
    if (idx >= 0) {
      _transactions[idx] =
          _transactions[idx].copyWith(isFlagged: 1, flagReason: reason);
      notifyListeners();
    }
  }

  Future<void> unflagTransaction(int transactionId) async {
    await _txRepo.unflagTransaction(transactionId);
    final idx = _transactions.indexWhere((t) => t.id == transactionId);
    if (idx >= 0) {
      _transactions[idx] = _transactions[idx].copyWith(isFlagged: 0);
      notifyListeners();
    }
  }

  void clearTransactions() {
    _transactions = [];
    _dailyTotals = {};
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
