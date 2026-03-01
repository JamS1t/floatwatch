import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/store_provider.dart';
import '../../widgets/common/primary_button.dart';

/// Screen to switch between Simple and Strict security modes.
class SecurityModeSettingsScreen extends StatefulWidget {
  const SecurityModeSettingsScreen({super.key});

  @override
  State<SecurityModeSettingsScreen> createState() =>
      _SecurityModeSettingsScreenState();
}

class _SecurityModeSettingsScreenState
    extends State<SecurityModeSettingsScreen> {
  late String _selectedMode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMode =
        context.read<StoreProvider>().currentStore?.securityMode ??
            'simple';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final success = await context
        .read<StoreProvider>()
        .updateSecurityMode(_selectedMode);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(success
                ? 'Security mode updated.'
                : 'Failed to update. Try again.')),
      );
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Mode')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose how staff access is controlled in your store.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // ── Simple mode ──────────────────────────────────────────────
            _ModeCard(
              title: 'Simple',
              subtitle:
                  'Staff can enter transactions without extra verification.',
              icon: Icons.lock_open_outlined,
              iconColor: AppColors.secondary,
              selected: _selectedMode == 'simple',
              onTap: () => setState(() => _selectedMode = 'simple'),
              bullets: const [
                'No PIN required for manual entry',
                'Staff login with their own PIN',
                'Recommended for trusted staff',
              ],
            ),
            const SizedBox(height: 12),

            // ── Strict mode ──────────────────────────────────────────────
            _ModeCard(
              title: 'Strict',
              subtitle:
                  'Staff must enter a one-time PIN from you to record transactions.',
              icon: Icons.security_outlined,
              iconColor: AppColors.primary,
              selected: _selectedMode == 'strict',
              onTap: () => setState(() => _selectedMode = 'strict'),
              bullets: const [
                'Owner generates one-time PINs',
                'Each PIN is used for one transaction entry',
                'Recommended for high-risk environments',
              ],
            ),
            const Spacer(),

            PrimaryButton(
              label: 'Save',
              onPressed: _save,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;
  final List<String> bullets;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? iconColor.withValues(alpha: 0.06)
                : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? iconColor : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const Spacer(),
                        if (selected)
                          Icon(Icons.check_circle,
                              color: iconColor, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    ...bullets.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle,
                                  size: 5,
                                  color: iconColor
                                      .withValues(alpha: 0.6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(b,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
