import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes.dart';
import '../../widgets/common/primary_button.dart';

/// Select store mode: solo owner or owner with staff.
class StoreModeSelectionScreen extends StatefulWidget {
  const StoreModeSelectionScreen({super.key});

  @override
  State<StoreModeSelectionScreen> createState() =>
      _StoreModeSelectionScreenState();
}

class _StoreModeSelectionScreenState extends State<StoreModeSelectionScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Setup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How do you manage your store?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This determines how FloatWatch sets up security and staff features.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              _ModeCard(
                selected: _selected == AppConstants.storeModeSolo,
                icon: Icons.person_rounded,
                title: 'Solo Owner',
                subtitle:
                    'I run the store myself. Simple setup with no staff management.',
                onTap: () =>
                    setState(() => _selected = AppConstants.storeModeSolo),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                selected: _selected == AppConstants.storeModeWithStaff,
                icon: Icons.group_rounded,
                title: 'Owner with Staff',
                subtitle:
                    'I have staff who handle transactions. Includes staff PIN login and activity tracking.',
                onTap: () => setState(
                    () => _selected = AppConstants.storeModeWithStaff),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onPressed: _selected == null
                    ? null
                    : () => context.go(
                          Routes.createOwnerAccount,
                          extra: {'storeMode': _selected},
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
