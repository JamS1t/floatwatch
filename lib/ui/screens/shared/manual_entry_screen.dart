import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/markup_calculator.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/daily_float_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/primary_button.dart';

/// Manual transaction entry screen (owner and staff).
class ManualEntryScreen extends StatefulWidget {
  final String transactionType;

  const ManualEntryScreen({
    super.key,
    this.transactionType = AppConstants.txCashIn,
  });

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  late String _selectedType;
  late bool _isOwner;
  int? _previewMarkupCentavos;

  static const _types = [
    (AppConstants.txCashIn, 'Cash In', Icons.arrow_downward_rounded, AppColors.secondary),
    (AppConstants.txCashOut, 'Cash Out', Icons.arrow_upward_rounded, AppColors.primary),
    (AppConstants.txBillsPayment, 'Bills Payment', Icons.receipt_outlined, Color(0xFF9333EA)),
    (AppConstants.txLoadOthers, 'Load / Others', Icons.sim_card_outlined, AppColors.warning),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.transactionType;
    _isOwner = context.read<AuthProvider>().isOwnerLoggedIn;
    // Markup preview is owner-only — staff should not see markup rates.
    if (_isOwner) _amountCtrl.addListener(_updateMarkupPreview);
  }

  void _updateMarkupPreview() {
    final store = context.read<StoreProvider>();
    final markup = store.getMarkupForType(_selectedType);
    if (markup == null) {
      if (_previewMarkupCentavos != null) setState(() => _previewMarkupCentavos = null);
      return;
    }
    final centavos = CurrencyFormatter.parseToCentavos(_amountCtrl.text);
    if (centavos <= 0) {
      if (_previewMarkupCentavos != null) setState(() => _previewMarkupCentavos = null);
      return;
    }
    try {
      final earned = MarkupCalculator.calculate(
        amount: centavos,
        rateType: markup.rateType,
        rateValue: markup.rateValue,
        bracketSize: markup.bracketSize,
      );
      setState(() => _previewMarkupCentavos = earned);
    } catch (_) {
      setState(() => _previewMarkupCentavos = null);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<StoreProvider>();
    final float = context.read<DailyFloatProvider>();
    final txProv = context.read<TransactionProvider>();
    final auth = context.read<AuthProvider>();

    if (store.currentStore?.id == null || float.todayFloat?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set opening balance first.')),
      );
      return;
    }

    final markup = store.getMarkupForType(_selectedType);
    if (markup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No markup setting for this transaction type.')),
      );
      return;
    }

    final ok = await txProv.addTransaction(
      storeId: store.currentStore!.id!,
      dailyFloatId: float.todayFloat!.id!,
      transactionType: _selectedType,
      amountCentavos: CurrencyFormatter.parseToCentavos(_amountCtrl.text),
      markupSettings: markup,
      entryMethod: auth.isOwnerLoggedIn
          ? AppConstants.entryManualOwner
          : AppConstants.entryManualStaff,
      enteredByRole: auth.isOwnerLoggedIn ? AppConstants.roleOwner : AppConstants.roleStaff,
      enteredByStaffId: auth.currentStaff?.id,
      referenceNumber: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      context.go(Routes.transactionSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TransactionProvider>().isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Manual Entry')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction type selector
                  const Text('Transaction Type',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types.map((t) {
                      final (value, label, icon, color) = t;
                      final selected = _selectedType == value;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = value);
                          _updateMarkupPreview();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.15)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: selected ? color : AppColors.divider,
                                width: selected ? 2 : 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: selected ? color : AppColors.textSecondary, size: 16),
                              const SizedBox(width: 6),
                              Text(label,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected ? color : AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (₱)',
                      hintText: '0.00',
                      prefixText: '₱ ',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter amount.';
                      if (double.tryParse(v.replaceAll(',', '')) == null) {
                        return 'Enter a valid amount.';
                      }
                      return null;
                    },
                  ),
                  if (_isOwner && _previewMarkupCentavos != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_outlined,
                              color: AppColors.secondary, size: 18),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Markup Preview',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              Text(
                                CurrencyFormatter.format(
                                    _previewMarkupCentavos!),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reference Number (optional)',
                      hintText: 'GCash reference #',
                      prefixIcon: Icon(Icons.tag_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Save Transaction',
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
