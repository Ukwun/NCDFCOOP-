import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../features/welcome/auth_provider.dart';

/// Navigation configuration for different user roles
/// Each role gets a tailored bottom nav with relevant actions
class RoleAwareNavigationShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const RoleAwareNavigationShell({
    required this.child,
    required this.currentRoute,
    super.key,
  });

  @override
  State<RoleAwareNavigationShell> createState() =>
      _RoleAwareNavigationShellState();
}

class _RoleAwareNavigationShellState extends State<RoleAwareNavigationShell> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authStateProvider);
        final currentUser = authState.value;
        final userRole = currentUser?.roles.isNotEmpty == true
            ? currentUser!.roles.first.toString().split('.').last.toLowerCase()
            : 'consumer';

        return Scaffold(
          body: widget.child,
          bottomNavigationBar: _buildBottomNav(context, userRole, ref),
        );
      },
    );
  }

  /// Build role-specific bottom navigation
  Widget _buildBottomNav(BuildContext context, String role, WidgetRef ref) {
    switch (role) {
      case 'consumer':
        return _ConsumerBottomNav(currentRoute: widget.currentRoute);
      case 'member':
        return _MemberBottomNav(currentRoute: widget.currentRoute);
      case 'franchise_owner':
        return _FranchiseBottomNav(currentRoute: widget.currentRoute);
      case 'warehouse_staff':
        return _WarehouseBottomNav(currentRoute: widget.currentRoute);
      case 'driver':
        return _DriverBottomNav(currentRoute: widget.currentRoute);
      case 'institutional_buyer':
        return _InstitutionalBottomNav(currentRoute: widget.currentRoute);
      case 'admin':
        return _AdminSideNav(currentRoute: widget.currentRoute);
      default:
        return _ConsumerBottomNav(currentRoute: widget.currentRoute);
    }
  }
}

/// Consumer: Browse → Cart → Orders → Profile
class _ConsumerBottomNav extends StatelessWidget {
  final String currentRoute;

  const _ConsumerBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Browse',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_outlined),
          activeIcon: Icon(Icons.receipt),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) => _navigateConsumer(context, index),
    );
  }

  void _navigateConsumer(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/products');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        context.go('/orders');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}

/// Member: Home → Benefits → Orders → Voting → Profile
class _MemberBottomNav extends StatelessWidget {
  final String currentRoute;

  const _MemberBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard_outlined),
          activeIcon: Icon(Icons.card_giftcard),
          label: 'Benefits',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.how_to_vote_outlined),
          activeIcon: Icon(Icons.how_to_vote),
          label: 'Voting',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_outlined),
          activeIcon: Icon(Icons.receipt),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) => _navigateMember(context, index),
    );
  }

  void _navigateMember(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/benefits');
        break;
      case 2:
        context.go('/voting');
        break;
      case 3:
        context.go('/orders');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}

/// Franchise: Dashboard → Inventory → Sales → Compliance → Settings
class _FranchiseBottomNav extends StatelessWidget {
  final String currentRoute;

  const _FranchiseBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Inventory',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Sales',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checklist_outlined),
          activeIcon: Icon(Icons.checklist),
          label: 'Compliance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      onTap: (index) => _navigateFranchise(context, index),
    );
  }

  void _navigateFranchise(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/franchise/dashboard');
        break;
      case 1:
        context.go('/franchise/inventory');
        break;
      case 2:
        context.go('/franchise/sales');
        break;
      case 3:
        context.go('/franchise/compliance');
        break;
      case 4:
        context.go('/franchise/settings');
        break;
    }
  }
}

/// Warehouse: Tasks → Queue → QC → Reports
class _WarehouseBottomNav extends StatelessWidget {
  final String currentRoute;

  const _WarehouseBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.task_outlined),
          activeIcon: Icon(Icons.task),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_outlined),
          activeIcon: Icon(Icons.list),
          label: 'Queue',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          activeIcon: Icon(Icons.check_circle),
          label: 'QC',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
      ],
      onTap: (index) => _navigateWarehouse(context, index),
    );
  }

  void _navigateWarehouse(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/warehouse/tasks');
        break;
      case 1:
        context.go('/warehouse/queue');
        break;
      case 2:
        context.go('/warehouse/qc');
        break;
      case 3:
        context.go('/warehouse/reports');
        break;
    }
  }
}

/// Driver: Route → Deliveries → Chat → Settings
class _DriverBottomNav extends StatelessWidget {
  final String currentRoute;

  const _DriverBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_outlined),
          activeIcon: Icon(Icons.directions),
          label: 'Route',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
          label: 'Deliveries',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          activeIcon: Icon(Icons.message),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      onTap: (index) => _navigateDriver(context, index),
    );
  }

  void _navigateDriver(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/driver/route');
        break;
      case 1:
        context.go('/driver/deliveries');
        break;
      case 2:
        context.go('/driver/chat');
        break;
      case 3:
        context.go('/driver/settings');
        break;
    }
  }
}

/// Institutional: Catalog → PO → Orders → Invoices → Profile
class _InstitutionalBottomNav extends StatelessWidget {
  final String currentRoute;

  const _InstitutionalBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Catalog',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'PO',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_outlined),
          activeIcon: Icon(Icons.receipt),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Invoices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) => _navigateInstitutional(context, index),
    );
  }

  void _navigateInstitutional(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/institutional/catalog');
        break;
      case 1:
        context.go('/institutional/po');
        break;
      case 2:
        context.go('/institutional/orders');
        break;
      case 3:
        context.go('/institutional/invoices');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}

/// Admin: Users → Pricing → Orders → Compliance → Audit
class _AdminSideNav extends StatelessWidget {
  final String currentRoute;

  const _AdminSideNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Admin Control',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Network Operations',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _AdminNavItem(
                  icon: Icons.people_outline,
                  label: 'Users & Roles',
                  route: '/admin/users',
                  currentRoute: currentRoute,
                ),
                _AdminNavItem(
                  icon: Icons.local_offer_outlined,
                  label: 'Pricing',
                  route: '/admin/pricing',
                  currentRoute: currentRoute,
                ),
                _AdminNavItem(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Orders',
                  route: '/admin/orders',
                  currentRoute: currentRoute,
                ),
                _AdminNavItem(
                  icon: Icons.store_outlined,
                  label: 'Franchises',
                  route: '/admin/franchises',
                  currentRoute: currentRoute,
                ),
                _AdminNavItem(
                  icon: Icons.business_outlined,
                  label: 'Institutions',
                  route: '/admin/institutions',
                  currentRoute: currentRoute,
                ),
                _AdminNavItem(
                  icon: Icons.assessment_outlined,
                  label: 'Reports',
                  route: '/admin/reports',
                  currentRoute: currentRoute,
                ),
                _AdminNavItem(
                  icon: Icons.gavel_outlined,
                  label: 'Compliance',
                  route: '/admin/compliance',
                  currentRoute: currentRoute,
                ),
                _AdminNavItem(
                  icon: Icons.history_outlined,
                  label: 'Audit Log',
                  route: '/admin/audit',
                  currentRoute: currentRoute,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;
    return ListTile(
      leading:
          Icon(icon, color: isActive ? AppColors.primary : AppColors.muted),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isActive ? AppColors.primary : AppColors.text,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}
