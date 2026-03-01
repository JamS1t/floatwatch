import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/security_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/pin_pad.dart';
import '../../widgets/common/primary_button.dart';

/// Staff must enter an owner-generated one-time PIN before manual entry.
/// Only shown in strict security mode.
class ManualEntryPinRequestScreen extends StatefulWidget {
  const ManualEntryPinRequestScreen({super.key});

  @override
  State<ManualEntryPinRequestScreen> createState() =>
      _ManualEntryPinRequestScreenState();
}

class _ManualEntryPinRequestScreenState
    extends State<ManualEntryPinRequestScreen> {
  String? _error;

  Future<void> _handleOtp(String pin) async {
    final staffId = context.read<AuthProvider>().currentStaff?.id;
    final security = context.read<SecurityService>();

    if (staffId == null) return;

    final valid = await security.validateOneTimePin(
        pin, staffId, AppConstants.otpPurposeManualEntry);
    if (!mounted) return;

    if (valid) {
      context.go(Routes.manualEntry, extra: {'transactionType': 'cash_in'});
    } else {
      setState(() => _error = 'Invalid or expired PIN. Ask the owner for a new one.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter One-Time PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.shield_outlined, color: AppColors.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This store requires a one-time PIN from the owner to enter transactions manually.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
              const Text('Enter One-Time PIN',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Ask your store owner for a 6-digit one-time PIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              PinPad(onComplete: _handleOtp, errorMessage: _error),
            ],
          ),
        ),
      ),
    );
  }
}
