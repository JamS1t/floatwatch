import 'dart:math';

/// Handles all markup income calculation logic for FloatWatch.
///
/// IMPORTANT: All amounts (including rate values) are in INTEGER centavos
/// to avoid floating-point precision errors.
///
/// Rate storage conventions:
///   percentage  → rate_value = percentage × 100
///                 (e.g. 1.00% stored as 100, 0.50% stored as 50)
///   fixed       → rate_value = flat fee in centavos
///                 (e.g. ₱10 flat = 1000)
///   per_bracket → rate_value = fee per bracket in centavos,
///                 bracket_size = bracket size in centavos
///                 (e.g. ₱10/₱500 bracket → rateValue=1000, bracketSize=50000)
class MarkupCalculator {
  MarkupCalculator._();

  // ── Main entry point ──────────────────────────────────────────────────────

  /// Calculate markup earned for a transaction.
  ///
  /// [amount]      — transaction amount in centavos
  /// [rateType]    — 'percentage' | 'fixed' | 'per_bracket'
  /// [rateValue]   — stored rate value (see conventions above)
  /// [bracketSize] — required for per_bracket; size of one bracket in centavos
  ///
  /// Returns markup earned in centavos.
  static int calculate({
    required int amount,
    required String rateType,
    required int rateValue,
    int? bracketSize,
  }) {
    switch (rateType) {
      case 'percentage':
        return _percentage(amount, rateValue);
      case 'fixed':
        return _fixed(rateValue);
      case 'per_bracket':
        if (bracketSize == null || bracketSize <= 0) {
          throw ArgumentError(
            'bracketSize is required and must be > 0 for per_bracket rate type',
          );
        }
        return _perBracket(amount, rateValue, bracketSize);
      default:
        throw ArgumentError('Unknown markup rate type: "$rateType"');
    }
  }

  // ── Rate type implementations ─────────────────────────────────────────────

  /// Percentage markup.
  ///
  /// Formula: markup = round(amount × rateValue / 10000)
  /// Example: ₱1,000 at 1.00% → 100000 × 100 / 10000 = 1000 centavos = ₱10
  static int _percentage(int amount, int rateValue) {
    return (amount * rateValue / 10000).round();
  }

  /// Fixed markup — same fee regardless of amount.
  ///
  /// Formula: markup = rateValue
  /// Example: any amount at ₱10 flat → 1000 centavos = ₱10
  static int _fixed(int rateValue) => rateValue;

  /// Per-bracket markup — fee per bracket, rounded up.
  ///
  /// Formula: markup = ceil(amount / bracketSize) × rateValue
  /// Example: ₱750 / ₱500 bracket / ₱10 per bracket
  ///          → ceil(75000 / 50000) = 2 brackets → 2 × 1000 = 2000 centavos = ₱20
  static int _perBracket(int amount, int rateValue, int bracketSize) {
    final brackets = (amount / bracketSize).ceil();
    return brackets * rateValue;
  }

  // ── Expected balance calculations ─────────────────────────────────────────

  /// Calculate the expected closing GCash balance.
  ///
  /// GCash balance movement rules:
  ///   Cash In        → GCash DECREASES (customer gives cash, gets GCash)
  ///   Cash Out       → GCash INCREASES (customer gives GCash, gets cash)
  ///   Bills Payment  → GCash DECREASES
  ///   Load Others    → GCash DECREASES
  ///
  /// Formula:
  ///   expected = openingGcash
  ///            - totalCashIn
  ///            - totalBillsPayment
  ///            - totalLoadOthers
  ///            + totalCashOut
  ///
  /// All values in centavos.
  static int expectedClosingGcash({
    required int openingGcash,
    required int totalCashIn,
    required int totalCashOut,
    required int totalBillsPayment,
    required int totalLoadOthers,
  }) {
    return openingGcash - totalCashIn - totalBillsPayment - totalLoadOthers + totalCashOut;
  }

  /// Determine the discrepancy status from the absolute discrepancy value.
  ///
  /// GREEN  : abs(discrepancy) ≤ ₱10  (≤ 1000 centavos)
  /// YELLOW : ₱10 < abs(discrepancy) ≤ ₱200  (1001–20000 centavos)
  /// RED    : abs(discrepancy) > ₱200  (> 20000 centavos)
  static String discrepancyStatus(int discrepancyCentavos) {
    final abs = discrepancyCentavos.abs();
    if (abs <= 1000) return 'clean';
    if (abs <= 20000) return 'warning';
    return 'flagged';
  }

  // ── Display helpers ───────────────────────────────────────────────────────

  /// Convert stored rateValue to a human-readable percentage string.
  /// e.g. 100 → "1.00%", 50 → "0.50%"
  static String percentageDisplay(int rateValue) {
    return '${(rateValue / 100).toStringAsFixed(2)}%';
  }

  /// Returns the number of brackets for a given amount and bracket size.
  static int bracketCount(int amount, int bracketSize) {
    if (bracketSize <= 0) return 0;
    return (amount / bracketSize).ceil();
  }
}
