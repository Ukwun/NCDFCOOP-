import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/features/home/role_aware_home_screen.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';
import 'package:coop_commerce/providers/auth_provider.dart' as global_auth;
import 'package:coop_commerce/features/home/scaffold_with_navbar.dart';
import 'package:coop_commerce/features/welcome/welcome_screen.dart';
import 'package:coop_commerce/features/welcome/splash_screen.dart';
import 'package:coop_commerce/features/welcome/onboarding_screen.dart';
import 'package:coop_commerce/features/welcome/onboarding_screen_2.dart';
import 'package:coop_commerce/features/welcome/onboarding_screen_3.dart';
import 'package:coop_commerce/features/welcome/feature_discovery_screen.dart';
import 'package:coop_commerce/features/welcome/sign_in_screen.dart';
import 'package:coop_commerce/features/welcome/login_form_screen.dart';
import 'package:coop_commerce/features/welcome/sign_up_screen.dart';
import 'package:coop_commerce/features/auth/screens/role_selection_screen.dart';
import 'package:coop_commerce/features/welcome/forgot_password_screen.dart';
import 'package:coop_commerce/features/welcome/create_new_password_screen.dart';
import 'package:coop_commerce/features/welcome/membership_screen.dart';
import 'package:coop_commerce/features/profile/profile_screen.dart';
import 'package:coop_commerce/features/profile/saved_items_screen.dart';
import 'package:coop_commerce/features/profile/wishlist_screen.dart';
import 'package:coop_commerce/features/profile/payment_methods_screen.dart';
import 'package:coop_commerce/features/profile/add_payment_method_screen.dart';
import 'package:coop_commerce/features/profile/addresses_screen.dart';
import 'package:coop_commerce/features/profile/notifications_screen.dart';
import 'package:coop_commerce/features/profile/help_support_screen.dart';
import 'package:coop_commerce/features/profile/settings_screen.dart';
import 'package:coop_commerce/features/profile/orders_screen.dart';
import 'package:coop_commerce/features/shopping/reorder_screen.dart';
import 'package:coop_commerce/features/shopping/track_orders_screen.dart';
import 'package:coop_commerce/features/shopping/my_rewards_screen.dart';
import 'package:coop_commerce/features/products/category_products_screen.dart';
import 'package:coop_commerce/features/products/products_listing_screen.dart';
import 'package:coop_commerce/features/cart/cart_screen.dart';
import 'package:coop_commerce/features/checkout/order_confirmation_screen.dart';
import 'package:coop_commerce/features/checkout/checkout_address_screen.dart';
import 'package:coop_commerce/features/checkout/checkout_delivery_method_screen.dart';
import 'package:coop_commerce/features/checkout/checkout_payment_screen.dart';
import 'package:coop_commerce/features/checkout/checkout_confirmation_screen.dart';
import 'package:coop_commerce/features/checkout/payment_processing_screen.dart';
import 'package:coop_commerce/models/order.dart' as order_model;
import 'package:coop_commerce/features/search/search_screen.dart';
import 'package:coop_commerce/features/member/member_benefits_screen.dart';
import 'package:coop_commerce/features/member/member_loyalty_screen.dart';
import 'package:coop_commerce/features/orders/enhanced_order_tracking_screen.dart';
import 'package:coop_commerce/features/benefits/exclusive_pricing_page.dart';
import 'package:coop_commerce/features/benefits/members_only_page.dart';
import 'package:coop_commerce/features/benefits/bulk_access_page.dart';
import 'package:coop_commerce/features/benefits/flash_sales_page.dart';
import 'package:coop_commerce/features/benefits/community_dividends_page.dart';
import 'package:coop_commerce/features/premium/subscription_payment_screen.dart';
import 'package:coop_commerce/features/premium/premium_membership_page.dart';
import 'package:coop_commerce/features/products/product_detail_screen.dart';
import 'package:coop_commerce/features/support/help_center_screen.dart';
import 'package:coop_commerce/features/checkout/order_tracking_screen.dart';
import 'package:coop_commerce/features/checkout/payment_status_screen.dart';
import 'package:coop_commerce/features/dashboard/personalized_dashboard_screen.dart';
import 'package:coop_commerce/core/auth/role.dart';
// Franchise feature imports
import 'package:coop_commerce/features/franchise/franchise_screens.dart';
import 'package:coop_commerce/features/franchise/franchise_analytics_screen.dart';
import 'package:coop_commerce/features/franchise/franchise_staff_screen.dart';
import 'package:coop_commerce/features/franchise/franchise_inventory_screen.dart';
import 'package:coop_commerce/features/franchise/franchise_store_management_screen.dart';
import 'package:coop_commerce/features/franchise/store_staff_pos_screen.dart';
import 'package:coop_commerce/features/franchise/store_staff_daily_sales_screen.dart';
import 'package:coop_commerce/features/franchise/store_staff_stock_adjustment_screen.dart';
import 'package:coop_commerce/features/franchise/franchisee_product_upload_screen.dart';
import 'package:coop_commerce/features/franchise/franchisee_product_management_screen.dart';
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
// Warehouse feature imports
import 'package:coop_commerce/features/warehouse/warehouse_packing_slip_screen.dart';
import 'package:coop_commerce/features/warehouse/warehouse_shipment_creation_screen.dart';
// Institutional Approver feature imports
import 'package:coop_commerce/features/institutional/approval_dashboard_screen.dart';
import 'package:coop_commerce/features/institutional/po_approval_interface_screen.dart';
import 'package:coop_commerce/features/institutional/approval_history_screen.dart';
// Store Manager Analytics feature imports
import 'package:coop_commerce/features/store_manager/store_manager_dashboard_screen.dart';
import 'package:coop_commerce/features/store_manager/product_performance_screen.dart';
import 'package:coop_commerce/features/store_manager/staff_performance_screen.dart';
import 'package:coop_commerce/features/store_manager/inventory_health_screen.dart';
// Analytics, Invoice, and Review feature imports
import 'package:coop_commerce/features/admin/analytics_dashboard_screen.dart';
import 'package:coop_commerce/features/orders/invoice_preview_screen.dart';
import 'package:coop_commerce/features/products/product_reviews_screen.dart';
// Educational feature imports
import 'package:coop_commerce/features/education/about_cooperatives_screen.dart';
import 'package:coop_commerce/features/education/features_guide_screen.dart';
import 'package:coop_commerce/features/education/app_tour_screen.dart';
// Phase 4: Search, Review, Inventory, and Logistics imports
import 'package:coop_commerce/features/inventory/inventory_dashboard_screen.dart';
import 'package:coop_commerce/features/inventory/warehouse_management_screen.dart';
import 'package:coop_commerce/features/inventory/reorder_management_screen.dart';
import 'package:coop_commerce/features/shipping/shipment_tracking_screen.dart';

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
  '/franchise/compliance': {UserRole.franchiseOwner, UserRole.storeManager},

  // Institutional/B2B routes
  '/institutional': {
    UserRole.institutionalBuyer,
    UserRole.institutionalApprover,
  },
  '/institutional/purchase-orders': {
    UserRole.institutionalBuyer,
    UserRole.institutionalApprover,
  },
  '/institutional/purchase-orders/create': {UserRole.institutionalBuyer},
  '/institutional/invoices': {
    UserRole.institutionalBuyer,
    UserRole.institutionalApprover,
  },

  // Warehouse routes
  '/warehouse': {UserRole.warehouseStaff},
  '/warehouse/tasks': {UserRole.warehouseStaff},

  // Driver routes
  '/driver': {UserRole.deliveryDriver},
  '/driver/route': {UserRole.deliveryDriver},

  // Admin routes
  '/admin': {UserRole.admin, UserRole.superAdmin},
  '/admin/users': {UserRole.admin, UserRole.superAdmin},
  '/admin/pricing': {UserRole.admin, UserRole.superAdmin},
  '/admin/orders': {UserRole.admin, UserRole.superAdmin},
  '/admin/franchises': {UserRole.admin, UserRole.superAdmin},
  '/admin/audit': {UserRole.admin, UserRole.superAdmin},
  '/admin/analytics': {UserRole.admin, UserRole.superAdmin},
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
    return _routeRoleRequirements['/institutional/invoices']!.any(
      (role) => userRoles.contains(role),
    );
  }

  // Route doesn't require specific role, allow all authenticated users
  return true;
}

/// Helper to check if user has a specific role in the current context
/// Note: This is used in route redirects where context access is limited
bool _hasRole(BuildContext context, UserRole requiredRole) {
  // This is a placeholder - in real implementation, you'd extract user info from context
  // For now, we return true to allow the router logic to handle it
  // Implementation will use AuthStateProvider when available
  return true;
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

Widget _buildSavingsItem(String category, String range, String percentage) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              range,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Save $percentage',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    ),
  );
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

        // IMPORTANT: Use currentUserProvider for fresh in-memory user state
        // This ensures role selection changes are immediately reflected
        final currentUser = ref.watch(global_auth.currentUserProvider);

        final isOnPublicRoute = state.uri.path == '/welcome' ||
            state.uri.path == '/signin' ||
            state.uri.path.startsWith('/signup') ||
            state.uri.path == '/splash' ||
            state.uri.path.startsWith('/onboarding') ||
            state.uri.path == '/forgot-password' ||
            state.uri.path == '/create-new-password' ||
            state.uri.path == '/about-cooperatives' ||
            state.uri.path == '/features-guide' ||
            state.uri.path == '/app-tour' ||
            state.uri.path == '/help-center' ||
            state.uri.path == '/role-selection';

        // While auth state is loading, stay on splash/welcome
        if (authState.isLoading) {
          if (!isOnPublicRoute) {
            return '/splash';
          }
          return null;
        }

        // If auth state has an error, redirect to splash
        if (authState.hasError) {
          debugPrint('Auth state error: ${authState.error}');
          if (!isOnPublicRoute) {
            return '/splash';
          }
          return null;
        }

        // Redirect to signin if not authenticated and not on public route
        if (!isAuthenticated && !isOnPublicRoute) {
          return '/signin';
        }

        // Only redirect to home if authenticated and on welcome route
        // Allow authenticated users to navigate to signin/signup (maybe to switch accounts)
        if (isAuthenticated && state.uri.path == '/welcome') {
          return '/';
        }

        // If authenticated but hasn't completed role selection, send to role-selection
        // (unless they're already on it or on a public route)
        // Use currentUser (fresh in-memory state) for role selection check
        if (isAuthenticated &&
            currentUser != null &&
            !currentUser.roleSelectionCompleted &&
            !isOnPublicRoute) {
          return '/role-selection';
        }

        // Check role-based permissions for protected routes
        // Use currentUser for role-based permission checks
        if (isAuthenticated && currentUser != null && !isOnPublicRoute) {
          final currentPath = state.uri.path;
          final userRolesSet = currentUser.roles.toSet();

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

        // Feature Discovery Route
        GoRoute(
          path: '/feature-discovery',
          name: 'feature-discovery',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const FeatureDiscoveryScreen(),
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
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SignInScreen(),
        ),

        // Login Form Route
        GoRoute(
          path: '/login-form',
          name: 'login-form',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const LoginFormScreen(),
        ),

        // Sign Up Route (without type - default to member)
        GoRoute(
          path: '/signup',
          name: 'signup',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            // Check if type is in query parameters
            final membershipType =
                state.uri.queryParameters['type'] ?? 'member';
            return SignUpScreen(membershipType: membershipType);
          },
        ),

        // Sign Up Route with Type Parameter
        GoRoute(
          path: '/signup/:type',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final membershipType = state.pathParameters['type'] ?? 'member';
            return SignUpScreen(membershipType: membershipType);
          },
        ),

        // Role Selection Screen (appears after signup)
        GoRoute(
          path: '/role-selection',
          name: 'role-selection',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final userId = extra?['userId'] ?? '';
            final userEmail = extra?['userEmail'] ?? '';
            final userName = extra?['userName'] ?? 'User';

            return RoleSelectionScreen(
              userId: userId,
              userEmail: userEmail,
              userName: userName,
            );
          },
        ),

        // Forgot Password Route
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Create New Password Route
        GoRoute(
          path: '/create-new-password',
          name: 'create-new-password',
          parentNavigatorKey: _rootNavigatorKey,
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

        // Member Loyalty Route
        GoRoute(
          path: '/member/loyalty',
          name: 'member-loyalty',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const MemberLoyaltyScreen(),
        ),

        // Products Routes
        GoRoute(
          path: '/products',
          name: 'products',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) =>
              const ProductsListingScreen(title: 'All Products'),
        ),

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
          builder: (context, state) =>
              const ProductsListingScreen(title: 'Buy Again'),
        ),

        GoRoute(
          path: '/essentials',
          name: 'essentials',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) =>
              const ProductsListingScreen(title: 'Essentials Basket'),
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

        // Delivery Tracking Route
        GoRoute(
          path: '/orders/tracking',
          name: 'delivery-tracking',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) =>
              const EnhancedOrderTrackingScreen(orderId: 'ORD-2026-001234'),
        ),

        // Phase 4: Shipment Tracking Route (New)
        GoRoute(
          path: '/shipments/tracking',
          name: 'shipment-tracking',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            // Get userId from auth provider (will be passed from profile)
            // For now, we'll use a placeholder that can be overridden
            final userId =
                state.uri.queryParameters['userId'] ?? 'current_user';
            return ShipmentTrackingScreen(memberId: userId);
          },
        ),

        // Phase 4: Inventory Management Routes (Admin/Staff)
        GoRoute(
          path: '/admin/inventory/dashboard',
          name: 'inventory-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const InventoryDashboardScreen(),
        ),

        GoRoute(
          path: '/admin/inventory/warehouse/:locationId',
          name: 'warehouse-management',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final locationId = state.pathParameters['locationId'] ?? '';
            return WarehouseManagementScreen(locationId: locationId);
          },
        ),

        GoRoute(
          path: '/admin/inventory/reorder',
          name: 'reorder-management',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final locationId = state.uri.queryParameters['locationId'];
            return ReorderManagementScreen(locationId: locationId);
          },
        ),

        // Phase 4: Product Reviews Route
        GoRoute(
          path: '/product/:productId/reviews',
          name: 'product-reviews',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final productId = state.pathParameters['productId'] ?? '';
            final productName = state.uri.queryParameters['name'] ?? 'Product';
            return ProductReviewsScreen(
              productId: productId,
              productName: productName,
            );
          },
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
          path: '/add-payment-method',
          name: 'add-payment-method',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AddPaymentMethodScreen(),
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

        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const PersonalizedDashboardScreen(),
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
        // Redirect /home to root
        GoRoute(
          path: '/home',
          redirect: (context, state) => '/',
        ),
        // Other routes (pushed on top of the shell)
        GoRoute(
          path: '/wishlist',
          name: 'wishlist',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const WishlistScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
          ),
        ),
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
            child: const CartScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/checkout/address',
          name: 'checkout-address',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CheckoutAddressScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/checkout/delivery',
          name: 'checkout-delivery',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CheckoutDeliveryMethodScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/checkout/payment',
          name: 'checkout-payment',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CheckoutPaymentScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/checkout/confirmation',
          name: 'checkout-confirmation',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CheckoutConfirmationScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/payment-processing',
          name: 'payment-processing',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PaymentProcessingScreen(
                orderId: extra?['orderId'] ?? '',
                amount: extra?['amount'] ?? 0.0,
                paymentMethod: extra?['paymentMethod'] ?? 'credit_card',
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/payment-success',
          name: 'payment-success',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PaymentSuccessScreen(
                orderId: extra?['orderId'] ?? '',
                transactionId: extra?['transactionId'] ?? '',
                amount: extra?['amount'] ?? 0.0,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/payment-failure',
          name: 'payment-failure',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PaymentFailureScreen(
                orderId: extra?['orderId'] ?? '',
                errorMessage:
                    extra?['errorMessage'] ?? 'Payment processing failed',
                amount: extra?['amount'] ?? 0.0,
                onRetry: () => context.go('/checkout/confirmation'),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                );
              },
            );
          },
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
              child: OrderConfirmationScreen(orderId: order.id),
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
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
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
              appBar: AppBar(
                title: const Text('Member Savings'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category Savings',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildSavingsItem('Oils & Fats',
                              '₦5,000 - ₦8,000 per item', '15-18%'),
                          const SizedBox(height: 12),
                          _buildSavingsItem(
                              'Proteins', '₦3,500 - ₦9,500 per item', '12-15%'),
                          const SizedBox(height: 12),
                          _buildSavingsItem('Vegetables',
                              '₦1,000 - ₦3,000 per item', '10-14%'),
                          const SizedBox(height: 12),
                          _buildSavingsItem('Grains & Staples',
                              '₦2,000 - ₦15,000 per item', '12-16%'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Annual Savings',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '₦450,000+',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Average savings for members across all categories',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF558B2F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
          builder: (context, state) => const ReorderScreen(),
        ),
        GoRoute(
          path: '/track-orders',
          name: 'track-orders',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const TrackOrdersScreen(),
        ),
        GoRoute(
          path: '/my-rewards',
          name: 'my-rewards',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const MyRewardsScreen(),
        ),
        GoRoute(
          path: '/help-center',
          name: 'help-center',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const HelpCenterScreen(),
        ),
        // Educational routes
        GoRoute(
          path: '/about-cooperatives',
          name: 'about-cooperatives',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AboutCooperativesScreen(),
        ),
        GoRoute(
          path: '/features-guide',
          name: 'features-guide',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const FeaturesGuideScreen(),
        ),
        GoRoute(
          path: '/app-tour',
          name: 'app-tour',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AppTourScreen(),
        ),
        GoRoute(
          path: '/subscription-payment/:tier',
          name: 'subscription-payment',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final tier = state.pathParameters['tier'] ?? 'gold';
            return SubscriptionPaymentScreen(tier: tier);
          },
        ),
        GoRoute(
          path: '/product/:productId',
          name: 'product-detail',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final productId = state.pathParameters['productId'] ?? '';
            final productData = state.extra as Map<String, dynamic>?;
            return ProductDetailScreen(
              productId: productId,
              productData: productData,
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

        // FRANCHISEE PRODUCT MANAGEMENT ROUTES
        GoRoute(
          path: '/franchisee/products',
          name: 'franchisee-products',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const FranchiseeProductManagementScreen();
          },
        ),
        GoRoute(
          path: '/franchisee/products/upload',
          name: 'franchisee-products-upload',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const FranchiseeProductUploadScreen();
          },
        ),

        // STORE STAFF ROUTES - Requires storeStaff
        GoRoute(
          path: '/store-staff/pos',
          name: 'store-staff-pos',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            final storeName = state.uri.queryParameters['storeName'] ?? 'Store';
            return StoreStaffPOSScreen(
              storeId: storeId,
              storeName: storeName,
            );
          },
        ),
        GoRoute(
          path: '/store-staff/daily-sales',
          name: 'store-staff-daily-sales',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            final storeName = state.uri.queryParameters['storeName'] ?? 'Store';
            return StoreStaffDailySalesScreen(
              storeId: storeId,
              storeName: storeName,
            );
          },
        ),
        GoRoute(
          path: '/store-staff/stock-adjustment',
          name: 'store-staff-stock-adjustment',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            final storeName = state.uri.queryParameters['storeName'] ?? 'Store';
            return StoreStaffStockAdjustmentScreen(
              storeId: storeId,
              storeName: storeName,
            );
          },
        ),
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
                child: Text('Purchase Orders List - Coming Soon'),
              ),
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
            // poId extracted from path but not currently used by InstitutionalApprovalWorkflowScreen
            return const InstitutionalApprovalWorkflowScreen();
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
                child: Text('Warehouse Dashboard - Coming Soon'),
              ),
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
        GoRoute(
          path: '/warehouse/packing-slip',
          name: 'warehouse-packing-slip',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final warehouseId = state.uri.queryParameters['warehouseId'] ?? '';
            final warehouseName =
                state.uri.queryParameters['warehouseName'] ?? 'Warehouse';
            final pickListId = state.uri.queryParameters['pickListId'] ?? '';
            final orderId = state.uri.queryParameters['orderId'] ?? '';
            return WarehousePackingSlipScreen(
              warehouseId: warehouseId,
              warehouseName: warehouseName,
              pickListId: pickListId,
              orderId: orderId,
            );
          },
        ),
        GoRoute(
          path: '/warehouse/shipment',
          name: 'warehouse-shipment',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final warehouseId = state.uri.queryParameters['warehouseId'] ?? '';
            final warehouseName =
                state.uri.queryParameters['warehouseName'] ?? 'Warehouse';
            return WarehouseShipmentCreationScreen(
              warehouseId: warehouseId,
              warehouseName: warehouseName,
            );
          },
        ),
        // Institutional Approver Routes
        GoRoute(
          path: '/institutional/approvals',
          name: 'approval-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const ApprovalDashboardScreen();
          },
        ),
        GoRoute(
          path: '/institutional/po-approval',
          name: 'po-approval-interface',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final poId = state.uri.queryParameters['poId'] ?? '';
            final poNumber = state.uri.queryParameters['poNumber'] ?? '';
            final poAmount =
                double.tryParse(state.uri.queryParameters['poAmount'] ?? '0') ??
                    0.0;
            final vendorName =
                state.uri.queryParameters['vendorName'] ?? 'Vendor';
            final departmentName =
                state.uri.queryParameters['departmentName'] ?? 'Department';
            final description =
                state.uri.queryParameters['description'] ?? 'N/A';

            return POApprovalInterfaceScreen(
              poId: poId,
              poNumber: poNumber,
              poAmount: poAmount,
              vendorName: vendorName,
              departmentName: departmentName,
              description: description,
            );
          },
        ),
        GoRoute(
          path: '/institutional/approval-history',
          name: 'approval-history',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final poId = state.uri.queryParameters['poId'] ?? '';
            final poNumber = state.uri.queryParameters['poNumber'] ?? '';

            return ApprovalHistoryScreen(
              poId: poId,
              poNumber: poNumber,
            );
          },
        ),
        // Store Manager Analytics Routes
        GoRoute(
          path: '/store-manager/dashboard',
          name: 'store-manager-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            final storeName = state.uri.queryParameters['storeName'] ?? 'Store';

            return StoreManagerDashboardScreen(
              storeId: storeId,
              storeName: storeName,
            );
          },
        ),
        GoRoute(
          path: '/store-manager/products',
          name: 'product-performance',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            final storeName = state.uri.queryParameters['storeName'] ?? 'Store';

            return ProductPerformanceScreen(
              storeId: storeId,
              storeName: storeName,
            );
          },
        ),
        GoRoute(
          path: '/store-manager/staff',
          name: 'staff-performance',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            final storeName = state.uri.queryParameters['storeName'] ?? 'Store';

            return StaffPerformanceScreen(
              storeId: storeId,
              storeName: storeName,
            );
          },
        ),
        GoRoute(
          path: '/store-manager/inventory',
          name: 'inventory-health',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final storeId = state.uri.queryParameters['storeId'] ?? '';
            final storeName = state.uri.queryParameters['storeName'] ?? 'Store';

            return InventoryHealthScreen(
              storeId: storeId,
              storeName: storeName,
            );
          },
        ),
        // Analytics, Invoice, and Review routes
        GoRoute(
          path: '/admin/analytics',
          name: 'analytics-dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const AnalyticsDashboardScreen();
          },
        ),
        GoRoute(
          path: '/order/:orderId/invoice',
          name: 'order-invoice',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final orderId = state.pathParameters['orderId'] ?? '';
            final orderType =
                state.uri.queryParameters['orderType'] ?? 'retail';

            return InvoicePreviewScreen(
              orderId: orderId,
              orderType: orderType,
            );
          },
        ),
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
          path: '/admin/pricing',
          name: 'admin-pricing',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(title: const Text('Pricing Management')),
              body: const Center(
                child: Text('Pricing Management - Coming Soon'),
              ),
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
                child: Text('Franchise Management - Coming Soon'),
              ),
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
        GoRoute(
          path: '/admin/analytics',
          name: 'admin-analytics',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            return const AnalyticsDashboardScreen();
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

  static void goCheckoutAddress(BuildContext context) =>
      context.goNamed('checkout-address');

  static void goCheckoutPayment(BuildContext context) =>
      context.goNamed('checkout-payment');

  static void goCheckoutConfirmation(BuildContext context) =>
      context.goNamed('checkout-confirmation');

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
