import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/daily_float_model.dart';
import '../common/status_badge.dart';

/// Dashboard card showing today's float status and balances.
class FloatStatusCard extends StatelessWidget {
  final DailyFloatModel? dailyFloat;
  final VoidCallback? onTap;

  const FloatStatusCard({
    super.key,
    this.dailyFloat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final float = dailyFloat;
    if (float == null) {
      return _buildNoFloatCard(context);
    }
    if (float.closed) {
      return _buildClosedCard(context, float);
    }
    return _buildFloatCard(context, float);
  }

  Widget _buildNoFloatCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No float opened today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormatter.toDisplay(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildClosedCard(BuildContext context, DailyFloatModel float) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.nights_stay_outlined,
                color: AppColors.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Day Closed',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormatter.toDisplay(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Re-open',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatCard(BuildContext context, DailyFloatModel float) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Today\'s Float',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                StatusBadge(status: float.status, compact: true),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _BalanceColumn(
                  label: 'GCash Opening',
                  value: float.openingGcashBalance,
                  icon: Icons.phone_android_rounded,
                  iconColor: AppColors.primary,
                ),
                const SizedBox(width: 16),
                _BalanceColumn(
                  label: 'Cash Opening',
                  value: float.openingCash,
                  icon: Icons.payments_outlined,
                  iconColor: AppColors.secondary,
                ),
              ],
            ),
            if (float.discrepancyGcash != null) ...[
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Discrepancy: ${CurrencyFormatter.formatSigned(float.discrepancyGcash!)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusForeground(float.status),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  final String label;
  final int? value;
  final IconData icon;
  final Color iconColor;

  const _BalanceColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value != null ? CurrencyFormatter.format(value!) : '—',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
