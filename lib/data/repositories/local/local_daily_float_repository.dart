import '../../../core/utils/date_formatter.dart';
import '../../database/database_helper.dart';
import '../../database/sync_log_helper.dart';
import '../../models/daily_float_model.dart';
import '../interfaces/i_daily_float_repository.dart';

/// Local SQLite implementation of [IDailyFloatRepository].
// TODO: Create FirebaseDailyFloatRepository for cloud sync.
class LocalDailyFloatRepository implements IDailyFloatRepository {
  final DatabaseHelper _db;
  late final SyncLogHelper _syncLog;

  LocalDailyFloatRepository(this._db) {
    _syncLog = SyncLogHelper(_db);
  }

  static const _table = 'daily_float';

  @override
  Future<DailyFloatModel?> getDailyFloat(int id) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : DailyFloatModel.fromMap(rows.first);
  }

  @override
  Future<DailyFloatModel?> getDailyFloatByDate(int storeId, String date) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'store_id = ? AND date = ?',
      whereArgs: [storeId, date],
      limit: 1,
    );
    return rows.isEmpty ? null : DailyFloatModel.fromMap(rows.first);
  }

  @override
  Future<DailyFloatModel?> getTodayFloat(int storeId) async {
    return getDailyFloatByDate(storeId, DateFormatter.todayDb());
  }

  @override
  Future<List<DailyFloatModel>> getRecentFloats(int storeId, int limit) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(DailyFloatModel.fromMap).toList();
  }

  @override
  Future<int> createDailyFloat(DailyFloatModel float) async {
    final db = await _db.database;
    final id = await db.insert(_table, float.toMap());
    await _syncLog.log(
      tableName: _table,
      recordSyncId: float.syncId,
      action: 'create',
    );
    return id;
  }

  @override
  Future<void> updateDailyFloat(DailyFloatModel float) async {
    final db = await _db.database;
    final map = float.toMap()..['updated_at'] = DateFormatter.nowDb();
    await db.update(_table, map, where: 'id = ?', whereArgs: [float.id]);
    await _syncLog.log(
      tableName: _table,
      recordSyncId: float.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> setOpeningBalance({
    required int dailyFloatId,
    required int gcashBalance,
    required int cashBalance,
    required String setBy,
  }) async {
    final float = await getDailyFloat(dailyFloatId);
    if (float == null) return;
    final db = await _db.database;
    await db.update(
      _table,
      {
        'opening_gcash_balance': gcashBalance,
        'opening_cash': cashBalance,
        'opening_set_by': setBy,
        'updated_at': DateFormatter.nowDb(),
      },
      where: 'id = ?',
      whereArgs: [dailyFloatId],
    );
    await _syncLog.log(
      tableName: _table,
      recordSyncId: float.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> setClosingBalance({
    required int dailyFloatId,
    required int gcashBalance,
    required int cashBalance,
    required int expectedGcash,
    required int discrepancyGcash,
    required int discrepancyCash,
    required String status,
  }) async {
    final float = await getDailyFloat(dailyFloatId);
    if (float == null) return;
    final db = await _db.database;
    await db.update(
      _table,
      {
        'closing_gcash_balance': gcashBalance,
        'closing_cash': cashBalance,
        'expected_gcash_balance': expectedGcash,
        'discrepancy_gcash': discrepancyGcash,
        'discrepancy_cash': discrepancyCash,
        'status': status,
        'updated_at': DateFormatter.nowDb(),
      },
      where: 'id = ?',
      whereArgs: [dailyFloatId],
    );
    await _syncLog.log(
      tableName: _table,
      recordSyncId: float.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> closeDay(int dailyFloatId) async {
    final float = await getDailyFloat(dailyFloatId);
    if (float == null) return;
    final db = await _db.database;
    await db.update(
      _table,
      {'is_closed': 1, 'updated_at': DateFormatter.nowDb()},
      where: 'id = ?',
      whereArgs: [dailyFloatId],
    );
    await _syncLog.log(
      tableName: _table,
      recordSyncId: float.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> reopenDay(int dailyFloatId) async {
    final float = await getDailyFloat(dailyFloatId);
    if (float == null) return;
    final db = await _db.database;
    await db.update(
      _table,
      {
        'is_closed': 0,
        'status': 'open',
        'closing_gcash_balance': null,
        'closing_cash': null,
        'expected_gcash_balance': null,
        'discrepancy_gcash': null,
        'discrepancy_cash': null,
        'updated_at': DateFormatter.nowDb(),
      },
      where: 'id = ?',
      whereArgs: [dailyFloatId],
    );
    await _syncLog.log(
      tableName: _table,
      recordSyncId: float.syncId,
      action: 'update',
    );
  }
}
