import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/batch_item_analysis.dart';
import '../../../core/services/ocr_result.dart';
import '../../../core/services/receipt_parser.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/markup_calculator.dart';
import '../../../data/models/markup_settings_model.dart';
import '../../../data/repositories/interfaces/i_daily_float_repository.dart';
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
  late List<TextEditingController> _markupCtrls;
  late final int _initialAutoCount;
  final Set<int> _showingRawText = {};
  late final int _initialReviewCount;
  int _expandedIndex = -1;
  bool _isSaving = false;
  Set<int> _batchDuplicateIndices = {};
  // Per-card: true if the owner is actively editing the markup override.
  final Set<int> _markupEditing = {};
  late bool _isOwner;

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
    _markupCtrls = _items
        .map((r) => TextEditingController(
              text: r.markupOverrideCentavos != null
                  ? (r.markupOverrideCentavos! / 100).toStringAsFixed(2)
                  : '',
            ))
        .toList();
    _isOwner = context.read<AuthProvider>().isOwnerLoggedIn;
    _recomputeBatchDuplicates();
  }

  /// Recompute within-batch duplicate indices based on ref+amount+type.
  void _recomputeBatchDuplicates() {
    final seen = <String, int>{}; // key → first index
    final dupes = <int>{};
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final ref = item.referenceNumber;
      if (ref == null || ref.isEmpty || item.amountCentavos == null || item.transactionType == null) {
        continue;
      }
      final key = '$ref|${item.amountCentavos}|${item.transactionType}';
      if (seen.containsKey(key)) {
        dupes.add(seen[key]!);
        dupes.add(i);
      } else {
        seen[key] = i;
      }
    }
    _batchDuplicateIndices = dupes;
  }

  @override
  void dispose() {
    for (final c in _amountCtrls) {
      c.dispose();
    }
    for (final c in _refCtrls) {
      c.dispose();
    }
    for (final c in _markupCtrls) {
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

    // Markup override (owner-only). Only apply if the user has actively
    // engaged the override editor for this card.
    int? markupOverride = _items[index].markupOverrideCentavos;
    bool clearOverride = false;
    if (_isOwner && _markupEditing.contains(index)) {
      final markupText = _markupCtrls[index].text.replaceAll(',', '');
      final markupPesos = double.tryParse(markupText);
      if (markupPesos != null && markupPesos >= 0) {
        markupOverride = (markupPesos * 100).round();
      } else {
        clearOverride = true;
      }
    }

    setState(() {
      _items[index] = _items[index].copyWith(
        amountCentavos: centavos,
        referenceNumber: ref.isNotEmpty ? ref : null,
        markupOverrideCentavos: clearOverride ? null : markupOverride,
        clearMarkupOverride: clearOverride,
      );
      _recomputeBatchDuplicates();
    });
  }

  /// Returns the calculated markup for the item at [index] using the
  /// configured rule for its transaction type, or null if the rule or
  /// required fields are missing.
  int? _calculatedMarkupFor(int index) {
    final item = _items[index];
    if (item.transactionType == null || item.amountCentavos == null) return null;
    final store = context.read<StoreProvider>();
    final markup = store.getMarkupForType(item.transactionType!);
    if (markup == null) return null;
    try {
      return MarkupCalculator.calculate(
        amount: item.amountCentavos!,
        rateType: markup.rateType,
        rateValue: markup.rateValue,
        bracketSize: markup.bracketSize,
      );
    } catch (_) {
      return null;
    }
  }

  /// Begin editing the markup override for [index]. Pre-fills the input
  /// with the current override (if any) or the configured calculation.
  void _beginMarkupOverride(int index) {
    final current = _items[index].markupOverrideCentavos ??
        _calculatedMarkupFor(index);
    if (current == null) return;
    _markupCtrls[index].text = (current / 100).toStringAsFixed(2);
    setState(() => _markupEditing.add(index));
  }

  /// Reset the markup override on [index] back to the configured calculation.
  void _resetMarkupOverride(int index) {
    setState(() {
      _markupEditing.remove(index);
      _markupCtrls[index].clear();
      _items[index] = _items[index].copyWith(clearMarkupOverride: true);
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
      final floatRepo = context.read<IDailyFloatRepository>();

      final storeId = storeProvider.currentStore?.id;
      final dailyFloatId = floatProvider.todayFloat?.id;

      if (storeId == null || dailyFloatId == null) {
        _showError('No active store or day open. Please open a day first.');
        return;
      }

      final todayDate = DateFormatter.todayDb();

      // ── Pre-save analysis ─────────────────────────────────────────────
      final analysis = await txProvider.analyzeBatch(
        storeId: storeId,
        items: _items,
        todayDate: todayDate,
        floatRepo: floatRepo,
      );

      final issues = analysis
          .where((a) => a.status != BatchItemStatus.ready)
          .toList();

      if (!mounted) return;

      var skipIndices = <int>{};
      var dailyFloatOverrides = <int, int>{};
      var newlyCreatedFloatIds = <int>{};

      if (issues.isNotEmpty) {
        final resolution = await _showBatchIssueResolutionSheet(
          issues: issues,
          storeId: storeId,
          floatProvider: floatProvider,
        );
        if (resolution == null) {
          // User cancelled
          return;
        }
        skipIndices = resolution.skipIndices;
        dailyFloatOverrides = resolution.dailyFloatOverrides;
        newlyCreatedFloatIds = resolution.newlyCreatedFloatIds;
      }

      // ── Build markup map ──────────────────────────────────────────────
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
        skipIndices: skipIndices,
        dailyFloatOverrides: dailyFloatOverrides,
      );

      if (!mounted) return;

      // Auto-close any system-created floats (past dates with no prior history)
      if (saved > 0) {
        for (final floatId in newlyCreatedFloatIds) {
          await floatProvider.autoCloseFloat(floatId);
        }
      }

      if (!mounted) return;

      final skipped = skipIndices.length;
      final dupCount = issues.where((a) => a.status == BatchItemStatus.duplicate).length;

      if (skipped > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$saved saved, $skipped skipped${dupCount > 0 ? ' ($dupCount duplicates)' : ''}'),
            backgroundColor: saved > 0 ? AppColors.secondary : AppColors.warning,
          ),
        );
      }

      if (saved > 0) {
        context.go(Routes.transactionSuccess);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Shows a bottom sheet for resolving batch issues (duplicates, cross-date).
  /// Returns null if the user cancels.
  Future<_BatchResolution?> _showBatchIssueResolutionSheet({
    required List<BatchItemAnalysis> issues,
    required int storeId,
    required DailyFloatProvider floatProvider,
  }) async {
    // Per-issue action: 'skip', 'saveToDate', 'saveToToday', 'reopenAndSave'
    final actions = <int, String>{};
    for (final issue in issues) {
      if (issue.status == BatchItemStatus.duplicate) {
        actions[issue.index] = 'skip'; // default: skip duplicates
      } else {
        actions[issue.index] = 'saveToDate'; // default: save to receipt's date
      }
    }

    final result = await showModalBottomSheet<_BatchResolution>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Issues Found (${issues.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Review and choose how to handle each item.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollCtrl,
                          itemCount: issues.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, idx) {
                            final issue = issues[idx];
                            final item = _items[issue.index];
                            final action = actions[issue.index]!;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Item summary
                                  Row(
                                    children: [
                                      Text(
                                        'Receipt #${issue.index + 1}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (item.amountCentavos != null)
                                        Text(
                                          CurrencyFormatter.format(item.amountCentavos!),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Status label
                                  _issueStatusChip(issue),
                                  const SizedBox(height: 8),
                                  // Action options
                                  if (issue.status == BatchItemStatus.duplicate) ...[
                                    _radioTile(
                                      label: 'Skip (recommended)',
                                      selected: action == 'skip',
                                      onTap: () => setSheetState(() => actions[issue.index] = 'skip'),
                                    ),
                                    _radioTile(
                                      label: 'Save anyway',
                                      selected: action == 'saveAnyway',
                                      onTap: () => setSheetState(() => actions[issue.index] = 'saveAnyway'),
                                    ),
                                  ] else ...[
                                    // Cross-date options
                                    _radioTile(
                                      label: 'Save to ${issue.receiptDate ?? "receipt date"}',
                                      selected: action == 'saveToDate',
                                      onTap: () => setSheetState(() => actions[issue.index] = 'saveToDate'),
                                    ),
                                    _radioTile(
                                      label: 'Save to today instead',
                                      selected: action == 'saveToToday',
                                      onTap: () => setSheetState(() => actions[issue.index] = 'saveToToday'),
                                    ),
                                    if (issue.status == BatchItemStatus.crossDateClosed)
                                      _radioTile(
                                        label: 'Reopen ${issue.receiptDate} & save',
                                        subtitle: 'This will reopen a closed day',
                                        selected: action == 'reopenAndSave',
                                        onTap: () => setSheetState(() => actions[issue.index] = 'reopenAndSave'),
                                      ),
                                    _radioTile(
                                      label: 'Skip',
                                      selected: action == 'skip',
                                      onTap: () => setSheetState(() => actions[issue.index] = 'skip'),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetCtx),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final skip = <int>{};
                                final floatOverrides = <int, int>{};
                                final newlyCreated = <int>{};

                                for (final issue in issues) {
                                  final act = actions[issue.index]!;
                                  if (act == 'skip') {
                                    skip.add(issue.index);
                                  } else if (act == 'saveToDate' || act == 'reopenAndSave') {
                                    if (act == 'reopenAndSave') {
                                      final targetFloat = await floatProvider
                                          .getFloatByDate(storeId, issue.receiptDate!);
                                      if (targetFloat?.id != null) {
                                        await floatProvider.reopenDayById(targetFloat!.id!);
                                      }
                                    } else {
                                      // saveToDate: check if float exists before creating
                                      final existing = await floatProvider
                                          .getFloatByDate(storeId, issue.receiptDate!);
                                      final created = await floatProvider
                                          .getOrCreateFloatForDate(storeId, issue.receiptDate!);
                                      floatOverrides[issue.index] = created.id!;
                                      if (existing == null) {
                                        newlyCreated.add(created.id!);
                                      }
                                      continue;
                                    }
                                    final targetFloat = await floatProvider
                                        .getOrCreateFloatForDate(storeId, issue.receiptDate!);
                                    floatOverrides[issue.index] = targetFloat.id!;
                                  }
                                  // 'saveToToday' and 'saveAnyway' — no override needed, uses default dailyFloatId
                                }

                                if (sheetCtx.mounted) {
                                  Navigator.pop(
                                    sheetCtx,
                                    _BatchResolution(
                                      skipIndices: skip,
                                      dailyFloatOverrides: floatOverrides,
                                      newlyCreatedFloatIds: newlyCreated,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Confirm & Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    return result;
  }

  Widget _issueStatusChip(BatchItemAnalysis issue) {
    final String label;
    final Color color;
    switch (issue.status) {
      case BatchItemStatus.duplicate:
        label = 'Already exists in database';
        color = Colors.orange;
      case BatchItemStatus.crossDate:
        label = 'Different date: ${issue.receiptDate}';
        color = AppColors.primary;
      case BatchItemStatus.crossDateClosed:
        label = 'Closed day: ${issue.receiptDate}';
        color = AppColors.danger;
      case BatchItemStatus.ready:
        label = 'Ready';
        color = AppColors.secondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _radioTile({
    required String label,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.warning),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                // Confidence badge + batch dupe chip
                Row(
                  children: [
                    _ConfidenceBadge(confidence: item.confidence),
                    if (_batchDuplicateIndices.contains(i)) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Possible duplicate',
                          style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    if (_isOwner && item.markupOverrideCentavos != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Markup overridden',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
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

          // Markup earned (owner-only)
          if (_isOwner) ...[
            _buildMarkupSection(i, item),
            const SizedBox(height: 12),
          ],

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

  Widget _buildMarkupSection(int i, OcrResult item) {
    final calculated = _calculatedMarkupFor(i);
    final override = item.markupOverrideCentavos;
    final isEditing = _markupEditing.contains(i);
    final hasOverride = override != null;

    // No configured markup rule (or missing amount/type) — nothing to show.
    if (calculated == null && !hasOverride) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: hasOverride
            ? AppColors.secondaryLight
            : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasOverride
              ? AppColors.secondary.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  size: 14, color: AppColors.secondary),
              const SizedBox(width: 6),
              const Text(
                'Markup Earned',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (!isEditing && !hasOverride)
                GestureDetector(
                  onTap: () => _beginMarkupOverride(i),
                  child: const Text(
                    'Override',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              if (isEditing || hasOverride)
                GestureDetector(
                  onTap: () => _resetMarkupOverride(i),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (isEditing) ...[
            TextField(
              controller: _markupCtrls[i],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₱ ',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                final pesos = double.tryParse(text.replaceAll(',', ''));
                final cents = pesos != null && pesos >= 0
                    ? (pesos * 100).round()
                    : null;
                setState(() {
                  _items[i] = _items[i].copyWith(
                    markupOverrideCentavos: cents,
                    clearMarkupOverride: cents == null,
                  );
                });
              },
            ),
            if (calculated != null) ...[
              const SizedBox(height: 6),
              Text(
                'Configured: ${CurrencyFormatter.format(calculated)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ] else ...[
            Text(
              CurrencyFormatter.format(override ?? calculated!),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: hasOverride
                    ? AppColors.secondary
                    : AppColors.textPrimary,
              ),
            ),
            if (hasOverride && calculated != null)
              Text(
                'Configured: ${CurrencyFormatter.format(calculated)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint),
              ),
          ],
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

/// Internal result from the batch issue resolution sheet.
class _BatchResolution {
  final Set<int> skipIndices;
  final Map<int, int> dailyFloatOverrides;
  final Set<int> newlyCreatedFloatIds;

  const _BatchResolution({
    required this.skipIndices,
    required this.dailyFloatOverrides,
    required this.newlyCreatedFloatIds,
  });
}

