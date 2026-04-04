import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../core/providers/rbac_providers.dart';
import '../../models/account_category_model.dart';
import '../../core/auth/role.dart';

/// UNIFIED ACCOUNT & CATEGORIES SCREEN
/// Single page combining categories and account settings for all user types
/// - Member users see: Member/Premium categories + Cooperative Transparency
/// - Wholesale users see: Business/Franchise categories (no Cooperative Transparency)
class UnifiedAccountCategoriesScreen extends ConsumerWidget {
  const UnifiedAccountCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final highestRole = ref.watch(highestUserRoleProvider);

    if (currentUser == null) {
      return _buildNotLoggedIn(context);
    }

    // Get config based on user role
    final config = _getConfigForRole(highestRole);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, currentUser),

              // Profile card
              _buildProfileCard(context, currentUser),

              const SizedBox(height: 32),

              // CATEGORIES SECTION
              _buildCategoriesSection(context, config),

              const SizedBox(height: 32),

              // ACCOUNT & SETTINGS SECTION
              _buildAccountSettingsSection(context, config),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: AppColors.muted,
            ),
            const SizedBox(height: 24),
            Text(
              'Sign in to view your account',
              style: AppTextStyles.h3.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/signin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                'Go to Login',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic currentUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Account',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.close,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic currentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child:
                currentUser.photoUrl != null && currentUser.photoUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          currentUser.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 32,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.primary,
                      ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser.name ?? 'User',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser.email ?? '',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    AccountAndCategoriesConfig config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Account Categories',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: config.memberCategories != null
              ? _buildMemberCategories(context, config.memberCategories!)
              : _buildWholesaleCategories(context, config.wholesaleCategories!),
        ),
      ],
    );
  }

  Widget _buildMemberCategories(
    BuildContext context,
    List<MemberCategory> categories,
  ) {
    return Column(
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final isLast = index == categories.length - 1;

        return GestureDetector(
          onTap: () {
            // Handle category selection
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${category.title} selected'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: category.iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                category.title,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              if (category.badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: category.isPremium
                                        ? Colors.amber.withValues(alpha: 0.2)
                                        : Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category.badge!,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 10,
                                      color: category.isPremium
                                          ? Colors.amber[700]
                                          : Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.subtitle,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ),
              if (!isLast) const SizedBox(height: 12),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWholesaleCategories(
    BuildContext context,
    List<WholesaleCategory> categories,
  ) {
    return Column(
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final isLast = index == categories.length - 1;

        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${category.title} selected'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: category.iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                category.title,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              if (category.badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category.badge!,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 10,
                                      color: Colors.purple[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.subtitle,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ),
              if (!isLast) const SizedBox(height: 12),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountSettingsSection(
    BuildContext context,
    AccountAndCategoriesConfig config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Account & Settings',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: config.accountMenuItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == config.accountMenuItems.length - 1;

              if (item.isSectionHeader && index > 0) {
                // Section header with divider
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: AppColors.border,
                      height: 1,
                      thickness: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Text(
                        item.label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.pushNamed(item.route);
                    },
                    child: Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast && item.showDivider)
                    Divider(
                      color: AppColors.border,
                      height: 1,
                      thickness: 1,
                      indent: 56,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  AccountAndCategoriesConfig _getConfigForRole(UserRole role) {
    switch (role) {
      case UserRole.coopMember:
      case UserRole.premiumMember:
        return AccountAndCategoriesConfig.forMember();

      case UserRole.wholesaleBuyer:
      case UserRole.franchiseOwner:
      default:
        return AccountAndCategoriesConfig.forWholesaleBuyer();
    }
  }
}
