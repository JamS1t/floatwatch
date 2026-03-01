import '../../data/database/database_helper.dart';

/// Central subscription service for FloatWatch.
///
/// Every premium feature MUST check this service before rendering.
/// Free users see a locked state with an upgrade prompt (PremiumLockWidget).
///
/// isPremium is currently hardcoded to false.
/// TODO: Implement actual billing / subscription check when IAP is integrated.
class SubscriptionService {
  // ignore: unused_field
  final DatabaseHelper _dbHelper;

  SubscriptionService(this._dbHelper);

  // ── Primary check ──────────────────────────────────────────────────────────

  /// Returns true if the owner has an active premium subscription.
  /// Currently always returns false (all users are on the free plan).
  ///
  /// TODO: Query subscription table or verify receipt with App Store / Play
  /// Store when in-app purchases are implemented.
  Future<bool> isPremium(int ownerId) async => false;

  // ── Feature flags ─────────────────────────────────────────────────────────
  // Each method returns true only if isPremium is true.
  // This makes it trivial to lock/unlock features without touching UI code.

  /// Export daily/weekly/monthly reports as PDF.
  Future<bool> canExportPDF(int ownerId) async => isPremium(ownerId);

  /// View weekly analytics report.
  Future<bool> canViewWeeklyReports(int ownerId) async => isPremium(ownerId);

  /// View monthly analytics report.
  Future<bool> canViewMonthlyReports(int ownerId) async => isPremium(ownerId);

  /// Register and manage more than one store.
  Future<bool> canAddMultipleStores(int ownerId) async => isPremium(ownerId);

  /// Batch-upload more than [AppConstants.freeBatchUploadLimit] receipts.
  Future<bool> canUseUnlimitedBatchUpload(int ownerId) async =>
      isPremium(ownerId);

  /// Re-open a closed day to correct entries.
  Future<bool> canReopenClosedDay(int ownerId) async => isPremium(ownerId);

  /// Sync data to Firebase / cloud storage.
  Future<bool> canUseCloudSync(int ownerId) async => isPremium(ownerId);
}
