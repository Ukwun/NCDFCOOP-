import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Quick Action Button for home screen
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String routeName;
  final VoidCallback? onPressed;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.routeName,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ??
          () {
            context.pushNamed(routeName);
          },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Home Quick Actions Bar - Shows 6 quick action buttons
class HomeQuickActionsBar extends StatelessWidget {
  const HomeQuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'Quick Actions',
              style: AppTextStyles.h4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: QuickActionButton(
                    icon: Icons.flash_on,
                    label: 'Flash Sales',
                    routeName: 'flash-sales',
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: QuickActionButton(
                    icon: Icons.refresh,
                    label: 'Reorder',
                    routeName: 'reorder',
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: QuickActionButton(
                    icon: Icons.favorite,
                    label: 'Wishlist',
                    routeName: 'wishlist',
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: QuickActionButton(
                    icon: Icons.local_shipping,
                    label: 'Track Order',
                    routeName: 'track-orders',
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: QuickActionButton(
                    icon: Icons.card_giftcard,
                    label: 'My Rewards',
                    routeName: 'my-rewards',
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: QuickActionButton(
                    icon: Icons.verified,
                    label: 'Membership',
                    routeName: 'premium-membership',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
