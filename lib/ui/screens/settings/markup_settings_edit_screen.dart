import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/markup_settings_model.dart';
import '../../../providers/store_provider.dart';

/// Screen for editing markup rates for each GCash transaction type.
class MarkupSettingsEditScreen extends StatelessWidget {
  const MarkupSettingsEditScreen({super.key});

  static const _types = [
    AppConstants.txCashIn,
    AppConstants.txCashOut,
    AppConstants.txBillsPayment,
    AppConstants.txLoadOthers,
  ];

  static const _labels = {
    AppConstants.txCashIn: 'Cash In',
    AppConstants.txCashOut: 'Cash Out',
    AppConstants.txBillsPayment: 'Bills Payment',
    AppConstants.txLoadOthers: 'Load / Others',
  };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Markup Settings')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final type = _types[i];
          final setting = store.getMarkupForType(type);
          return _MarkupTypeTile(
            transactionType: type,
            label: _labels[type] ?? type,
            setting: setting,
          );
        },
      ),
    );
  }
}

class _MarkupTypeTile extends StatelessWidget {
  final String transactionType;
  final String label;
  final MarkupSettingsModel? setting;

  const _MarkupTypeTile({
    required this.transactionType,
    required this.label,
    required this.setting,
  });

  String _describeRate(MarkupSettingsModel s) {
    switch (s.rateType) {
      case AppConstants.markupPercentage:
        return '${(s.rateValue / 100).toStringAsFixed(2)}% of amount';
      case AppConstants.markupFixed:
        return '${CurrencyFormatter.format(s.rateValue)} flat fee';
      case AppConstants.markupPerBracket:
        final bracket = s.bracketSize != null
            ? CurrencyFormatter.format(s.bracketSize!)
            : '—';
        return '${CurrencyFormatter.format(s.rateValue)} per $bracket bracket';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.transactionTypeColor(transactionType)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.percent,
                      color:
                          AppColors.transactionTypeColor(transactionType),
                      size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                TextButton(
                  onPressed: () =>
                      _showEditDialog(context, setting),
                  child: const Text('Edit'),
                ),
              ],
            ),
            if (setting != null) ...[
              const SizedBox(height: 6),
              Text(_describeRate(setting!),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ] else
              const Text('Not configured',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontStyle: FontStyle.italic)),
          ],
        ),
      );

  void _showEditDialog(
      BuildContext context, MarkupSettingsModel? existing) {
    showDialog(
      context: context,
      builder: (ctx) => _MarkupEditDialog(
        transactionType: transactionType,
        existing: existing,
      ),
    );
  }
}

class _MarkupEditDialog extends StatefulWidget {
  final String transactionType;
  final MarkupSettingsModel? existing;

  const _MarkupEditDialog(
      {required this.transactionType, this.existing});

  @override
  State<_MarkupEditDialog> createState() => _MarkupEditDialogState();
}

class _MarkupEditDialogState extends State<_MarkupEditDialog> {
  late String _rateType;
  final _valueCtrl = TextEditingController();
  final _bracketCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rateType =
        widget.existing?.rateType ?? AppConstants.markupPercentage;
    if (widget.existing != null) {
      final s = widget.existing!;
      if (s.rateType == AppConstants.markupPercentage) {
        _valueCtrl.text =
            (s.rateValue / 100).toStringAsFixed(2);
      } else {
        _valueCtrl.text = CurrencyFormatter.toPesos(s.rateValue)
            .toStringAsFixed(2);
      }
      if (s.bracketSize != null) {
        _bracketCtrl.text = CurrencyFormatter.toPesos(s.bracketSize!)
            .toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _bracketCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<StoreProvider>();
    if (store.currentStore == null) return;

    setState(() => _isSaving = true);
    try {
      final rawValue = double.tryParse(
              _valueCtrl.text.replaceAll(',', '')) ??
          0;
      int rateValue;
      if (_rateType == AppConstants.markupPercentage) {
        rateValue = (rawValue * 100).round(); // percent × 100
      } else {
        rateValue =
            CurrencyFormatter.toCentavos(rawValue); // pesos to centavos
      }

      int? bracketSize;
      if (_rateType == AppConstants.markupPerBracket) {
        final rawBracket = double.tryParse(
                _bracketCtrl.text.replaceAll(',', '')) ??
            0;
        bracketSize = CurrencyFormatter.toCentavos(rawBracket);
      }

      final now = DateFormatter.nowDb();
      final setting = MarkupSettingsModel(
        id: widget.existing?.id,
        storeId: store.currentStore!.id!,
        transactionType: widget.transactionType,
        rateType: _rateType,
        rateValue: rateValue,
        bracketSize: bracketSize,
        effectiveDate: DateFormatter.todayDb(),
        createdAt: now,
        syncId: widget.existing?.syncId ?? const Uuid().v4(),
      );

      await store.saveMarkupSetting(setting);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Markup'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate Type',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _rateType,
              decoration:
                  const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: AppConstants.markupPercentage,
                    child: Text('Percentage')),
                DropdownMenuItem(
                    value: AppConstants.markupFixed,
                    child: Text('Fixed Amount')),
                DropdownMenuItem(
                    value: AppConstants.markupPerBracket,
                    child: Text('Per Bracket')),
              ],
              onChanged: (v) => setState(() => _rateType = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: InputDecoration(
                labelText: _rateType ==
                        AppConstants.markupPercentage
                    ? 'Rate (%)'
                    : 'Amount (₱)',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_rateType == AppConstants.markupPerBracket) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _bracketCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Bracket Size (₱)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
