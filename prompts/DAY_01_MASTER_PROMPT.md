I am building a Flutter mobile app called FloatWatch — a GCash
Partner Outlet (GPO) transaction tracker for Filipino store
operators. It tracks daily transactions, calculates markup
income, monitors float balance, detects discrepancies, and
supports both solo owners and owners with staff.

════════════════════════════════════════
TECH STACK
════════════════════════════════════════

- Flutter (latest stable)
- sqflite (SQLite local database)
- provider (state management)
- google_ml_kit (OCR — integrate later, just set up the
  dependency now)
- image_picker (camera and gallery)
- firebase_core, firebase_auth, cloud_firestore,
  firebase_storage (add dependencies but DO NOT activate —
  architecture must be cloud-sync ready via repository
  pattern)
- flutter_local_notifications (push notifications)
- fl_chart (graphs and analytics)
- pdf (PDF export — premium feature, lock it but set up)
- path_provider (local file storage)
- crypto (PIN hashing)
- uuid (generating sync IDs)
- intl (date and currency formatting)

════════════════════════════════════════
ARCHITECTURE RULES — READ CAREFULLY
════════════════════════════════════════

1. Use Repository Pattern for ALL database operations.
   Every data call goes through a Repository class.
   UI → Provider (ViewModel) → Repository → SQLite
   When Firebase is activated later, only the Repository
   implementation changes. UI and ViewModels never change.

2. Use a central SecurityService class that checks
   store security_mode (simple or strict) and returns
   boolean flags for every security-dependent feature.

3. Use a central SubscriptionService class with an
   isPremium() method. Every premium feature checks this
   before rendering. Free users see a locked state with
   an upgrade prompt.

4. Every database table must have a sync_id (UUID) field
   for future Firebase sync. Every write operation must
   also write to a SyncLog table.

5. Never store raw PINs. Always hash using SHA-256 before
   saving to database.

6. All monetary values stored as INTEGER (centavos) in
   the database to avoid floating point errors. Display
   layer converts to pesos for UI.

════════════════════════════════════════
COMPLETE DATABASE SCHEMA
════════════════════════════════════════

Create all tables in a DatabaseHelper class using sqflite.
Use onUpgrade for future migrations. Current version: 1.

TABLE: owners

- id INTEGER PRIMARY KEY AUTOINCREMENT
- name TEXT NOT NULL
- mobile_number TEXT NOT NULL
- pin_hash TEXT NOT NULL
- store_mode TEXT DEFAULT 'solo'
  (values: solo / with_staff)
- created_at TEXT NOT NULL
- updated_at TEXT NOT NULL
- sync_id TEXT NOT NULL UNIQUE

TABLE: stores

- id INTEGER PRIMARY KEY AUTOINCREMENT
- owner_id INTEGER NOT NULL (FK → owners)
- store_name TEXT NOT NULL
- location TEXT
- gcash_outlet_number TEXT
- security_mode TEXT DEFAULT 'simple'
  (values: simple / strict)
- is_active INTEGER DEFAULT 1
- created_at TEXT NOT NULL
- updated_at TEXT NOT NULL
- sync_id TEXT NOT NULL UNIQUE

TABLE: staff

- id INTEGER PRIMARY KEY AUTOINCREMENT
- owner_id INTEGER NOT NULL (FK → owners)
- store_id INTEGER NOT NULL (FK → stores)
- name TEXT NOT NULL
- mobile_number TEXT
- pin_hash TEXT NOT NULL
- is_active INTEGER DEFAULT 1
- is_locked INTEGER DEFAULT 0
- failed_attempts INTEGER DEFAULT 0
- last_active TEXT
- created_at TEXT NOT NULL
- updated_at TEXT NOT NULL
- sync_id TEXT NOT NULL UNIQUE

TABLE: markup_settings

- id INTEGER PRIMARY KEY AUTOINCREMENT
- store_id INTEGER NOT NULL (FK → stores)
- transaction_type TEXT NOT NULL
  (values: cash_in / cash_out / bills_payment /
  load_others)
- rate_type TEXT NOT NULL
  (values: percentage / fixed / per_bracket)
- rate_value INTEGER NOT NULL (stored in centavos)
- bracket_size INTEGER
  (nullable, only used for per_bracket)
- effective_date TEXT NOT NULL
- created_at TEXT NOT NULL
- sync_id TEXT NOT NULL UNIQUE

TABLE: daily_float

- id INTEGER PRIMARY KEY AUTOINCREMENT
- store_id INTEGER NOT NULL (FK → stores)
- date TEXT NOT NULL
- opening_gcash_balance INTEGER
- opening_cash INTEGER
- closing_gcash_balance INTEGER
- closing_cash INTEGER
- expected_gcash_balance INTEGER
- expected_cash INTEGER
- discrepancy_gcash INTEGER
- discrepancy_cash INTEGER
- status TEXT DEFAULT 'open'
  (values: open / clean / warning / flagged)
- is_closed INTEGER DEFAULT 0
- opening_set_by TEXT (values: owner / staff)
- opening_confirmed INTEGER DEFAULT 0
- created_at TEXT NOT NULL
- updated_at TEXT NOT NULL
- sync_id TEXT NOT NULL UNIQUE
- UNIQUE(store_id, date)

TABLE: transactions

- id INTEGER PRIMARY KEY AUTOINCREMENT
- store_id INTEGER NOT NULL (FK → stores)
- daily_float_id INTEGER NOT NULL (FK → daily_float)
- transaction_type TEXT NOT NULL
  (values: cash_in / cash_out / bills_payment /
  load_others)
- amount INTEGER NOT NULL (centavos)
- markup_rate_type_snapshot TEXT NOT NULL
- markup_rate_value_snapshot INTEGER NOT NULL
- markup_bracket_size_snapshot INTEGER
- markup_earned INTEGER NOT NULL (centavos)
- reference_number TEXT
- receipt_image_path TEXT
- receipt_image_sync_url TEXT
- entry_method TEXT NOT NULL
  (values: batch_ocr / manual_owner / manual_staff)
- entered_by_role TEXT NOT NULL
  (values: owner / staff)
- entered_by_staff_id INTEGER (FK → staff, nullable)
- missing_receipt_reason TEXT
- ocr_confidence_score REAL
- one_time_pin_used INTEGER DEFAULT 0
- is_flagged INTEGER DEFAULT 0
- flag_reason TEXT
- created_at TEXT NOT NULL
- updated_at TEXT NOT NULL
- sync_id TEXT NOT NULL UNIQUE

TABLE: daily_reports

- id INTEGER PRIMARY KEY AUTOINCREMENT
- store_id INTEGER NOT NULL (FK → stores)
- daily_float_id INTEGER NOT NULL (FK → daily_float)
- date TEXT NOT NULL
- total_transactions INTEGER DEFAULT 0
- total_cash_in_count INTEGER DEFAULT 0
- total_cash_out_count INTEGER DEFAULT 0
- total_bills_payment_count INTEGER DEFAULT 0
- total_load_others_count INTEGER DEFAULT 0
- total_gross_amount INTEGER DEFAULT 0
- total_markup_earned INTEGER DEFAULT 0
- status TEXT
  (values: clean / warning / flagged)
- notes TEXT
- closed_by TEXT (values: owner)
- created_at TEXT NOT NULL
- sync_id TEXT NOT NULL UNIQUE

TABLE: one_time_pins

- id INTEGER PRIMARY KEY AUTOINCREMENT
- store_id INTEGER NOT NULL (FK → stores)
- staff_id INTEGER NOT NULL (FK → staff)
- pin_hash TEXT NOT NULL
- purpose TEXT NOT NULL
  (values: manual_entry)
- is_used INTEGER DEFAULT 0
- expires_at TEXT NOT NULL
- created_at TEXT NOT NULL
- sync_id TEXT NOT NULL UNIQUE

TABLE: sync_log

- id INTEGER PRIMARY KEY AUTOINCREMENT
- table_name TEXT NOT NULL
- record_sync_id TEXT NOT NULL
- action TEXT NOT NULL
  (values: create / update / delete)
- is_synced INTEGER DEFAULT 0
- synced_at TEXT
- created_at TEXT NOT NULL

════════════════════════════════════════
BUSINESS LOGIC — IMPLEMENT THESE EXACTLY
════════════════════════════════════════

MARKUP CALCULATION:

Percentage:
markup_earned = amount × rate_value
e.g. ₱1000 at 1% = ₱10

Fixed:
markup_earned = rate_value
e.g. any amount = ₱10 flat

Per Bracket:
brackets = (amount / bracket_size).ceil()
markup_earned = brackets × rate_value
e.g. ₱750 at ₱500 bracket / ₱10 per bracket
= 2 brackets = ₱20

GCASH BALANCE MOVEMENT:
Cash In: GCash DECREASES, Cash INCREASES
Cash Out: GCash INCREASES, Cash DECREASES
Bills Payment: GCash DECREASES, Cash INCREASES
Load Others: GCash DECREASES, Cash INCREASES

EXPECTED CLOSING GCASH:
expected_gcash = opening_gcash - total_cash_in_amounts - total_bills_payment_amounts - total_load_others_amounts + total_cash_out_amounts

DISCREPANCY STATUS:
GREEN: abs(discrepancy) <= 1000 centavos (₱10)
YELLOW: abs(discrepancy) > 1000
AND <= 20000 centavos (₱200)
RED: abs(discrepancy) > 20000 centavos

════════════════════════════════════════
SECURITY SERVICE — IMPLEMENT THIS CLASS
════════════════════════════════════════

class SecurityService {

// Check store security mode
Future<bool> isStrictMode(int storeId)

// Returns true if manual entry needs one-time PIN
Future<bool> requiresManualEntryPin(int storeId)

// Returns true if opening balance needs owner confirm
Future<bool> requiresOpeningBalanceConfirmation(
int storeId)

// Returns true if staff must submit before day close
Future<bool> requiresStaffDaySubmission(int storeId)

// Hash PIN using SHA-256
String hashPin(String pin)

// Verify PIN against stored hash
bool verifyPin(String inputPin, String storedHash)

// Generate 6-digit one-time PIN
String generateOneTimePin()

// Check if one-time PIN is valid and not expired
Future<bool> validateOneTimePin(
String pin, int staffId, String purpose)

}

════════════════════════════════════════
SUBSCRIPTION SERVICE — IMPLEMENT THIS CLASS
════════════════════════════════════════

class SubscriptionService {

// Check if owner has premium
Future<bool> isPremium(int ownerId)

// Individual feature checks
Future<bool> canExportPDF(int ownerId)
Future<bool> canViewWeeklyReports(int ownerId)
Future<bool> canViewMonthlyReports(int ownerId)
Future<bool> canAddMultipleStores(int ownerId)
Future<bool> canUseUnlimitedBatchUpload(int ownerId)
Future<bool> canReopenClosedDay(int ownerId)
Future<bool> canUseCloudSync(int ownerId)

}

════════════════════════════════════════
ALL SCREENS TO SCAFFOLD
════════════════════════════════════════

Scaffold ALL screens with basic UI and correct
navigation. They do not need to be fully functional
yet — just connected, named correctly, and structured
properly with placeholder widgets.

ONBOARDING:

- SplashScreen
- WelcomeScreen
- StoreModeSelectionScreen
  (solo owner / owner with staff)
- CreateOwnerAccountScreen
- CreateStoreProfileScreen
- MarkupSettingsScreen (initial setup)
- OnboardingCompleteScreen

AUTHENTICATION:

- RoleSelectionScreen
- OwnerPinEntryScreen
- StaffSelectionScreen
- StaffPinEntryScreen
- PinLockedScreen

OWNER SCREENS:

- OwnerDashboardScreen
- OpeningBalanceScreen
- PendingApprovalsScreen
- StaffManagementScreen
- StaffActivityDetailScreen
- AddStaffScreen

SHARED SCREENS (owner and staff):

- BatchUploadScreen
- OcrReviewScreen
- ManualEntryScreen
- TransactionSuccessScreen

STAFF SCREENS:

- StaffHomeScreen
- StaffTransactionListScreen
- ManualEntryPinRequestScreen

TRANSACTION SCREENS:

- TransactionHistoryScreen
- TransactionDetailScreen

END OF DAY:

- EndOfDayPreCheckScreen
- EndOfDayBalanceEntryScreen
- EndOfDaySummaryScreen
- DayClosedSuccessScreen

REPORTS (owner only):

- ReportsHomeScreen
- DailyReportDetailScreen
- WeeklyReportScreen (premium)
- MonthlyReportScreen (premium)

SETTINGS:

- SettingsScreen
- SecurityModeSettingsScreen
- MarkupSettingsScreen (edit)
- ChangePinScreen
- NotificationSettingsScreen
- SubscriptionScreen
- AboutScreen

════════════════════════════════════════
NAVIGATION ROUTING
════════════════════════════════════════

Use named routes with GoRouter or Navigator 2.0.
All route names defined as constants in a
Routes class. Example:

class Routes {
static const splash = '/';
static const welcome = '/welcome';
static const storeModeSelection = '/store-mode';
static const ownerDashboard = '/owner/dashboard';
static const staffHome = '/staff/home';
// etc for every screen
}

════════════════════════════════════════
THEME AND DESIGN SYSTEM
════════════════════════════════════════

Primary color: #1B4FD8 (trust, professional blue)
Secondary color: #16A34A (money, green)
Warning color: #F59E0B (yellow)
Danger color: #DC2626 (red)
Background: #F8FAFC (light grey-white)
Card background: #FFFFFF
Text primary: #0F172A
Text secondary: #64748B

Font: Use Google Fonts — Inter for all text

Status colors (use consistently everywhere):
GREEN = #16A34A (clean, no discrepancy)
YELLOW = #F59E0B (warning, small discrepancy)
RED = #DC2626 (flagged, large discrepancy)

Border radius: 12px for all cards and buttons
Button height: 52px for all primary buttons
Card elevation: 2px shadow

════════════════════════════════════════
FOLDER STRUCTURE
════════════════════════════════════════

lib/
├── main.dart
├── app.dart (MaterialApp, theme, router)
├── routes.dart (all named routes)
│
├── core/
│ ├── constants/
│ │ ├── app_colors.dart
│ │ ├── app_text_styles.dart
│ │ └── app_constants.dart
│ ├── services/
│ │ ├── security_service.dart
│ │ └── subscription_service.dart
│ └── utils/
│ ├── currency_formatter.dart
│ ├── date_formatter.dart
│ └── markup_calculator.dart
│
├── data/
│ ├── database/
│ │ ├── database_helper.dart
│ │ └── sync_log_helper.dart
│ ├── models/
│ │ ├── owner_model.dart
│ │ ├── store_model.dart
│ │ ├── staff_model.dart
│ │ ├── transaction_model.dart
│ │ ├── daily_float_model.dart
│ │ ├── daily_report_model.dart
│ │ ├── markup_settings_model.dart
│ │ └── one_time_pin_model.dart
│ └── repositories/
│ ├── interfaces/
│ │ ├── i_owner_repository.dart
│ │ ├── i_store_repository.dart
│ │ ├── i_staff_repository.dart
│ │ ├── i_transaction_repository.dart
│ │ ├── i_daily_float_repository.dart
│ │ └── i_report_repository.dart
│ └── local/
│ ├── local_owner_repository.dart
│ ├── local_store_repository.dart
│ ├── local_staff_repository.dart
│ ├── local_transaction_repository.dart
│ ├── local_daily_float_repository.dart
│ └── local_report_repository.dart
│
├── providers/
│ ├── auth_provider.dart
│ ├── store_provider.dart
│ ├── transaction_provider.dart
│ ├── daily_float_provider.dart
│ └── report_provider.dart
│
└── ui/
├── screens/
│ ├── onboarding/
│ ├── auth/
│ ├── owner/
│ ├── staff/
│ ├── shared/
│ ├── reports/
│ └── settings/
└── widgets/
├── common/
│ ├── primary_button.dart
│ ├── pin_pad.dart
│ ├── status_badge.dart
│ ├── premium_lock_widget.dart
│ └── loading_overlay.dart
└── dashboard/
├── float_status_card.dart
├── profit_summary_card.dart
└── quick_action_button.dart

════════════════════════════════════════
WHAT TO BUILD IN THIS SESSION
════════════════════════════════════════

Please complete ALL of the following in this session:

1. Create the complete Flutter project structure
   with all folders and files as defined above

2. Implement DatabaseHelper with all 9 tables,
   correct foreign keys, and version management

3. Implement all Model classes with fromMap()
   and toMap() methods

4. Implement all Repository interfaces and their
   local SQLite implementations

5. Implement SecurityService fully including
   PIN hashing, verification, and OTP generation

6. Implement SubscriptionService with all
   feature check methods (hardcode isPremium
   as false for now)

7. Implement MarkupCalculator utility class
   with all three rate types and unit tests

8. Implement CurrencyFormatter
   (centavos to pesos display)

9. Set up GoRouter with all named routes
   connecting to scaffolded screens

10. Implement app theme with all colors,
    typography, and component defaults

11. Scaffold ALL screens listed above with
    correct AppBar, basic layout structure,
    and navigation connections

12. Create reusable widgets:
    PrimaryButton, PinPad, StatusBadge,
    PremiumLockWidget

13. Implement Provider setup with
    ChangeNotifierProvider for all providers

14. Create main.dart and app.dart with
    correct initialization order:
    → Initialize database
    → Initialize services
    → Run app with providers
    → Start at SplashScreen

════════════════════════════════════════
IMPORTANT RULES FOR THIS SESSION
════════════════════════════════════════

- Use Filipino-friendly language in all UI labels
  e.g. "Mag-upload ng Resibo" or English is also fine
  Keep it simple and clear for non-tech users

- Every monetary amount displayed must show
  Philippine Peso sign: ₱

- Date format throughout app: MMM dd, yyyy
  e.g. "Mar 01, 2026"

- All database writes must also write to sync_log

- Never store raw PINs anywhere

- All amounts stored as INTEGER centavos in DB,
  converted to double pesos only in UI layer

- Add TODO comments everywhere Firebase
  will be integrated later so it's easy to find

- Write clean, well-commented Dart code

After completing everything above, show me:

1. The complete folder structure generated
2. Confirmation that flutter run works
   without errors
3. A list of what was completed and
   what needs to be built next session
