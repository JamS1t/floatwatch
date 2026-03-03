# DAY 02 — OCR Receipt Scanning & Classification System

## Overview

Build the OCR pipeline that turns GCash receipt screenshots into classified, validated transactions. The system uses Google ML Kit on-device text recognition (already in pubspec.yaml) to extract text, then applies regex-based parsing and GCash number matching to classify each receipt automatically.

**End-to-end flow:**
```
Pick images → OCR each image → Parse & classify → Review screen → Batch save (chronological order)
```

---

## Step 1 — OcrResult Data Class

**File:** `lib/core/services/ocr_result.dart`

A plain data class holding everything extracted from a single receipt.

```dart
class OcrResult {
  final String imagePath;
  final String rawText;
  final String? transactionType;   // cash_in | cash_out | bills_payment | load_others | null (unknown)
  final int? amountCentavos;
  final String? referenceNumber;
  final DateTime? transactionDateTime;  // extracted from receipt, NOT system time
  final String? recipientNumber;   // phone number of recipient found in receipt
  final String? senderNumber;      // phone number of sender found in receipt
  final double confidence;         // 0.0–1.0
  final bool needsManualReview;
  final String? reviewReason;      // why manual review is needed

  // copyWith for editing in review screen
}
```

**Key rules:**
- `needsManualReview = true` when: date can't be parsed, type can't be classified, amount can't be found, or confidence < 0.6
- `reviewReason` explains what went wrong (e.g., "Could not extract date/time", "Unknown transaction type")

---

## Step 2 — OcrService (ML Kit Wrapper)

**File:** `lib/core/services/ocr_service.dart`

Thin wrapper around `google_mlkit_text_recognition`. Single responsibility: image → raw text.

```dart
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  /// Process a single image and return all recognized text.
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);
    return recognized.text;
  }

  /// Process multiple images. Returns list of (imagePath, rawText) pairs.
  /// Emits progress via callback for UI progress bar.
  Future<List<({String path, String text})>> extractBatch(
    List<String> imagePaths,
    {void Function(int completed, int total)? onProgress}
  ) async { ... }

  void dispose() => _recognizer.close();
}
```

**Notes:**
- ML Kit runs entirely on-device — no internet needed
- `dispose()` must be called when done (in screen dispose or after batch completes)
- Image quality 85% from ImagePicker is sufficient for ML Kit

---

## Step 3 — ReceiptParser (Classification Engine)

**File:** `lib/core/services/receipt_parser.dart`

The core intelligence. Takes raw OCR text + owner GCash number → `OcrResult`.

### 3A — Amount Extraction

GCash receipts show amounts in several formats:
```
Amount          ₱500.00
Total Amount    PHP 1,500.00
You sent ₱200.00
₱ 1,000.00
Php500
```

**Regex patterns (ordered by priority):**
```dart
// Pattern 1: Labeled amount (highest priority)
RegExp(r'(?:amount|total|paid|sent|received|load)\s*[:\-]?\s*(?:₱|php|p)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false)

// Pattern 2: Standalone peso amount (₱ prefix)
RegExp(r'₱\s*([\d,]+(?:\.\d{1,2})?)')

// Pattern 3: PHP prefix
RegExp(r'(?:php|PHP)\s*([\d,]+(?:\.\d{1,2})?)')
```

**Parse to centavos:**
1. Strip commas: `"1,500.00"` → `"1500.00"`
2. Use `CurrencyFormatter.parseToCentavos()` (already exists)

### 3B — Reference Number Extraction

GCash reference numbers are typically 13-digit numbers:
```
Ref No. 1234567890123
Reference Number: 1234 567 890 1234
Ref. No.: 1234567890123
```

**Regex:**
```dart
// Labeled reference
RegExp(r'ref(?:erence)?\.?\s*(?:no|number|#)?\.?\s*[:\-]?\s*([\d\s]{10,20})', caseSensitive: false)
```

Strip spaces from captured group, take first match.

### 3C — Phone Number Extraction

GCash numbers appear as `09XXXXXXXXX` (11 digits) or `+639XXXXXXXXX`:
```
Sent to 09171234567
From: 09291234567
09XX XXX XXXX
+63 917 123 4567
```

**Regex:**
```dart
// Philippine mobile number
RegExp(r'(?:\+?63|0)(9\d{2})[\s\-]?(\d{3})[\s\-]?(\d{4})')
```

Normalize all found numbers to `09XXXXXXXXX` format. Identify sender vs recipient by context keywords:

**Sender keywords:** `"sent to"`, `"paid to"`, `"transferred to"`, `"receiver"`, `"recipient"`
**Recipient keywords (owner receives):** `"from"`, `"sent by"`, `"received from"`, `"sender"`

The number appearing AFTER a sender keyword is the recipient. The number after a recipient keyword is the sender.

### 3D — Transaction Type Classification

**Priority order:**

1. **Bills Payment** — keyword match:
   ```dart
   final billsKeywords = [
     'bills payment', 'pay bills', 'biller',
     'meralco', 'manila water', 'maynilad', 'pldt', 'converge',
     'globe broadband', 'smart bro', 'cignal', 'sss', 'pagibig',
     'pag-ibig', 'philhealth', 'national grid',
   ];
   ```
   If any keyword found in text (case-insensitive) → `txBillsPayment`

2. **Load/Others** — keyword match:
   ```dart
   final loadKeywords = [
     'buy load', 'prepaid load', 'load to', 'regular load',
     'smart prepaid', 'globe prepaid', 'tm prepaid', 'dito prepaid',
     'gomo', 'smart load', 'globe load', 'tnt load',
   ];
   ```
   If any keyword found → `txLoadOthers`

3. **Cash In / Cash Out** — GCash number matching:
   - Extract all phone numbers from receipt
   - Compare each against `owner.gcashNumber`
   - If owner number appears as **recipient** (money sent TO owner) → `txCashOut`
     - Customer is cashing out GCash → gives phone, owner receives GCash, owner gives physical cash
   - If owner number appears as **sender** (money sent FROM owner) → `txCashIn`
     - Customer is cashing in → gives physical cash, owner sends GCash from their account
   - **Fallback:** If owner number found but context unclear → check receipt header:
     - "Send Money" / "Express Send" with owner as sender → `txCashIn`
     - "Receive Money" / "Cash In" with owner as recipient → `txCashOut`

4. **Unknown** — if none of the above match:
   - `transactionType = null`
   - `needsManualReview = true`
   - `reviewReason = "Could not determine transaction type"`

### 3E — Date/Time Extraction

GCash receipts show dates in various formats:
```
Mar 01, 2026 3:45 PM
March 1, 2026, 3:45:30 PM
2026-03-01 15:45:00
03/01/2026 3:45 PM
Jan 15, 2026
```

**Regex patterns:**
```dart
// Pattern 1: "Mon DD, YYYY H:MM PM" (most common GCash format)
RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\.?\s+(\d{1,2}),?\s+(\d{4}),?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM|am|pm)', caseSensitive: false)

// Pattern 2: "MM/DD/YYYY H:MM PM"
RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)', caseSensitive: false)

// Pattern 3: ISO-ish "YYYY-MM-DD HH:MM"
RegExp(r'(\d{4})-(\d{2})-(\d{2})\s+(\d{1,2}):(\d{2})')

// Pattern 4: Date only (no time — flag for review but still extract date)
RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\.?\s+(\d{1,2}),?\s+(\d{4})', caseSensitive: false)
```

**Critical rule:** If no date/time can be extracted at all → `needsManualReview = true`, `reviewReason = "Could not extract date/time from receipt"`.

### 3F — Confidence Score Calculation

```dart
double _calculateConfidence(OcrResult partial) {
  double score = 0.0;
  if (partial.amountCentavos != null) score += 0.30;
  if (partial.transactionType != null) score += 0.30;
  if (partial.transactionDateTime != null) score += 0.20;
  if (partial.referenceNumber != null) score += 0.10;
  if (partial.recipientNumber != null || partial.senderNumber != null) score += 0.10;
  return score;
}
```

If confidence < 0.6 → `needsManualReview = true`.

### 3G — Main Parse Method

```dart
class ReceiptParser {
  OcrResult parse({
    required String imagePath,
    required String rawText,
    required String ownerGcashNumber,
  }) {
    final amount = _extractAmount(rawText);
    final refNo = _extractReferenceNumber(rawText);
    final dateTime = _extractDateTime(rawText);
    final phones = _extractPhoneNumbers(rawText);
    final type = _classifyType(rawText, phones, ownerGcashNumber);
    final confidence = _calculateConfidence(...);
    final needsReview = dateTime == null || type == null || amount == null || confidence < 0.6;

    return OcrResult(
      imagePath: imagePath,
      rawText: rawText,
      transactionType: type,
      amountCentavos: amount,
      referenceNumber: refNo,
      transactionDateTime: dateTime,
      confidence: confidence,
      needsManualReview: needsReview,
      reviewReason: _buildReviewReason(...),
    );
  }
}
```

---

## Step 4 — Receipt Image Persistence

**File:** `lib/core/services/receipt_storage_service.dart`

Images from ImagePicker are in temp directories. Before saving a transaction, copy the image to a permanent app directory.

```dart
class ReceiptStorageService {
  /// Copy a receipt image to permanent storage.
  /// Returns the new permanent path.
  Future<String> saveReceipt(String tempPath, String syncId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${appDir.path}/receipts');
    if (!await receiptsDir.exists()) await receiptsDir.create(recursive: true);

    final ext = path.extension(tempPath);
    final fileName = '${syncId}$ext';  // use transaction syncId for unique naming
    final destPath = '${receiptsDir.path}/$fileName';

    await File(tempPath).copy(destPath);
    return destPath;
  }
}
```

---

## Step 5 — Update BatchUploadScreen

**File:** `lib/ui/screens/shared/batch_upload_screen.dart`

### Changes:
1. Add processing state: `_isProcessing`, `_processedCount`, `_totalCount`
2. After picking images, show thumbnails grid with remove button per image
3. "Process Receipts" button triggers OCR pipeline:
   - Show linear progress indicator
   - Run `OcrService.extractBatch()` with progress callback
   - Parse each result with `ReceiptParser.parse()`
   - Navigate to OcrReviewScreen with `List<OcrResult>` via `state.extra`
4. Enforce free plan limit: if `_uploadedPaths.length > AppConstants.freeBatchUploadLimit`, show premium lock
5. Error handling: if ML Kit fails on an image, create OcrResult with `needsManualReview = true`

### UI States:
- **Empty:** Upload area (current design)
- **Images selected:** Thumbnail grid + count + "Process Receipts" button
- **Processing:** Progress bar with "Processing 3 of 8..." text, disable back button
- **Error:** Snackbar with retry option

---

## Step 6 — Rewrite OcrReviewScreen

**File:** `lib/ui/screens/shared/ocr_review_screen.dart`

Complete rewrite from current static placeholder to full batch review screen.

### Screen receives:
`List<OcrResult>` via `GoRouter state.extra`

### UI Layout:
```
AppBar: "Review Receipts (5)"
  ├── Summary banner: "3 auto-classified, 2 need review"
  ├── ListView of receipt cards (sorted chronologically)
  │   ├── Receipt Card
  │   │   ├── Row: [Thumbnail] [Type chip] [Amount] [Time]
  │   │   ├── Reference number (if found)
  │   │   ├── Confidence badge (green ≥0.8, yellow ≥0.6, red <0.6)
  │   │   └── Warning banner if needsManualReview (with reason)
  │   │   └── Tap → expand to edit fields
  │   └── ...more cards
  ├── Spacer
  └── "Confirm & Save All" button (disabled if any unresolved reviews)
```

### Editable fields per receipt:
- Transaction type (dropdown: Cash In / Cash Out / Bills Payment / Load/Others)
- Amount (text field, pre-filled from OCR)
- Date/time (date+time picker, pre-filled from OCR)
- Reference number (text field, pre-filled)

### Review resolution:
- Receipts with `needsManualReview = true` show orange warning
- User must tap and fill in missing fields to resolve
- Once all fields filled → warning clears
- "Confirm & Save All" only enabled when every receipt has: type, amount, and dateTime

### Chronological sort:
- Receipts sorted by `transactionDateTime` ascending (earliest first)
- Receipts without dates go to the end with a "Date required" badge

---

## Step 7 — TransactionProvider Batch Save

**File:** `lib/providers/transaction_provider.dart`

### New method:
```dart
/// Save a batch of OCR-processed transactions in chronological order.
/// Returns count of successfully saved transactions.
Future<int> addBatchTransactions({
  required int storeId,
  required int dailyFloatId,
  required List<OcrResult> results,
  required Map<String, MarkupSettingsModel> markupByType,
  required String enteredByRole,
  int? enteredByStaffId,
}) async {
  // 1. Sort results by transactionDateTime ascending
  // 2. For each result:
  //    a. Get markup settings for this transaction type
  //    b. Save receipt image to permanent storage
  //    c. Call addTransaction() with all extracted fields
  //    d. Set entryMethod = AppConstants.entryBatchOcr
  //    e. Set createdAt to the RECEIPT's dateTime (not system time)
  // 3. Return count of saved transactions
}
```

**Critical:** The `createdAt` field must use the receipt's extracted date/time, NOT `DateFormatter.nowDb()`. This ensures the transaction timeline matches reality.

---

## Step 8 — Provider Registration

**File:** `lib/main.dart`

Add to MultiProvider:
```dart
Provider<OcrService>.value(value: OcrService()),
Provider<ReceiptStorageService>.value(value: ReceiptStorageService()),
```

`ReceiptParser` is stateless — instantiate where needed, no provider required.

---

## Step 9 — Route Updates

**File:** `lib/routes.dart`

Update `OcrReviewScreen` route to accept `List<OcrResult>` via `state.extra`:
```dart
GoRoute(
  path: '/shared/ocr-review',
  builder: (context, state) {
    final results = state.extra as List<OcrResult>;
    return OcrReviewScreen(results: results);
  },
),
```

---

## Step 10 — Unit Tests

**File:** `test/receipt_parser_test.dart`

### Test groups:

**Amount extraction:**
- `"Amount ₱500.00"` → 50000 centavos
- `"Total Amount PHP 1,500.00"` → 150000
- `"You sent ₱200.00"` → 20000
- `"₱ 1,000.00"` → 100000
- No amount found → null

**Reference number extraction:**
- `"Ref No. 1234567890123"` → `"1234567890123"`
- `"Reference Number: 1234 567 890 1234"` → `"12345678901234"`
- No reference → null

**Phone number extraction:**
- `"09171234567"` → `"09171234567"`
- `"+63 917 123 4567"` → `"09171234567"`
- `"0917 123 4567"` → `"09171234567"`

**Date/time extraction:**
- `"Mar 01, 2026 3:45 PM"` → DateTime(2026, 3, 1, 15, 45)
- `"January 15, 2026, 10:30:00 AM"` → DateTime(2026, 1, 15, 10, 30)
- `"03/01/2026 3:45 PM"` → DateTime(2026, 3, 1, 15, 45)
- No date found → null, needsManualReview = true

**Classification:**
- Receipt with owner number as recipient → `cash_out`
- Receipt with owner number as sender → `cash_in`
- Receipt with "bills payment" keyword → `bills_payment`
- Receipt with "buy load" keyword → `load_others`
- Receipt with unknown number, no keywords → null, needsManualReview = true

**Confidence scoring:**
- All fields found → 1.0
- Amount + type only → 0.6
- Only amount → 0.3, needsManualReview = true

**Batch chronological sort:**
- 5 receipts with shuffled dates → sorted ascending by dateTime
- Receipts without dates placed at end

---

## Implementation Order

1. `OcrResult` data class (no dependencies)
2. `ReceiptParser` + unit tests (depends on OcrResult only)
3. `OcrService` (ML Kit wrapper, no other internal deps)
4. `ReceiptStorageService` (standalone utility)
5. Provider registration in `main.dart`
6. `BatchUploadScreen` rewrite (uses OcrService + ReceiptParser)
7. `OcrReviewScreen` rewrite (uses OcrResult, saves via TransactionProvider)
8. `TransactionProvider.addBatchTransactions()` (uses ReceiptStorageService)
9. Route updates
10. Integration testing on device

---

## Files Created/Modified Summary

| Action | File | Purpose |
|--------|------|---------|
| CREATE | `lib/core/services/ocr_result.dart` | Parsed receipt data class |
| CREATE | `lib/core/services/receipt_parser.dart` | Regex extraction + classification |
| CREATE | `lib/core/services/ocr_service.dart` | ML Kit text recognition wrapper |
| CREATE | `lib/core/services/receipt_storage_service.dart` | Copy receipt images to permanent storage |
| MODIFY | `lib/ui/screens/shared/batch_upload_screen.dart` | Add processing pipeline, thumbnails, progress |
| REWRITE | `lib/ui/screens/shared/ocr_review_screen.dart` | Full batch review with editable fields |
| MODIFY | `lib/providers/transaction_provider.dart` | Add `addBatchTransactions()` method |
| MODIFY | `lib/main.dart` | Register OcrService + ReceiptStorageService |
| MODIFY | `lib/routes.dart` | Pass OcrResult list to review screen |
| CREATE | `test/receipt_parser_test.dart` | Unit tests for parser/classifier |

## Verification
1. `flutter analyze` — 0 errors
2. `flutter test` — all existing + new tests pass
3. On-device test: pick 3-5 GCash screenshots → OCR extracts text → parser classifies correctly → review screen shows results → confirm saves transactions to DB in chronological order
