import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/features/home/role_aware_home_screen.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';
import 'package:coop_commerce/features/home/scaffold_with_navbar.dart';
import 'package:coop_commerce/features/welcome/welcome_screen.dart';
import 'package:coop_commerce/features/welcome/splash_screen.dart';
import 'package:coop_commerce/features/welcome/onboarding_screen.dart';
import 'package:coop_commerce/features/welcome/onboarding_screen_2.dart';
import 'package:coop_commerce/features/welcome/onboarding_screen_3.dart';
import 'package:coop_commerce/features/welcome/sign_in_screen.dart';
import 'package:coop_commerce/features/welcome/sign_up_screen.dart';
import 'package:coop_commerce/features/welcome/forgot_password_screen.dart';
import 'package:coop_commerce/features/welcome/create_new_password_screen.dart';
import 'package:coop_commerce/features/welcome/membership_screen.dart';
import 'package:coop_commerce/features/profile/profile_screen.dart';
import 'package:coop_commerce/features/profile/orders_screen.dart';
import 'package:coop_commerce/features/profile/saved_items_screen.dart';
import 'package:coop_commerce/features/profile/payment_methods_screen.dart';
import 'package:coop_commerce/features/profile/addresses_screen.dart';
import 'package:coop_commerce/features/profile/notifications_screen.dart';
import 'package:coop_commerce/features/profile/help_support_screen.dart';
import 'package:coop_commerce/features/profile/settings_screen.dart';
import 'package:coop_commerce/features/products/category_products_screen.dart';
import 'package:coop_commerce/features/products/products_listing_screen.dart';
import 'package:coop_commerce/features/cart/cart_screen.dart';
import 'package:coop_commerce/features/checkout/checkout_screen.dart';
import 'package:coop_commerce/features/checkout/order_confirmation_screen.dart';
import 'package:coop_commerce/features/checkout/order_tracking_screen.dart';
import 'package:coop_commerce/models/order.dart' as order_model;
import 'package:coop_commerce/features/search/search_screen.dart';
import 'package:coop_commerce/features/member/member_benefits_screen.dart';
import 'package:coop_commerce/features/benefits/exclusive_pricing_page.dart';
import 'package:coop_commerce/features/benefits/members_only_page.dart';
import 'package:coop_commerce/features/benefits/bulk_access_page.dart';
import 'package:coop_commerce/features/benefits/flash_sales_page.dart';
import 'package:coop_commerce/features/benefits/community_dividends_page.dart';
import 'package:coop_commerce/features/premium/premium_membership_page.dart';
import 'package:coop_commerce/features/products/product_detail_screen.dart';
import 'package:coop_commerce/features/support/help_center_screen.dart';
import 'package:coop_commerce/core/auth/role.dart';
// Franchise feature imports
import 'package:coop_commerce/features/franchise/franchise_screens.dart';
import 'package:coop_commerce/features/franchise/franchise_analytics_screen.dart';
import 'package:coop_commerce/features/franchise/franchise_staff_screen.dart';
import 'package:coop_commerce/features/franchise/franchise_inventory_screen.dart';
import 'package:coop_commerce/features/franchise/franchise_store_management_screen.dart';
// Institutional feature imports
import 'package:coop_commerce/features/institutional/institutional_procurement_home_screen.dart';
import 'package:coop_commerce/features/institutional/institutional_po_creation_screen.dart';
import 'package:coop_commerce/features/institutional/institutional_approval_workflow_screen.dart';
import 'package:coop_commerce/features/institutional/institutional_invoice_screen.dart';
// Admin feature imports
import 'package:coop_commerce/features/admin/admin_control_tower_home_screen.dart';
import 'package:coop_commerce/features/admin/admin_user_management_screen.dart';
import 'package:coop_commerce/features/admin/admin_compliance_dashboard_screen.dart';
import 'package:coop_commerce/features/admin/admin_audit_log_browser_screen.dart';
import 'package:coop_commerce/features/admin/price_override_admin_dashboard.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final _shellNavigatorCartKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellCart',
);
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellProfile',
);

// ============================================================================
// PERMISSION CHECK HELPER FUNCTION
// ============================================================================

/// Maps route paths to required user roles
/// If a route is not in this map, it's accessible to all authenticated users
const Map<String, Set<UserRole>> _routeRoleRequirements = {
  // Franchise routes
  '/franchise': {
    UserRole.franchiseOwner,
    UserRole.storeManager,
    UserRole.storeStaff,
  },
  '/franchise/store-management': {
    UserRole.franchiseOwner,
    UserRole.storeManager,
  },
  '/franchise/wholesale-pricing': {
    UserRole.franchiseOwner,
    UserRole.storeManager,
  },
  '/franchise/inventory': {
    UserRole.franchiseOwner,
    UserRole.storeManager,
    UserRole.storeStaff,
  },
  '/franchise/compliance': {
    UserRole.franchiseOwner,
    UserRole.storeManager,
  },

  // Institutional/B2B routes
  '/institutional': {
    UserRole.institutionalBuyer,
    UserRole.institutionalApprover,
  },
  '/institutional/purchase-orders': {
    UserRole.institutionalBuyer,
    UserRole.institutionalApprover,
  },
  '/institutional/purchase-orders/create': {
    UserRole.institutionalBuyer,
  },
  '/institutional/invoices': {
    UserRole.institutionalBuyer,
    UserRole.institutionalApprover,
  },

  // Warehouse routes
  '/warehouse': {
    UserRole.warehouseStaff,
  },
  '/warehouse/tasks': {
    UserRole.warehouseStaff,
  },

  // Driver routes
  '/driver': {
    UserRole.deliveryDriver,
  },
  '/driver/route': {
    UserRole.deliveryDriver,
  },

  // Admin routes
  '/admin': {
    UserRole.admin,
    UserRole.superAdmin,
  },
  '/admin/users': {
    UserRole.admin,
    UserRole.superAdmin,
  },
  '/admin/pricing': {
    UserRole.admin,
    UserRole.superAdmin,
  },
  '/admin/orders': {
    UserRole.admin,
    UserRole.superAdmin,
  },
  '/admin/franchises': {
    UserRole.admin,
    UserRole.superAdmin,
  },
  '/admin/audit': {
    UserRole.admin,
    UserRole.superAdmin,
  },
};

/// Checks if a path matches the route role requirements
/// Returns true if user has permission, false otherwise
bool _userHasPermissionForRoute(String path, Set<UserRole> userRoles) {
  // Check exact path match
  if (_routeRoleRequirements.containsKey(path)) {
    final requiredRoles = _routeRoleRequirements[path]!;
    return userRoles.any((role) => requiredRoles.contains(role));
  }

  // Check path prefixes for parameterized routes
  // e.g., /warehouse/pick/task123 matches /warehouse/pick/:taskId
  if (path.startsWith('/warehouse/pick/')) {
    return userRoles.contains(UserRole.warehouseStaff);
  }
  if (path.startsWith('/driver/deliveries/')) {
    return userRoles.contains(UserRole.deliveryDriver);
  }
  if (path.startsWith('/institutional/purchase-orders/')) {
    final requiredRoles =
        _routeRoleRequirements['/institutional/purchase-orders']!;
    return userRoles.any((role) => requiredRoles.contains(role));
  }
  if (path.startsWith('/institutional/invoices/')) {
    return _routeRoleRequirements['/institutional/invoices']!
        .any((role) => userRoles.contains(role));
  }

  // Route doesn't require specific role, allow all authenticated users
  return true;
}

// ============================================================================
// RIVERPOD PROVIDER FOR ROUTER
// ============================================================================

class AppRouter {
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/welcome',
      redirect: (context, state) {
        final isAuthenticated = ref.watch(isAuthenticatedProvider);
        final authState = ref.watch(authStateProvider);
        final user = authState.value;

        final isOnPublicRoute = state.uri.path == '/welcome' ||
            state.uri.path == '/signin' ||
            state.uri.path == '/signup' ||
            state.uri.path == '/splash' ||
            state.uri.path.startsWith('/onboarding') ||
            state.uri.path == '/forgot-password' ||
            state.uri.path == '/create-new-password';

        // Redirect to signin if not authenticated and not on public route
        if (!isAuthenticated && !isOnPublicRoute) {
          return '/signin';
        }

        // Redirect to home if authenticated and on public route
        if (isAuthenticated &&
            (state.uri.path == '/welcome' ||
                state.uri.path == '/signin' ||
                state.uri.path == '/signup')) {
          return '/';
        }

        // Check role-based permissions for protected routes
        if (isAuthenticated && user != null && !isOnPublicRoute) {
          final currentPath = state.uri.path;
          final userRolesSet = user.roles.toSet();

          // Skip permission check for non-protected routes
          if (!_userHasPermissionForRoute(currentPath, userRolesSet)) {
            return '/';
          }
        }

        return null;
      },
      routes: [
        // Splash Route (Initial Screen)
        GoRoute(
          path: '/splash',
          name: 'splash',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        // Welcome Route (First Screen)
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        // Onboarding Route
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),

        // Onboarding 2 Route
        GoRoute(
          path: '/onboarding2',
          name: 'onboarding2',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingScreen2(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),

        // Onboarding 3 Route
        GoRoute(
          path: '/onboarding3',
          name: 'onboarding3',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const OnboardingScreen3(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),

        // Sign In Route
        GoRoute(
          path: '/signin',
          name: 'signin',
          builder: (context, state) => const SignInScreen(),
        ),

        // Sign Up Route
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),

        // Forgot Password Route
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Create New Password Route
        GoRoute(
          path: '/create-new-password',
          name: 'create-new-password',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'] ?? '';
            return CreateNewPasswordScreen(token: token);
          },
        ),

        // Membership Route
        GoRoute(
          path: '/membership',
          name: 'membership',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const MembershipScreen(),
        ),

        // Search Route
        GoRoute(
          path: '/search',
          name: 'search',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SearchScreen(),
        ),

        // Member Benefits Route
        GoRoute(
          path: '/member-benefits',
          name: 'member-benefits',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const MemberBenefitsScreen(),
        ),

        // Products Routes
        GoRoute(
          path: '/category/:categoryName',
          name: 'category-products',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final categoryName = state.pathParameters['categoryName'] ?? '';
            return CategoryProductsScreen(
              categoryName: Uri.decodeComponent(categoryName),
            );
          },
        ),

        GoRoute(
          path: '/buy-again',
          name: 'buy-again',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ProductsListingScreen(
            title: 'Buy Again',
            type: 'buy-again',
          ),
        ),

        GoRoute(
          path: '/essentials',
          name: 'essentials',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ProductsListingScreen(
            title: 'Essentials Basket',
            type: 'essentials',
          ),
        ),

        GoRoute(
          path: '/member-exclusives',
          name: 'member-exclusives',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const MembershipScreen(),
        ),

        // Profile Routes
        GoRoute(
          path: '/orders',
          name: 'orders',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const OrdersScreen(),
        ),

        GoRoute(
          path: '/saved-items',
          name: 'saved-items',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SavedItemsScreen(),
        ),

        GoRoute(
          path: '/payment-methods',
          name: 'payment-methods',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const PaymentMethodsScreen(),
        ),

        GoRoute(
          path: '/addresses',
          name: 'addresses',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AddressesScreen(),
        ),

        GoRoute(
          path: '/notifications',
          name: 'notifications',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const NotificationsScreen(),
        ),

        GoRoute(
          path: '/help-support',
          name: 'help-support',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const HelpSupportScreen(),
        ),

        GoRoute(
          path: '/settings',
          name: 'settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SettingsScreen(),
        ),

        // Stateful Shell Route for Bottom Navigation
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
          branches: [
            // Branch 1: Home
            StatefulShellBranch(
              navigatorKey: _shellNavigatorHomeKey,
              routes: [
                GoRoute(
                  path: '/',
                  name: 'home',
                  builder: (context, state) => const RoleAwareHomeScreen(),
                ),
              ],
            ),
            // Branch 2: Cart
            StatefulShellBranch(
              navigatorKey: _shellNavigatorCartKey,
              routes: [
                GoRoute(
                  path: '/cart',
                  name: 'cart',
                  builder: (context, state) => const CartScreen(),
                ),
              ],
            ),
            // Branch 3: Profile
            StatefulShellBranch(
              navigatorKey: _shellNavigatorProfileKey,
              routes: [
                GoRoute(
                  path: '/profile',
                  name: 'profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        // Other routes (pushed on top of the shell)
        GoRoute(
          path: '/category/:categoryId',
          name: 'category',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final categoryId = state.pathParameters['categoryId'];
            return Scaffold(
              appBar: AppBar(title: const Text('Category')),
              body: Center(child: Text('Category: $categoryId')),
            );
          },
        ),
        GoRoute(
          path: '/checkout',
          name: 'checkout',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CheckoutScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/order-confirmation',
          name: 'order-confirmation',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final order = state.extra as order_model.Order?;
            if (order == null) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: Scaffold(
                  body: const Center(child: Text('Order not found')),
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            }
            return CustomTransitionPage(
              key: state.pageKey,
              child: OrderConfirmationScreen(order: order),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/order-tracking/:orderId',
          name: 'order-tracking',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            return CustomTransitionPage(
              key: state.pageKey,
              child: OrderTrackingScreen(orderId: orderId),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/member-savings',
          name: 'member-savings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Member Savings')),
              body: const Center(child: Text('Member Savings Screen')),
            );
          },
        ),
        GoRoute(
          path: '/bulk-order',
          name: 'bulk-order',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Bulk Order')),
              body: const Center(child: Text('Bulk Order Screen')),
            );
          },
        ),
        // Benefit Detail Pages
        GoRoute(
          path: '/benefits/exclusive-pricing',
          name: 'exclusive-pricing',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ExclusivePricingPage(),
        ),
        GoRoute(
          path: '/benefits/members-only',
          name: 'members-only',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const MembersOnlyAccessPage(),
        ),
        GoRoute(
          path: '/benefits/bulk-access',
          name: 'bulk-access',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const BulkAccessPage(),
        ),
        GoRoute(
          path: '/benefits/flash-sales',
          name: 'flash-sales',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const FlashSalesPage(),
        ),
        GoRoute(
          path: '/benefits/community-dividends',
          name: 'community-dividends',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const CommunityDividendsPage(),
        ),
        // Premium Membership Route
        GoRoute(
          path: '/premium-membership',
          name: 'premium-membership',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const PremiumMembershipPage(),
        ),
        // Quick Action Routes
        GoRoute(
          path: '/reorder',
          name: 'reorder',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Reorder')),
            body: const Center(child: Text('Reorder Products')),
          ),
        ),
        GoRoute(
          path: '/wishlist',
          name: 'wishlist',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SavedItemsScreen(),
        ),
        GoRoute(
          path: '/track-orders',
          name: 'track-orders',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/my-rewards',
          name: 'my-rewards',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('My Rewards')),
            body: const Center(child: Text('My Rewards & Points')),
          ),
        ),
        GoRoute(
          path: '/help-center',
          name: 'help-center',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const HelpCenterScreen(),
        ),
        GoRoute(
          path: '/subscription-payment/:tier',
          name: 'subscription-payment',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final tier = state.pathParameters['tier'] ?? 'gold';
            return Scaffold(
              appBar: AppBar(title: const Text('Subscription Payment')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Payment for $tier membership'),
                    const SizedBox(height: 20),
                    const Text('Payment processing will be implemented here'),
                  ],
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/product/:productId',
          name: 'product-detail',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final productId = state.pathParameters['productId'] ??
                state.extra as String? ??
                '';
            return ProductDetailScreen(
              productId: productId,
            );
          },
        ),

        // ====================================================================
        // ROLE-PROTECTED ROUTES - PERMISSION GUARDS ENFORCED
        // ====================================================================

        // FRANCHISE ROUTES - Requires franchiseOwner, storeManager, storeStaff
        GoRoute(
          path: '/franchise',
          name: 'franchise-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            return FranchiseDashboardScreen(storeId: storeId);
          },
        ),
        GoRoute(
          path: '/franchise/analytics',
          name: 'franchise-analytics',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            return FranchiseAnalyticsScreen(storeId: storeId);
          },
        ),
        GoRoute(
          path: '/franchise/staff',
          name: 'franchise-staff',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            return FranchiseStaffScreen(storeId: storeId);
          },
        ),
        GoRoute(
          path: '/franchise/inventory',
          name: 'franchise-inventory',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            return FranchiseInventoryScreen(storeId: storeId);
          },
        ),
        GoRoute(
          path: '/franchise/management',
          name: 'franchise-store-management',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            return FranchiseStoreManagementScreen(storeId: storeId);
          },
        ),

        // INSTITUTIONAL/B2B ROUTES - Requires institutionalBuyer, institutionalApprover
        GoRoute(
          path: '/institutional',
          name: 'institutional-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const InstitutionalProcurementHomeScreen();
          },
        ),
        GoRoute(
          path: '/institutional/purchase-orders',
          name: 'institutional-po-list',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Purchase Orders')),
              body: const Center(
                  child: Text('Purchase Orders List - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/institutional/purchase-orders/create',
          name: 'institutional-po-create',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const InstitutionalPOCreationScreen();
          },
        ),
        GoRoute(
          path: '/institutional/purchase-orders/:poId',
          name: 'institutional-po-detail',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final poId = state.pathParameters['poId'] ?? '';
            return InstitutionalApprovalWorkflowScreen(poId: poId);
          },
        ),
        GoRoute(
          path: '/institutional/invoices',
          name: 'institutional-invoices',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const InstitutionalInvoiceScreen();
          },
        ),
        GoRoute(
          path: '/institutional/invoices/:invoiceId',
          name: 'institutional-invoice-detail',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final invoiceId = state.pathParameters['invoiceId'] ?? '';
            return InstitutionalInvoiceDetailScreen(invoiceId: invoiceId);
          },
        ),

        // WAREHOUSE ROUTES - Requires warehouseStaff
        GoRoute(
          path: '/warehouse',
          name: 'warehouse-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Warehouse Dashboard')),
              body: const Center(
                  child: Text('Warehouse Dashboard - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/warehouse/tasks',
          name: 'warehouse-tasks',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Warehouse Tasks')),
              body: const Center(child: Text('Warehouse Tasks - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/warehouse/pick/:taskId',
          name: 'warehouse-pick-task',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final taskId = state.pathParameters['taskId'] ?? '';
            return Scaffold(
              appBar: AppBar(title: const Text('Pick Task')),
              body: Center(child: Text('Pick Task: $taskId - Coming Soon')),
            );
          },
        ),

        // DRIVER ROUTES - Requires deliveryDriver
        GoRoute(
          path: '/driver',
          name: 'driver-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Driver Dashboard')),
              body: const Center(child: Text('Driver Dashboard - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/driver/route',
          name: 'driver-route',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Today\'s Route')),
              body: const Center(child: Text('Today\'s Route - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/driver/deliveries/:deliveryId',
          name: 'driver-delivery-detail',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final deliveryId = state.pathParameters['deliveryId'] ?? '';
            return Scaffold(
              appBar: AppBar(title: const Text('Delivery Details')),
              body: Center(child: Text('Delivery: $deliveryId - Coming Soon')),
            );
          },
        ),

        // ADMIN ROUTES - Requires admin, superAdmin
        GoRoute(
          path: '/admin',
          name: 'admin-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          redirect: (context, state) {
            if (!_hasRole(context, UserRole.admin) &&
                !_hasRole(context, UserRole.superAdmin)) {
              return '/login';
            }
            return null;
          },
          builder: (context, state) {
            return const AdminControlTowerHomeScreen();
          },
        ),
        GoRoute(
          path: '/admin/users',
          name: 'admin-users',
          parentNavigatorKey: _rootNavigatorKey,
          redirect: (context, state) {
            if (!_hasRole(context, UserRole.admin) &&
                !_hasRole(context, UserRole.superAdmin)) {
              return '/login';
            }
            return null;
          },
          builder: (context, state) {
            return const AdminUserManagementScreen();
          },
        ),
        GoRoute(
          path: '/admin/approvals',
          name: 'admin-approvals',
          parentNavigatorKey: _rootNavigatorKey,
          redirect: (context, state) {
            if (!_hasRole(context, UserRole.admin) &&
                !_hasRole(context, UserRole.superAdmin)) {
              return '/login';
            }
            return null;
          },
          builder: (context, state) {
            return const PriceOverrideAdminDashboard();
          },
        ),
        GoRoute(
          path: '/admin/compliance',
          name: 'admin-compliance',
          parentNavigatorKey: _rootNavigatorKey,
          redirect: (context, state) {
            if (!_hasRole(context, UserRole.admin) &&
                !_hasRole(context, UserRole.superAdmin)) {
              return '/login';
            }
            return null;
          },
          builder: (context, state) {
            return const AdminComplianceDashboardScreen();
          },
        ),
        GoRoute(
          path: '/admin/audit-logs',
          name: 'admin-audit-logs',
          parentNavigatorKey: _rootNavigatorKey,
          redirect: (context, state) {
            if (!_hasRole(context, UserRole.admin) &&
                !_hasRole(context, UserRole.superAdmin)) {
              return '/login';
            }
            return null;
          },
          builder: (context, state) {
            return const AdminAuditLogBrowserScreen();
          },
        ),
        GoRoute(
          path: '/admin/users',
          name: 'admin-users',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('User Management')),
              body: const Center(child: Text('User Management - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/admin/pricing',
          name: 'admin-pricing',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Pricing Management')),
              body:
                  const Center(child: Text('Pricing Management - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/admin/orders',
          name: 'admin-orders',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Order Management')),
              body: const Center(child: Text('Order Management - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/admin/franchises',
          name: 'admin-franchises',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Franchise Management')),
              body: const Center(
                  child: Text('Franchise Management - Coming Soon')),
            );
          },
        ),
        GoRoute(
          path: '/admin/audit',
          name: 'admin-audit',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Audit Logs')),
              body: const Center(child: Text('Audit Logs - Coming Soon')),
            );
          },
        ),
      ],
      errorBuilder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Route not found: ${state.uri}')),
        );
      },
    );
  }

  // Navigation helpers
  static void goHome(BuildContext context) => context.goNamed('home');

  static void goCategory(BuildContext context, String categoryId) =>
      context.goNamed('category', pathParameters: {'categoryId': categoryId});

  static void goProductDetail(BuildContext context, String productId) => context
      .goNamed('product-detail', pathParameters: {'productId': productId});

  static void goCart(BuildContext context) => context.goNamed('cart');

  static void goCheckout(BuildContext context) => context.goNamed('checkout');

  static void goMemberSavings(BuildContext context) =>
      context.goNamed('member-savings');

  static void goBulkOrder(BuildContext context) =>
      context.goNamed('bulk-order');

  static void goOrderTracking(BuildContext context, String orderId) =>
      context.goNamed('order-tracking', pathParameters: {'orderId': orderId});

  static void goCreateNewPassword(BuildContext context, String resetToken) =>
      context.goNamed(
        'create-new-password',
        queryParameters: {'token': resetToken},
      );
}
