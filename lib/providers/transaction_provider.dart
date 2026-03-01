import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/security_service.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/markup_calculator.dart';
import '../data/models/markup_settings_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/interfaces/i_transaction_repository.dart';

/// TransactionProvider manages transaction data for the current day.
class TransactionProvider extends ChangeNotifier {
  final ITransactionRepository _txRepo;
  // ignore: unused_field
  final SecurityService _security;

  TransactionProvider({
    required ITransactionRepository transactionRepo,
    required SecurityService securityService,
  })  : _txRepo = transactionRepo,
        _security = securityService;

  // ── State ─────────────────────────────────────────────────────────────────
  List<TransactionModel> _transactions = [];
  Map<String, int> _dailyTotals = {};
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  Map<String, int> get dailyTotals => Map.unmodifiable(_dailyTotals);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalMarkupEarned => _dailyTotals['total_markup_earned'] ?? 0;
  int get totalGrossAmount => _dailyTotals['total_gross_amount'] ?? 0;
  int get transactionCount => _dailyTotals['total_transactions'] ?? 0;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadTransactionsForDay(int dailyFloatId) async {
    _setLoading(true);
    try {
      _transactions = await _txRepo.getTransactionsByDailyFloat(dailyFloatId);
      _dailyTotals = await _txRepo.getDailyTotals(dailyFloatId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load transactions.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshTotals(int dailyFloatId) async {
    _dailyTotals = await _txRepo.getDailyTotals(dailyFloatId);
    notifyListeners();
  }

  // ── Add transaction ───────────────────────────────────────────────────────

  /// Create a new transaction, automatically calculating markup earned.
  Future<bool> addTransaction({
    required int storeId,
    required int dailyFloatId,
    required String transactionType,
    required int amountCentavos,
    required MarkupSettingsModel markupSettings,
    required String entryMethod,
    required String enteredByRole,
    int? enteredByStaffId,
    String? referenceNumber,
    String? receiptImagePath,
    String? missingReceiptReason,
    double? ocrConfidenceScore,
    bool oneTimePinUsed = false,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      // Calculate markup earned using snapshot of current settings
      final markupEarned = MarkupCalculator.calculate(
        amount: amountCentavos,
        rateType: markupSettings.rateType,
        rateValue: markupSettings.rateValue,
        bracketSize: markupSettings.bracketSize,
      );

      final now = DateFormatter.nowDb();
      final tx = TransactionModel(
        storeId: storeId,
        dailyFloatId: dailyFloatId,
        transactionType: transactionType,
        amount: amountCentavos,
        // Snapshot markup settings — never changes after creation
        markupRateTypeSnapshot: markupSettings.rateType,
        markupRateValueSnapshot: markupSettings.rateValue,
        markupBracketSizeSnapshot: markupSettings.bracketSize,
        markupEarned: markupEarned,
        referenceNumber: referenceNumber,
        receiptImagePath: receiptImagePath,
        entryMethod: entryMethod,
        enteredByRole: enteredByRole,
        enteredByStaffId: enteredByStaffId,
        missingReceiptReason: missingReceiptReason,
        ocrConfidenceScore: ocrConfidenceScore,
        oneTimePinUsed: oneTimePinUsed ? 1 : 0,
        createdAt: now,
        updatedAt: now,
        syncId: const Uuid().v4(),
      );

      final id = await _txRepo.createTransaction(tx);
      final saved = tx.copyWith(id: id);
      _transactions = [saved, ..._transactions];

      // Refresh aggregates
      _dailyTotals = await _txRepo.getDailyTotals(dailyFloatId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to save transaction. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Flag / unflag ─────────────────────────────────────────────────────────

  Future<void> flagTransaction(int transactionId, String reason) async {
    await _txRepo.flagTransaction(transactionId, reason);
    final idx = _transactions.indexWhere((t) => t.id == transactionId);
    if (idx >= 0) {
      _transactions[idx] =
          _transactions[idx].copyWith(isFlagged: 1, flagReason: reason);
      notifyListeners();
    }
  }

  Future<void> unflagTransaction(int transactionId) async {
    await _txRepo.unflagTransaction(transactionId);
    final idx = _transactions.indexWhere((t) => t.id == transactionId);
    if (idx >= 0) {
      _transactions[idx] = _transactions[idx].copyWith(isFlagged: 0);
      notifyListeners();
    }
  }

  void clearTransactions() {
    _transactions = [];
    _dailyTotals = {};
    notifyListeners();
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

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
