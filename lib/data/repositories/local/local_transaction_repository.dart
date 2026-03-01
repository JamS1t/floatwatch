import '../../../core/utils/date_formatter.dart';
import '../../database/database_helper.dart';
import '../../database/sync_log_helper.dart';
import '../../models/transaction_model.dart';
import '../interfaces/i_transaction_repository.dart';

/// Local SQLite implementation of [ITransactionRepository].
// TODO: Create FirebaseTransactionRepository for cloud sync.
class LocalTransactionRepository implements ITransactionRepository {
  final DatabaseHelper _db;
  late final SyncLogHelper _syncLog;

  LocalTransactionRepository(this._db) {
    _syncLog = SyncLogHelper(_db);
  }

  static const _table = 'transactions';

  @override
  Future<TransactionModel?> getTransaction(int id) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : TransactionModel.fromMap(rows.first);
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDailyFloat(int dailyFloatId) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'daily_float_id = ?',
      whereArgs: [dailyFloatId],
      orderBy: 'created_at DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByStore(int storeId) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'created_at DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByStoreAndDate(
    int storeId,
    String date,
  ) async {
    final db = await _db.database;
    // Use daily_float join via dailyFloatId — or query by date prefix on created_at
    final rows = await db.rawQuery(
      '''
      SELECT t.*
      FROM transactions t
      INNER JOIN daily_float df ON t.daily_float_id = df.id
      WHERE t.store_id = ? AND df.date = ?
      ORDER BY t.created_at DESC
      ''',
      [storeId, date],
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<List<TransactionModel>> getFlaggedTransactions(int storeId) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'store_id = ? AND is_flagged = 1',
      whereArgs: [storeId],
      orderBy: 'created_at DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await _db.database;
    final id = await db.insert(_table, transaction.toMap());
    await _syncLog.log(
      tableName: _table,
      recordSyncId: transaction.syncId,
      action: 'create',
    );
    return id;
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await _db.database;
    final map = transaction.toMap()..['updated_at'] = DateFormatter.nowDb();
    await db.update(_table, map, where: 'id = ?', whereArgs: [transaction.id]);
    await _syncLog.log(
      tableName: _table,
      recordSyncId: transaction.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> flagTransaction(int id, String reason) async {
    final tx = await getTransaction(id);
    if (tx == null) return;
    final db = await _db.database;
    await db.update(
      _table,
      {
        'is_flagged': 1,
        'flag_reason': reason,
        'updated_at': DateFormatter.nowDb(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncLog.log(
      tableName: _table,
      recordSyncId: tx.syncId,
      action: 'update',
    );
  }

  @override
  Future<void> unflagTransaction(int id) async {
    final tx = await getTransaction(id);
    if (tx == null) return;
    final db = await _db.database;
    await db.update(
      _table,
      {
        'is_flagged': 0,
        'flag_reason': null,
        'updated_at': DateFormatter.nowDb(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncLog.log(
      tableName: _table,
      recordSyncId: tx.syncId,
      action: 'update',
    );
  }

  @override
  Future<Map<String, int>> getDailyTotals(int dailyFloatId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total_transactions,
        SUM(CASE WHEN transaction_type = 'cash_in' THEN 1 ELSE 0 END) as cash_in_count,
        SUM(CASE WHEN transaction_type = 'cash_out' THEN 1 ELSE 0 END) as cash_out_count,
        SUM(CASE WHEN transaction_type = 'bills_payment' THEN 1 ELSE 0 END) as bills_payment_count,
        SUM(CASE WHEN transaction_type = 'load_others' THEN 1 ELSE 0 END) as load_others_count,
        SUM(CASE WHEN transaction_type = 'cash_in' THEN amount ELSE 0 END) as total_cash_in,
        SUM(CASE WHEN transaction_type = 'cash_out' THEN amount ELSE 0 END) as total_cash_out,
        SUM(CASE WHEN transaction_type = 'bills_payment' THEN amount ELSE 0 END) as total_bills_payment,
        SUM(CASE WHEN transaction_type = 'load_others' THEN amount ELSE 0 END) as total_load_others,
        SUM(amount) as total_gross_amount,
        SUM(markup_earned) as total_markup_earned
      FROM transactions
      WHERE daily_float_id = ?
      ''',
      [dailyFloatId],
    );

    if (result.isEmpty) {
      return {
        'total_transactions': 0,
        'cash_in_count': 0,
        'cash_out_count': 0,
        'bills_payment_count': 0,
        'load_others_count': 0,
        'total_cash_in': 0,
        'total_cash_out': 0,
        'total_bills_payment': 0,
        'total_load_others': 0,
        'total_gross_amount': 0,
        'total_markup_earned': 0,
      };
    }

    final row = result.first;
    return {
      'total_transactions': (row['total_transactions'] as int?) ?? 0,
      'cash_in_count': (row['cash_in_count'] as int?) ?? 0,
      'cash_out_count': (row['cash_out_count'] as int?) ?? 0,
      'bills_payment_count': (row['bills_payment_count'] as int?) ?? 0,
      'load_others_count': (row['load_others_count'] as int?) ?? 0,
      'total_cash_in': (row['total_cash_in'] as int?) ?? 0,
      'total_cash_out': (row['total_cash_out'] as int?) ?? 0,
      'total_bills_payment': (row['total_bills_payment'] as int?) ?? 0,
      'total_load_others': (row['total_load_others'] as int?) ?? 0,
      'total_gross_amount': (row['total_gross_amount'] as int?) ?? 0,
      'total_markup_earned': (row['total_markup_earned'] as int?) ?? 0,
    };
  }
}
