import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/widgets/app_header_utility.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceColor = Theme.of(context).scaffoldBackgroundColor;
    final role = ref.watch(currentRoleProvider);
    final destinations = _buildDestinations(role);

    return Scaffold(
      body: Column(
        children: [
          // Global Utility Header - ALWAYS VISIBLE
          const AppHeaderUtility(),
          // Main Content
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => _onTap(context, index),
        backgroundColor: surfaceColor,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: destinations,
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(UserRole role) {
    if (_isMember(role)) {
      return const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.primary),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon:
              Icon(Icons.account_balance_wallet, color: AppColors.primary),
          label: 'Wallet',
        ),
        NavigationDestination(
          icon: Icon(Icons.savings_outlined),
          selectedIcon: Icon(Icons.savings, color: AppColors.primary),
          label: 'Savings',
        ),
        NavigationDestination(
          icon: Icon(Icons.trending_up_outlined),
          selectedIcon: Icon(Icons.trending_up, color: AppColors.primary),
          label: 'Investments',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'Profile',
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
          label: 'Profile',
        ),
      ];
    }

    if (_isWholesale(role)) {
      return const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard, color: AppColors.primary),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.workspaces_outline),
          selectedIcon: Icon(Icons.workspaces, color: AppColors.primary),
          label: 'Portfolio',
        ),
        NavigationDestination(
          icon: Icon(Icons.trending_up_outlined),
          selectedIcon: Icon(Icons.trending_up, color: AppColors.primary),
          label: 'Bulk Invest',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics, color: AppColors.primary),
          label: 'Analytics',
        ),
        NavigationDestination(
          icon: Icon(Icons.verified_user_outlined),
          selectedIcon: Icon(Icons.verified_user, color: AppColors.primary),
          label: 'Compliance',
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
    return role == UserRole.coopMember || role == UserRole.premiumMember;
  }

  bool _isSeller(UserRole role) {
    return role == UserRole.seller;
  }

  bool _isWholesale(UserRole role) {
    return role == UserRole.wholesaleBuyer ||
        role == UserRole.institutionalBuyer ||
        role == UserRole.institutionalApprover;
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
