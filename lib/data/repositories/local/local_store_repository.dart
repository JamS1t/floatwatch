import '../../../core/utils/date_formatter.dart';
import '../../database/database_helper.dart';
import '../../database/sync_log_helper.dart';
import '../../models/markup_settings_model.dart';
import '../../models/store_model.dart';
import '../interfaces/i_store_repository.dart';

/// Local SQLite implementation of [IStoreRepository].
// TODO: Create FirebaseStoreRepository for cloud sync.
class LocalStoreRepository implements IStoreRepository {
  final DatabaseHelper _db;
  late final SyncLogHelper _syncLog;

  LocalStoreRepository(this._db) {
    _syncLog = SyncLogHelper(_db);
  }

  static const _storeTable = 'stores';
  static const _markupTable = 'markup_settings';

  // ── Stores ────────────────────────────────────────────────────────────────

  @override
  Future<StoreModel?> getStore(int id) async {
    final db = await _db.database;
    final rows = await db.query(_storeTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : StoreModel.fromMap(rows.first);
  }

  @override
  Future<List<StoreModel>> getStoresByOwner(int ownerId) async {
    final db = await _db.database;
    final rows = await db.query(
      _storeTable,
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'store_name ASC',
    );
    return rows.map(StoreModel.fromMap).toList();
  }

  @override
  Future<StoreModel?> getActiveStoreForOwner(int ownerId) async {
    final db = await _db.database;
    final rows = await db.query(
      _storeTable,
      where: 'owner_id = ? AND is_active = 1',
      whereArgs: [ownerId],
      limit: 1,
    );
    return rows.isEmpty ? null : StoreModel.fromMap(rows.first);
  }

  @override
  Future<int> createStore(StoreModel store) async {
    final db = await _db.database;
    final id = await db.insert(_storeTable, store.toMap());
    await _syncLog.log(
      tableName: _storeTable,
      recordSyncId: store.syncId,
      action: 'create',
    );
    return id;
  }

  @override
  Future<void> updateStore(StoreModel store) async {
    final db = await _db.database;
    final map = store.toMap()..['updated_at'] = DateFormatter.nowDb();
    await db.update(_storeTable, map, where: 'id = ?', whereArgs: [store.id]);
    await _syncLog.log(
      tableName: _storeTable,
      recordSyncId: store.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> deactivateStore(int id) async {
    final store = await getStore(id);
    if (store == null) return;
    final db = await _db.database;
    await db.update(
      _storeTable,
      {'is_active': 0, 'updated_at': DateFormatter.nowDb()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncLog.log(
      tableName: _storeTable,
      recordSyncId: store.syncId,
      action: 'update',
    );
  }

  // ── Markup Settings ───────────────────────────────────────────────────────

  @override
  Future<List<MarkupSettingsModel>> getMarkupSettings(int storeId) async {
    final db = await _db.database;
    final rows = await db.query(
      _markupTable,
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'transaction_type ASC',
    );
    return rows.map(MarkupSettingsModel.fromMap).toList();
  }

  @override
  Future<MarkupSettingsModel?> getMarkupSettingForType(
    int storeId,
    String transactionType,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      _markupTable,
      where: 'store_id = ? AND transaction_type = ?',
      whereArgs: [storeId, transactionType],
      orderBy: 'effective_date DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : MarkupSettingsModel.fromMap(rows.first);
  }

  @override
  Future<int> createMarkupSetting(MarkupSettingsModel setting) async {
    final db = await _db.database;
    final id = await db.insert(_markupTable, setting.toMap());
    await _syncLog.log(
      tableName: _markupTable,
      recordSyncId: setting.syncId,
      action: 'create',
    );
    return id;
  }

  @override
  Future<void> updateMarkupSetting(MarkupSettingsModel setting) async {
    final db = await _db.database;
    await db.update(
      _markupTable,
      setting.toMap(),
      where: 'id = ?',
      whereArgs: [setting.id],
    );
    await _syncLog.log(
      tableName: _markupTable,
      recordSyncId: setting.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> deleteMarkupSetting(int id) async {
    final settings = await _getMarkupSettingById(id);
    if (settings == null) return;
    final db = await _db.database;
    await db.delete(_markupTable, where: 'id = ?', whereArgs: [id]);
    await _syncLog.log(
      tableName: _markupTable,
      recordSyncId: settings.syncId,
      action: 'delete',
    );
  }

  Future<MarkupSettingsModel?> _getMarkupSettingById(int id) async {
    final db = await _db.database;
    final rows = await db.query(_markupTable, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : MarkupSettingsModel.fromMap(rows.first);
  }
}
