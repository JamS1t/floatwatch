import 'package:flutter_test/flutter_test.dart';
import 'package:floatwatch/core/utils/markup_calculator.dart';

void main() {
  group('MarkupCalculator.calculate — percentage', () {
    test('1% on ₱1,000 = ₱10 (1000 centavos)', () {
      // 1.00% stored as 100 (percent × 100)
      // 100000 × 100 / 10000 = 1000
      expect(
        MarkupCalculator.calculate(
          amount: 100000,
          rateType: 'percentage',
          rateValue: 100,
        ),
        equals(1000),
      );
    });

    test('0.5% on ₱500 = ₱2.50 (250 centavos)', () {
      // 0.50% stored as 50
      // 50000 × 50 / 10000 = 250
      expect(
        MarkupCalculator.calculate(
          amount: 50000,
          rateType: 'percentage',
          rateValue: 50,
        ),
        equals(250),
      );
    });

    test('2% on ₱3,000 = ₱60 (6000 centavos)', () {
      // 2.00% stored as 200
      // 300000 × 200 / 10000 = 6000
      expect(
        MarkupCalculator.calculate(
          amount: 300000,
          rateType: 'percentage',
          rateValue: 200,
        ),
        equals(6000),
      );
    });

    test('percentage rounds to nearest centavo', () {
      // 1% of ₱3.33 (333 centavos): 333 × 100 / 10000 = 3.33 → rounds to 3
      expect(
        MarkupCalculator.calculate(
          amount: 333,
          rateType: 'percentage',
          rateValue: 100,
        ),
        equals(3),
      );
    });

    test('zero amount gives zero markup', () {
      expect(
        MarkupCalculator.calculate(
          amount: 0,
          rateType: 'percentage',
          rateValue: 100,
        ),
        equals(0),
      );
    });
  });

  group('MarkupCalculator.calculate — fixed', () {
    test('₱10 flat fee returns 1000 centavos regardless of amount', () {
      expect(
        MarkupCalculator.calculate(
          amount: 100000,
          rateType: 'fixed',
          rateValue: 1000,
        ),
        equals(1000),
      );
    });

    test('fixed fee on small amount still returns full fee', () {
      expect(
        MarkupCalculator.calculate(
          amount: 500,
          rateType: 'fixed',
          rateValue: 1000,
        ),
        equals(1000),
      );
    });

    test('zero fixed fee returns zero', () {
      expect(
        MarkupCalculator.calculate(
          amount: 100000,
          rateType: 'fixed',
          rateValue: 0,
        ),
        equals(0),
      );
    });
  });

  group('MarkupCalculator.calculate — per_bracket', () {
    test('₱750 / ₱500 bracket / ₱10 per bracket = ₱20 (2 brackets)', () {
      // ceil(75000 / 50000) = 2 brackets × 1000 = 2000 centavos = ₱20
      expect(
        MarkupCalculator.calculate(
          amount: 75000,
          rateType: 'per_bracket',
          rateValue: 1000,
          bracketSize: 50000,
        ),
        equals(2000),
      );
    });

    test('exact bracket — ₱500 / ₱500 bracket / ₱10 = ₱10 (1 bracket)', () {
      // ceil(50000 / 50000) = 1 bracket × 1000 = 1000 centavos = ₱10
      expect(
        MarkupCalculator.calculate(
          amount: 50000,
          rateType: 'per_bracket',
          rateValue: 1000,
          bracketSize: 50000,
        ),
        equals(1000),
      );
    });

    test('₱1 above bracket rounds up — ₱501 / ₱500 bracket = 2 brackets', () {
      // ceil(50100 / 50000) = 2 brackets × 1000 = 2000
      expect(
        MarkupCalculator.calculate(
          amount: 50100,
          rateType: 'per_bracket',
          rateValue: 1000,
          bracketSize: 50000,
        ),
        equals(2000),
      );
    });

    test('throws when bracketSize is null', () {
      expect(
        () => MarkupCalculator.calculate(
          amount: 50000,
          rateType: 'per_bracket',
          rateValue: 1000,
          bracketSize: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when bracketSize is zero', () {
      expect(
        () => MarkupCalculator.calculate(
          amount: 50000,
          rateType: 'per_bracket',
          rateValue: 1000,
          bracketSize: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('MarkupCalculator.calculate — unknown rateType', () {
    test('throws ArgumentError for unknown rate type', () {
      expect(
        () => MarkupCalculator.calculate(
          amount: 50000,
          rateType: 'unknown_type',
          rateValue: 100,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('MarkupCalculator.expectedClosingGcash', () {
    test('cash in decreases GCash', () {
      // Opening 100k, 20k cash in → GCash decreases by 20k
      expect(
        MarkupCalculator.expectedClosingGcash(
          openingGcash: 1000000,
          totalCashIn: 200000,
          totalCashOut: 0,
          totalBillsPayment: 0,
          totalLoadOthers: 0,
        ),
        equals(800000),
      );
    });

    test('cash out increases GCash', () {
      // Opening 100k, 20k cash out → GCash increases by 20k
      expect(
        MarkupCalculator.expectedClosingGcash(
          openingGcash: 1000000,
          totalCashIn: 0,
          totalCashOut: 200000,
          totalBillsPayment: 0,
          totalLoadOthers: 0,
        ),
        equals(1200000),
      );
    });

    test('bills payment decreases GCash', () {
      expect(
        MarkupCalculator.expectedClosingGcash(
          openingGcash: 1000000,
          totalCashIn: 0,
          totalCashOut: 0,
          totalBillsPayment: 100000,
          totalLoadOthers: 0,
        ),
        equals(900000),
      );
    });

    test('load others decreases GCash', () {
      expect(
        MarkupCalculator.expectedClosingGcash(
          openingGcash: 1000000,
          totalCashIn: 0,
          totalCashOut: 0,
          totalBillsPayment: 0,
          totalLoadOthers: 50000,
        ),
        equals(950000),
      );
    });

    test('full day scenario with mixed transactions', () {
      // Opening: ₱10,000 (1,000,000 centavos)
      // Cash In: ₱2,000 (200,000) — decreases GCash
      // Cash Out: ₱1,000 (100,000) — increases GCash
      // Bills: ₱500 (50,000) — decreases GCash
      // Load: ₱300 (30,000) — decreases GCash
      // Expected = 1,000,000 - 200,000 + 100,000 - 50,000 - 30,000 = 820,000
      expect(
        MarkupCalculator.expectedClosingGcash(
          openingGcash: 1000000,
          totalCashIn: 200000,
          totalCashOut: 100000,
          totalBillsPayment: 50000,
          totalLoadOthers: 30000,
        ),
        equals(820000),
      );
    });

    test('no transactions — closing equals opening', () {
      expect(
        MarkupCalculator.expectedClosingGcash(
          openingGcash: 500000,
          totalCashIn: 0,
          totalCashOut: 0,
          totalBillsPayment: 0,
          totalLoadOthers: 0,
        ),
        equals(500000),
      );
    });
  });

  group('MarkupCalculator.discrepancyStatus', () {
    test('zero discrepancy is clean', () {
      expect(MarkupCalculator.discrepancyStatus(0), equals('clean'));
    });

    test('₱10 discrepancy is clean (boundary)', () {
      expect(MarkupCalculator.discrepancyStatus(1000), equals('clean'));
    });

    test('₱10.01 discrepancy is warning', () {
      expect(MarkupCalculator.discrepancyStatus(1001), equals('warning'));
    });

    test('₱200 discrepancy is warning (boundary)', () {
      expect(MarkupCalculator.discrepancyStatus(20000), equals('warning'));
    });

    test('₱200.01 discrepancy is flagged', () {
      expect(MarkupCalculator.discrepancyStatus(20001), equals('flagged'));
    });

    test('negative discrepancy uses absolute value — ₱-5 is clean', () {
      expect(MarkupCalculator.discrepancyStatus(-500), equals('clean'));
    });

    test('negative discrepancy uses absolute value — ₱-500 is flagged', () {
      expect(MarkupCalculator.discrepancyStatus(-50000), equals('flagged'));
    });
  });

  group('MarkupCalculator.percentageDisplay', () {
    test('100 → "1.00%"', () {
      expect(MarkupCalculator.percentageDisplay(100), equals('1.00%'));
    });

    test('50 → "0.50%"', () {
      expect(MarkupCalculator.percentageDisplay(50), equals('0.50%'));
    });

    test('250 → "2.50%"', () {
      expect(MarkupCalculator.percentageDisplay(250), equals('2.50%'));
    });
  });

  group('MarkupCalculator.bracketCount', () {
    test('exact bracket → 1', () {
      expect(MarkupCalculator.bracketCount(50000, 50000), equals(1));
    });

    test('1 centavo over → rounds up to 2', () {
      expect(MarkupCalculator.bracketCount(50001, 50000), equals(2));
    });

    test('zero bracket size → returns 0', () {
      expect(MarkupCalculator.bracketCount(50000, 0), equals(0));
    });
  });
}
