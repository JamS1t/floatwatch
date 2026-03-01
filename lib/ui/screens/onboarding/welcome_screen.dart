import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// First screen of onboarding — shown to new users.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to FloatWatch',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Track your GCash Partner Outlet transactions, monitor float balance, and know your income every day.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Feature highlights
              _FeatureRow(
                icon: Icons.receipt_long_outlined,
                label: 'Track Cash In, Cash Out, Bills & Load',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.trending_up_rounded,
                label: 'Auto-calculate your markup income',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.balance_outlined,
                label: 'Daily float balancing & discrepancy alerts',
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Get Started',
                onPressed: () => context.go(Routes.storeModeSelection),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(Routes.roleSelection),
                child: const Text(
                  'I already have an account',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
