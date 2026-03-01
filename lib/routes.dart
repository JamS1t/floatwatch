import 'package:go_router/go_router.dart';

import 'ui/screens/auth/owner_pin_entry_screen.dart';
import 'ui/screens/auth/pin_locked_screen.dart';
import 'ui/screens/auth/role_selection_screen.dart';
import 'ui/screens/auth/staff_pin_entry_screen.dart';
import 'ui/screens/auth/staff_selection_screen.dart';
import 'ui/screens/end_of_day/day_closed_success_screen.dart';
import 'ui/screens/end_of_day/end_of_day_balance_entry_screen.dart';
import 'ui/screens/end_of_day/end_of_day_pre_check_screen.dart';
import 'ui/screens/end_of_day/end_of_day_summary_screen.dart';
import 'ui/screens/onboarding/create_owner_account_screen.dart';
import 'ui/screens/onboarding/create_store_profile_screen.dart';
import 'ui/screens/onboarding/onboarding_complete_screen.dart';
import 'ui/screens/onboarding/onboarding_markup_settings_screen.dart';
import 'ui/screens/onboarding/splash_screen.dart';
import 'ui/screens/onboarding/store_mode_selection_screen.dart';
import 'ui/screens/onboarding/welcome_screen.dart';
import 'ui/screens/owner/add_staff_screen.dart';
import 'ui/screens/owner/opening_balance_screen.dart';
import 'ui/screens/owner/owner_dashboard_screen.dart';
import 'ui/screens/owner/pending_approvals_screen.dart';
import 'ui/screens/owner/staff_activity_detail_screen.dart';
import 'ui/screens/owner/staff_management_screen.dart';
import 'ui/screens/reports/daily_report_detail_screen.dart';
import 'ui/screens/reports/monthly_report_screen.dart';
import 'ui/screens/reports/reports_home_screen.dart';
import 'ui/screens/reports/weekly_report_screen.dart';
import 'ui/screens/settings/about_screen.dart';
import 'ui/screens/settings/change_pin_screen.dart';
import 'ui/screens/settings/markup_settings_edit_screen.dart';
import 'ui/screens/settings/notification_settings_screen.dart';
import 'ui/screens/settings/security_mode_settings_screen.dart';
import 'ui/screens/settings/settings_screen.dart';
import 'ui/screens/settings/subscription_screen.dart';
import 'ui/screens/shared/batch_upload_screen.dart';
import 'ui/screens/shared/manual_entry_screen.dart';
import 'ui/screens/shared/ocr_review_screen.dart';
import 'ui/screens/shared/transaction_success_screen.dart';
import 'ui/screens/staff/manual_entry_pin_request_screen.dart';
import 'ui/screens/staff/staff_home_screen.dart';
import 'ui/screens/staff/staff_transaction_list_screen.dart';
import 'ui/screens/transactions/transaction_detail_screen.dart';
import 'ui/screens/transactions/transaction_history_screen.dart';

/// All named route constants for FloatWatch.
/// Always navigate using these constants — never use raw strings.
class Routes {
  Routes._();

  // ── Onboarding ──────────────────────────────────────────────────────────
  static const splash = '/';
  static const welcome = '/welcome';
  static const storeModeSelection = '/onboarding/store-mode';
  static const createOwnerAccount = '/onboarding/owner';
  static const createStoreProfile = '/onboarding/store';
  static const onboardingMarkupSettings = '/onboarding/markup';
  static const onboardingComplete = '/onboarding/complete';

  // ── Authentication ──────────────────────────────────────────────────────
  static const roleSelection = '/auth/role';
  static const ownerPinEntry = '/auth/owner-pin';
  static const staffSelection = '/auth/staff';
  static const staffPinEntry = '/auth/staff-pin';
  static const pinLocked = '/auth/locked';

  // ── Owner ────────────────────────────────────────────────────────────────
  static const ownerDashboard = '/owner/dashboard';
  static const openingBalance = '/owner/opening-balance';
  static const pendingApprovals = '/owner/approvals';
  static const staffManagement = '/owner/staff';
  static const addStaff = '/owner/staff/add';
  static const staffActivityDetail = '/owner/staff/:staffId';

  // ── Shared (owner + staff) ───────────────────────────────────────────────
  static const batchUpload = '/shared/batch-upload';
  static const ocrReview = '/shared/ocr-review';
  static const manualEntry = '/shared/manual-entry';
  static const transactionSuccess = '/shared/success';

  // ── Staff ────────────────────────────────────────────────────────────────
  static const staffHome = '/staff/home';
  static const staffTransactionList = '/staff/transactions';
  static const manualEntryPinRequest = '/staff/pin-request';

  // ── Transactions ─────────────────────────────────────────────────────────
  static const transactionHistory = '/transactions';
  static const transactionDetail = '/transactions/:id';

  // ── End of Day ───────────────────────────────────────────────────────────
  static const endOfDayPreCheck = '/end-of-day/pre-check';
  static const endOfDayBalanceEntry = '/end-of-day/balance';
  static const endOfDaySummary = '/end-of-day/summary';
  static const dayClosedSuccess = '/end-of-day/success';

  // ── Reports ──────────────────────────────────────────────────────────────
  static const reportsHome = '/reports';
  static const dailyReportDetail = '/reports/daily/:date';
  static const weeklyReport = '/reports/weekly';
  static const monthlyReport = '/reports/monthly';

  // ── Settings ─────────────────────────────────────────────────────────────
  static const settings = '/settings';
  static const securityModeSettings = '/settings/security';
  static const markupSettingsEdit = '/settings/markup';
  static const changePinScreen = '/settings/change-pin';
  static const notificationSettings = '/settings/notifications';
  static const subscriptionScreen = '/settings/subscription';
  static const aboutScreen = '/settings/about';

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Build the staffActivityDetail path with a real staffId
  static String staffDetail(int staffId) => '/owner/staff/$staffId';

  /// Build the transactionDetail path with a real transaction id
  static String txDetail(int id) => '/transactions/$id';

  /// Build the dailyReportDetail path with a date string (yyyy-MM-dd)
  static String dailyReport(String date) => '/reports/daily/$date';
}

/// GoRouter instance used by [FloatWatchApp].
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  debugLogDiagnostics: false,
  routes: [
    // ── Onboarding ──────────────────────────────────────────────────────
    GoRoute(
      path: Routes.splash,
      name: 'splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.welcome,
      name: 'welcome',
      builder: (_, __) => const WelcomeScreen(),
    ),
    GoRoute(
      path: Routes.storeModeSelection,
      name: 'storeModeSelection',
      builder: (_, __) => const StoreModeSelectionScreen(),
    ),
    GoRoute(
      path: Routes.createOwnerAccount,
      name: 'createOwnerAccount',
      builder: (_, __) => const CreateOwnerAccountScreen(),
    ),
    GoRoute(
      path: Routes.createStoreProfile,
      name: 'createStoreProfile',
      builder: (_, __) => const CreateStoreProfileScreen(),
    ),
    GoRoute(
      path: Routes.onboardingMarkupSettings,
      name: 'onboardingMarkupSettings',
      builder: (_, __) => const OnboardingMarkupSettingsScreen(),
    ),
    GoRoute(
      path: Routes.onboardingComplete,
      name: 'onboardingComplete',
      builder: (_, __) => const OnboardingCompleteScreen(),
    ),

    // ── Authentication ──────────────────────────────────────────────────
    GoRoute(
      path: Routes.roleSelection,
      name: 'roleSelection',
      builder: (_, __) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: Routes.ownerPinEntry,
      name: 'ownerPinEntry',
      builder: (_, __) => const OwnerPinEntryScreen(),
    ),
    GoRoute(
      path: Routes.staffSelection,
      name: 'staffSelection',
      builder: (_, __) => const StaffSelectionScreen(),
    ),
    GoRoute(
      path: Routes.staffPinEntry,
      name: 'staffPinEntry',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return StaffPinEntryScreen(staffId: extra?['staffId'] as int? ?? 0);
      },
    ),
    GoRoute(
      path: Routes.pinLocked,
      name: 'pinLocked',
      builder: (_, __) => const PinLockedScreen(),
    ),

    // ── Owner ────────────────────────────────────────────────────────────
    GoRoute(
      path: Routes.ownerDashboard,
      name: 'ownerDashboard',
      builder: (_, __) => const OwnerDashboardScreen(),
    ),
    GoRoute(
      path: Routes.openingBalance,
      name: 'openingBalance',
      builder: (_, __) => const OpeningBalanceScreen(),
    ),
    GoRoute(
      path: Routes.pendingApprovals,
      name: 'pendingApprovals',
      builder: (_, __) => const PendingApprovalsScreen(),
    ),
    GoRoute(
      path: Routes.staffManagement,
      name: 'staffManagement',
      builder: (_, __) => const StaffManagementScreen(),
    ),
    // NOTE: addStaff must be listed BEFORE staffActivityDetail to avoid
    // the literal 'add' segment being matched as a :staffId parameter.
    GoRoute(
      path: Routes.addStaff,
      name: 'addStaff',
      builder: (_, __) => const AddStaffScreen(),
    ),
    GoRoute(
      path: Routes.staffActivityDetail,
      name: 'staffActivityDetail',
      builder: (_, state) => StaffActivityDetailScreen(
        staffId: int.tryParse(state.pathParameters['staffId'] ?? '') ?? 0,
      ),
    ),

    // ── Shared ───────────────────────────────────────────────────────────
    GoRoute(
      path: Routes.batchUpload,
      name: 'batchUpload',
      builder: (_, __) => const BatchUploadScreen(),
    ),
    GoRoute(
      path: Routes.ocrReview,
      name: 'ocrReview',
      builder: (_, __) => const OcrReviewScreen(),
    ),
    GoRoute(
      path: Routes.manualEntry,
      name: 'manualEntry',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ManualEntryScreen(
          transactionType: extra?['transactionType'] as String? ?? 'cash_in',
        );
      },
    ),
    GoRoute(
      path: Routes.transactionSuccess,
      name: 'transactionSuccess',
      builder: (_, __) => const TransactionSuccessScreen(),
    ),

    // ── Staff ────────────────────────────────────────────────────────────
    GoRoute(
      path: Routes.staffHome,
      name: 'staffHome',
      builder: (_, __) => const StaffHomeScreen(),
    ),
    GoRoute(
      path: Routes.staffTransactionList,
      name: 'staffTransactionList',
      builder: (_, __) => const StaffTransactionListScreen(),
    ),
    GoRoute(
      path: Routes.manualEntryPinRequest,
      name: 'manualEntryPinRequest',
      builder: (_, __) => const ManualEntryPinRequestScreen(),
    ),

    // ── Transactions ─────────────────────────────────────────────────────
    GoRoute(
      path: Routes.transactionHistory,
      name: 'transactionHistory',
      builder: (_, __) => const TransactionHistoryScreen(),
    ),
    GoRoute(
      path: Routes.transactionDetail,
      name: 'transactionDetail',
      builder: (_, state) => TransactionDetailScreen(
        transactionId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
      ),
    ),

    // ── End of Day ───────────────────────────────────────────────────────
    GoRoute(
      path: Routes.endOfDayPreCheck,
      name: 'endOfDayPreCheck',
      builder: (_, __) => const EndOfDayPreCheckScreen(),
    ),
    GoRoute(
      path: Routes.endOfDayBalanceEntry,
      name: 'endOfDayBalanceEntry',
      builder: (_, __) => const EndOfDayBalanceEntryScreen(),
    ),
    GoRoute(
      path: Routes.endOfDaySummary,
      name: 'endOfDaySummary',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return EndOfDaySummaryScreen(
          closingGcash: extra?['closingGcash'] as int? ?? 0,
          closingCash: extra?['closingCash'] as int? ?? 0,
        );
      },
    ),
    GoRoute(
      path: Routes.dayClosedSuccess,
      name: 'dayClosedSuccess',
      builder: (_, __) => const DayClosedSuccessScreen(),
    ),

    // ── Reports ──────────────────────────────────────────────────────────
    GoRoute(
      path: Routes.reportsHome,
      name: 'reportsHome',
      builder: (_, __) => const ReportsHomeScreen(),
    ),
    GoRoute(
      path: Routes.dailyReportDetail,
      name: 'dailyReportDetail',
      builder: (_, state) => DailyReportDetailScreen(
        date: state.pathParameters['date'] ?? '',
      ),
    ),
    GoRoute(
      path: Routes.weeklyReport,
      name: 'weeklyReport',
      builder: (_, __) => const WeeklyReportScreen(),
    ),
    GoRoute(
      path: Routes.monthlyReport,
      name: 'monthlyReport',
      builder: (_, __) => const MonthlyReportScreen(),
    ),

    // ── Settings ─────────────────────────────────────────────────────────
    GoRoute(
      path: Routes.settings,
      name: 'settings',
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: Routes.securityModeSettings,
      name: 'securityModeSettings',
      builder: (_, __) => const SecurityModeSettingsScreen(),
    ),
    GoRoute(
      path: Routes.markupSettingsEdit,
      name: 'markupSettingsEdit',
      builder: (_, __) => const MarkupSettingsEditScreen(),
    ),
    GoRoute(
      path: Routes.changePinScreen,
      name: 'changePinScreen',
      builder: (_, __) => const ChangePinScreen(),
    ),
    GoRoute(
      path: Routes.notificationSettings,
      name: 'notificationSettings',
      builder: (_, __) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: Routes.subscriptionScreen,
      name: 'subscriptionScreen',
      builder: (_, __) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: Routes.aboutScreen,
      name: 'aboutScreen',
      builder: (_, __) => const AboutScreen(),
    ),
  ],
);
