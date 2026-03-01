import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// Review OCR-extracted transaction details before saving.
/// TODO: Populate from ML Kit OCR results passed via GoRouter extra.
class OcrReviewScreen extends StatelessWidget {
  const OcrReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Receipt')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Check Details',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                  'FloatWatch read your receipt. Please verify the details below before saving.',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              // OCR Result fields (editable)
              _ReviewField(label: 'Transaction Type', value: 'Cash In'),
              const SizedBox(height: 12),
              _ReviewField(label: 'Amount', value: '₱500.00'),
              const SizedBox(height: 12),
              _ReviewField(label: 'Reference Number', value: '—'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('OCR confidence: 92%. Review carefully.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary))),
                ]),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Confirm & Save',
                onPressed: () => context.go(Routes.transactionSuccess),
                leadingIcon: Icons.check_rounded,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go(Routes.manualEntry,
                    extra: {'transactionType': 'cash_in'}),
                child: const Text('Edit manually',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewField extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          )),
          const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}
