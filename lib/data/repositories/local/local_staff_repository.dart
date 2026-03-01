import '../../../core/utils/date_formatter.dart';
import '../../database/database_helper.dart';
import '../../database/sync_log_helper.dart';
import '../../models/one_time_pin_model.dart';
import '../../models/staff_model.dart';
import '../interfaces/i_staff_repository.dart';

/// Local SQLite implementation of [IStaffRepository].
// TODO: Create FirebaseStaffRepository for cloud sync.
class LocalStaffRepository implements IStaffRepository {
  final DatabaseHelper _db;
  late final SyncLogHelper _syncLog;

  LocalStaffRepository(this._db) {
    _syncLog = SyncLogHelper(_db);
  }

  static const _staffTable = 'staff';
  static const _otpTable = 'one_time_pins';

  // ── Staff ─────────────────────────────────────────────────────────────────

  @override
  Future<StaffModel?> getStaff(int id) async {
    final db = await _db.database;
    final rows = await db.query(_staffTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : StaffModel.fromMap(rows.first);
  }

  @override
  Future<List<StaffModel>> getStaffByStore(int storeId) async {
    final db = await _db.database;
    final rows = await db.query(
      _staffTable,
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'name ASC',
    );
    return rows.map(StaffModel.fromMap).toList();
  }

  @override
  Future<List<StaffModel>> getActiveStaffByStore(int storeId) async {
    final db = await _db.database;
    final rows = await db.query(
      _staffTable,
      where: 'store_id = ? AND is_active = 1',
      whereArgs: [storeId],
      orderBy: 'name ASC',
    );
    return rows.map(StaffModel.fromMap).toList();
  }

  @override
  Future<int> createStaff(StaffModel staff) async {
    final db = await _db.database;
    final id = await db.insert(_staffTable, staff.toMap());
    await _syncLog.log(
      tableName: _staffTable,
      recordSyncId: staff.syncId,
      action: 'create',
    );
    return id;
  }

  @override
  Future<void> updateStaff(StaffModel staff) async {
    final db = await _db.database;
    final map = staff.toMap()..['updated_at'] = DateFormatter.nowDb();
    await db.update(_staffTable, map, where: 'id = ?', whereArgs: [staff.id]);
    await _syncLog.log(
      tableName: _staffTable,
      recordSyncId: staff.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> deactivateStaff(int id) async {
    final staff = await getStaff(id);
    if (staff == null) return;
    final db = await _db.database;
    await db.update(
      _staffTable,
      {'is_active': 0, 'updated_at': DateFormatter.nowDb()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncLog.log(
      tableName: _staffTable,
      recordSyncId: staff.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> incrementFailedAttempts(int staffId) async {
    final staff = await getStaff(staffId);
    if (staff == null) return;
    final db = await _db.database;
    final newAttempts = staff.failedAttempts + 1;
    final newLocked = newAttempts >= 3 ? 1 : 0; // lock after 3 failures
    await db.update(
      _staffTable,
      {
        'failed_attempts': newAttempts,
        'is_locked': newLocked,
        'updated_at': DateFormatter.nowDb(),
      },
      where: 'id = ?',
      whereArgs: [staffId],
    );
    await _syncLog.log(
      tableName: _staffTable,
      recordSyncId: staff.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> resetFailedAttempts(int staffId) async {
    final staff = await getStaff(staffId);
    if (staff == null) return;
    final db = await _db.database;
    await db.update(
      _staffTable,
      {
        'failed_attempts': 0,
        'updated_at': DateFormatter.nowDb(),
      },
      where: 'id = ?',
      whereArgs: [staffId],
    );
    await _syncLog.log(
      tableName: _staffTable,
      recordSyncId: staff.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> lockStaff(int staffId) async {
    final staff = await getStaff(staffId);
    if (staff == null) return;
    final db = await _db.database;
    await db.update(
      _staffTable,
      {'is_locked': 1, 'updated_at': DateFormatter.nowDb()},
      where: 'id = ?',
      whereArgs: [staffId],
    );
    await _syncLog.log(
      tableName: _staffTable,
      recordSyncId: staff.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> unlockStaff(int staffId) async {
    final staff = await getStaff(staffId);
    if (staff == null) return;
    final db = await _db.database;
    await db.update(
      _staffTable,
      {
        'is_locked': 0,
        'failed_attempts': 0,
        'updated_at': DateFormatter.nowDb(),
      },
      where: 'id = ?',
      whereArgs: [staffId],
    );
    await _syncLog.log(
      tableName: _staffTable,
      recordSyncId: staff.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> updateLastActive(int staffId, String timestamp) async {
    final staff = await getStaff(staffId);
    if (staff == null) return;
    final db = await _db.database;
    await db.update(
      _staffTable,
      {'last_active': timestamp, 'updated_at': DateFormatter.nowDb()},
      where: 'id = ?',
      whereArgs: [staffId],
    );
    await _syncLog.log(
      tableName: _staffTable,
      recordSyncId: staff.syncId,
      action: 'update',
    );
  }

  // ── One-time PINs ─────────────────────────────────────────────────────────

  @override
  Future<int> createOneTimePin(OneTimePinModel otp) async {
    final db = await _db.database;
    final id = await db.insert(_otpTable, otp.toMap());
    await _syncLog.log(
      tableName: _otpTable,
      recordSyncId: otp.syncId,
      action: 'create',
    );
    return id;
  }

  @override
  Future<void> markOtpUsed(int otpId) async {
    final db = await _db.database;
    await db.update(
      _otpTable,
      {'is_used': 1},
      where: 'id = ?',
      whereArgs: [otpId],
    );
  }
}
