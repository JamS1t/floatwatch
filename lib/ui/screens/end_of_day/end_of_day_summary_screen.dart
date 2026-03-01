import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/markup_calculator.dart';
import '../../../providers/daily_float_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/status_badge.dart';

/// End of Day summary screen — shows computed discrepancy before closing.
/// Receives closing balances from [EndOfDayBalanceEntryScreen] via GoRouter extra.
class EndOfDaySummaryScreen extends StatefulWidget {
  final int closingGcash;
  final int closingCash;

  const EndOfDaySummaryScreen({
    super.key,
    required this.closingGcash,
    required this.closingCash,
  });

  @override
  State<EndOfDaySummaryScreen> createState() =>
      _EndOfDaySummaryScreenState();
}

class _EndOfDaySummaryScreenState extends State<EndOfDaySummaryScreen> {
  bool _isClosing = false;

  Future<void> _closeDay() async {
    setState(() => _isClosing = true);
    try {
      final float = context.read<DailyFloatProvider>();
      final tx = context.read<TransactionProvider>();
      final report = context.read<ReportProvider>();

      final totals = tx.dailyTotals;

      final success = await float.closeDay(
        closingGcash: widget.closingGcash,
        closingCash: widget.closingCash,
        dailyTotals: totals,
      );

      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to close the day. Try again.')),
        );
        return;
      }

      // Create daily report
      final discrepancyStatus = MarkupCalculator.discrepancyStatus(
          (widget.closingGcash -
              MarkupCalculator.expectedClosingGcash(
                openingGcash: float.todayFloat?.openingGcashBalance ?? 0,
                totalCashIn: totals['total_cash_in'] ?? 0,
                totalCashOut: totals['total_cash_out'] ?? 0,
                totalBillsPayment: totals['total_bills_payment'] ?? 0,
                totalLoadOthers: totals['total_load_others'] ?? 0,
              ))
          .abs());

      await report.createDailyReport(
        storeId: float.todayFloat!.storeId,
        dailyFloatId: float.todayFloat!.id!,
        totals: totals,
        status: discrepancyStatus,
      );

      if (mounted) context.go(Routes.dayClosedSuccess);
    } finally {
      if (mounted) setState(() => _isClosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final float = context.watch<DailyFloatProvider>();
    final tx = context.watch<TransactionProvider>();
    final totals = tx.dailyTotals;

    final openingGcash = float.todayFloat?.openingGcashBalance ?? 0;
    final expectedGcash = MarkupCalculator.expectedClosingGcash(
      openingGcash: openingGcash,
      totalCashIn: totals['total_cash_in'] ?? 0,
      totalCashOut: totals['total_cash_out'] ?? 0,
      totalBillsPayment: totals['total_bills_payment'] ?? 0,
      totalLoadOthers: totals['total_load_others'] ?? 0,
    );

    final discrepancyGcash = widget.closingGcash - expectedGcash;
    final status =
        MarkupCalculator.discrepancyStatus(discrepancyGcash.abs());

    return LoadingOverlay(
      isLoading: _isClosing,
      message: 'Closing the day...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Day Summary')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Discrepancy status banner ──────────────────────────────
              _DiscrepancyBanner(
                  status: status, discrepancy: discrepancyGcash),
              const SizedBox(height: 16),

              // ── Transaction totals ─────────────────────────────────────
              _SectionLabel('Transactions'),
              _SummaryCard(children: [
                _SummaryRow('Total Transactions',
                    '${totals['total_transactions'] ?? 0}'),
                _SummaryRow('Cash In (GCash→Cash)',
                    CurrencyFormatter.format(totals['total_cash_in'] ?? 0)),
                _SummaryRow('Cash Out (Cash→GCash)',
                    CurrencyFormatter.format(totals['total_cash_out'] ?? 0)),
                _SummaryRow('Bills Payment',
                    CurrencyFormatter.format(
                        totals['total_bills_payment'] ?? 0)),
                _SummaryRow('Load / Others',
                    CurrencyFormatter.format(
                        totals['total_load_others'] ?? 0)),
              ]),
              const SizedBox(height: 12),

              // ── Markup earned ──────────────────────────────────────────
              _SectionLabel('Earnings'),
              _SummaryCard(children: [
                _SummaryRow('Gross Volume',
                    CurrencyFormatter.format(
                        totals['total_gross_amount'] ?? 0)),
                _SummaryRow(
                  'Markup Earned',
                  CurrencyFormatter.format(
                      totals['total_markup_earned'] ?? 0),
                  valueColor: AppColors.secondary,
                  bold: true,
                ),
              ]),
              const SizedBox(height: 12),

              // ── GCash balance ──────────────────────────────────────────
              _SectionLabel('GCash Balance'),
              _SummaryCard(children: [
                _SummaryRow('Opening GCash',
                    CurrencyFormatter.format(openingGcash)),
                _SummaryRow('Expected Closing',
                    CurrencyFormatter.format(expectedGcash)),
                _SummaryRow('Actual Closing',
                    CurrencyFormatter.format(widget.closingGcash)),
                _SummaryRow(
                  'Discrepancy',
                  CurrencyFormatter.formatSigned(discrepancyGcash),
                  valueColor: status == 'clean'
                      ? AppColors.secondary
                      : status == 'warning'
                          ? AppColors.warning
                          : AppColors.danger,
                  bold: true,
                ),
              ]),
              const SizedBox(height: 12),

              // ── Cash balance ───────────────────────────────────────────
              _SectionLabel('Cash Balance'),
              _SummaryCard(children: [
                _SummaryRow('Opening Cash',
                    CurrencyFormatter.format(
                        float.todayFloat?.openingCash ?? 0)),
                _SummaryRow('Closing Cash',
                    CurrencyFormatter.format(widget.closingCash)),
              ]),
              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Confirm & Close Day',
                onPressed: _closeDay,
                isLoading: _isClosing,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscrepancyBanner extends StatelessWidget {
  final String status;
  final int discrepancy;

  const _DiscrepancyBanner(
      {required this.status, required this.discrepancy});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case 'clean':
        bg = const Color(0xFFDCFCE7);
        fg = AppColors.secondary;
        icon = Icons.check_circle_outline;
        label = 'Balanced — discrepancy within acceptable range';
        break;
      case 'warning':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        icon = Icons.warning_amber_outlined;
        label = 'Small discrepancy detected — review before closing';
        break;
      default:
        bg = AppColors.dangerLight;
        fg = AppColors.danger;
        icon = Icons.error_outline;
        label = 'Large discrepancy — please investigate';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(status: status),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(fontSize: 13, color: fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      );
}

class _SummaryCard extends StatelessWidget {
  final List<Widget> children;
  const _SummaryCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(children: children),
      );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow(this.label, this.value,
      {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        bold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary)),
          ],
        ),
      );
}
