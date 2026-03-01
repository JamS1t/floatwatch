import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// Screen for entering closing GCash and cash balances at end of day.
class EndOfDayBalanceEntryScreen extends StatefulWidget {
  const EndOfDayBalanceEntryScreen({super.key});

  @override
  State<EndOfDayBalanceEntryScreen> createState() =>
      _EndOfDayBalanceEntryScreenState();
}

class _EndOfDayBalanceEntryScreenState
    extends State<EndOfDayBalanceEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gcashCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();

  @override
  void dispose() {
    _gcashCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;

    final gcash =
        CurrencyFormatter.parseToCentavos(_gcashCtrl.text);
    final cash =
        CurrencyFormatter.parseToCentavos(_cashCtrl.text);

    context.push(
      Routes.endOfDaySummary,
      extra: {
        'closingGcash': gcash,
        'closingCash': cash,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Closing Balances')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Count your physical cash and check your GCash app balance before entering here.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),
                const Text('GCash Wallet',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _gcashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Closing GCash Balance',
                    prefixText: '₱ ',
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter GCash balance.';
                    }
                    if (double.tryParse(v.replaceAll(',', '')) == null) {
                      return 'Enter a valid amount.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text('Cash on Hand',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cashCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Closing Cash Balance',
                    prefixText: '₱ ',
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter cash balance.';
                    }
                    if (double.tryParse(v.replaceAll(',', '')) == null) {
                      return 'Enter a valid amount.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                PrimaryButton(
                  label: 'Preview Day Summary',
                  onPressed: _proceed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
