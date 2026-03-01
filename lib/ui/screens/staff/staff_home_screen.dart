import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/security_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/daily_float_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../routes.dart';
import '../../widgets/dashboard/quick_action_button.dart';

/// Staff home screen — simplified dashboard for staff members.
class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Navigate to Manual Entry directly (simple mode) or via OTP screen (strict mode).
  Future<void> _goToManualEntry() async {
    final storeId = context.read<StoreProvider>().currentStore?.id;
    if (storeId == null) return;
    final needsPin = await context
        .read<SecurityService>()
        .requiresManualEntryPin(storeId);
    if (!mounted) return;
    if (needsPin) {
      context.push(Routes.manualEntryPinRequest);
    } else {
      context.push(Routes.manualEntry);
    }
  }

  Future<void> _load() async {
    final store = context.read<StoreProvider>();
    final auth = context.read<AuthProvider>();
    final float = context.read<DailyFloatProvider>();
    final tx = context.read<TransactionProvider>();

    if (auth.currentStaff?.ownerId != null) {
      await store.loadStoreForOwner(auth.currentStaff!.ownerId);
    }
    final storeId = store.currentStore?.id;
    if (storeId != null) {
      await float.loadTodayFloat(storeId);
      if (float.todayFloat?.id != null) {
        await tx.loadTransactionsForDay(float.todayFloat!.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    context.watch<StoreProvider>(); // triggers rebuild when store changes
    final float = context.watch<DailyFloatProvider>();
    final tx = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, ${auth.currentStaff?.name.split(' ').first ?? 'Staff'}!',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text(DateFormatter.toDisplay(DateTime.now()),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go(Routes.roleSelection);
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Today's summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1A44B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today',
                      style:
                          TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    '${tx.transactionCount} Transactions',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(tx.totalGrossAmount),
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Actions',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: [
                QuickActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Upload\nReceipt',
                  iconColor: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                  onTap: () => context.push(Routes.batchUpload),
                ),
                QuickActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Manual\nEntry',
                  iconColor: AppColors.secondary,
                  backgroundColor: AppColors.secondaryLight,
                  onTap: _goToManualEntry,
                ),
                QuickActionButton(
                  icon: Icons.history_rounded,
                  label: 'My\nTransactions',
                  iconColor: AppColors.warning,
                  backgroundColor: AppColors.warningLight,
                  onTap: () => context.push(Routes.staffTransactionList),
                ),
                // Open Day — shown when no active day exists yet
                if (!float.hasTodayFloat)
                  QuickActionButton(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Open\nDay',
                    iconColor: AppColors.secondary,
                    backgroundColor: AppColors.secondaryLight,
                    onTap: () => context.push(Routes.openingBalance),
                  ),
                // Close Day — shown when day is open
                if (float.isDayOpen)
                  QuickActionButton(
                    icon: Icons.nights_stay_outlined,
                    label: 'Close\nDay',
                    iconColor: AppColors.danger,
                    backgroundColor: AppColors.dangerLight,
                    onTap: () => context.push(Routes.endOfDayPreCheck),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
