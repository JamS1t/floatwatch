import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../routes.dart';

/// Main settings screen with links to all setting sub-screens.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Store info header ──────────────────────────────────────────
          if (store.currentStore != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
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
                    child: const Icon(Icons.store_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.currentStore!.storeName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        if (store.currentStore!.location != null)
                          Text(store.currentStore!.location!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Security section ───────────────────────────────────────────
          _SectionHeader(label: 'Security'),
          _SettingsTile(
            icon: Icons.shield_outlined,
            iconColor: AppColors.primary,
            label: 'Security Mode',
            subtitle: store.currentStore?.securityMode == 'strict'
                ? 'Strict — OTP required for manual entry'
                : 'Simple — no extra PIN required',
            onTap: () => context.push(Routes.securityModeSettings),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            iconColor: AppColors.primary,
            label: 'Change PIN',
            subtitle: 'Update your owner PIN',
            onTap: () => context.push(Routes.changePinScreen),
          ),
          const SizedBox(height: 16),

          // ── Markup section ─────────────────────────────────────────────
          _SectionHeader(label: 'Markup Settings'),
          _SettingsTile(
            icon: Icons.percent_outlined,
            iconColor: AppColors.secondary,
            label: 'Markup Configuration',
            subtitle: 'Edit rates for each transaction type',
            onTap: () => context.push(Routes.markupSettingsEdit),
          ),
          const SizedBox(height: 16),

          // ── Notifications section ──────────────────────────────────────
          _SectionHeader(label: 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.warning,
            label: 'Notification Settings',
            subtitle: 'Configure reminders and alerts',
            onTap: () => context.push(Routes.notificationSettings),
          ),
          const SizedBox(height: 16),

          // ── Subscription section ───────────────────────────────────────
          _SectionHeader(label: 'Subscription'),
          _SettingsTile(
            icon: Icons.workspace_premium_outlined,
            iconColor: const Color(0xFFF59E0B),
            label: 'FloatWatch Premium',
            subtitle: 'Free plan — unlock weekly/monthly reports, PDF export',
            onTap: () => context.push(Routes.subscriptionScreen),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('FREE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B))),
            ),
          ),
          const SizedBox(height: 16),

          // ── About section ──────────────────────────────────────────────
          _SectionHeader(label: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: AppColors.textSecondary,
            label: 'About FloatWatch',
            subtitle: 'Version, licenses, and more',
            onTap: () => context.push(Routes.aboutScreen),
          ),
          const SizedBox(height: 16),

          // ── Logout ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_outlined,
                  color: AppColors.danger, size: 20),
              title: const Text('Sign Out',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w600)),
              onTap: () {
                context.read<AuthProvider>().logout();
                context.go(Routes.roleSelection);
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          title: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          subtitle: Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          trailing: trailing ??
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
          onTap: onTap,
        ),
      );
}
