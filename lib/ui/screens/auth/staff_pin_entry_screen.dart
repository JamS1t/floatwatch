import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/pin_pad.dart';

/// Staff enters their PIN after being selected.
class StaffPinEntryScreen extends StatefulWidget {
  final int staffId;

  const StaffPinEntryScreen({super.key, required this.staffId});

  @override
  State<StaffPinEntryScreen> createState() => _StaffPinEntryScreenState();
}

class _StaffPinEntryScreenState extends State<StaffPinEntryScreen> {
  String? _error;

  Future<void> _handlePin(String pin) async {
    final ok = await context.read<AuthProvider>().loginStaff(widget.staffId, pin);
    if (!mounted) return;
    if (ok) {
      context.go(Routes.staffHome);
    } else {
      final auth = context.read<AuthProvider>();
      final errMsg = auth.error ?? 'Incorrect PIN.';
      // Check if locked after this attempt
      if (errMsg.toLowerCase().contains('locked')) {
        context.go(Routes.pinLocked);
      } else {
        setState(() => _error = errMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.staffSelection),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.badge_outlined,
                    color: AppColors.secondary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Enter your PIN',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Enter your 6-digit staff PIN to continue.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              PinPad(onComplete: _handlePin, errorMessage: _error),
            ],
          ),
        ),
      ),
    );
  }
}
