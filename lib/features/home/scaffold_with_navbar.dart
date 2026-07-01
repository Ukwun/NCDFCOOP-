import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/core/providers/real_time_providers.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/features/search/search_screen.dart';
import 'package:coop_commerce/providers/user_activity_providers.dart';
import 'package:coop_commerce/widgets/app_header_utility.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceColor = Theme.of(context).scaffoldBackgroundColor;
    final role = ref.watch(currentRoleProvider);
    final currentUser = ref.watch(currentUserProvider);
    final needsMessengerBadge = _isWholesale(role);
    final messengerUnreadCount = currentUser == null
        ? 0
        : needsMessengerBadge
            ? ref
                .watch(unreadMessengerCountProvider(currentUser.id))
                .maybeWhen(data: (count) => count, orElse: () => 0)
            : 0;
    final destinations = _buildDestinations(
      role,
      messengerBadgeCount: messengerUnreadCount,
    );
    final showFullUtilityHeader = !_isWholesale(role);
    const compactHeaderTitle = 'Wholesale Marketplace';

    return Scaffold(
      body: Column(
        children: [
          // Keep wholesale screens focused by using a compact, low-noise top bar.
          if (showFullUtilityHeader)
            const AppHeaderUtility()
          else
            _CompactUtilityHeader(
              title: compactHeaderTitle,
              onProfileTap: () {
                ref.read(activityLoggerProvider.notifier).logButtonTap(
                      buttonName: 'compact_header_profile',
                      screenName: 'compact_header',
                      context: 'profile_navigation',
                      success: true,
                    );
                context.pushNamed('my-ncdfcoop');
              },
            ),
          // Main Content
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => _onTap(context, ref, index),
        backgroundColor: surfaceColor,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: destinations,
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(
    UserRole role, {
    int messengerBadgeCount = 0,
  }) {
    if (_isMember(role)) {
      return const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.primary),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.category_outlined),
          selectedIcon: Icon(Icons.category, color: AppColors.primary),
          label: 'Categories',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
          label: 'Messenger',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart, color: AppColors.primary),
          label: 'Cart',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'My CoopX',
        ),
      ];
    }

    if (_isSeller(role)) {
      return const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups, color: AppColors.primary),
          label: 'Clients',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
          label: 'Products',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon:
              Icon(Icons.account_balance_wallet, color: AppColors.primary),
          label: 'Earnings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'My CoopX',
        ),
      ];
    }

    if (_isWholesale(role)) {
      return <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.primary),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.category_outlined),
          selectedIcon: Icon(Icons.category, color: AppColors.primary),
          label: 'Categories',
        ),
        NavigationDestination(
          icon: _buildIconWithBadge(
            icon: Icons.chat_bubble_outline,
            badgeCount: messengerBadgeCount,
            isSelected: false,
          ),
          selectedIcon: _buildIconWithBadge(
            icon: Icons.chat_bubble,
            badgeCount: messengerBadgeCount,
            isSelected: true,
          ),
          label: 'Messenger',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart, color: AppColors.primary),
          label: 'Cart',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'My CoopX',
        ),
      ];
    }

    return const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home, color: AppColors.primary),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.local_offer_outlined),
        selectedIcon: Icon(Icons.local_offer, color: AppColors.primary),
        label: 'Offer',
      ),
      NavigationDestination(
        icon: Icon(Icons.message_outlined),
        selectedIcon: Icon(Icons.message, color: AppColors.primary),
        label: 'Message',
      ),
      NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart, color: AppColors.primary),
        label: 'Cart',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person, color: AppColors.primary),
        label: 'My NCDFCOOP',
      ),
    ];
  }

  bool _isMember(UserRole role) {
    return role == UserRole.coopMember;
  }

  bool _isSeller(UserRole role) {
    return role == UserRole.seller;
  }

  bool _isWholesale(UserRole role) {
    return role == UserRole.wholesaleBuyer;
  }

  Widget _buildIconWithBadge({
    required IconData icon,
    required int badgeCount,
    required bool isSelected,
  }) {
    final normalizedCount = badgeCount.clamp(0, 99);
    final showBadge = normalizedCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: isSelected ? AppColors.primary : null),
        if (showBadge)
          Positioned(
            right: -9,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D00),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
              child: Text(
                normalizedCount == 99 ? '99+' : normalizedCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    ref.read(activityLoggerProvider.notifier).logButtonTap(
          buttonName: 'bottom_nav_$index',
          screenName: 'bottom_navigation',
          context: 'role_tab_switch',
          success: true,
        );

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _CompactUtilityHeader extends ConsumerStatefulWidget {
  const _CompactUtilityHeader({
    required this.title,
    required this.onProfileTap,
  });

  final String title;
  final VoidCallback onProfileTap;

  @override
  ConsumerState<_CompactUtilityHeader> createState() =>
      _CompactUtilityHeaderState();
}

class _CompactUtilityHeaderState extends ConsumerState<_CompactUtilityHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    ref.read(activityLoggerProvider.notifier).logButtonTap(
          buttonName: 'compact_header_search_open',
          screenName: 'compact_header',
          context: 'search_overlay',
          success: true,
        );

    Navigator.of(context).push(
      PageRouteBuilder(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SearchScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    _searchFocusNode.unfocus();

    ref.read(activityLoggerProvider.notifier).logButtonTap(
          buttonName: 'compact_header_search_submit',
          screenName: 'compact_header',
          context: query.isEmpty ? 'empty_query' : 'query_submitted',
          success: true,
        );

    context.pushNamed(
      'search',
      queryParameters: query.isEmpty ? const {} : {'q': query},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
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
                    ? TextField(
                        key: const ValueKey('compact-header-search-field'),
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _submitSearch(),
                        decoration: InputDecoration(
                          hintText: 'Search products, brands, categories...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
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
                      )
                    : Text(
                        widget.title,
                        key: const ValueKey('compact-header-title'),
                        style: AppTextStyles.labelLarge
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            if (_isSearching)
              IconButton(
                onPressed: () {
                  ref.read(activityLoggerProvider.notifier).logButtonTap(
                        buttonName: 'compact_header_search_close',
                        screenName: 'compact_header',
                        context: 'search_overlay',
                        success: true,
                      );
                  _closeSearch();
                },
                icon: const Icon(Icons.close),
                tooltip: 'Close search',
              )
            else ...[
              IconButton(
                onPressed: _openSearch,
                icon: const Icon(Icons.search),
                tooltip: 'Search',
              ),
              IconButton(
                onPressed: () {
                  ref.read(activityLoggerProvider.notifier).logButtonTap(
                        buttonName: 'compact_header_notifications',
                        screenName: 'compact_header',
                        context: 'notifications_navigation',
                        success: true,
                      );
                  context.pushNamed('notifications');
                },
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
              ),
              IconButton(
                onPressed: widget.onProfileTap,
                icon: const Icon(Icons.person_outline),
                tooltip: 'Profile',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
