import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// Shown when a staff account is locked after too many failed PIN attempts.
class PinLockedScreen extends StatelessWidget {
  const PinLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.dangerLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppColors.danger, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Account Locked',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              const Text(
                'This account has been locked after too many failed PIN attempts.\n\nPlease contact the store owner to unlock your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Back to Login',
                onPressed: () => context.go(Routes.roleSelection),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
