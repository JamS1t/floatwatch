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
import '../../widgets/dashboard/float_status_card.dart';
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
    context.watch<StoreProvider>();
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
            // ── Float status ───────────────────────────────────────────────
            FloatStatusCard(
              dailyFloat: float.todayFloat,
              // Staff can open the day but cannot re-open a closed day.
              onTap: !float.hasTodayFloat
                  ? () => context.push(Routes.openingBalance)
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Today's activity stats ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transactions Today',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('${tx.transactionCount}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  Container(
                      width: 1, height: 36, color: AppColors.divider),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Amount',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(tx.totalGrossAmount),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Quick actions ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 4,
                    childAspectRatio: 0.85,
                    children: [
                      QuickActionButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Upload\nReceipt',
                        iconColor: AppColors.primary,
                        backgroundColor: AppColors.primaryLight,
                        onTap: float.isDayOpen
                            ? () => context.push(Routes.batchUpload)
                            : null,
                      ),
                      QuickActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Manual\nEntry',
                        iconColor: AppColors.secondary,
                        backgroundColor: AppColors.secondaryLight,
                        onTap: float.isDayOpen ? _goToManualEntry : null,
                      ),
                      QuickActionButton(
                        icon: Icons.history_rounded,
                        label: 'My\nTransactions',
                        iconColor: AppColors.warning,
                        backgroundColor: AppColors.warningLight,
                        onTap: () => context.push(Routes.staffTransactionList),
                      ),
                      // Open Day — shown only when no active day exists yet
                      if (!float.hasTodayFloat)
                        QuickActionButton(
                          icon: Icons.wb_sunny_outlined,
                          label: 'Open\nDay',
                          iconColor: AppColors.secondary,
                          backgroundColor: AppColors.secondaryLight,
                          onTap: () => context.push(Routes.openingBalance),
                        ),
                      // NOTE: Close Day is intentionally owner-only.
                      // Staff should not see markup/earnings data.
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Recent transactions ────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Text('Recent Transactions',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                TextButton(
                  onPressed: () =>
                      context.push(Routes.staffTransactionList),
                  child: const Text('See all',
                      style:
                          TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ),
            if (tx.transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Center(
                  child: Text('No transactions yet today.',
                      style:
                          TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ...tx.transactions.take(5).map((t) => _StaffTxRow(
                    type: t.transactionType,
                    amount: t.amount,
                    time: t.createdAt,
                    byOwner: t.enteredByRole == 'owner',
                    onTap: () => context.push(Routes.txDetail(t.id!)),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StaffTxRow extends StatelessWidget {
  final String type;
  final int amount;
  final String time;
  final bool byOwner;
  final VoidCallback onTap;

  const _StaffTxRow({
    required this.type,
    required this.amount,
    required this.time,
    required this.byOwner,
    required this.onTap,
  });

  String get _label {
    switch (type) {
      case 'cash_in':
        return 'Cash In';
      case 'cash_out':
        return 'Cash Out';
      case 'bills_payment':
        return 'Bills Payment';
      case 'load_others':
        return 'Load / Others';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.transactionTypeColor(type)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_long_outlined,
                  color: AppColors.transactionTypeColor(type), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      if (byOwner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('By Owner',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  Text(DateFormatter.dbToDisplayDateTime(time),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(amount),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
