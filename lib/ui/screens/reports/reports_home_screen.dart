import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/premium_lock_widget.dart';
import '../../widgets/common/status_badge.dart';

/// Reports home screen — list of daily reports, with premium weekly/monthly.
class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({super.key});

  @override
  State<ReportsHomeScreen> createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = context.read<StoreProvider>();
    final report = context.read<ReportProvider>();
    if (store.currentStore?.id != null) {
      await report.loadRecentReports(store.currentStore!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Premium report types ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: PremiumLockWidget(
                      isPremium: false,
                      featureName: 'Weekly Reports',
                      child: _ReportTypeCard(
                        icon: Icons.calendar_view_week_outlined,
                        label: 'Weekly',
                        onTap: () => context.push(Routes.weeklyReport),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumLockWidget(
                      isPremium: false,
                      featureName: 'Monthly Reports',
                      child: _ReportTypeCard(
                        icon: Icons.calendar_month_outlined,
                        label: 'Monthly',
                        onTap: () => context.push(Routes.monthlyReport),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Daily reports list ────────────────────────────────────
              const Text('Daily Reports',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              if (report.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (report.reports.isEmpty)
                _EmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: report.reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = report.reports[i];
                    return GestureDetector(
                      onTap: () =>
                          context.push(Routes.dailyReport(r.date)),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.primary,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatter.dbToDisplay(r.date),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r.totalTransactions} txns · ${CurrencyFormatter.format(r.totalGrossAmount)} gross',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(
                                      r.totalMarkupEarned),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary),
                                ),
                                const SizedBox(height: 2),
                                if (r.status != null)
                                  StatusBadge(
                                      status: r.status!, compact: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReportTypeCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.bar_chart_outlined,
                  size: 48, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text('No reports yet.',
                  style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text('Reports are created when you close the day.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}
