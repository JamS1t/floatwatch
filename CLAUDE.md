# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/markup_calculator_test.dart

# Static analysis
flutter analyze

# Run on emulator (list devices first)
flutter devices
flutter run -d <device-id>

# Run on wireless ADB device
flutter run -d <IP>:<PORT>
```

> ADB binary: `/c/AndroidSDK/platform-tools/adb.exe`
> Core Library Desugaring is required and already configured in `android/build.gradle.kts`.

## Architecture

**Data flow:** UI Screen → Provider (ChangeNotifier/ViewModel) → Repository Interface → Local SQLite Implementation

The repository interfaces in `lib/data/repositories/interfaces/` exist so local SQLite implementations can be swapped for Firebase without touching providers or UI. Firebase packages are present in `pubspec.yaml` but **not yet initialized** — see TODOs in `main.dart`.

### Key layers

| Layer | Location |
|---|---|
| App entry / DI wiring | `lib/main.dart` |
| Navigation (GoRouter) | `lib/routes.dart` — all routes as `Routes.*` constants |
| State (ViewModels) | `lib/providers/` |
| Repository interfaces | `lib/data/repositories/interfaces/` |
| SQLite implementations | `lib/data/repositories/local/` |
| DB schema / migrations | `lib/data/database/database_helper.dart` |
| Business constants | `lib/core/constants/app_constants.dart` |
| Markup income logic | `lib/core/utils/markup_calculator.dart` |
| OCR pipeline | `lib/core/services/ocr_service.dart` + `receipt_parser.dart` |

### Providers registered in `main.dart`

- `Provider<SecurityService>`, `Provider<SubscriptionService>`, `Provider<OcrService>`, `Provider<ReceiptStorageService>`
- `Provider<IStaffRepository>`, `Provider<IDailyFloatRepository>` — exposed directly for screens that skip the provider layer
- `ChangeNotifierProvider`: `AuthProvider`, `StoreProvider`, `TransactionProvider`, `DailyFloatProvider`, `ReportProvider`

### Database

SQLite via `sqflite`. Version **2**. 9 tables: `owners`, `stores`, `staff`, `markup_settings`, `daily_float`, `transactions`, `daily_reports`, `one_time_pins`, `sync_log`.

- Every DB write must also insert a row into `sync_log` (cloud-sync readiness).
- Never drop tables in migrations — only `ALTER TABLE … ADD COLUMN`.
- `PRAGMA foreign_keys = ON` is set on every connection.

## Critical Business Rules

**All monetary values are stored and computed as INTEGER centavos.** Convert to pesos only at the UI display layer.

**Markup rate storage:**
- `percentage`: `rate_value` = percent × 100 (1.00% → 100). Formula: `amount × rateValue / 10000`
- `fixed`: `rate_value` = flat fee in centavos
- `per_bracket`: `rate_value` = fee per bracket in centavos; `bracket_size` = bracket size in centavos

**Constant naming — use only these (never invent alternatives):**
- Transaction types: `AppConstants.txCashIn / txCashOut / txBillsPayment / txLoadOthers`
- Markup rate types: `AppConstants.markupPercentage / markupFixed / markupPerBracket`

**GCash balance movement:**
- Cash In → GCash DECREASES (customer pays cash, receives GCash)
- Cash Out → GCash INCREASES (customer pays GCash, receives cash)
- Bills Payment / Load Others → GCash DECREASES

**Markup settings are snapshotted on every transaction** (`markup_rate_type_snapshot`, `markup_rate_value_snapshot`) so historical income is correct even after settings change.

**Discrepancy thresholds:** GREEN ≤ ₱10 (1000 centavos), YELLOW ≤ ₱200 (20000 centavos), RED > ₱200.

**SubscriptionService.isPremium()** is hardcoded `false` — all premium feature gates check this.

## OCR Pipeline

`BatchUploadScreen` → `OcrService.extractBatch()` (Google ML Kit, on-device) → `ReceiptParser.parse()` → `OcrReviewScreen` → `TransactionProvider.addBatchTransactions()`

`ReceiptParser` classifies Cash In vs Cash Out by matching the owner's GCash number against phone numbers found in the receipt text. Transactions with `confidence < 0.6` or missing amount/type/date are flagged `needsManualReview = true`.

## Navigation Patterns

- Use `Routes.*` constants — never raw path strings.
- `EndOfDaySummaryScreen` receives `{closingGcash: int, closingCash: int}` via `state.extra`.
- `StaffPinEntryScreen` receives `{staffId: int}` via `state.extra`.
- `ManualEntryScreen` receives `{transactionType: String}` via `state.extra`.
- `OcrReviewScreen` receives `List<OcrResult>` directly as `state.extra`.
- `addStaff` route must be defined **before** `staffActivityDetail` (`:staffId` param) to avoid `add` being matched as an ID.

## Tests

```
test/markup_calculator_test.dart  — 33 unit tests for all 3 markup types, GCash balance, discrepancy
test/receipt_parser_test.dart     — 48 tests for OCR parsing patterns
test/dedup_test.dart              — duplicate detection logic
test/widget_test.dart             — 1 smoke test
```

Test baseline: `flutter test` → 82/82 pass, `flutter analyze` → 0 errors.
