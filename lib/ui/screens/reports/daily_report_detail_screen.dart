import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/store_provider.dart';
import '../../widgets/common/status_badge.dart';

/// Detailed view of a single daily report.
class DailyReportDetailScreen extends StatefulWidget {
  final String date; // yyyy-MM-dd

  const DailyReportDetailScreen({super.key, required this.date});

  @override
  State<DailyReportDetailScreen> createState() =>
      _DailyReportDetailScreenState();
}

class _DailyReportDetailScreenState extends State<DailyReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = context.read<StoreProvider>();
    final report = context.read<ReportProvider>();
    if (store.currentStore?.id != null) {
      await report.loadReportByDate(store.currentStore!.id!, widget.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();
    final r = report.selectedReport;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          r != null
              ? DateFormatter.dbToDisplay(r.date)
              : 'Daily Report',
        ),
      ),
      body: report.isLoading
          ? const Center(child: CircularProgressIndicator())
          : r == null
              ? const Center(
                  child: Text('Report not found.',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Earnings header ──────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.secondary,
                              Color(0xFF128A3C)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Markup Earned',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(
                                  r.totalMarkupEarned),
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gross: ${CurrencyFormatter.format(r.totalGrossAmount)}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white70),
                            ),
                            if (r.status != null) ...[
                              const SizedBox(height: 10),
                              StatusBadge(status: r.status!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Transaction breakdown ──────────────────────────
                      _SectionLabel('Transaction Breakdown'),
                      _Card(children: [
                        _Row('Total Transactions',
                            '${r.totalTransactions}'),
                        _Row('Cash In',
                            '${r.totalCashInCount} transactions'),
                        _Row('Cash Out',
                            '${r.totalCashOutCount} transactions'),
                        _Row('Bills Payment',
                            '${r.totalBillsPaymentCount} transactions'),
                        _Row('Load / Others',
                            '${r.totalLoadOthersCount} transactions'),
                      ]),
                      const SizedBox(height: 12),

                      // ── Report metadata ────────────────────────────────
                      _SectionLabel('Report Info'),
                      _Card(children: [
                        _Row('Report Date',
                            DateFormatter.dbToDisplay(r.date)),
                        _Row('Closed By', r.closedBy ?? 'owner'),
                        _Row('Created',
                            DateFormatter.dbToDisplayDateTime(
                                r.createdAt)),
                        _Row('Report ID', '#${r.id}'),
                      ]),

                      if (r.notes != null && r.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SectionLabel('Notes'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(r.notes!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      );
}
