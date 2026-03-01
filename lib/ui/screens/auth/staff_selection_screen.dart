import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/staff_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../routes.dart';
import '../../widgets/common/loading_overlay.dart';

/// Staff selects their name from the list before entering PIN.
class StaffSelectionScreen extends StatefulWidget {
  const StaffSelectionScreen({super.key});

  @override
  State<StaffSelectionScreen> createState() => _StaffSelectionScreenState();
}

class _StaffSelectionScreenState extends State<StaffSelectionScreen> {
  List<StaffModel> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStaff());
  }

  Future<void> _loadStaff() async {
    final storeId = context.read<StoreProvider>().currentStore?.id;
    if (storeId == null) {
      setState(() => _loading = false);
      return;
    }
    final list = await context.read<AuthProvider>().getStaffForStore(storeId);
    if (mounted) setState(() { _staff = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Staff'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(Routes.roleSelection),
          ),
        ),
        body: SafeArea(
          child: _staff.isEmpty && !_loading
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staff.length,
                  itemBuilder: (_, i) => _StaffTile(
                    staff: _staff[i],
                    onTap: () => context.go(
                      Routes.staffPinEntry,
                      extra: {'staffId': _staff[i].id},
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_off_outlined,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('No staff found.',
              style:
                  TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          TextButton(
            onPressed: () => context.go(Routes.roleSelection),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onTap;

  const _StaffTile({required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = staff.locked;
    return ListTile(
      onTap: locked ? null : onTap,
      leading: CircleAvatar(
        backgroundColor:
            locked ? AppColors.dangerLight : AppColors.primaryLight,
        child: Text(
          staff.name[0].toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: locked ? AppColors.danger : AppColors.primary,
          ),
        ),
      ),
      title: Text(staff.name,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: locked ? AppColors.textSecondary : AppColors.textPrimary)),
      subtitle: locked
          ? const Text('Account locked',
              style: TextStyle(color: AppColors.danger, fontSize: 12))
          : null,
      trailing: locked
          ? const Icon(Icons.lock_rounded, color: AppColors.danger, size: 18)
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
