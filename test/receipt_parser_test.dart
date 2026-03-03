import 'package:flutter_test/flutter_test.dart';
import 'package:floatwatch/core/services/receipt_parser.dart';
import 'package:floatwatch/core/services/ocr_result.dart';
import 'package:floatwatch/core/constants/app_constants.dart';

void main() {
  late ReceiptParser parser;

  setUp(() {
    parser = ReceiptParser();
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Amount extraction
  // ══════════════════════════════════════════════════════════════════════════

  group('Amount extraction', () {
    test('labeled "Amount ₱500.00" → 50000 centavos', () {
      expect(parser.extractAmount('Amount ₱500.00'), equals(50000));
    });

    test('labeled "Total Amount PHP 1,500.00" → 150000 centavos', () {
      expect(
        parser.extractAmount('Total Amount PHP 1,500.00'),
        equals(150000),
      );
    });

    test('labeled "You sent ₱200.00" → 20000 centavos', () {
      expect(parser.extractAmount('You sent ₱200.00'), equals(20000));
    });

    test('standalone "₱ 1,000.00" → 100000 centavos', () {
      expect(parser.extractAmount('₱ 1,000.00'), equals(100000));
    });

    test('PHP prefix "PHP500" → 50000 centavos', () {
      expect(parser.extractAmount('PHP500'), equals(50000));
    });

    test('no amount found → null', () {
      expect(parser.extractAmount('No amount here'), isNull);
    });

    test('labeled amount takes priority over standalone ₱', () {
      // "Amount ₱500.00" should win over a stray "₱100.00" elsewhere
      expect(
        parser.extractAmount('Balance ₱100.00\nAmount ₱500.00'),
        equals(50000),
      );
    });

    test('amount with centavos "₱1,234.56" → 123456 centavos', () {
      expect(parser.extractAmount('₱1,234.56'), equals(123456));
    });

    test('GCash layout: "Amount" label then ₱ on next line', () {
      expect(
        parser.extractAmount('Amount\n₱500.00'),
        equals(50000),
      );
    });

    test('GCash layout: "Amount" label then P on next line (OCR artifact)', () {
      expect(
        parser.extractAmount('Amount\nP500.00'),
        equals(50000),
      );
    });

    test('OCR artifact capital P prefix "P1,500.00" → 150000', () {
      expect(parser.extractAmount('P1,500.00'), equals(150000));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Reference number extraction
  // ══════════════════════════════════════════════════════════════════════════

  group('Reference number extraction', () {
    test('"Ref No. 1234567890123" → "1234567890123"', () {
      expect(
        parser.extractReferenceNumber('Ref No. 1234567890123'),
        equals('1234567890123'),
      );
    });

    test('"Reference Number: 1234 567 890 1234" → strips spaces', () {
      expect(
        parser.extractReferenceNumber('Reference Number: 1234 567 890 1234'),
        equals('12345678901234'),
      );
    });

    test('"Ref. No.: 1234567890123" → "1234567890123"', () {
      expect(
        parser.extractReferenceNumber('Ref. No.: 1234567890123'),
        equals('1234567890123'),
      );
    });

    test('"Ref# 9876543210987" → "9876543210987"', () {
      expect(
        parser.extractReferenceNumber('Ref# 9876543210987'),
        equals('9876543210987'),
      );
    });

    test('"Reference No. 790823820" (9-digit load ref) → "790823820"', () {
      expect(
        parser.extractReferenceNumber('Reference No. 790823820'),
        equals('790823820'),
      );
    });

    test('ML Kit split: "Reference No." and "742851717 0" on separate lines', () {
      // Real OCR output: ML Kit puts label and number in separate text blocks
      // with ad text in between. The "0" is the copy icon read as a character.
      const ocrText = '''Reference No.
May FREE
Health Insurance
kada load mo!
99.00
Nov 18, 2025 12:45 PM
742851717 0
P 99.00''';
      expect(
        parser.extractReferenceNumber(ocrText),
        equals('742851717'),
      );
    });

    test('ML Kit split: standalone 9-digit ref without copy icon artifact', () {
      const ocrText = '''Reference No.
Some ad text
790823820
More text''';
      expect(
        parser.extractReferenceNumber(ocrText),
        equals('790823820'),
      );
    });

    test('no reference → null', () {
      expect(parser.extractReferenceNumber('No ref here'), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Phone number extraction
  // ══════════════════════════════════════════════════════════════════════════

  group('Phone number extraction', () {
    test('"09171234567" → ["09171234567"]', () {
      expect(
        parser.extractPhoneNumbers('09171234567'),
        equals(['09171234567']),
      );
    });

    test('"+63 917 123 4567" → ["09171234567"]', () {
      expect(
        parser.extractPhoneNumbers('+63 917 123 4567'),
        equals(['09171234567']),
      );
    });

    test('"0917 123 4567" → ["09171234567"]', () {
      expect(
        parser.extractPhoneNumbers('0917 123 4567'),
        equals(['09171234567']),
      );
    });

    test('"0917-123-4567" → ["09171234567"]', () {
      expect(
        parser.extractPhoneNumbers('0917-123-4567'),
        equals(['09171234567']),
      );
    });

    test('multiple numbers extracted', () {
      expect(
        parser.extractPhoneNumbers('From 09171234567 to 09291234567'),
        equals(['09171234567', '09291234567']),
      );
    });

    test('no phone → empty list', () {
      expect(parser.extractPhoneNumbers('No phone here'), isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Date/time extraction
  // ══════════════════════════════════════════════════════════════════════════

  group('Date/time extraction', () {
    test('"Mar 01, 2026 3:45 PM" → DateTime(2026, 3, 1, 15, 45)', () {
      expect(
        parser.extractDateTime('Mar 01, 2026 3:45 PM'),
        equals(DateTime(2026, 3, 1, 15, 45)),
      );
    });

    test('"January 15, 2026, 10:30:00 AM" → with seconds', () {
      expect(
        parser.extractDateTime('January 15, 2026, 10:30:00 AM'),
        equals(DateTime(2026, 1, 15, 10, 30, 0)),
      );
    });

    test('"03/01/2026 3:45 PM" → DateTime(2026, 3, 1, 15, 45)', () {
      expect(
        parser.extractDateTime('03/01/2026 3:45 PM'),
        equals(DateTime(2026, 3, 1, 15, 45)),
      );
    });

    test('"2026-03-01 15:45" → ISO-ish format', () {
      expect(
        parser.extractDateTime('2026-03-01 15:45'),
        equals(DateTime(2026, 3, 1, 15, 45)),
      );
    });

    test('"Jan 15, 2026" → date only, midnight', () {
      expect(
        parser.extractDateTime('Jan 15, 2026'),
        equals(DateTime(2026, 1, 15)),
      );
    });

    test('12:00 AM → midnight (hour 0)', () {
      expect(
        parser.extractDateTime('Mar 01, 2026 12:00 AM'),
        equals(DateTime(2026, 3, 1, 0, 0)),
      );
    });

    test('12:00 PM → noon (hour 12)', () {
      expect(
        parser.extractDateTime('Mar 01, 2026 12:00 PM'),
        equals(DateTime(2026, 3, 1, 12, 0)),
      );
    });

    test('"Feb 26,2026 6:02 PM" → no space before year (real GCash format)', () {
      expect(
        parser.extractDateTime('Feb 26,2026 6:02 PM'),
        equals(DateTime(2026, 2, 26, 18, 2)),
      );
    });

    test('"Feb 26,2026" date-only no space before year → date only', () {
      expect(
        parser.extractDateTime('Feb 26,2026'),
        equals(DateTime(2026, 2, 26)),
      );
    });

    test('no date found → null', () {
      expect(parser.extractDateTime('No date here'), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Transaction type classification
  // ══════════════════════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════════════════════
  // Layer 1: "Paid via GCash" vs "Sent via GCash"
  // ══════════════════════════════════════════════════════════════════════════

  group('Layer 1 — Paid vs Sent verb detection', () {
    test('"Paid via GCash" with no other keywords → txLoadOthers', () {
      expect(
        parser.classifyType(
          'POWER ALL 99\nPaid via GCash\nAmount 99.00',
          ['09695101423'],
          '09171111111',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('"Paid via GCash" + bills keyword → txBillsPayment', () {
      expect(
        parser.classifyType(
          'Meralco\nPaid via GCash\nAmount ₱2,500.00',
          [],
          '09171111111',
        ),
        equals(AppConstants.txBillsPayment),
      );
    });

    test('"Sent via GCash" + customer number → txCashIn', () {
      expect(
        parser.classifyType(
          'Sent via GCash\nTotal Amount Sent\nP5,271.00',
          ['09292222222'],
          '09631853737',
        ),
        equals(AppConstants.txCashIn),
      );
    });

    test('"Sent via GCash" + owner number → txCashOut', () {
      expect(
        parser.classifyType(
          'Sent via GCash\nTotal Amount Sent\nP1,000.00',
          ['09631853737'],
          '09631853737',
        ),
        equals(AppConstants.txCashOut),
      );
    });

    test('"Sent via GCash" + no phones → null (needs review)', () {
      expect(
        parser.classifyType(
          'Sent via GCash\nTotal Amount Sent\nP500.00',
          [],
          '09171111111',
        ),
        isNull,
      );
    });

    test('"Total Amount Sent" alone (no "Sent via") + customer number → txCashIn', () {
      expect(
        parser.classifyType(
          'Total Amount Sent\nP500.00',
          ['09339999999'],
          '09171111111',
        ),
        equals(AppConstants.txCashIn),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Layer 2a: Load-specific indicators
  // ══════════════════════════════════════════════════════════════════════════

  group('Layer 2a — Load indicators', () {
    test('"Paid via GCash" + "Schedule for Autoload" → txLoadOthers', () {
      expect(
        parser.classifyType(
          'ALL ACCESS 99\nPaid via GCash\nSchedule for Autoload\nAmount 99.00',
          ['09695101423'],
          '09171111111',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('"Paid via GCash" + "Convenience Fee" → txLoadOthers', () {
      expect(
        parser.classifyType(
          'ML 15\nPaid via GCash\nAmount 15.00\nConvenience Fee 2.00',
          ['09511757238'],
          '09171111111',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('"Paid via GCash" even with owner number → txLoadOthers (not cash out)', () {
      // Owner bought load for their own number — "Paid via GCash" wins
      expect(
        parser.classifyType(
          'POWER ALL TIKTOK 99\nPaid via GCash\nAmount 99.00\nConvenience Fee 3.00',
          ['09171111111'],
          '09171111111',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('telco promo name "EasySURF" in fallback → txLoadOthers', () {
      // No "Paid via GCash" but telco promo name present
      expect(
        parser.classifyType(
          'EasySURF50 5G FunALIW\nAmount 50.00',
          ['09750761364'],
          '09171111111',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('"Schedule for Autoload" in fallback → txLoadOthers', () {
      expect(
        parser.classifyType(
          'Some receipt\nSchedule for Autoload\nAmount 99.00',
          [],
          '09171111111',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('"Convenience Fee" in fallback → txLoadOthers', () {
      expect(
        parser.classifyType(
          'Some receipt\nAmount 99.00\nConvenience Fee 3.00',
          [],
          '09171111111',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Fallback classification (no paid/sent verb)
  // ══════════════════════════════════════════════════════════════════════════

  group('Fallback classification', () {
    test('receipt with "bills payment" keyword → txBillsPayment', () {
      expect(
        parser.classifyType(
          'GCash Bills Payment\nMeralco\nAmount ₱2,500.00',
          [],
          '09171111111',
        ),
        equals(AppConstants.txBillsPayment),
      );
    });

    test('receipt with "Meralco" keyword → txBillsPayment', () {
      expect(
        parser.classifyType(
          'Payment to Meralco\n₱1,500.00',
          [],
          '09171111111',
        ),
        equals(AppConstants.txBillsPayment),
      );
    });

    test('receipt with "buy load" keyword → txLoadOthers', () {
      expect(
        parser.classifyType(
          'Buy Load\nSmart Prepaid\n₱100.00',
          [],
          '09171111111',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('owner number in receipt → txCashOut', () {
      expect(
        parser.classifyType(
          'Transaction\n₱500.00',
          ['09292222222', '09631853737'],
          '09631853737',
        ),
        equals(AppConstants.txCashOut),
      );
    });

    test('only customer number in receipt → txCashIn', () {
      expect(
        parser.classifyType(
          'Transaction\n₱500.00',
          ['09292222222'],
          '09631853737',
        ),
        equals(AppConstants.txCashIn),
      );
    });

    test('no phones, no keywords → null, needs review', () {
      expect(
        parser.classifyType(
          'Some random receipt text\nP500.00',
          [],
          '09171111111',
        ),
        isNull,
      );
    });

    test('non-owner number, no keywords → txCashIn', () {
      expect(
        parser.classifyType(
          'Some random text\n₱500.00',
          ['09339999999'],
          '09171111111',
        ),
        equals(AppConstants.txCashIn),
      );
    });

    test('bills keywords take priority over cash in/out', () {
      expect(
        parser.classifyType(
          'Bills Payment\nPLDT\nFrom 09171111111',
          ['09171111111'],
          '09171111111',
        ),
        equals(AppConstants.txBillsPayment),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Real GCash receipt OCR text classification
  // ══════════════════════════════════════════════════════════════════════════

  group('Real receipt classification', () {
    test('real load receipt: POWER ALL FB 99 → txLoadOthers', () {
      const receipt = '''POWER ALL FB 99
James Carl Sitsit
+63 969 510 1423
Paid via GCash
Amount 99.00
Convenience Fee 3.00
Total ₱ 102.00
Schedule for Autoload
Date Dec 09, 2024 11:32 AM
Reference No. 757310290''';
      expect(
        parser.classifyType(
          receipt,
          parser.extractPhoneNumbers(receipt),
          '09695101423',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('real load receipt: ML 15 (other customer) → txLoadOthers', () {
      const receipt = '''ML 15
+63 951 175 7238
Paid via GCash
Amount 15.00
Convenience Fee 2.00
Total ₱ 17.00
Schedule for Autoload
Date Feb 06, 2025 2:09 PM
Reference No. 704886394''';
      expect(
        parser.classifyType(
          receipt,
          parser.extractPhoneNumbers(receipt),
          '09695101423',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('real load receipt: NEW DITO Level-Up 99 → txLoadOthers', () {
      const receipt = '''NEW DITO Level-Up 99
+63 993 819 5661
Paid via GCash
Amount 99.00
Total ₱ 99.00
Schedule for Autoload
Date Nov 18, 2025 12:45 PM
Reference No. 742851717''';
      expect(
        parser.classifyType(
          receipt,
          parser.extractPhoneNumbers(receipt),
          '09695101423',
        ),
        equals(AppConstants.txLoadOthers),
      );
    });

    test('real cash in receipt: customer sends to owner → txCashIn', () {
      const receipt = '''LE·H JE···E V.
+63 981 547 5656
Sent via GCash
Amount 1,200.00
Total Amount Sent ₱1,200.00
Ref No. 7038 256 863947
Feb 28, 2026 9:01 AM''';
      expect(
        parser.classifyType(
          receipt,
          parser.extractPhoneNumbers(receipt),
          '09631853737',
        ),
        equals(AppConstants.txCashIn),
      );
    });

    test('real cash out receipt: owner number in receipt → txCashOut', () {
      const receipt = '''ED··R F.
+63 963 185 3737
Sent via GCash
Amount 5,271.00
Total Amount Sent ₱5,271.00
Ref No. 7038 204 888040
Feb 26, 2026 6:02 PM''';
      expect(
        parser.classifyType(
          receipt,
          parser.extractPhoneNumbers(receipt),
          '09631853737',
        ),
        equals(AppConstants.txCashOut),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Load amount correction (triplet sum)
  // ══════════════════════════════════════════════════════════════════════════

  group('Load amount correction — triplet sum', () {
    test('extractAllAmounts finds ₱, P, PHP, and plain decimals', () {
      const text = '₱102.00\nPHP500\nP99.00\n 3.00 \n30.00';
      final amounts = parser.extractAllAmounts(text);
      expect(amounts, containsAll([10200, 50000, 9900, 300, 3000]));
    });

    test('load receipt with ad amount: triplet sum picks correct total', () {
      // Simulates img2: ALL ACCESS 99
      // Receipt has: 99.00 + 3.00 = ₱102.00
      // Ad has: ₱1,015.03 (GSave ad)
      const ocrText = '''ALL ACCESS 99
+63 969 510 1423
Paid via GCash
Amount
Convenience Fee
Total
Schedule for Autoload
Date
Reference No.
₱ 1,015.03
Easy to save
99.00
 3.00
₱ 102.00
Oct 30, 2024 2:15 PM
767791449 0
P 102.00''';
      final result = parser.parse(
        imagePath: '/tmp/img2.jpg',
        rawText: ocrText,
        ownerGcashNumber: '09695101423',
      );
      // Should be 102.00 (10200 centavos), NOT 1,015.03 from ad
      expect(result.amountCentavos, equals(10200));
      expect(result.transactionType, equals(AppConstants.txLoadOthers));
    });

    test('load receipt with ad PHP amounts: triplet sum picks correct total', () {
      // Simulates img9: ALL-NET SURF 30
      // Receipt has: 30.00 + 1.00 = ₱31.00
      // Ad has: PHP 30K, PHP 50
      const ocrText = '''ALL-NET SURF 30
+63 905 686 9330
Paid via GCash
Amount
Convenience Fee
Total
Schedule for Autoload
Date
Reference No.
Claim your FREE Health Insurance
with up to PHP 30K Accidental Coverage!
Buy Load
PHP 50
 30.00
 1.00
₱ 31.00
Nov 13, 2025 3:30 PM
724869825 0
P 31.00''';
      final result = parser.parse(
        imagePath: '/tmp/img9.jpg',
        rawText: ocrText,
        ownerGcashNumber: '09695101423',
      );
      // Should be 31.00 (3100 centavos), NOT 50 or 30K from ad
      expect(result.amountCentavos, equals(3100));
      expect(result.transactionType, equals(AppConstants.txLoadOthers));
    });

    test('load receipt without convenience fee: uses normal extractAmount', () {
      // Simulates img10: DITO Level-Up 99 (no convenience fee)
      const ocrText = '''NEW DITO Level-Up 99
+63 993 819 5661
Paid via GCash
Amount
Total
99.00
₱ 99.00
P 99.00
Nov 18, 2025 12:45 PM
742851717 0''';
      final result = parser.parse(
        imagePath: '/tmp/img10.jpg',
        rawText: ocrText,
        ownerGcashNumber: '09695101423',
      );
      expect(result.amountCentavos, equals(9900));
      expect(result.transactionType, equals(AppConstants.txLoadOthers));
    });

    test('cash in receipt is NOT affected by triplet sum logic', () {
      // Cash in/out receipts should not use triplet sum even if amounts
      // happen to form a triplet
      const receipt = '''Sent via GCash
+63 981 547 5656
Total Amount Sent
₱1,200.00
Ref No. 7038 256 863947
Feb 28, 2026 9:01 AM''';
      final result = parser.parse(
        imagePath: '/tmp/cashin.jpg',
        rawText: receipt,
        ownerGcashNumber: '09631853737',
      );
      expect(result.amountCentavos, equals(120000));
      expect(result.transactionType, equals(AppConstants.txCashIn));
    });

    test('triplet sum with ML 15: 15.00 + 2.00 = 17.00', () {
      const ocrText = '''ML 15
+63 951 175 7238
Paid via GCash
Amount
Convenience Fee
Total
15.00
 2.00
₱ 17.00
Feb 06, 2025 2:09 PM
704886394 0''';
      final result = parser.parse(
        imagePath: '/tmp/ml15.jpg',
        rawText: ocrText,
        ownerGcashNumber: '09695101423',
      );
      expect(result.amountCentavos, equals(1700));
      expect(result.transactionType, equals(AppConstants.txLoadOthers));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Confidence scoring
  // ══════════════════════════════════════════════════════════════════════════

  group('Confidence scoring', () {
    test('all fields found → 1.0', () {
      expect(
        parser.calculateConfidence(
          amount: 50000,
          type: AppConstants.txCashIn,
          dateTime: DateTime(2026, 3, 1),
          refNo: '1234567890123',
          sender: '09171234567',
          recipient: null,
        ),
        equals(1.0),
      );
    });

    test('amount + type only → 0.6', () {
      expect(
        parser.calculateConfidence(
          amount: 50000,
          type: AppConstants.txCashIn,
          dateTime: null,
          refNo: null,
          sender: null,
          recipient: null,
        ),
        equals(0.6),
      );
    });

    test('only amount → 0.3, below review threshold', () {
      final score = parser.calculateConfidence(
        amount: 50000,
        type: null,
        dateTime: null,
        refNo: null,
        sender: null,
        recipient: null,
      );
      expect(score, equals(0.3));
      expect(score < 0.6, isTrue); // triggers needsManualReview
    });

    test('nothing extracted → 0.0', () {
      expect(
        parser.calculateConfidence(
          amount: null,
          type: null,
          dateTime: null,
          refNo: null,
          sender: null,
          recipient: null,
        ),
        equals(0.0),
      );
    });

    test('amount + type + date → 0.8', () {
      expect(
        parser.calculateConfidence(
          amount: 50000,
          type: AppConstants.txCashOut,
          dateTime: DateTime(2026, 3, 1),
          refNo: null,
          sender: null,
          recipient: null,
        ),
        equals(0.8),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Full parse integration
  // ══════════════════════════════════════════════════════════════════════════

  group('Full parse', () {
    test('complete GCash receipt with customer number → txCashIn', () {
      // Receipt shows customer's number (not owner's) → Cash In.
      const receipt = '''
GCash
Send Money

09292222222
Amount ₱500.00
Ref No. 1234567890123
Mar 01, 2026 3:45 PM
''';
      final result = parser.parse(
        imagePath: '/tmp/receipt.jpg',
        rawText: receipt,
        ownerGcashNumber: '09171111111',
      );

      expect(result.amountCentavos, equals(50000));
      expect(result.referenceNumber, equals('1234567890123'));
      expect(result.transactionDateTime, equals(DateTime(2026, 3, 1, 15, 45)));
      expect(result.transactionType, equals(AppConstants.txCashIn));
      expect(result.confidence, greaterThanOrEqualTo(0.8));
      expect(result.needsManualReview, isFalse);
    });

    test('incomplete receipt → needsManualReview = true', () {
      const receipt = 'Some random text with no useful data';
      final result = parser.parse(
        imagePath: '/tmp/bad.jpg',
        rawText: receipt,
        ownerGcashNumber: '09171111111',
      );

      expect(result.transactionType, isNull);
      expect(result.amountCentavos, isNull);
      expect(result.needsManualReview, isTrue);
      expect(result.reviewReason, isNotNull);
      expect(result.confidence, lessThan(0.6));
    });

    test('receipt with amount but no type → needsManualReview = true', () {
      const receipt = '₱500.00\nMar 01, 2026 3:45 PM';
      final result = parser.parse(
        imagePath: '/tmp/partial.jpg',
        rawText: receipt,
        ownerGcashNumber: '09171111111',
      );

      expect(result.amountCentavos, equals(50000));
      expect(result.transactionType, isNull);
      expect(result.needsManualReview, isTrue);
      expect(result.reviewReason, contains('transaction type'));
    });

    test('+63 format owner number in receipt → txCashOut', () {
      // Owner's number appears as +63 format. After normalization it matches
      // the stored 09-format → Cash Out (owner's number = Cash Out, always).
      const receipt = '''
+63 963 185 3737
Total Amount Sent
P500.00
Ref No. 1234567890123
Mar 01, 2026 3:45 PM
''';
      final result = parser.parse(
        imagePath: '/tmp/plus63.jpg',
        rawText: receipt,
        ownerGcashNumber: '09631853737',
      );
      expect(result.transactionType, equals(AppConstants.txCashOut));
      expect(result.needsManualReview, isFalse);
    });

    test('two phones, owner number present → txCashOut', () {
      // Two numbers in receipt; one matches the owner → Cash Out.
      const receipt = '''
09292222222
09631853737
P1,000.00
Ref No. 9876543210987
Mar 01, 2026 10:00 AM
''';
      final result = parser.parse(
        imagePath: '/tmp/twophones.jpg',
        rawText: receipt,
        ownerGcashNumber: '09631853737',
      );
      expect(result.transactionType, equals(AppConstants.txCashOut));
    });

    test('real GCash OCR text: owner number found → txCashOut', () {
      // Real OCR output. Owner's number (+63 963 185 3737 = 09631853737) is
      // in the receipt → Cash Out. Keywords like "Total Amount Sent" are
      // IGNORED for cash in/out — only the number match matters.
      const receipt = '''Amount
ED.R F.
+63 963 185 3737
Sent via GCash
Total Amount Sent
s 279g(gco2e)
Ref No. 7038 204 888040
Feb 26,2026 6:02 PM
5,271.00
P5,271.00
transportation, paper, and plastic
By going digital, you reduce your carbon footprint from''';

      final result = parser.parse(
        imagePath: '/tmp/real_receipt.jpg',
        rawText: receipt,
        ownerGcashNumber: '09631853737',
      );

      expect(result.transactionType, equals(AppConstants.txCashOut));
      expect(result.amountCentavos, equals(527100));
      expect(result.transactionDateTime, equals(DateTime(2026, 2, 26, 18, 2)));
      expect(result.referenceNumber, isNotNull);
      expect(result.needsManualReview, isFalse);
    });

    test('receipt missing date → needsManualReview = true with reason', () {
      const receipt = 'Bills Payment\nMeralco\nAmount ₱2,500.00';
      final result = parser.parse(
        imagePath: '/tmp/nodatetime.jpg',
        rawText: receipt,
        ownerGcashNumber: '09171111111',
      );

      expect(result.amountCentavos, equals(250000));
      expect(result.transactionType, equals(AppConstants.txBillsPayment));
      expect(result.needsManualReview, isTrue);
      expect(result.reviewReason, contains('date/time'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Chronological sorting
  // ══════════════════════════════════════════════════════════════════════════

  group('Chronological sorting', () {
    test('5 receipts with shuffled dates → sorted ascending', () {
      final results = [
        _makeResult(DateTime(2026, 3, 5)), // 5th
        _makeResult(DateTime(2026, 3, 1)), // 1st
        _makeResult(DateTime(2026, 3, 3)), // 3rd
        _makeResult(DateTime(2026, 3, 2)), // 2nd
        _makeResult(DateTime(2026, 3, 4)), // 4th
      ];

      final sorted = ReceiptParser.sortChronologically(results);

      expect(sorted[0].transactionDateTime, equals(DateTime(2026, 3, 1)));
      expect(sorted[1].transactionDateTime, equals(DateTime(2026, 3, 2)));
      expect(sorted[2].transactionDateTime, equals(DateTime(2026, 3, 3)));
      expect(sorted[3].transactionDateTime, equals(DateTime(2026, 3, 4)));
      expect(sorted[4].transactionDateTime, equals(DateTime(2026, 3, 5)));
    });

    test('receipts without dates placed at end', () {
      final results = [
        _makeResult(null),
        _makeResult(DateTime(2026, 3, 2)),
        _makeResult(null),
        _makeResult(DateTime(2026, 3, 1)),
      ];

      final sorted = ReceiptParser.sortChronologically(results);

      expect(sorted[0].transactionDateTime, equals(DateTime(2026, 3, 1)));
      expect(sorted[1].transactionDateTime, equals(DateTime(2026, 3, 2)));
      expect(sorted[2].transactionDateTime, isNull);
      expect(sorted[3].transactionDateTime, isNull);
    });

    test('all dates null → original order preserved', () {
      final results = [
        _makeResult(null, path: 'a.jpg'),
        _makeResult(null, path: 'b.jpg'),
        _makeResult(null, path: 'c.jpg'),
      ];

      final sorted = ReceiptParser.sortChronologically(results);

      expect(sorted[0].imagePath, equals('a.jpg'));
      expect(sorted[1].imagePath, equals('b.jpg'));
      expect(sorted[2].imagePath, equals('c.jpg'));
    });
  });
}

/// Helper to create minimal OcrResult for sorting tests.
OcrResult _makeResult(DateTime? dateTime, {String path = 'test.jpg'}) {
  return OcrResult(
    imagePath: path,
    rawText: '',
    transactionDateTime: dateTime,
  );
}
