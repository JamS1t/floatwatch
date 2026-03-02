import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Flat quick action button — designed to sit inside a section card container.
/// No outer card/border on individual items; the parent container provides the
/// visual grouping.
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool badge;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primaryLight;
    final ic = iconColor ?? AppColors.primary;

    return Opacity(
      opacity: onTap == null ? 0.35 : 1.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: ic, size: 24),
                    ),
                    if (badge)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
