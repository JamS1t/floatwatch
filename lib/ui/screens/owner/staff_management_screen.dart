import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/staff_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../routes.dart';

/// Owner view of all staff members.
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<StaffModel> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final storeId = context.read<StoreProvider>().currentStore?.id;
    if (storeId == null) { setState(() => _loading = false); return; }
    final list = await context.read<AuthProvider>().getStaffForStore(storeId);
    if (mounted) setState(() { _staff = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push(Routes.addStaff).then((_) => _load()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
              ? _buildEmpty(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = _staff[i];
                    return ListTile(
                      tileColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.divider)),
                      leading: CircleAvatar(
                        backgroundColor: s.locked
                            ? AppColors.dangerLight
                            : AppColors.primaryLight,
                        child: Text(s.name[0].toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: s.locked
                                    ? AppColors.danger
                                    : AppColors.primary)),
                      ),
                      title: Text(s.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        s.locked ? 'Locked' : (s.active ? 'Active' : 'Inactive'),
                        style: TextStyle(
                            fontSize: 12,
                            color: s.locked
                                ? AppColors.danger
                                : AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                      onTap: () =>
                          context.push(Routes.staffDetail(s.id!)).then((_) => _load()),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('No staff yet.',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push(Routes.addStaff).then((_) => _load()),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add First Staff'),
          ),
        ],
      ),
    );
  }
}
