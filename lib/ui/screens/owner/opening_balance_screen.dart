import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/daily_float_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/primary_button.dart';

/// Set the opening GCash and cash balances for today.
class OpeningBalanceScreen extends StatefulWidget {
  const OpeningBalanceScreen({super.key});

  @override
  State<OpeningBalanceScreen> createState() => _OpeningBalanceScreenState();
}

class _OpeningBalanceScreenState extends State<OpeningBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gcashCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();

  @override
  void dispose() {
    _gcashCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final floatProv = context.read<DailyFloatProvider>();
    final store = context.read<StoreProvider>();
    final auth = context.read<AuthProvider>();

    // Ensure today's float record exists
    if (!floatProv.hasTodayFloat) {
      await floatProv.openDay(store.currentStore!.id!);
    }
    await floatProv.setOpeningBalance(
      gcashBalance: CurrencyFormatter.parseToCentavos(_gcashCtrl.text),
      cashBalance: CurrencyFormatter.parseToCentavos(_cashCtrl.text),
      setBy: auth.isOwnerLoggedIn ? 'owner' : 'staff',
    );
    if (!mounted) return;
    // Navigate to the correct dashboard based on who set the opening balance.
    context.go(
        auth.isOwnerLoggedIn ? Routes.ownerDashboard : Routes.staffHome);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<DailyFloatProvider>().isLoading;
    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Opening Balance')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set Opening Balance',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text(
                      'Enter your starting GCash wallet balance and cash on hand for today.',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _gcashCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'GCash Opening Balance (₱)',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.phone_android_rounded),
                      prefixText: '₱ ',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter GCash balance.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cashCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cash Opening Balance (₱)',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.payments_outlined),
                      prefixText: '₱ ',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter cash balance.' : null,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Set Opening Balance',
                    onPressed: _submit,
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
