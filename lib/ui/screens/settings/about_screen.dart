import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// About screen — app version, description, and links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // TODO: Pull from package_info_plus when added
  static const _version = '1.0.0';
  static const _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About FloatWatch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── App logo & name ──────────────────────────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1A44B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('FloatWatch',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Version $_version (Build $_buildNumber)',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text(
              'GCash Partner Outlet Transaction Tracker',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // ── Description ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Text(
                'FloatWatch helps GCash Partner Outlet (GPO) owners and staff track daily transactions, monitor GCash float balances, and compute markup earnings — all stored securely on-device.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),

            // ── Info tiles ───────────────────────────────────────────────
            _AboutTile(
              icon: Icons.storage_outlined,
              label: 'Local Storage',
              value: 'SQLite (sqflite)',
            ),
            const SizedBox(height: 4),
            _AboutTile(
              icon: Icons.cloud_outlined,
              label: 'Cloud Sync',
              value: 'Firebase (Premium — coming soon)',
            ),
            const SizedBox(height: 4),
            _AboutTile(
              icon: Icons.document_scanner_outlined,
              label: 'Receipt OCR',
              value: 'Google ML Kit',
            ),
            const SizedBox(height: 4),
            _AboutTile(
              icon: Icons.build_outlined,
              label: 'Built with',
              value: 'Flutter + Dart',
            ),
            const SizedBox(height: 24),

            // ── Legal ────────────────────────────────────────────────────
            const Text(
              '© 2026 FloatWatch. All rights reserved.\nThis app is not affiliated with GCash or Mynt.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      );
}
