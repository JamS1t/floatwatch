import '../../models/daily_float_model.dart';

/// Repository interface for daily_float data.
// TODO: Add a FirebaseDailyFloatRepository implementation for cloud sync.
abstract class IDailyFloatRepository {
  Future<DailyFloatModel?> getDailyFloat(int id);
  Future<DailyFloatModel?> getDailyFloatByDate(int storeId, String date);
  Future<DailyFloatModel?> getTodayFloat(int storeId);
  Future<List<DailyFloatModel>> getRecentFloats(int storeId, int limit);
  Future<int> createDailyFloat(DailyFloatModel float);
  Future<void> updateDailyFloat(DailyFloatModel float);

  /// Set opening balances and mark as set by role.
  Future<void> setOpeningBalance({
    required int dailyFloatId,
    required int gcashBalance,
    required int cashBalance,
    required String setBy, // 'owner' | 'staff'
  });

  /// Set closing balances, calculate expected/discrepancy, update status.
  Future<void> setClosingBalance({
    required int dailyFloatId,
    required int gcashBalance,
    required int cashBalance,
    required int expectedGcash,
    required int discrepancyGcash,
    required int discrepancyCash,
    required String status,
  });

  /// Mark the day as closed.
  Future<void> closeDay(int dailyFloatId);
}
