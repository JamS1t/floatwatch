import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_formatter.dart';
import '../core/utils/markup_calculator.dart';
import '../data/models/daily_float_model.dart';
import '../data/repositories/interfaces/i_daily_float_repository.dart';

/// DailyFloatProvider manages the current day's float record.
class DailyFloatProvider extends ChangeNotifier {
  final IDailyFloatRepository _floatRepo;

  DailyFloatProvider({required IDailyFloatRepository dailyFloatRepo})
      : _floatRepo = dailyFloatRepo;

  // ── State ─────────────────────────────────────────────────────────────────
  DailyFloatModel? _todayFloat;
  List<DailyFloatModel> _recentFloats = [];
  List<DailyFloatModel> _unclosedPastFloats = [];
  bool _isLoading = false;
  String? _error;

  DailyFloatModel? get todayFloat => _todayFloat;
  List<DailyFloatModel> get recentFloats => List.unmodifiable(_recentFloats);
  List<DailyFloatModel> get unclosedPastFloats => List.unmodifiable(_unclosedPastFloats);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDayOpen => _todayFloat != null && !_todayFloat!.closed;
  bool get hasTodayFloat => _todayFloat != null;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadTodayFloat(int storeId) async {
    _setLoading(true);
    try {
      _todayFloat = await _floatRepo.getTodayFloat(storeId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load today\'s float.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRecentFloats(int storeId, {int limit = 30}) async {
    _setLoading(true);
    try {
      _recentFloats = await _floatRepo.getRecentFloats(storeId, limit);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recent floats.');
    } finally {
      _setLoading(false);
    }
  }

  // ── Open day ──────────────────────────────────────────────────────────────

  /// Create the daily_float record for today if it doesn't exist yet.
  Future<bool> openDay(int storeId) async {
    _setLoading(true);
    try {
      final existing = await _floatRepo.getTodayFloat(storeId);
      if (existing != null) {
        _todayFloat = existing;
        notifyListeners();
        return true;
      }
      final now = DateFormatter.nowDb();
      final float = DailyFloatModel(
        storeId: storeId,
        date: DateFormatter.todayDb(),
        status: 'open',
        createdAt: now,
        updatedAt: now,
        syncId: const Uuid().v4(),
      );
      final id = await _floatRepo.createDailyFloat(float);
      _todayFloat = float.copyWith(id: id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to open today\'s float.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Opening balance ───────────────────────────────────────────────────────

  Future<bool> setOpeningBalance({
    required int gcashBalance,
    required int cashBalance,
    required String setBy,
  }) async {
    if (_todayFloat?.id == null) return false;
    _setLoading(true);
    try {
      await _floatRepo.setOpeningBalance(
        dailyFloatId: _todayFloat!.id!,
        gcashBalance: gcashBalance,
        cashBalance: cashBalance,
        setBy: setBy,
      );
      _todayFloat = _todayFloat!.copyWith(
        openingGcashBalance: gcashBalance,
        openingCash: cashBalance,
        openingSetBy: setBy,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to set opening balance.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Close day ─────────────────────────────────────────────────────────────

  /// Calculate expected balance, discrepancy, determine status, then close.
  Future<bool> closeDay({
    required int closingGcash,
    required int closingCash,
    required Map<String, int> dailyTotals,
  }) async {
    if (_todayFloat?.id == null) return false;
    _setLoading(true);
    try {
      final expectedGcash = MarkupCalculator.expectedClosingGcash(
        openingGcash: _todayFloat!.openingGcashBalance ?? 0,
        totalCashIn: dailyTotals['total_cash_in'] ?? 0,
        totalCashOut: dailyTotals['total_cash_out'] ?? 0,
        totalBillsPayment: dailyTotals['total_bills_payment'] ?? 0,
        totalLoadOthers: dailyTotals['total_load_others'] ?? 0,
      );

      final discrepancyGcash = closingGcash - expectedGcash;
      final discrepancyCash = closingCash -
          ((_todayFloat!.openingCash ?? 0) +
              (dailyTotals['total_cash_in'] ?? 0) +
              (dailyTotals['total_bills_payment'] ?? 0) +
              (dailyTotals['total_load_others'] ?? 0) -
              (dailyTotals['total_cash_out'] ?? 0));

      final status = MarkupCalculator.discrepancyStatus(discrepancyGcash);

      await _floatRepo.setClosingBalance(
        dailyFloatId: _todayFloat!.id!,
        gcashBalance: closingGcash,
        cashBalance: closingCash,
        expectedGcash: expectedGcash,
        discrepancyGcash: discrepancyGcash,
        discrepancyCash: discrepancyCash,
        status: status,
      );
      await _floatRepo.closeDay(_todayFloat!.id!);

      _todayFloat = _todayFloat!.copyWith(
        closingGcashBalance: closingGcash,
        closingCash: closingCash,
        expectedGcashBalance: expectedGcash,
        discrepancyGcash: discrepancyGcash,
        discrepancyCash: discrepancyCash,
        status: status,
        isClosed: 1,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to close the day. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Reopen day ────────────────────────────────────────────────────────────

  /// Reset a closed day back to open, clearing all closing/discrepancy fields.
  Future<bool> reopenDay() async {
    if (_todayFloat?.id == null) return false;
    _setLoading(true);
    try {
      await _floatRepo.reopenDay(_todayFloat!.id!);
      // Reload from DB so closing fields are correctly null in the model.
      _todayFloat = await _floatRepo.getDailyFloat(_todayFloat!.id!);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to re-open the day.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Cross-date helpers ──────────────────────────────────────────────────

  /// Get the daily_float record for a specific date (may be null).
  Future<DailyFloatModel?> getFloatByDate(int storeId, String dateStr) async {
    return _floatRepo.getDailyFloatByDate(storeId, dateStr);
  }

  /// Get existing daily_float for a date, or create a new open one if none exists.
  /// Also updates [_recentFloats] so history screens reflect the new record immediately.
  Future<DailyFloatModel> getOrCreateFloatForDate(
      int storeId, String dateStr) async {
    final existing = await _floatRepo.getDailyFloatByDate(storeId, dateStr);
    if (existing != null) return existing;

    final now = DateFormatter.nowDb();
    final float = DailyFloatModel(
      storeId: storeId,
      date: dateStr,
      status: 'open',
      createdAt: now,
      updatedAt: now,
      syncId: const Uuid().v4(),
    );
    final id = await _floatRepo.createDailyFloat(float);
    final saved = float.copyWith(id: id);

    // Keep _recentFloats up to date so history/report screens see the new float.
    _recentFloats = [..._recentFloats, saved]
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    return saved;
  }

  /// Reopen a specific closed day by its id (for cross-date receipt routing).
  Future<bool> reopenDayById(int dailyFloatId) async {
    try {
      await _floatRepo.reopenDay(dailyFloatId);
      return true;
    } catch (e) {
      _setError('Failed to re-open the day.');
      return false;
    }
  }

  // ── Unclosed past floats ──────────────────────────────────────────────────

  Future<void> loadUnclosedPastFloats(int storeId) async {
    try {
      _unclosedPastFloats = await _floatRepo.getUnclosedPastFloats(storeId);
      notifyListeners();
    } catch (_) {}
  }

  /// Silently mark a system-created float as auto_closed.
  Future<void> autoCloseFloat(int dailyFloatId) async {
    try {
      await _floatRepo.autoCloseDay(dailyFloatId);
      _recentFloats = _recentFloats.map((f) {
        if (f.id == dailyFloatId) return f.copyWith(isClosed: 1, status: 'auto_closed');
        return f;
      }).toList();
      _unclosedPastFloats.removeWhere((f) => f.id == dailyFloatId);
      notifyListeners();
    } catch (_) {}
  }

  /// Close a past-day float (not today) with physical count data.
  /// Returns true on success. Does NOT set _todayFloat.
  Future<bool> closePastDay({
    required DailyFloatModel float,
    required int closingGcash,
    required int closingCash,
    required Map<String, int> dailyTotals,
  }) async {
    if (float.id == null) return false;
    try {
      final expectedGcash = MarkupCalculator.expectedClosingGcash(
        openingGcash: float.openingGcashBalance ?? 0,
        totalCashIn: dailyTotals['total_cash_in'] ?? 0,
        totalCashOut: dailyTotals['total_cash_out'] ?? 0,
        totalBillsPayment: dailyTotals['total_bills_payment'] ?? 0,
        totalLoadOthers: dailyTotals['total_load_others'] ?? 0,
      );
      final discrepancyGcash = closingGcash - expectedGcash;
      final discrepancyCash = closingCash -
          ((float.openingCash ?? 0) +
              (dailyTotals['total_cash_in'] ?? 0) +
              (dailyTotals['total_bills_payment'] ?? 0) +
              (dailyTotals['total_load_others'] ?? 0) -
              (dailyTotals['total_cash_out'] ?? 0));
      final status = MarkupCalculator.discrepancyStatus(discrepancyGcash);

      await _floatRepo.setClosingBalance(
        dailyFloatId: float.id!,
        gcashBalance: closingGcash,
        cashBalance: closingCash,
        expectedGcash: expectedGcash,
        discrepancyGcash: discrepancyGcash,
        discrepancyCash: discrepancyCash,
        status: status,
      );
      await _floatRepo.closeDay(float.id!);

      _unclosedPastFloats.removeWhere((f) => f.id == float.id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
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
