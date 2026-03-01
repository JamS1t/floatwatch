import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/primary_button.dart';

/// Set up the store profile during onboarding.
class CreateStoreProfileScreen extends StatefulWidget {
  const CreateStoreProfileScreen({super.key});

  @override
  State<CreateStoreProfileScreen> createState() =>
      _CreateStoreProfileScreenState();
}

class _CreateStoreProfileScreenState extends State<CreateStoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _outletNumberCtrl = TextEditingController();

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _locationCtrl.dispose();
    _outletNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ownerId = context.read<AuthProvider>().currentOwner?.id;
    if (ownerId == null) return;

    final ok = await context.read<StoreProvider>().createStore(
          ownerId: ownerId,
          storeName: _storeNameCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          gcashOutletNumber: _outletNumberCtrl.text.trim().isEmpty
              ? null
              : _outletNumberCtrl.text.trim(),
        );
    if (!mounted) return;
    if (ok) context.go(Routes.onboardingMarkupSettings);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<StoreProvider>().isLoading;
    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Store Profile')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your GCash Store',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your store details. You can change these later in Settings.',
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _storeNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Store Name',
                      hintText: 'e.g. Santos Sari-Sari Store',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your store name.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Location (optional)',
                      hintText: 'e.g. Barangay Maligaya, Caloocan',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _outletNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'GCash Outlet Number (optional)',
                      hintText: 'e.g. GPO-12345678',
                      prefixIcon: Icon(Icons.qr_code_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Continue',
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
