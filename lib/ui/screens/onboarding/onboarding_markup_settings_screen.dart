import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// Initial markup settings setup during onboarding.
/// Full editing available in Settings → Markup Settings.
class OnboardingMarkupSettingsScreen extends StatelessWidget {
  const OnboardingMarkupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markup Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Your Markup Rates',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Define how much you earn per transaction. You can update these anytime in Settings.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              // Markup type cards — placeholder for now
              _MarkupRow(
                label: 'Cash In',
                icon: Icons.arrow_downward_rounded,
                color: AppColors.secondary,
                hint: 'e.g. ₱10 per transaction',
              ),
              const SizedBox(height: 12),
              _MarkupRow(
                label: 'Cash Out',
                icon: Icons.arrow_upward_rounded,
                color: AppColors.primary,
                hint: 'e.g. 1% of amount',
              ),
              const SizedBox(height: 12),
              _MarkupRow(
                label: 'Bills Payment',
                icon: Icons.receipt_outlined,
                color: const Color(0xFF9333EA),
                hint: 'e.g. ₱15 flat fee',
              ),
              const SizedBox(height: 12),
              _MarkupRow(
                label: 'Load / Others',
                icon: Icons.sim_card_outlined,
                color: AppColors.warning,
                hint: 'e.g. ₱5 per bracket',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can configure detailed rates after setup. Tap "Skip for now" to continue.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Save & Continue',
                onPressed: () => context.go(Routes.onboardingComplete),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go(Routes.onboardingComplete),
                child: const Text('Skip for now',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _MarkupRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String hint;

  const _MarkupRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
