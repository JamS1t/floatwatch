import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/daily_float_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// Pre-check screen shown before closing the day.
/// Summarises the day's activity and warns about any flagged transactions.
class EndOfDayPreCheckScreen extends StatelessWidget {
  const EndOfDayPreCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = context.watch<TransactionProvider>();
    final float = context.watch<DailyFloatProvider>();

    final flaggedCount =
        tx.transactions.where((t) => t.flagged).length;
    final hasFlagged = flaggedCount > 0;
    final isDayOpen = float.isDayOpen;

    return Scaffold(
      appBar: AppBar(title: const Text('End of Day')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Today's Summary ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1A44B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today\'s Summary',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('${tx.transactionCount} Transactions',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _SummaryChip(
                        label: 'Gross',
                        value: CurrencyFormatter.format(tx.totalGrossAmount),
                      ),
                      const SizedBox(width: 12),
                      _SummaryChip(
                        label: 'Markup',
                        value:
                            CurrencyFormatter.format(tx.totalMarkupEarned),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Pre-close checks ─────────────────────────────────────────
            const Text('Pre-close Checks',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            _CheckItem(
              icon: Icons.receipt_long_outlined,
              label: 'Transactions recorded',
              value: '${tx.transactionCount} transactions',
              status: CheckStatus.ok,
            ),
            const SizedBox(height: 8),
            _CheckItem(
              icon: Icons.flag_outlined,
              label: 'Flagged transactions',
              value: hasFlagged
                  ? '$flaggedCount flagged — review before closing'
                  : 'None flagged',
              status: hasFlagged ? CheckStatus.warning : CheckStatus.ok,
            ),
            const SizedBox(height: 8),
            _CheckItem(
              icon: Icons.store_outlined,
              label: 'Day status',
              value: isDayOpen ? 'Day is open and active' : 'No active day',
              status: isDayOpen ? CheckStatus.ok : CheckStatus.error,
            ),
            const SizedBox(height: 24),

            if (!isDayOpen)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.error_outline,
                      color: AppColors.danger, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No active day found. Go back to the dashboard and open the day first.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              )
            else ...[
              if (hasFlagged)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_outlined,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$flaggedCount transaction${flaggedCount == 1 ? '' : 's'} flagged for review. You may still close the day.',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Enter Closing Balances',
                onPressed: () => context.push(Routes.endOfDayBalanceEntry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum CheckStatus { ok, warning, error }

class _CheckItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final CheckStatus status;

  const _CheckItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  Color get _statusColor {
    switch (status) {
      case CheckStatus.ok:
        return AppColors.secondary;
      case CheckStatus.warning:
        return AppColors.warning;
      case CheckStatus.error:
        return AppColors.danger;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case CheckStatus.ok:
        return Icons.check_circle_outline;
      case CheckStatus.warning:
        return Icons.warning_amber_outlined;
      case CheckStatus.error:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(_statusIcon, color: _statusColor, size: 20),
          ],
        ),
      );
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.white70)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      );
}
