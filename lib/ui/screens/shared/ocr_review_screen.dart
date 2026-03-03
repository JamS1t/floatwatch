import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ocr_result.dart';
import '../../../core/services/receipt_parser.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/markup_settings_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/daily_float_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../core/services/receipt_storage_service.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// Full batch review screen. Receives [List<OcrResult>] via GoRouter extra.
/// Shows editable cards sorted chronologically. Saves on confirmation.
class OcrReviewScreen extends StatefulWidget {
  final List<OcrResult> results;

  const OcrReviewScreen({super.key, required this.results});

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  late List<OcrResult> _items;
  late List<TextEditingController> _amountCtrls;
  late List<TextEditingController> _refCtrls;
  late final int _initialAutoCount;
  final Set<int> _showingRawText = {};
  late final int _initialReviewCount;
  int _expandedIndex = -1;
  bool _isSaving = false;

  static const _typeLabels = {
    AppConstants.txCashIn: 'Cash In',
    AppConstants.txCashOut: 'Cash Out',
    AppConstants.txBillsPayment: 'Bills Payment',
    AppConstants.txLoadOthers: 'Load/Others',
  };

  static const _typeIcons = {
    AppConstants.txCashIn: Icons.arrow_downward_rounded,
    AppConstants.txCashOut: Icons.arrow_upward_rounded,
    AppConstants.txBillsPayment: Icons.receipt_long_outlined,
    AppConstants.txLoadOthers: Icons.sim_card_outlined,
  };

  @override
  void initState() {
    super.initState();
    _items = ReceiptParser.sortChronologically(widget.results);
    _initialAutoCount = _items.where((r) => !r.needsManualReview).length;
    _initialReviewCount = _items.where((r) => r.needsManualReview).length;
    _amountCtrls = _items
        .map((r) => TextEditingController(
              text: r.amountCentavos != null
                  ? (r.amountCentavos! / 100).toStringAsFixed(2)
                  : '',
            ))
        .toList();
    _refCtrls = _items
        .map((r) => TextEditingController(text: r.referenceNumber ?? ''))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _amountCtrls) {
      c.dispose();
    }
    for (final c in _refCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isResolved(int i) {
    final item = _items[i];
    return item.transactionType != null &&
        item.amountCentavos != null &&
        item.transactionDateTime != null;
  }

  bool get _allResolved =>
      List.generate(_items.length, (i) => i).every(_isResolved);

  /// Apply text controller values back to the item at [index].
  void _applyEdits(int index) {
    final amountText = _amountCtrls[index].text.replaceAll(',', '');
    final pesos = double.tryParse(amountText);
    final centavos = pesos != null && pesos > 0
        ? (pesos * 100).round()
        : _items[index].amountCentavos;
    final ref = _refCtrls[index].text.trim();

    setState(() {
      _items[index] = _items[index].copyWith(
        amountCentavos: centavos,
        referenceNumber: ref.isNotEmpty ? ref : null,
      );
    });
  }

  void _toggleExpand(int index) {
    if (_expandedIndex == index) {
      _applyEdits(index);
      setState(() => _expandedIndex = -1);
    } else {
      if (_expandedIndex >= 0) _applyEdits(_expandedIndex);
      setState(() => _expandedIndex = index);
    }
  }

  Future<void> _pickDateTime(int index) async {
    final current = _items[index].transactionDateTime ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    setState(() {
      _items[index] = _items[index].copyWith(
        transactionDateTime: DateTime(
            date.year, date.month, date.day, time.hour, time.minute),
      );
    });
  }

  Future<void> _confirmAndSave() async {
    // Apply any in-progress edits
    if (_expandedIndex >= 0) _applyEdits(_expandedIndex);

    setState(() => _isSaving = true);

    try {
      final txProvider = context.read<TransactionProvider>();
      final storeProvider = context.read<StoreProvider>();
      final floatProvider = context.read<DailyFloatProvider>();
      final authProvider = context.read<AuthProvider>();
      final receiptStorage = context.read<ReceiptStorageService>();

      final storeId = storeProvider.currentStore?.id;
      final dailyFloatId = floatProvider.todayFloat?.id;

      if (storeId == null || dailyFloatId == null) {
        _showError('No active store or day open. Please open a day first.');
        return;
      }

      final markupByType = <String, MarkupSettingsModel>{};
      for (final type in AppConstants.transactionTypes) {
        final m = storeProvider.getMarkupForType(type);
        if (m != null) markupByType[type] = m;
      }

      final enteredByRole = authProvider.isOwnerLoggedIn ? 'owner' : 'staff';
      final staffId = authProvider.currentOwner == null
          ? null
          : null; // staff ID not in scope here

      final saved = await txProvider.addBatchTransactions(
        storeId: storeId,
        dailyFloatId: dailyFloatId,
        results: _items,
        markupByType: markupByType,
        enteredByRole: enteredByRole,
        receiptStorage: receiptStorage,
        enteredByStaffId: staffId,
      );

      if (!mounted) return;

      if (saved == _items.length) {
        context.go(Routes.transactionSuccess);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$saved of ${_items.length} transactions saved.'),
            backgroundColor: AppColors.warning,
          ),
        );
        if (saved > 0) context.go(Routes.transactionSuccess);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Receipts (${_items.length})'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryBanner(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _buildReceiptCard(i),
              ),
            ),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _initialReviewCount > 0
          ? AppColors.warningLight
          : AppColors.secondaryLight,
      child: Row(
        children: [
          Icon(
            _initialReviewCount > 0
                ? Icons.info_outline
                : Icons.check_circle_outline,
            size: 16,
            color: _initialReviewCount > 0
                ? AppColors.warning
                : AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            _initialReviewCount > 0
                ? '$_initialAutoCount auto-classified • $_initialReviewCount need review'
                : 'All $_initialAutoCount receipts auto-classified',
            style: TextStyle(
              fontSize: 13,
              color: _initialReviewCount > 0
                  ? AppColors.textPrimary
                  : AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(int i) {
    final item = _items[i];
    final isExpanded = _expandedIndex == i;
    final resolved = _isResolved(i);
    final showWarning = item.needsManualReview && !resolved;

    return GestureDetector(
      onTap: () => _toggleExpand(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: showWarning
                ? AppColors.warning
                : isExpanded
                    ? AppColors.primary
                    : AppColors.divider,
            width: isExpanded || showWarning ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(i, item, showWarning),
            if (showWarning) _buildWarningRow(i, item.reviewReason),
            if (isExpanded) _buildEditableFields(i, item),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(int i, OcrResult item, bool showWarning) {
    final typeColor = item.transactionType != null
        ? AppColors.transactionTypeColor(item.transactionType!)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: item.imagePath.isNotEmpty
                ? Image.file(
                    File(item.imagePath),
                    width: 52,
                    height: 68,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 52,
                    height: 68,
                    color: AppColors.divider,
                    child: const Icon(Icons.receipt_long,
                        color: AppColors.textHint),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type chip + amount
                Row(
                  children: [
                    _TypeChip(
                      label: item.transactionType != null
                          ? _typeLabels[item.transactionType!]!
                          : 'Unknown',
                      color: typeColor,
                      icon: item.transactionType != null
                          ? _typeIcons[item.transactionType!]!
                          : Icons.help_outline,
                    ),
                    const Spacer(),
                    Text(
                      item.amountCentavos != null
                          ? CurrencyFormatter.format(item.amountCentavos!)
                          : '—',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Date/time
                Text(
                  item.transactionDateTime != null
                      ? '${DateFormatter.toDisplay(item.transactionDateTime!)} • ${DateFormatter.toTime(item.transactionDateTime!)}'
                      : 'No date — tap to set',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.transactionDateTime != null
                        ? AppColors.textSecondary
                        : AppColors.warning,
                  ),
                ),
                if (item.referenceNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ref: ${item.referenceNumber}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                // Confidence badge
                _ConfidenceBadge(confidence: item.confidence),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            _expandedIndex == i
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: 20,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningRow(int i, String? reason) {
    final showRaw = _showingRawText.contains(i);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reason ?? 'Needs manual review',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  if (showRaw) {
                    _showingRawText.remove(i);
                  } else {
                    _showingRawText.add(i);
                  }
                }),
                child: Text(
                  showRaw ? 'Hide OCR' : 'View OCR',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (showRaw)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Raw OCR Text:',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  _items[i].rawText.isEmpty
                      ? '(no text extracted)'
                      : _items[i].rawText,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEditableFields(int i, OcrResult item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Transaction type
          const _FieldLabel('Transaction Type'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AppConstants.transactionTypes.map((type) {
              final selected = item.transactionType == type;
              final color = AppColors.transactionTypeColor(type);
              return GestureDetector(
                onTap: () => setState(() {
                  _items[i] = _items[i].copyWith(transactionType: type);
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? color : AppColors.divider,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    _typeLabels[type]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Amount
          const _FieldLabel('Amount (₱)'),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrls[i],
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: '₱ ',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Date & Time
          const _FieldLabel('Date & Time'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _pickDateTime(i),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.transactionDateTime != null
                          ? '${DateFormatter.toDisplay(item.transactionDateTime!)}  ${DateFormatter.toTime(item.transactionDateTime!)}'
                          : 'Tap to set date & time',
                      style: TextStyle(
                        fontSize: 14,
                        color: item.transactionDateTime != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Reference number (optional)
          const _FieldLabel('Reference No. (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _refCtrls[i],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 1234567890123',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_allResolved)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${List.generate(_items.length, (i) => i).where((i) => !_isResolved(i)).length} receipt(s) still need type, amount, and date.',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          PrimaryButton(
            label: _isSaving
                ? 'Saving...'
                : 'Confirm & Save All (${_items.length})',
            onPressed: (_allResolved && !_isSaving) ? _confirmAndSave : null,
            leadingIcon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _TypeChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final Color color;
    if (confidence >= 0.8) {
      color = AppColors.statusGreen;
    } else if (confidence >= 0.6) {
      color = AppColors.statusYellow;
    } else {
      color = AppColors.statusRed;
    }
    return Text(
      '$pct% confidence',
      style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary));
  }
}

