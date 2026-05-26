import 'package:flutter_test/flutter_test.dart';

import 'package:floatwatch/core/models/batch_item_analysis.dart';
import 'package:floatwatch/core/services/ocr_result.dart';
import 'package:floatwatch/core/services/security_service.dart';
import 'package:floatwatch/data/database/database_helper.dart';
import 'package:floatwatch/data/models/daily_float_model.dart';
import 'package:floatwatch/data/models/transaction_model.dart';
import 'package:floatwatch/data/repositories/interfaces/i_daily_float_repository.dart';
import 'package:floatwatch/data/repositories/interfaces/i_transaction_repository.dart';
import 'package:floatwatch/providers/transaction_provider.dart';

// ── Fake security service (TransactionProvider requires it but doesn't use it) ──

class FakeSecurityService extends SecurityService {
  FakeSecurityService() : super(DatabaseHelper.instance);
}

// ── Fake transaction repository ──────────────────────────────────────────────

class FakeTransactionRepository implements ITransactionRepository {
  final List<TransactionModel> _store = [];

  @override
  Future<int> createTransaction(TransactionModel tx) async {
    final id = _store.length + 1;
    _store.add(tx.copyWith(id: id));
    return id;
  }

  @override
  Future<TransactionModel?> findDuplicate({
    required int storeId,
    required String referenceNumber,
    required int amount,
    required String transactionType,
  }) async {
    try {
      return _store.firstWhere(
        (t) =>
            t.storeId == storeId &&
            t.referenceNumber == referenceNumber &&
            t.amount == amount &&
            t.transactionType == transactionType,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TransactionModel?> getTransaction(int id) async => null;
  @override
  Future<List<TransactionModel>> getTransactionsByDailyFloat(int dailyFloatId) async => [];
  @override
  Future<List<TransactionModel>> getTransactionsByStore(int storeId) async => [];
  @override
  Future<List<TransactionModel>> getTransactionsByStoreAndDate(int storeId, String date) async => [];
  @override
  Future<List<TransactionModel>> getFlaggedTransactions(int storeId) async => [];
  @override
  Future<void> updateTransaction(TransactionModel transaction) async {}
  @override
  Future<void> flagTransaction(int id, String reason) async {}
  @override
  Future<void> unflagTransaction(int id) async {}
  @override
  Future<Map<String, int>> getDailyTotals(int dailyFloatId) async => {
        'total_transactions': 0,
        'total_gross_amount': 0,
        'total_markup_earned': 0,
      };
}

// ── Fake daily float repository ──────────────────────────────────────────────

class FakeDailyFloatRepository implements IDailyFloatRepository {
  final Map<String, DailyFloatModel> _byDate = {};

  void addFloat(DailyFloatModel f) {
    _byDate[f.date] = f;
  }

  @override
  Future<DailyFloatModel?> getDailyFloatByDate(int storeId, String date) async {
    return _byDate[date];
  }

  @override
  Future<DailyFloatModel?> getDailyFloat(int id) async => null;
  @override
  Future<DailyFloatModel?> getTodayFloat(int storeId) async => null;
  @override
  Future<List<DailyFloatModel>> getRecentFloats(int storeId, int limit) async => [];
  @override
  Future<int> createDailyFloat(DailyFloatModel float) async => 99;
  @override
  Future<void> updateDailyFloat(DailyFloatModel float) async {}
  @override
  Future<void> setOpeningBalance({
    required int dailyFloatId,
    required int gcashBalance,
    required int cashBalance,
    required String setBy,
  }) async {}
  @override
  Future<void> setClosingBalance({
    required int dailyFloatId,
    required int gcashBalance,
    required int cashBalance,
    required int expectedGcash,
    required int discrepancyGcash,
    required int discrepancyCash,
    required String status,
  }) async {}
  @override
  Future<void> closeDay(int dailyFloatId) async {}
  @override
  Future<void> reopenDay(int dailyFloatId) async {}
  @override
  Future<void> autoCloseDay(int dailyFloatId) async {}
  @override
  Future<List<DailyFloatModel>> getUnclosedPastFloats(int storeId) async => [];
}

// ── Helpers ──────────────────────────────────────────────────────────────────

TransactionModel _makeTx({
  int storeId = 1,
  int dailyFloatId = 1,
  String type = 'cash_in',
  int amount = 50000,
  String? ref,
}) {
  return TransactionModel(
    storeId: storeId,
    dailyFloatId: dailyFloatId,
    transactionType: type,
    amount: amount,
    markupRateTypeSnapshot: 'percentage',
    markupRateValueSnapshot: 100,
    markupEarned: 500,
    referenceNumber: ref,
    entryMethod: 'manual_owner',
    enteredByRole: 'owner',
    createdAt: '2026-03-03 10:00:00',
    updatedAt: '2026-03-03 10:00:00',
    syncId: 'test-sync-id',
  );
}

OcrResult _makeOcrItem({
  String? ref,
  int? amount,
  String? type,
  DateTime? dateTime,
}) {
  return OcrResult(
    imagePath: '',
    rawText: '',
    referenceNumber: ref,
    amountCentavos: amount,
    transactionType: type,
    transactionDateTime: dateTime,
    confidence: 0.9,
    needsManualReview: false,
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late FakeTransactionRepository txRepo;
  late FakeDailyFloatRepository floatRepo;
  late TransactionProvider provider;

  setUp(() {
    txRepo = FakeTransactionRepository();
    floatRepo = FakeDailyFloatRepository();
    provider = TransactionProvider(
      transactionRepo: txRepo,
      securityService: FakeSecurityService(),
    );
  });

  group('findDuplicate', () {
    test('returns match on exact composite key', () async {
      final tx = _makeTx(ref: 'REF123', amount: 50000, type: 'cash_in');
      await txRepo.createTransaction(tx);

      final result = await provider.checkDuplicate(
        storeId: 1,
        referenceNumber: 'REF123',
        amountCentavos: 50000,
        transactionType: 'cash_in',
      );

      expect(result, isNotNull);
      expect(result!.referenceNumber, 'REF123');
    });

    test('returns null when amount differs', () async {
      final tx = _makeTx(ref: 'REF123', amount: 50000, type: 'cash_in');
      await txRepo.createTransaction(tx);

      final result = await provider.checkDuplicate(
        storeId: 1,
        referenceNumber: 'REF123',
        amountCentavos: 60000, // different
        transactionType: 'cash_in',
      );

      expect(result, isNull);
    });

    test('returns null when type differs', () async {
      final tx = _makeTx(ref: 'REF123', amount: 50000, type: 'cash_in');
      await txRepo.createTransaction(tx);

      final result = await provider.checkDuplicate(
        storeId: 1,
        referenceNumber: 'REF123',
        amountCentavos: 50000,
        transactionType: 'cash_out', // different
      );

      expect(result, isNull);
    });
  });

  group('analyzeBatch', () {
    test('detects within-batch duplicates', () async {
      final items = [
        _makeOcrItem(
          ref: 'REF1',
          amount: 50000,
          type: 'cash_in',
          dateTime: DateTime(2026, 3, 3, 10, 0),
        ),
        _makeOcrItem(
          ref: 'REF1',
          amount: 50000,
          type: 'cash_in',
          dateTime: DateTime(2026, 3, 3, 10, 5),
        ),
      ];

      final results = await provider.analyzeBatch(
        storeId: 1,
        items: items,
        todayDate: '2026-03-03',
        floatRepo: floatRepo,
      );

      expect(results[0].status, BatchItemStatus.ready);
      expect(results[1].status, BatchItemStatus.duplicate);
    });

    test('detects DB duplicates', () async {
      await txRepo.createTransaction(
        _makeTx(ref: 'REF999', amount: 100000, type: 'cash_out'),
      );

      final items = [
        _makeOcrItem(
          ref: 'REF999',
          amount: 100000,
          type: 'cash_out',
          dateTime: DateTime(2026, 3, 3, 11, 0),
        ),
      ];

      final results = await provider.analyzeBatch(
        storeId: 1,
        items: items,
        todayDate: '2026-03-03',
        floatRepo: floatRepo,
      );

      expect(results[0].status, BatchItemStatus.duplicate);
      expect(results[0].existingTxId, isNotNull);
    });

    test('marks cross-date items (open day)', () async {
      floatRepo.addFloat(DailyFloatModel(
        id: 5,
        storeId: 1,
        date: '2026-03-02',
        status: 'open',
        isClosed: 0,
        createdAt: '2026-03-02 08:00:00',
        updatedAt: '2026-03-02 08:00:00',
        syncId: 'float-sync',
      ));

      final items = [
        _makeOcrItem(
          ref: 'REF_CROSS',
          amount: 75000,
          type: 'cash_in',
          dateTime: DateTime(2026, 3, 2, 14, 0), // yesterday
        ),
      ];

      final results = await provider.analyzeBatch(
        storeId: 1,
        items: items,
        todayDate: '2026-03-03',
        floatRepo: floatRepo,
      );

      expect(results[0].status, BatchItemStatus.crossDate);
      expect(results[0].receiptDate, '2026-03-02');
      expect(results[0].dayIsClosed, false);
    });

    test('marks cross-date items (closed day)', () async {
      floatRepo.addFloat(DailyFloatModel(
        id: 6,
        storeId: 1,
        date: '2026-03-01',
        status: 'clean',
        isClosed: 1,
        createdAt: '2026-03-01 08:00:00',
        updatedAt: '2026-03-01 20:00:00',
        syncId: 'float-closed',
      ));

      final items = [
        _makeOcrItem(
          ref: 'REF_CLOSED',
          amount: 25000,
          type: 'bills_payment',
          dateTime: DateTime(2026, 3, 1, 9, 0),
        ),
      ];

      final results = await provider.analyzeBatch(
        storeId: 1,
        items: items,
        todayDate: '2026-03-03',
        floatRepo: floatRepo,
      );

      expect(results[0].status, BatchItemStatus.crossDateClosed);
      expect(results[0].receiptDate, '2026-03-01');
      expect(results[0].dayIsClosed, true);
    });

    test('items without ref numbers are always ready', () async {
      final items = [
        _makeOcrItem(
          ref: null,
          amount: 50000,
          type: 'cash_in',
          dateTime: DateTime(2026, 3, 3, 10, 0),
        ),
        _makeOcrItem(
          ref: '',
          amount: 50000,
          type: 'cash_in',
          dateTime: DateTime(2026, 3, 3, 10, 0),
        ),
      ];

      final results = await provider.analyzeBatch(
        storeId: 1,
        items: items,
        todayDate: '2026-03-03',
        floatRepo: floatRepo,
      );

      expect(results[0].status, BatchItemStatus.ready);
      expect(results[1].status, BatchItemStatus.ready);
    });

    test('cross-date for non-existent day returns crossDate (not closed)', () async {
      // No float exists for 2026-03-02 → treated as open (will be auto-created)
      final items = [
        _makeOcrItem(
          ref: 'REF_NEW',
          amount: 30000,
          type: 'cash_in',
          dateTime: DateTime(2026, 3, 2, 15, 0),
        ),
      ];

      final results = await provider.analyzeBatch(
        storeId: 1,
        items: items,
        todayDate: '2026-03-03',
        floatRepo: floatRepo,
      );

      expect(results[0].status, BatchItemStatus.crossDate);
      expect(results[0].dayIsClosed, false);
    });
  });

  group('BatchItemAnalysis model', () {
    test('toString contains index and status', () {
      const a = BatchItemAnalysis(
        index: 2,
        status: BatchItemStatus.duplicate,
        receiptDate: '2026-03-02',
      );
      expect(a.toString(), contains('index: 2'));
      expect(a.toString(), contains('duplicate'));
    });

    test('dayIsClosed defaults to false', () {
      const a = BatchItemAnalysis(
        index: 0,
        status: BatchItemStatus.ready,
      );
      expect(a.dayIsClosed, false);
    });
  });
}
