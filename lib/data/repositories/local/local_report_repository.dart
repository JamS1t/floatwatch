import '../../database/database_helper.dart';
import '../../database/sync_log_helper.dart';
import '../../models/daily_report_model.dart';
import '../interfaces/i_report_repository.dart';

/// Local SQLite implementation of [IReportRepository].
// TODO: Create FirebaseReportRepository for cloud sync.
class LocalReportRepository implements IReportRepository {
  final DatabaseHelper _db;
  late final SyncLogHelper _syncLog;

  LocalReportRepository(this._db) {
    _syncLog = SyncLogHelper(_db);
  }

  static const _table = 'daily_reports';

  @override
  Future<DailyReportModel?> getDailyReport(int id) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : DailyReportModel.fromMap(rows.first);
  }

  @override
  Future<DailyReportModel?> getDailyReportByDate(int storeId, String date) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'store_id = ? AND date = ?',
      whereArgs: [storeId, date],
      limit: 1,
    );
    return rows.isEmpty ? null : DailyReportModel.fromMap(rows.first);
  }

  @override
  Future<List<DailyReportModel>> getReportsInRange(
    int storeId,
    String startDate,
    String endDate,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'store_id = ? AND date >= ? AND date <= ?',
      whereArgs: [storeId, startDate, endDate],
      orderBy: 'date DESC',
    );
    return rows.map(DailyReportModel.fromMap).toList();
  }

  @override
  Future<List<DailyReportModel>> getRecentReports(int storeId, int limit) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(DailyReportModel.fromMap).toList();
  }

  @override
  Future<int> createDailyReport(DailyReportModel report) async {
    final db = await _db.database;
    final id = await db.insert(_table, report.toMap());
    await _syncLog.log(
      tableName: _table,
      recordSyncId: report.syncId,
      action: 'create',
    );
    return id;
  }

  @override
  Future<void> updateDailyReport(DailyReportModel report) async {
    final db = await _db.database;
    await db.update(_table, report.toMap(), where: 'id = ?', whereArgs: [report.id]);
    await _syncLog.log(
      tableName: _table,
      recordSyncId: report.syncId,
      action: 'update',
    );
  }

  @override
  Future<Map<String, int>> getWeeklyTotals(
    int storeId,
    String weekStartDate,
  ) async {
    // weekStartDate is yyyy-MM-dd (Monday)
    final weekEnd = DateTime.parse(weekStartDate).add(const Duration(days: 6));
    final weekEndStr =
        '${weekEnd.year.toString().padLeft(4, '0')}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';

    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total_days,
        SUM(total_transactions) as total_transactions,
        SUM(total_gross_amount) as total_gross_amount,
        SUM(total_markup_earned) as total_markup_earned,
        SUM(total_cash_in_count) as total_cash_in_count,
        SUM(total_cash_out_count) as total_cash_out_count,
        SUM(total_bills_payment_count) as total_bills_payment_count,
        SUM(total_load_others_count) as total_load_others_count
      FROM daily_reports
      WHERE store_id = ? AND date >= ? AND date <= ?
      ''',
      [storeId, weekStartDate, weekEndStr],
    );

    return _aggregateRow(result);
  }

  @override
  Future<Map<String, int>> getMonthlyTotals(
    int storeId,
    int year,
    int month,
  ) async {
    final startDate =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDate =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total_days,
        SUM(total_transactions) as total_transactions,
        SUM(total_gross_amount) as total_gross_amount,
        SUM(total_markup_earned) as total_markup_earned,
        SUM(total_cash_in_count) as total_cash_in_count,
        SUM(total_cash_out_count) as total_cash_out_count,
        SUM(total_bills_payment_count) as total_bills_payment_count,
        SUM(total_load_others_count) as total_load_others_count
      FROM daily_reports
      WHERE store_id = ? AND date >= ? AND date <= ?
      ''',
      [storeId, startDate, endDate],
    );

    return _aggregateRow(result);
  }

  Map<String, int> _aggregateRow(List<Map<String, Object?>> result) {
    if (result.isEmpty) return _emptyAggregates();
    final row = result.first;
    return {
      'total_days': (row['total_days'] as int?) ?? 0,
      'total_transactions': (row['total_transactions'] as int?) ?? 0,
      'total_gross_amount': (row['total_gross_amount'] as int?) ?? 0,
      'total_markup_earned': (row['total_markup_earned'] as int?) ?? 0,
      'total_cash_in_count': (row['total_cash_in_count'] as int?) ?? 0,
      'total_cash_out_count': (row['total_cash_out_count'] as int?) ?? 0,
      'total_bills_payment_count': (row['total_bills_payment_count'] as int?) ?? 0,
      'total_load_others_count': (row['total_load_others_count'] as int?) ?? 0,
    };
  }

  Map<String, int> _emptyAggregates() => {
        'total_days': 0,
        'total_transactions': 0,
        'total_gross_amount': 0,
        'total_markup_earned': 0,
        'total_cash_in_count': 0,
        'total_cash_out_count': 0,
        'total_bills_payment_count': 0,
        'total_load_others_count': 0,
      };
}
