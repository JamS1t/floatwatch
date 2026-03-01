import '../../database/database_helper.dart';
import '../../database/sync_log_helper.dart';
import '../../models/owner_model.dart';
import '../interfaces/i_owner_repository.dart';
import '../../../core/utils/date_formatter.dart';

/// Local SQLite implementation of [IOwnerRepository].
///
/// TODO: When Firebase is activated, create a FirebaseOwnerRepository that
/// implements IOwnerRepository — this file stays untouched.
class LocalOwnerRepository implements IOwnerRepository {
  final DatabaseHelper _db;
  late final SyncLogHelper _syncLog;

  LocalOwnerRepository(this._db) {
    _syncLog = SyncLogHelper(_db);
  }

  static const _table = 'owners';

  @override
  Future<OwnerModel?> getOwner(int id) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : OwnerModel.fromMap(rows.first);
  }

  @override
  Future<OwnerModel?> getOwnerByMobileNumber(String mobileNumber) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'mobile_number = ?',
      whereArgs: [mobileNumber],
      limit: 1,
    );
    return rows.isEmpty ? null : OwnerModel.fromMap(rows.first);
  }

  @override
  Future<List<OwnerModel>> getAllOwners() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'name ASC');
    return rows.map(OwnerModel.fromMap).toList();
  }

  @override
  Future<int> createOwner(OwnerModel owner) async {
    final db = await _db.database;
    final id = await db.insert(_table, owner.toMap());
    await _syncLog.log(
      tableName: _table,
      recordSyncId: owner.syncId,
      action: 'create',
    );
    return id;
  }

  @override
  Future<void> updateOwner(OwnerModel owner) async {
    final db = await _db.database;
    final map = owner.toMap()..['updated_at'] = DateFormatter.nowDb();
    await db.update(_table, map, where: 'id = ?', whereArgs: [owner.id]);
    await _syncLog.log(
      tableName: _table,
      recordSyncId: owner.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> deleteOwner(int id) async {
    final owner = await getOwner(id);
    if (owner == null) return;
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    await _syncLog.log(
      tableName: _table,
      recordSyncId: owner.syncId,
      action: 'delete',
    );
  }

  @override
  Future<bool> hasOwner() async {
    final db = await _db.database;
    final rows = await db.query(_table, columns: ['id'], limit: 1);
    return rows.isNotEmpty;
  }
}
