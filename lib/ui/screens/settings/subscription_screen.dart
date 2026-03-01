import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

/// Subscription / upgrade screen — shows premium features and upgrade CTA.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const _features = [
    _PremiumFeature(
      icon: Icons.calendar_view_week_outlined,
      title: 'Weekly Reports',
      desc: 'See your 7-day earnings trend at a glance.',
    ),
    _PremiumFeature(
      icon: Icons.calendar_month_outlined,
      title: 'Monthly Reports',
      desc: 'Full month breakdown with markup income summary.',
    ),
    _PremiumFeature(
      icon: Icons.picture_as_pdf_outlined,
      title: 'PDF Export',
      desc: 'Export daily reports as PDF to share or print.',
    ),
    _PremiumFeature(
      icon: Icons.camera_alt_outlined,
      title: 'Unlimited Batch Upload',
      desc: 'Upload unlimited receipts per day (free: 10/day).',
    ),
    _PremiumFeature(
      icon: Icons.cloud_sync_outlined,
      title: 'Cloud Sync',
      desc: 'Sync data across devices and protect from data loss.',
    ),
    _PremiumFeature(
      icon: Icons.storefront_outlined,
      title: 'Multiple Stores',
      desc: 'Manage more than one GCash outlet from one account.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FloatWatch Premium')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero banner ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4FD8), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('FloatWatch Premium',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text(
                    'Unlock all features and grow your GCash business faster.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // ── Current plan chip ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Current plan:',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('FREE',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),

            // ── Premium features ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Premium Features',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _features.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final f = _features[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.icon,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.title,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text(f.desc,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.lock_outline,
                          color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── CTA ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement in-app purchase or redirect
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Premium upgrade coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Upgrade to Premium',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Maybe later',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeature {
  final IconData icon;
  final String title;
  final String desc;
  const _PremiumFeature(
      {required this.icon, required this.title, required this.desc});
}
