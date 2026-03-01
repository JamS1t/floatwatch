import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/transaction_provider.dart';
import '../../widgets/common/status_badge.dart';

/// Detailed view of a single transaction record.
class TransactionDetailScreen extends StatelessWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final matches = provider.transactions.where((t) => t.id == transactionId);
    final t = matches.isEmpty ? null : matches.first;

    if (t == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Detail')),
        body: const Center(
          child: Text('Transaction not found.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        actions: [
          if (!t.flagged)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Flag for review',
              onPressed: () => _showFlagDialog(context, t),
            )
          else
            IconButton(
              icon: const Icon(Icons.flag, color: AppColors.danger),
              tooltip: 'Remove flag',
              onPressed: () {
                context
                    .read<TransactionProvider>()
                    .unflagTransaction(t.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flag removed.')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.transactionTypeColor(t.transactionType)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.receipt_long_outlined,
                        color: AppColors.transactionTypeColor(t.transactionType),
                        size: 28),
                  ),
                  const SizedBox(height: 12),
                  TransactionTypeBadge(type: t.transactionType),
                  if (t.flagged) ...[
                    const SizedBox(height: 6),
                    const StatusBadge(status: 'flagged'),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.format(t.amount),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${CurrencyFormatter.format(t.markupEarned)} markup earned',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Detail rows ─────────────────────────────────────────────
            _DetailCard(children: [
              _DetailRow(
                label: 'Date & Time',
                value: DateFormatter.dbToDisplayDateTime(t.createdAt),
              ),
              _DetailRow(
                label: 'Reference Number',
                value: t.referenceNumber?.isNotEmpty == true
                    ? t.referenceNumber!
                    : '—',
              ),
              _DetailRow(
                label: 'Entry Method',
                value: t.entryMethod.replaceAll('_', ' ').toUpperCase(),
              ),
              _DetailRow(
                label: 'Entered By',
                value: t.enteredByRole == 'owner' ? 'Owner' : 'Staff',
              ),
              _DetailRow(
                label: 'Used One-Time PIN',
                value: t.usedOtp ? 'Yes' : 'No',
              ),
            ]),
            const SizedBox(height: 12),

            // ── Markup breakdown ────────────────────────────────────────
            _SectionHeader(label: 'Markup Breakdown'),
            _DetailCard(children: [
              _DetailRow(
                label: 'Rate Type',
                value: t.markupRateTypeSnapshot
                    .replaceAll('_', ' ')
                    .toUpperCase(),
              ),
              if (t.markupRateTypeSnapshot == 'percentage')
                _DetailRow(
                  label: 'Rate',
                  value:
                      '${(t.markupRateValueSnapshot / 100).toStringAsFixed(2)}%',
                ),
              if (t.markupRateTypeSnapshot == 'fixed')
                _DetailRow(
                  label: 'Fixed Fee',
                  value: CurrencyFormatter.format(t.markupRateValueSnapshot),
                ),
              if (t.markupRateTypeSnapshot == 'per_bracket' &&
                  t.markupBracketSizeSnapshot != null)
                _DetailRow(
                  label: 'Rate / Bracket',
                  value:
                      '${CurrencyFormatter.format(t.markupRateValueSnapshot)} per ${CurrencyFormatter.format(t.markupBracketSizeSnapshot!)}',
                ),
              _DetailRow(
                label: 'Markup Earned',
                value: CurrencyFormatter.format(t.markupEarned),
                valueColor: AppColors.secondary,
              ),
            ]),
            const SizedBox(height: 12),

            // ── Receipt ─────────────────────────────────────────────────
            _SectionHeader(label: 'Receipt'),
            _DetailCard(children: [
              _DetailRow(
                label: 'Receipt Status',
                value: t.hasReceipt ? 'Attached' : 'No receipt',
              ),
              if (!t.hasReceipt && t.missingReceiptReason != null)
                _DetailRow(
                  label: 'Reason',
                  value: t.missingReceiptReason!,
                ),
              if (t.ocrConfidenceScore != null)
                _DetailRow(
                  label: 'OCR Confidence',
                  value:
                      '${(t.ocrConfidenceScore! * 100).toStringAsFixed(0)}%',
                ),
            ]),

            if (t.flagged && t.flagReason != null) ...[
              const SizedBox(height: 12),
              _SectionHeader(label: 'Flag Details'),
              _DetailCard(children: [
                _DetailRow(
                  label: 'Reason',
                  value: t.flagReason!,
                  valueColor: AppColors.danger,
                ),
              ]),
            ],

            const SizedBox(height: 12),
            _DetailCard(children: [
              _DetailRow(label: 'Transaction ID', value: '#${t.id}'),
              _DetailRow(label: 'Sync ID', value: t.syncId.substring(0, 8)),
            ]),
          ],
        ),
      ),
    );
  }

  void _showFlagDialog(BuildContext context, TransactionModel t) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Flag Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for flagging this transaction.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Amount mismatch, missing receipt...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = ctrl.text.trim().isEmpty
                  ? 'Flagged for review'
                  : ctrl.text.trim();
              context
                  .read<TransactionProvider>()
                  .flagTransaction(t.id!, reason);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Transaction flagged for review.')),
              );
            },
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

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

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppColors.textPrimary)),
            ),
          ],
        ),
      );
}
