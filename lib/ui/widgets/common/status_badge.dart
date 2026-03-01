import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Colored status chip for discrepancy and report status display.
///
/// Status values: 'clean' | 'warning' | 'flagged' | 'open'
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.statusBackground(status),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.statusForeground(status),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _label(status),
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: AppColors.statusForeground(status),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String status) {
    switch (status) {
      case 'clean':
        return 'Clean';
      case 'warning':
        return 'Warning';
      case 'flagged':
        return 'Flagged';
      case 'open':
        return 'Open';
      default:
        return status;
    }
  }
}

/// Transaction type badge with corresponding color.
class TransactionTypeBadge extends StatelessWidget {
  final String type;

  const TransactionTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.transactionTypeColor(type).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _label(type),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.transactionTypeColor(type),
        ),
      ),
    );
  }

  String _label(String type) {
    switch (type) {
      case 'cash_in':
        return 'Cash In';
      case 'cash_out':
        return 'Cash Out';
      case 'bills_payment':
        return 'Bills';
      case 'load_others':
        return 'Load';
      default:
        return type;
    }
  }
}
