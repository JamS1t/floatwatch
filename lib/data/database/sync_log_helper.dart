import '../database/database_helper.dart';
import '../../core/utils/date_formatter.dart';

/// Helper that writes entries to the sync_log table.
///
/// Every Repository write operation MUST call [SyncLogHelper.log] so that
/// future Firebase sync can identify unsynced records.
///
/// TODO: When Firebase is activated, a sync worker will:
///   1. Query sync_log WHERE is_synced = 0
///   2. Push each record to Firestore using the record's sync_id
///   3. Mark is_synced = 1 and set synced_at timestamp
class SyncLogHelper {
  final DatabaseHelper _dbHelper;

  SyncLogHelper(this._dbHelper);

  /// Log a write operation on [tableName] for the record identified by
  /// [recordSyncId]. [action] must be one of: 'create', 'update', 'delete'.
  Future<void> log({
    required String tableName,
    required String recordSyncId,
    required String action, // 'create' | 'update' | 'delete'
  }) async {
    assert(
      action == 'create' || action == 'update' || action == 'delete',
      'action must be create, update, or delete',
    );

    final db = await _dbHelper.database;
    await db.insert('sync_log', {
      'table_name': tableName,
      'record_sync_id': recordSyncId,
      'action': action,
      'is_synced': 0,
      // TODO: Firebase sync sets is_synced = 1 and synced_at after upload
      'synced_at': null,
      'created_at': DateFormatter.nowDb(),
    });
  }
}
