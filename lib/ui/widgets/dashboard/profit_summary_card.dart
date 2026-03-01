import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Dashboard card showing today's markup income and transaction counts.
class ProfitSummaryCard extends StatelessWidget {
  final int markupEarned; // centavos
  final int totalGrossAmount; // centavos
  final int transactionCount;
  final int cashInCount;
  final int cashOutCount;

  const ProfitSummaryCard({
    super.key,
    required this.markupEarned,
    required this.totalGrossAmount,
    required this.transactionCount,
    this.cashInCount = 0,
    this.cashOutCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1A44B8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text(
                'Today\'s Income',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(markupEarned),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'from ${CurrencyFormatter.formatCompact(totalGrossAmount)} total',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: 'Transactions',
                value: transactionCount.toString(),
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Cash In',
                value: cashInCount.toString(),
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Cash Out',
                value: cashOutCount.toString(),
                icon: Icons.arrow_upward_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Row(
          children: [
            Icon(icon, size: 10, color: Colors.white60),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white60),
            ),
          ],
        ),
      ],
    );
  }
}
