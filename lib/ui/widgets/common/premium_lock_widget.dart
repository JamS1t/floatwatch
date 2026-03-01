import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes.dart';

/// Overlay that blocks access to premium features for free plan users.
///
/// Wrap any premium widget tree with this:
/// ```dart
/// PremiumLockWidget(
///   featureName: 'Weekly Reports',
///   child: WeeklyReportContent(),
/// )
/// ```
/// When isPremium is false, shows a locked state instead of [child].
class PremiumLockWidget extends StatelessWidget {
  final Widget child;
  final bool isPremium;
  final String featureName;

  const PremiumLockWidget({
    super.key,
    required this.child,
    required this.isPremium,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) return child;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Blurred / faded preview of the underlying content
        IgnorePointer(
          child: Opacity(opacity: 0.3, child: child),
        ),

        // Lock overlay — adapts between full and compact based on available height.
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Full overlay needs ~202dp; use compact below that threshold.
              final compact = constraints.maxHeight < 202;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: compact ? 0.88 : 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: compact
                    // ── Compact: icon + "Premium" label only ──────────────
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      )
                    // ── Full: icon + title + description + button ─────────
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            featureName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Upgrade to FloatWatch Premium\nto unlock this feature.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () =>
                                context.push(Routes.subscriptionScreen),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Upgrade Now',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact inline lock badge — use inside lists/cards.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'Premium',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
