/// App-wide constants for FloatWatch.
/// Business rules, thresholds, and configuration values live here.
class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'FloatWatch';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'GCash Partner Outlet Tracker';
  static const String supportEmail = 'support@floatwatch.ph';

  // ── Database ──────────────────────────────────────────────────────────────
  static const String databaseName = 'floatwatch.db';
  static const int databaseVersion = 1;

  // ── Security ──────────────────────────────────────────────────────────────
  static const int maxFailedPinAttempts = 3;
  static const int pinLength = 6;

  /// One-time PINs expire after this many minutes.
  static const int otpExpiryMinutes = 15;

  // ── Discrepancy Thresholds (in centavos) ─────────────────────────────────
  /// GREEN status: abs(discrepancy) ≤ ₱10 (1000 centavos)
  static const int discrepancyGreenMax = 1000;

  /// YELLOW status: ₱10 < abs(discrepancy) ≤ ₱200 (20000 centavos)
  static const int discrepancyYellowMax = 20000;

  // ── Store Modes ───────────────────────────────────────────────────────────
  static const String storeModeSolo = 'solo';
  static const String storeModeWithStaff = 'with_staff';

  // ── Security Modes ───────────────────────────────────────────────────────
  static const String securityModeSimple = 'simple';
  static const String securityModeStrict = 'strict';

  // ── Transaction Types ─────────────────────────────────────────────────────
  static const String txCashIn = 'cash_in';
  static const String txCashOut = 'cash_out';
  static const String txBillsPayment = 'bills_payment';
  static const String txLoadOthers = 'load_others';

  static const List<String> transactionTypes = [
    txCashIn,
    txCashOut,
    txBillsPayment,
    txLoadOthers,
  ];

  // ── Markup Rate Types ─────────────────────────────────────────────────────
  static const String markupPercentage = 'percentage';
  static const String markupFixed = 'fixed';
  static const String markupPerBracket = 'per_bracket';

  // ── Entry Methods ─────────────────────────────────────────────────────────
  static const String entryBatchOcr = 'batch_ocr';
  static const String entryManualOwner = 'manual_owner';
  static const String entryManualStaff = 'manual_staff';

  // ── Roles ─────────────────────────────────────────────────────────────────
  static const String roleOwner = 'owner';
  static const String roleStaff = 'staff';

  // ── Daily Float Status ────────────────────────────────────────────────────
  static const String floatStatusOpen = 'open';
  static const String floatStatusClean = 'clean';
  static const String floatStatusWarning = 'warning';
  static const String floatStatusFlagged = 'flagged';

  // ── OTP Purpose ───────────────────────────────────────────────────────────
  static const String otpPurposeManualEntry = 'manual_entry';

  // ── Batch Upload ──────────────────────────────────────────────────────────
  /// Free plan batch upload limit (number of receipts per session)
  static const int freeBatchUploadLimit = 10;

  // ── Date / Currency Formats ───────────────────────────────────────────────
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String dbDateFormat = 'yyyy-MM-dd';
  static const String dbDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String pesoSymbol = '₱';

  // ── Sync Log Actions ──────────────────────────────────────────────────────
  static const String syncActionCreate = 'create';
  static const String syncActionUpdate = 'update';
  static const String syncActionDelete = 'delete';

  // ── UI ────────────────────────────────────────────────────────────────────
  static const double cardBorderRadius = 12.0;
  static const double buttonHeight = 52.0;
  static const double cardElevation = 2.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
}
