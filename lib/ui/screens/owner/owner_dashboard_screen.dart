import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/markup_calculator.dart';
import '../../../data/models/daily_float_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/daily_float_provider.dart';
import '../../../providers/report_provider.dart';
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

  Future<void> _showClosePastDaySheet(DailyFloatModel float) async {
    final floatProvider = context.read<DailyFloatProvider>();
    final txProvider = context.read<TransactionProvider>();
    final reportProvider = context.read<ReportProvider>();
    final storeProvider = context.read<StoreProvider>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _ClosePastDaySheet(
        float: float,
        floatProvider: floatProvider,
        txProvider: txProvider,
        reportProvider: reportProvider,
        storeProvider: storeProvider,
        onClosed: _loadData,
      ),
    );
  }

  Future<void> _confirmReopen() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Re-open Day?'),
        content: const Text(
          'This will re-open today\'s session. All closing data will be '
          'cleared and you can continue adding transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Re-open',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<DailyFloatProvider>().reopenDay();
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
      await float.loadUnclosedPastFloats(storeId);
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
            // ── Unclosed past days banner ─────────────────────────────────
            if (float.unclosedPastFloats.isNotEmpty)
              _UnclosedDaysBanner(
                floats: float.unclosedPastFloats,
                onClose: (f) => _showClosePastDaySheet(f),
              ),
            if (float.unclosedPastFloats.isNotEmpty) const SizedBox(height: 12),

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
              onTap: float.isDayOpen
                  ? () => context.push(Routes.endOfDayPreCheck)
                  : float.hasTodayFloat
                      ? _confirmReopen   // closed float → offer re-open
                      : () => context.push(Routes.openingBalance),
            ),
            const SizedBox(height: 20),

            // ── Quick actions ─────────────────────────────────────────────
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
                        onTap: float.isDayOpen
                            ? () => context.push(Routes.manualEntry,
                                extra: {'transactionType': 'cash_in'})
                            : null,
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
                      ),
                      QuickActionButton(
                        icon: Icons.nights_stay_outlined,
                        label: 'Close Day',
                        iconColor: AppColors.danger,
                        backgroundColor: AppColors.dangerLight,
                        onTap: float.isDayOpen
                            ? () => context.push(Routes.endOfDayPreCheck)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
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

// ── Unclosed days banner ──────────────────────────────────────────────────────

class _UnclosedDaysBanner extends StatelessWidget {
  final List<DailyFloatModel> floats;
  final void Function(DailyFloatModel) onClose;

  const _UnclosedDaysBanner({required this.floats, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text(
                '${floats.length} unclosed day${floats.length > 1 ? 's' : ''} need${floats.length == 1 ? 's' : ''} attention',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...floats.map((f) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: Color(0xFF92400E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        DateFormatter.toDisplay(DateTime.parse(f.date)),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onClose(f),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: const Color(0xFFB45309),
                      ),
                      child: const Text('Close',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Close past day sheet ──────────────────────────────────────────────────────

class _ClosePastDaySheet extends StatefulWidget {
  final DailyFloatModel float;
  final DailyFloatProvider floatProvider;
  final TransactionProvider txProvider;
  final ReportProvider reportProvider;
  final StoreProvider storeProvider;
  final Future<void> Function() onClosed;

  const _ClosePastDaySheet({
    required this.float,
    required this.floatProvider,
    required this.txProvider,
    required this.reportProvider,
    required this.storeProvider,
    required this.onClosed,
  });

  @override
  State<_ClosePastDaySheet> createState() => _ClosePastDaySheetState();
}

class _ClosePastDaySheetState extends State<_ClosePastDaySheet> {
  Map<String, int>? _totals;
  bool _isLoading = true;
  bool _isSaving = false;
  final _gcashCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  @override
  void dispose() {
    _gcashCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTotals() async {
    final totals = await widget.txProvider.getDailyTotalsForFloat(widget.float.id!);
    if (mounted) setState(() { _totals = totals; _isLoading = false; });
  }

  Future<void> _closeDay() async {
    final gcashPesos = double.tryParse(_gcashCtrl.text.replaceAll(',', ''));
    final cashPesos = double.tryParse(_cashCtrl.text.replaceAll(',', ''));
    if (gcashPesos == null || cashPesos == null || _totals == null) return;

    final closingGcash = (gcashPesos * 100).round();
    final closingCash = (cashPesos * 100).round();

    // Compute status for the report
    final expectedGcash = MarkupCalculator.expectedClosingGcash(
      openingGcash: widget.float.openingGcashBalance ?? 0,
      totalCashIn: _totals!['total_cash_in'] ?? 0,
      totalCashOut: _totals!['total_cash_out'] ?? 0,
      totalBillsPayment: _totals!['total_bills_payment'] ?? 0,
      totalLoadOthers: _totals!['total_load_others'] ?? 0,
    );
    final resultStatus = MarkupCalculator.discrepancyStatus(closingGcash - expectedGcash);

    setState(() => _isSaving = true);
    final success = await widget.floatProvider.closePastDay(
      float: widget.float,
      closingGcash: closingGcash,
      closingCash: closingCash,
      dailyTotals: _totals!,
    );

    if (success) {
      final storeId = widget.storeProvider.currentStore?.id;
      if (storeId != null) {
        await widget.reportProvider.createDailyReport(
          storeId: storeId,
          dailyFloatId: widget.float.id!,
          totals: _totals!,
          status: resultStatus,
          date: widget.float.date,
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
      await widget.onClosed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormatter.toDisplay(DateTime.parse(widget.float.date));
    final totals = _totals;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Close Day — $dateLabel',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Text(
                  '${totals?['total_transactions'] ?? 0} transaction(s) recorded',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expected GCash: ${CurrencyFormatter.format(MarkupCalculator.expectedClosingGcash(
                    openingGcash: widget.float.openingGcashBalance ?? 0,
                    totalCashIn: totals?['total_cash_in'] ?? 0,
                    totalCashOut: totals?['total_cash_out'] ?? 0,
                    totalBillsPayment: totals?['total_bills_payment'] ?? 0,
                    totalLoadOthers: totals?['total_load_others'] ?? 0,
                  ))}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                const Text('Actual GCash Balance (₱)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _gcashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: '₱ ',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Actual Cash on Hand (₱)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _cashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: '₱ ',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _closeDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_isSaving ? 'Closing...' : 'Close Day',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Transaction row ───────────────────────────────────────────────────────────

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
