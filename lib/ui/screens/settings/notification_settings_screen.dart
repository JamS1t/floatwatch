import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Notification settings — toggle reminders and alerts.
/// TODO: Persist toggles via SharedPreferences or local DB settings table.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _endOfDayReminder = true;
  bool _discrepancyAlert = true;
  bool _staffActivityAlert = false;
  bool _weeklyDigest = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.notifications_outlined,
                  color: AppColors.warning, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Push notification delivery requires the app to be installed. Notification delivery is not guaranteed on all devices.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          _SectionHeader(label: 'Daily Reminders'),
          _NotifTile(
            icon: Icons.nightlight_outlined,
            label: 'End-of-Day Reminder',
            subtitle: 'Remind you to close the day at 9 PM',
            value: _endOfDayReminder,
            onChanged: (v) => setState(() => _endOfDayReminder = v),
          ),
          const SizedBox(height: 16),

          _SectionHeader(label: 'Alerts'),
          _NotifTile(
            icon: Icons.warning_amber_outlined,
            label: 'Discrepancy Alert',
            subtitle: 'Alert when GCash discrepancy is detected',
            value: _discrepancyAlert,
            onChanged: (v) => setState(() => _discrepancyAlert = v),
          ),
          const SizedBox(height: 4),
          _NotifTile(
            icon: Icons.person_outlined,
            label: 'Staff Activity',
            subtitle: 'Notify when staff enters transactions',
            value: _staffActivityAlert,
            onChanged: (v) => setState(() => _staffActivityAlert = v),
          ),
          const SizedBox(height: 16),

          _SectionHeader(label: 'Reports'),
          _NotifTile(
            icon: Icons.summarize_outlined,
            label: 'Weekly Digest',
            subtitle: 'Summary of the week every Sunday',
            value: _weeklyDigest,
            onChanged: (v) => setState(() => _weeklyDigest = v),
          ),
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

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: SwitchListTile(
          secondary: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          title: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          subtitle: Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          value: value,
          activeThumbColor: AppColors.primary,
          onChanged: onChanged,
        ),
      );
}
