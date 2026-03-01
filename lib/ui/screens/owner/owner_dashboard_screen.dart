import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/daily_float_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../routes.dart';
import '../../widgets/dashboard/float_status_card.dart';
import '../../widgets/dashboard/profit_summary_card.dart';
import '../../widgets/dashboard/quick_action_button.dart';

/// Owner dashboard — main hub after login.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final store = context.read<StoreProvider>();
    final float = context.read<DailyFloatProvider>();
    final tx = context.read<TransactionProvider>();

    if (auth.currentOwner?.id != null) {
      await store.loadStoreForOwner(auth.currentOwner!.id!);
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
    final store = context.watch<StoreProvider>();
    final float = context.watch<DailyFloatProvider>();
    final tx = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.currentStore?.storeName ?? 'FloatWatch',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(DateFormatter.toDisplay(DateTime.now()),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Profit summary ────────────────────────────────────────────
            ProfitSummaryCard(
              markupEarned: tx.totalMarkupEarned,
              totalGrossAmount: tx.totalGrossAmount,
              transactionCount: tx.transactionCount,
              cashInCount: tx.dailyTotals['cash_in_count'] ?? 0,
              cashOutCount: tx.dailyTotals['cash_out_count'] ?? 0,
            ),
            const SizedBox(height: 16),

            // ── Float status ──────────────────────────────────────────────
            FloatStatusCard(
              dailyFloat: float.todayFloat,
              onTap: () => float.hasTodayFloat
                  ? context.push(Routes.endOfDayPreCheck)
                  : context.push(Routes.openingBalance),
            ),
            const SizedBox(height: 20),

            // ── Quick actions ─────────────────────────────────────────────
            const Text('Quick Actions',
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
                  onTap: () => context.push(Routes.manualEntry,
                      extra: {'transactionType': 'cash_in'}),
                ),
                QuickActionButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  iconColor: const Color(0xFF9333EA),
                  backgroundColor: const Color(0xFFF3E8FF),
                  onTap: () => context.push(Routes.reportsHome),
                ),
                QuickActionButton(
                  icon: Icons.history_rounded,
                  label: 'History',
                  iconColor: AppColors.warning,
                  backgroundColor: AppColors.warningLight,
                  onTap: () => context.push(Routes.transactionHistory),
                ),
                QuickActionButton(
                  icon: Icons.group_outlined,
                  label: 'Staff',
                  iconColor: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                  onTap: () => context.push(Routes.staffManagement),
                  badge: false, // TODO: badge=true if pending approvals > 0
                ),
                QuickActionButton(
                  icon: Icons.nights_stay_outlined,
                  label: 'Close Day',
                  iconColor: AppColors.danger,
                  backgroundColor: AppColors.dangerLight,
                  onTap: () => context.push(Routes.endOfDayPreCheck),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Recent transactions ───────────────────────────────────────
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
                  onPressed: () => context.push(Routes.transactionHistory),
                  child: const Text('See all',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
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
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ...tx.transactions.take(5).map((t) => _TxRow(
                    type: t.transactionType,
                    amount: t.amount,
                    markup: t.markupEarned,
                    time: t.createdAt,
                    onTap: () => context.push(Routes.txDetail(t.id!)),
                  )),
          ],
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final String type;
  final int amount;
  final int markup;
  final String time;
  final VoidCallback onTap;

  const _TxRow({
    required this.type,
    required this.amount,
    required this.markup,
    required this.time,
    required this.onTap,
  });

  String get _label {
    switch (type) {
      case 'cash_in': return 'Cash In';
      case 'cash_out': return 'Cash Out';
      case 'bills_payment': return 'Bills Payment';
      case 'load_others': return 'Load / Others';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                color: AppColors.transactionTypeColor(type).withValues(alpha: 0.12),
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
                  Text(_label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(DateFormatter.dbToDisplayDateTime(time),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₱${(amount / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text('+₱${(markup / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
