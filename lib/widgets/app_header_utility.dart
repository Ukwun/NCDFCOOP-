import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart'
    as welcome_auth;
import 'package:coop_commerce/providers/auth_provider.dart' as global_auth;

/// ALIBABA-INSPIRED GLOBAL UTILITY HEADER
/// Infrastructure layer showing shared utilities + role-aware utilities
/// Sits at the top of the app, persistent across all screens
class AppHeaderUtility extends ConsumerWidget {
  const AppHeaderUtility({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(global_auth.currentUserProvider);
    final userRole = ref.watch(global_auth.currentRoleProvider);

    if (user == null) {
      return const SizedBox.shrink();
    }

    return _buildHeaderForRole(context, ref, user, userRole);
  }

  /// Build header based on user role
  Widget _buildHeaderForRole(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    UserRole role,
  ) {
    final displayName = user.name.toString().trim().isEmpty
        ? 'Coop Commerce User'
        : user.name.toString().trim();
    final avatarText = displayName.characters.first.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactLayout = constraints.maxWidth < 420;

              final utilityIcons = Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment:
                    compactLayout ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => context.pushNamed('search'),
                    child: Icon(
                      Icons.search_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed('notifications'),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed('settings'),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed('help-support'),
                    child: Icon(
                      Icons.help_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showLogoutConfirmation(context, ref),
                    child: Icon(
                      Icons.logout_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              );

              final profileRow = GestureDetector(
                onTap: () => context.pushNamed('my-ncdfcoop'),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        avatarText,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            role.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              final topRow = compactLayout
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: profileRow),
                            const SizedBox(width: AppSpacing.sm),
                            _buildRoleIndicator(context, role),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        utilityIcons,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: profileRow),
                        const SizedBox(width: AppSpacing.md),
                        Flexible(child: _buildRoleIndicator(context, role)),
                        const SizedBox(width: AppSpacing.md),
                        utilityIcons,
                      ],
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  topRow,
                  const SizedBox(height: AppSpacing.sm),
                  _buildRoleSpecificUtilities(context, user, role),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build role-specific indicator badge
  Widget _buildRoleIndicator(BuildContext context, UserRole role) {
    final color = _getRoleColor(role);
    return GestureDetector(
      onTap: () => _showRoleSwitcher(context, role),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              role.displayName,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 12,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  /// Build role-specific utility buttons
  Widget _buildRoleSpecificUtilities(
    BuildContext context,
    dynamic user,
    UserRole role,
  ) {
    switch (role) {
      case UserRole.coopMember:
      case UserRole.premiumMember:
        return _buildMemberUtilities(context, user);

      case UserRole.seller:
        return _buildSellerUtilities(context, user);

      case UserRole.institutionalBuyer:
      case UserRole.institutionalApprover:
        return _buildInstitutionalUtilities(context, user);

      case UserRole.franchiseOwner:
        return _buildFranchiseUtilities(context, user);

      case UserRole.wholesaleBuyer:
        return _buildWholesaleUtilities(context, user);

      case UserRole.admin:
      case UserRole.superAdmin:
        return _buildAdminUtilities(context, user);

      default:
        return const SizedBox.shrink();
    }
  }

  /// Member-specific utilities
  Widget _buildMemberUtilities(BuildContext context, dynamic user) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUtilityButton(
              context: context,
              icon: Icons.verified_outlined,
              label: 'KYC Status',
              onTap: () => context.pushNamed('profile'),
              description: 'View verification',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              onTap: () => context.pushNamed('payment-methods'),
              description: 'Manage funds',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.card_giftcard_outlined,
              label: 'Loyalty',
              onTap: () => context.pushNamed('member-loyalty'),
              description: 'View rewards',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.savings_outlined,
              label: 'Savings',
              onTap: () => context.pushNamed('member-benefits'),
              description: 'View benefits',
            ),
          ],
        ),
      ),
    );
  }

  /// Seller-specific utilities
  Widget _buildSellerUtilities(BuildContext context, dynamic user) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUtilityButton(
              context: context,
              icon: Icons.trending_up_outlined,
              label: 'Leads',
              onTap: () => context.pushNamed('messages'),
              description: 'Buyer inquiries',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.sell_outlined,
              label: 'Sales',
              onTap: () => context.pushNamed('orders'),
              description: 'View orders',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.account_balance_outlined,
              label: 'Commission',
              onTap: () => context.pushNamed('payment-methods'),
              description: 'View earnings',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.inventory_outlined,
              label: 'Products',
              onTap: () => context.pushNamed('products'),
              description: 'Manage stock',
            ),
          ],
        ),
      ),
    );
  }

  /// Institutional buyer-specific utilities
  Widget _buildInstitutionalUtilities(BuildContext context, dynamic user) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUtilityButton(
              context: context,
              icon: Icons.assignment_outlined,
              label: 'Compliance',
              onTap: () => context.pushNamed('help-support'),
              description: 'View reports',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.notifications_active_outlined,
              label: 'Alerts',
              onTap: () => context.pushNamed('notifications'),
              description: 'Active alerts',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.group_outlined,
              label: 'Team',
              onTap: () => context.pushNamed('messages'),
              description: 'Manage team',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.description_outlined,
              label: 'Invoices',
              onTap: () => context.pushNamed('orders'),
              description: 'View docs',
            ),
          ],
        ),
      ),
    );
  }

  /// Franchise-specific utilities
  Widget _buildFranchiseUtilities(BuildContext context, dynamic user) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUtilityButton(
              context: context,
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              onTap: () => context.pushNamed('franchise-dashboard'),
              description: 'View analytics',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.inventory_2_outlined,
              label: 'Stock',
              onTap: () => context.pushNamed('products'),
              description: 'Inventory mgmt',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.bar_chart_outlined,
              label: 'Sales',
              onTap: () => context.pushNamed('orders'),
              description: 'Performance',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.store_outlined,
              label: 'Store',
              onTap: () => context.pushNamed('help-support'),
              description: 'Manage outlet',
            ),
          ],
        ),
      ),
    );
  }

  /// Wholesale buyer-specific utilities
  Widget _buildWholesaleUtilities(BuildContext context, dynamic user) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUtilityButton(
              context: context,
              icon: Icons.local_shipping_outlined,
              label: 'Orders',
              onTap: () => context.pushNamed('orders'),
              description: 'Track shipments',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.discount_outlined,
              label: 'Bulk Rate',
              onTap: () => context.pushNamed('products'),
              description: 'Price quotes',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Account',
              onTap: () => context.pushNamed('payment-methods'),
              description: 'Payment terms',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.support_agent_outlined,
              label: 'Support',
              onTap: () => context.pushNamed('help-support'),
              description: 'Get help',
            ),
          ],
        ),
      ),
    );
  }

  /// Admin-specific utilities
  Widget _buildAdminUtilities(BuildContext context, dynamic user) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildUtilityButton(
              context: context,
              icon: Icons.admin_panel_settings_outlined,
              label: 'Control Tower',
              onTap: () => context.pushNamed('admin-dashboard'),
              description: 'System control',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.people_outline,
              label: 'Users',
              onTap: () => context.pushNamed('admin-users'),
              description: 'Manage users',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.analytics_outlined,
              label: 'Analytics',
              onTap: () => context.pushNamed('notifications'),
              description: 'View metrics',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.security_outlined,
              label: 'Security',
              onTap: () => context.pushNamed('settings'),
              description: 'System security',
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable utility button widget
  Widget _buildUtilityButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            description,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 8,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Get color for role
  Color _getRoleColor(UserRole role) {
    return switch (role) {
      UserRole.wholesaleBuyer => const Color(0xFF1E7F4E),
      UserRole.coopMember => const Color(0xFFC9A227),
      UserRole.premiumMember => const Color(0xFFFFD700),
      UserRole.seller => const Color(0xFF0B6B3A),
      UserRole.franchiseOwner => const Color(0xFFF3951A),
      UserRole.institutionalBuyer => const Color(0xFF8B5CF6),
      UserRole.institutionalApprover => const Color(0xFF8B5CF6),
      UserRole.warehouseStaff => const Color(0xFFEC4899),
      UserRole.deliveryDriver => const Color(0xFF06B6D4),
      UserRole.admin => const Color(0xFFEF4444),
      UserRole.superAdmin => const Color(0xFFDC2626),
      _ => AppColors.primary,
    };
  }

  /// Show role switcher dialog
  void _showRoleSwitcher(BuildContext context, UserRole currentRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Switch Role',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // This would typically show available roles from user.roles
              // For now showing message that multiple roles can be switched
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'To enable role switching, ensure user has multiple roles assigned.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref
                      .read(welcome_auth.authControllerProvider.notifier)
                      .signOut();
                  // Navigate to welcome screen
                  if (context.mounted) {
                    context.go('/welcome');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
