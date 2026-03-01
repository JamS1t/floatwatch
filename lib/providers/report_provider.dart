import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_formatter.dart';
import '../data/models/daily_report_model.dart';
import '../data/repositories/interfaces/i_report_repository.dart';

/// ReportProvider manages daily, weekly, and monthly report data.
class ReportProvider extends ChangeNotifier {
  final IReportRepository _reportRepo;

  ReportProvider({required IReportRepository reportRepo})
      : _reportRepo = reportRepo;

  // ── State ─────────────────────────────────────────────────────────────────
  List<DailyReportModel> _reports = [];
  DailyReportModel? _selectedReport;
  Map<String, int> _weeklyTotals = {};
  Map<String, int> _monthlyTotals = {};
  bool _isLoading = false;
  String? _error;

  List<DailyReportModel> get reports => List.unmodifiable(_reports);
  DailyReportModel? get selectedReport => _selectedReport;
  Map<String, int> get weeklyTotals => Map.unmodifiable(_weeklyTotals);
  Map<String, int> get monthlyTotals => Map.unmodifiable(_monthlyTotals);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadRecentReports(int storeId, {int limit = 30}) async {
    _setLoading(true);
    try {
      _reports = await _reportRepo.getRecentReports(storeId, limit);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load reports.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReportByDate(int storeId, String date) async {
    _setLoading(true);
    try {
      _selectedReport = await _reportRepo.getDailyReportByDate(storeId, date);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load report.');
    } finally {
      _setLoading(false);
    }
  }

  /// Load weekly totals — premium feature, check SubscriptionService first.
  Future<void> loadWeeklyTotals(int storeId, String weekStartDate) async {
    _setLoading(true);
    try {
      _weeklyTotals = await _reportRepo.getWeeklyTotals(storeId, weekStartDate);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load weekly totals.');
    } finally {
      _setLoading(false);
    }
  }

  /// Load monthly totals — premium feature, check SubscriptionService first.
  Future<void> loadMonthlyTotals(int storeId, int year, int month) async {
    _setLoading(true);
    try {
      _monthlyTotals =
          await _reportRepo.getMonthlyTotals(storeId, year, month);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load monthly totals.');
    } finally {
      _setLoading(false);
    }
  }

  // ── Create (called on day close) ──────────────────────────────────────────

  Future<bool> createDailyReport({
    required int storeId,
    required int dailyFloatId,
    required Map<String, int> totals,
    required String status,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final now = DateFormatter.nowDb();
      final report = DailyReportModel(
        storeId: storeId,
        dailyFloatId: dailyFloatId,
        date: DateFormatter.todayDb(),
        totalTransactions: totals['total_transactions'] ?? 0,
        totalCashInCount: totals['cash_in_count'] ?? 0,
        totalCashOutCount: totals['cash_out_count'] ?? 0,
        totalBillsPaymentCount: totals['bills_payment_count'] ?? 0,
        totalLoadOthersCount: totals['load_others_count'] ?? 0,
        totalGrossAmount: totals['total_gross_amount'] ?? 0,
        totalMarkupEarned: totals['total_markup_earned'] ?? 0,
        status: status,
        notes: notes,
        closedBy: 'owner',
        createdAt: now,
        syncId: const Uuid().v4(),
      );

      final id = await _reportRepo.createDailyReport(report);
      final saved = report.copyWith(id: id);
      _reports = [saved, ..._reports];
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to save daily report.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
