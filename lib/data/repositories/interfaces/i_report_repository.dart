import '../../models/daily_report_model.dart';

/// Repository interface for daily/weekly/monthly report data.
// TODO: Add a FirebaseReportRepository implementation for cloud sync.
abstract class IReportRepository {
  Future<DailyReportModel?> getDailyReport(int id);
  Future<DailyReportModel?> getDailyReportByDate(int storeId, String date);
  Future<List<DailyReportModel>> getReportsInRange(
    int storeId,
    String startDate,
    String endDate,
  );
  Future<List<DailyReportModel>> getRecentReports(int storeId, int limit);
  Future<int> createDailyReport(DailyReportModel report);
  Future<void> updateDailyReport(DailyReportModel report);

  /// Aggregate totals for a week (premium feature).
  /// Returns a map of totals: { 'totalMarkupEarned': int, ... }
  Future<Map<String, int>> getWeeklyTotals(int storeId, String weekStartDate);

  /// Aggregate totals for a month (premium feature).
  Future<Map<String, int>> getMonthlyTotals(int storeId, int year, int month);
}
