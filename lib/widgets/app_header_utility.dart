import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/models/product.dart';
import 'package:coop_commerce/core/providers/product_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:coop_commerce/features/welcome/auth_provider.dart'
    as welcome_auth;
import 'package:coop_commerce/providers/auth_provider.dart' as global_auth;
import 'package:coop_commerce/providers/user_activity_providers.dart';

/// Global utility header with role-aware shortcuts
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

              final profileRow = GestureDetector(
                onTap: () {
                  ProviderScope.containerOf(context, listen: false)
                      .read(activityLoggerProvider.notifier)
                      .logButtonTap(
                        buttonName: 'header_profile',
                        screenName: 'header_utility',
                        context: 'profile_navigation',
                        success: true,
                      );
                  context.pushNamed('my-ncdfcoop');
                },
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

              return Row(
                children: [
                  Expanded(child: profileRow),
                  if (!compactLayout) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: _buildRoleIndicator(context, role)),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  _HeaderQuickActions(maxWidth: constraints.maxWidth),
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
              onTap: () => context.pushNamed('my-ncdfcoop'),
              description: 'View verification',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.how_to_vote_outlined,
              label: 'Voting',
              onTap: () => context.pushNamed('member-voting'),
              description: 'Community voice',
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
              icon: Icons.account_circle_outlined,
              label: 'Profile',
              onTap: () => context.pushNamed('my-ncdfcoop'),
              description: 'Manage account',
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
              onTap: () => context.pushNamed('seller-sales-ledger'),
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
              onTap: () => context.pushNamed('institutional-invoices'),
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
              onTap: () => context.pushNamed('admin-analytics'),
              description: 'View metrics',
            ),
            _buildUtilityButton(
              context: context,
              icon: Icons.security_outlined,
              label: 'Security',
              onTap: () => context.pushNamed('admin-audit-logs'),
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
      onTap: () {
        ProviderScope.containerOf(context, listen: false)
            .read(activityLoggerProvider.notifier)
            .logButtonTap(
              buttonName: 'header_utility_$label',
              screenName: 'header_utility',
              context: description,
              success: true,
            );
        onTap();
      },
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

class _HeaderQuickActions extends ConsumerStatefulWidget {
  const _HeaderQuickActions({required this.maxWidth});

  final double maxWidth;

  @override
  ConsumerState<_HeaderQuickActions> createState() =>
      _HeaderQuickActionsState();
}

class _HeaderQuickActionsState extends ConsumerState<_HeaderQuickActions> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  List<Product> _suggestions = const [];
  bool _isLoadingSuggestions = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    ref.read(activityLoggerProvider.notifier).logButtonTap(
          buttonName: 'header_search_open',
          screenName: 'header_utility',
          context: 'search_overlay',
          success: true,
        );
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (mounted) {
      setState(() {
        _isSearching = false;
        _suggestions = const [];
        _isLoadingSuggestions = false;
      });
    }
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    _searchFocusNode.unfocus();
    ref.read(activityLoggerProvider.notifier).logButtonTap(
          buttonName: 'header_search_submit',
          screenName: 'header_utility',
          context: query.isEmpty ? 'empty_query' : 'query_submitted',
          success: true,
        );
    setState(() {
      _suggestions = const [];
    });
    context.pushNamed(
      'search',
      queryParameters: query.isEmpty ? const {} : {'q': query},
    );
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();

    if (query.length < 2) {
      setState(() {
        _suggestions = const [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    _debounce = Timer(const Duration(milliseconds: 260), () async {
      final currentText = _searchController.text.trim();
      if (currentText.length < 2) {
        if (!mounted) return;
        setState(() {
          _suggestions = const [];
          _isLoadingSuggestions = false;
        });
        return;
      }

      try {
        final results = await ref
            .read(productSearchProvider(currentText).future)
            .timeout(const Duration(seconds: 5), onTimeout: () => <Product>[]);

        if (!mounted || _searchController.text.trim() != currentText) return;

        setState(() {
          _suggestions = results.take(5).toList();
          _isLoadingSuggestions = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = const [];
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  void _onTapSuggestion(Product product) {
    final productId = product.id.trim();
    _searchFocusNode.unfocus();
    if (productId.isEmpty) {
      _searchController.text = product.name;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: product.name.length),
      );
      _submitSearch();
      return;
    }

    context.pushNamed(
      'product-detail',
      pathParameters: {'productId': productId},
    );
    setState(() {
      _suggestions = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchWidth = (widget.maxWidth * 0.62).clamp(220.0, 360.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axis: Axis.horizontal,
            child: child,
          ),
        );
      },
      child: _isSearching
          ? SizedBox(
              key: const ValueKey('header-expanded-search'),
              width: searchWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) => _submitSearch(),
                          decoration: InputDecoration(
                            hintText: 'Search any product...',
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: IconButton(
                              onPressed: _submitSearch,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              tooltip: 'Search now',
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref
                              .read(activityLoggerProvider.notifier)
                              .logButtonTap(
                                buttonName: 'header_search_close',
                                screenName: 'header_utility',
                                context: 'search_overlay',
                                success: true,
                              );
                          _closeSearch();
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'Close search',
                      ),
                    ],
                  ),
                  if (_isLoadingSuggestions || _suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isLoadingSuggestions
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: _suggestions.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (context, index) {
                                final product = _suggestions[index];
                                final query = _searchController.text.trim();
                                return InkWell(
                                  onTap: () => _onTapSuggestion(product),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSuggestionThumbnail(product),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildHighlightedText(
                                                product.name,
                                                query,
                                                baseStyle: AppTextStyles
                                                    .bodySmall
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                product.categoryId.isEmpty
                                                    ? 'Product'
                                                    : product.categoryId,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  _buildMetaChip(
                                                    'Verified supplier',
                                                  ),
                                                  _buildMetaChip(
                                                    _fastShippingText(product),
                                                  ),
                                                  _buildMetaChip(
                                                    'MOQ ${product.minimumOrderQuantity}',
                                                  ),
                                                  _buildMetaChip(
                                                    '⭐ ${product.rating.toStringAsFixed(1)}',
                                                  ),
                                                  _buildMetaChip(
                                                    _estimateSoldText(product),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _formatSuggestionPrice(product),
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                ],
              ),
            )
          : Row(
              key: const ValueKey('header-action-icons'),
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search_outlined),
                  tooltip: 'Search',
                ),
                IconButton(
                  onPressed: () {
                    ref.read(activityLoggerProvider.notifier).logButtonTap(
                          buttonName: 'header_notifications',
                          screenName: 'header_utility',
                          context: 'notifications_navigation',
                          success: true,
                        );
                    context.pushNamed('notifications');
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                ),
              ],
            ),
    );
  }
}

Widget _buildMetaChip(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
        fontSize: 9,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

Widget _buildSuggestionThumbnail(Product product) {
  final url = (product.imageUrl ?? '').trim();

  Widget fallback() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        size: 16,
        color: AppColors.primary,
      ),
    );
  }

  if (url.isEmpty || url.contains('via.placeholder.com')) {
    return fallback();
  }

  if (url.startsWith('assets/')) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        url,
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: CachedNetworkImage(
      imageUrl: url,
      width: 34,
      height: 34,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => fallback(),
      placeholder: (_, __) => fallback(),
    ),
  );
}

Widget _buildHighlightedText(
  String source,
  String query, {
  required TextStyle baseStyle,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return Text(
      source,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );
  }

  final sourceLower = source.toLowerCase();
  final start = sourceLower.indexOf(normalizedQuery);
  if (start < 0) {
    return Text(
      source,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle,
    );
  }

  final end = start + normalizedQuery.length;
  return RichText(
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    text: TextSpan(
      style: baseStyle,
      children: [
        if (start > 0) TextSpan(text: source.substring(0, start)),
        TextSpan(
          text: source.substring(start, end),
          style: baseStyle.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (end < source.length) TextSpan(text: source.substring(end)),
      ],
    ),
  );
}

String _estimateSoldText(Product product) {
  final sold = product.stock <= 0 ? 25 : (product.stock * 2);
  if (sold >= 1000) {
    return '${(sold / 1000).toStringAsFixed(1)}k sold';
  }
  return '$sold sold';
}

String _fastShippingText(Product product) {
  return product.stock > 20 ? 'Fast shipping' : 'Standard shipping';
}

String _formatSuggestionPrice(Product product) {
  final value = product.wholesalePrice > 0
      ? product.wholesalePrice
      : (product.retailPrice > 0 ? product.retailPrice : 0);
  if (value <= 0) {
    return 'N/A';
  }
  return '₦${value.toStringAsFixed(0)}';
}
