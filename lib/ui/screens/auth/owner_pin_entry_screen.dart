import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/pin_pad.dart';

/// Owner PIN entry screen.
class OwnerPinEntryScreen extends StatefulWidget {
  const OwnerPinEntryScreen({super.key});

  @override
  State<OwnerPinEntryScreen> createState() => _OwnerPinEntryScreenState();
}

class _OwnerPinEntryScreenState extends State<OwnerPinEntryScreen> {
  String? _error;
  int? _ownerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOwner());
  }

  Future<void> _loadOwner() async {
    final owners = await context.read<AuthProvider>().getOwners();
    if (owners.isNotEmpty && mounted) {
      setState(() => _ownerId = owners.first.id);
    }
  }

  Future<void> _handlePin(String pin) async {
    if (_ownerId == null) return;
    final ok = await context.read<AuthProvider>().loginOwner(_ownerId!, pin);
    if (!mounted) return;
    if (ok) {
      context.go(Routes.ownerDashboard);
    } else {
      setState(
          () => _error = context.read<AuthProvider>().error ?? 'Incorrect PIN.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.roleSelection),
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
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your PIN',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter your 6-digit owner PIN to continue.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              PinPad(
                onComplete: _handlePin,
                errorMessage: _error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
