import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/primary_button.dart';

/// Collect owner name, mobile number, and set a 6-digit PIN.
class CreateOwnerAccountScreen extends StatefulWidget {
  const CreateOwnerAccountScreen({super.key});

  @override
  State<CreateOwnerAccountScreen> createState() =>
      _CreateOwnerAccountScreenState();
}

class _CreateOwnerAccountScreenState extends State<CreateOwnerAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _gcashCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _gcashSameAsMobile = false;

  String get _storeMode {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    return extra?['storeMode'] as String? ?? AppConstants.storeModeSolo;
  }

  @override
  void initState() {
    super.initState();
    _mobileCtrl.addListener(_syncGcashIfMirrored);
  }

  void _syncGcashIfMirrored() {
    if (_gcashSameAsMobile && _gcashCtrl.text != _mobileCtrl.text) {
      _gcashCtrl.text = _mobileCtrl.text;
    }
  }

  void _toggleGcashSameAsMobile(bool? checked) {
    final next = checked ?? false;
    setState(() {
      _gcashSameAsMobile = next;
      if (next) {
        _gcashCtrl.text = _mobileCtrl.text;
      } else {
        _gcashCtrl.clear();
      }
    });
  }

  @override
  void dispose() {
    _mobileCtrl.removeListener(_syncGcashIfMirrored);
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _gcashCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.createOwner(
      name: _nameCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      gcashNumber: _gcashCtrl.text.trim(),
      pin: _pinCtrl.text,
      storeMode: _storeMode,
    );
    if (!mounted) return;
    if (ok) {
      context.go(Routes.createStoreProfile);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Error creating account.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Account')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Account',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Set up your owner account. Your PIN keeps the app secure.',
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Maria Santos',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter your name.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      hintText: '09XXXXXXXXX',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter your mobile number.';
                      }
                      if (!RegExp(r'^09\d{9}$').hasMatch(v.trim())) {
                        return 'Enter a valid PH mobile number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _toggleGcashSameAsMobile(!_gcashSameAsMobile),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _gcashSameAsMobile,
                              onChanged: _toggleGcashSameAsMobile,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'GCash number is the same as Mobile Number',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _gcashCtrl,
                    keyboardType: TextInputType.phone,
                    enabled: !_gcashSameAsMobile,
                    decoration: const InputDecoration(
                      labelText: 'GCash Number *',
                      hintText: '09XXXXXXXXX',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      helperText:
                          'Used to identify your transactions from receipts.',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'GCash number is required.';
                      }
                      if (!RegExp(r'^09\d{9}$').hasMatch(v.trim())) {
                        return 'Enter a valid PH GCash number (09XXXXXXXXX).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pinCtrl,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    maxLength: AppConstants.pinLength,
                    decoration: InputDecoration(
                      labelText: '6-Digit PIN',
                      hintText: '••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePin
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length != AppConstants.pinLength) {
                        return 'PIN must be exactly 6 digits.';
                      }
                      if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                        return 'PIN must contain only numbers.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPinCtrl,
                    obscureText: _obscureConfirm,
                    keyboardType: TextInputType.number,
                    maxLength: AppConstants.pinLength,
                    decoration: InputDecoration(
                      labelText: 'Confirm PIN',
                      hintText: '••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != _pinCtrl.text) return 'PINs do not match.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Create Account',
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
