import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/transaction_provider.dart';
import '../../../routes.dart';

/// Staff view of their own transactions for today.
class StaffTransactionListScreen extends StatelessWidget {
  const StaffTransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>().transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('My Transactions')),
      body: transactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No transactions yet.',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final t = transactions[i];
                return ListTile(
                  tileColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.divider)),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.transactionTypeColor(t.transactionType)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long_outlined,
                        color: AppColors.transactionTypeColor(t.transactionType),
                        size: 20),
                  ),
                  title: Text(t.transactionType.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(DateFormatter.dbToDisplayDateTime(t.createdAt),
                      style: const TextStyle(fontSize: 11)),
                  trailing: Text(CurrencyFormatter.format(t.amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  onTap: () => context.push(Routes.txDetail(t.id!)),
                );
              },
            ),
    );
  }
}
