import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Centralized route definitions for the entire app
/// This ensures consistency across all navigation
class AppRoutes {
  // Authentication routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String splash = '/';

  // Consumer routes
  static const String home = '/home';
  static const String products = '/products';
  static const String productDetail = '/products/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String tracking = '/tracking/:id';
  static const String profile = '/profile';
  static const String savedItems = '/saved-items';
  static const String address = '/address';
  static const String settings = '/settings';
  static const String support = '/support';

  // Member routes
  static const String benefits = '/benefits';
  static const String benefitDetail = '/benefits/:id';
  static const String voting = '/voting';
  static const String proposal = '/proposal/:id';
  static const String reports = '/reports';

  // Franchise routes
  static const String franchiseHome = '/franchise/home';
  static const String franchiseDashboard = '/franchise/dashboard';
  static const String franchiseInventory = '/franchise/inventory';
  static const String franchiseSales = '/franchise/sales';
  static const String franchiseCompliance = '/franchise/compliance';
  static const String franchiseSettings = '/franchise/settings';
  static const String franchiseStaff = '/franchise/staff';
  static const String franchiseStaffDetail = '/franchise/staff/:id';
  static const String franchiseReports = '/franchise/reports';

  // Warehouse routes
  static const String warehouseHome = '/warehouse/home';
  static const String warehouseTasks = '/warehouse/tasks';
  static const String warehouseQueue = '/warehouse/queue';
  static const String warehouseQc = '/warehouse/qc';
  static const String warehouseReports = '/warehouse/reports';
  static const String pickTask = '/warehouse/pick/:id';
  static const String packTask = '/warehouse/pack/:id';
  static const String qcTask = '/warehouse/qc/:id';

  // Driver routes
  static const String driverHome = '/driver/home';
  static const String driverRoute = '/driver/route';
  static const String driverDeliveries = '/driver/deliveries';
  static const String driverDeliveryDetail = '/driver/deliveries/:id';
  static const String driverChat = '/driver/chat';
  static const String driverSettings = '/driver/settings';
  static const String driverMap = '/driver/map';
  static const String deliveryProof = '/driver/proof/:id';

  // Institutional (B2B) routes
  static const String institutionalHome = '/institutional/home';
  static const String institutionalCatalog = '/institutional/catalog';
  static const String institutionalPo = '/institutional/po';
  static const String poCreation = '/institutional/po/create';
  static const String poDetail = '/institutional/po/:id';
  static const String poApproval = '/institutional/po/:id/approval';
  static const String institutionalOrders = '/institutional/orders';
  static const String institutionalOrderDetail = '/institutional/orders/:id';
  static const String institutionalInvoices = '/institutional/invoices';
  static const String invoiceDetail = '/institutional/invoices/:id';
  static const String contracts = '/institutional/contracts';
  static const String contractDetail = '/institutional/contracts/:id';

  // Admin routes
  static const String adminHome = '/admin/home';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/:id';
  static const String adminPricing = '/admin/pricing';
  static const String adminOrders = '/admin/orders';
  static const String adminFranchises = '/admin/franchises';
  static const String adminFranchiseDetail = '/admin/franchises/:id';
  static const String adminInstitutions = '/admin/institutions';
  static const String adminInstitutionDetail = '/admin/institutions/:id';
  static const String adminReports = '/admin/reports';
  static const String adminCompliance = '/admin/compliance';
  static const String adminAudit = '/admin/audit';
  static const String adminSettings = '/admin/settings';
}

/// Route parameters
class RouteParams {
  static String idFromPath(String path) {
    return path.split('/').last;
  }

  static String poIdFromPath(String path) {
    final parts = path.split('/');
    // Path: /institutional/po/:id/approval
    return parts[parts.length - 2];
  }
}

/// Navigation context - use this instead of context.go() for type safety
class AppNavigation {
  static void goHome(BuildContext context) => context.go(AppRoutes.home);
  static void goProducts(BuildContext context) =>
      context.go(AppRoutes.products);
  static void goCart(BuildContext context) => context.go(AppRoutes.cart);
  static void goOrders(BuildContext context) => context.go(AppRoutes.orders);
  static void goProfile(BuildContext context) => context.go(AppRoutes.profile);

  // Product routes
  static void goProductDetail(BuildContext context, String productId) {
    context.go(AppRoutes.productDetail.replaceFirst(':id', productId));
  }

  // Order routes
  static void goOrderDetail(BuildContext context, String orderId) {
    context.go(AppRoutes.orderDetail.replaceFirst(':id', orderId));
  }

  static void goTracking(BuildContext context, String orderId) {
    context.go(AppRoutes.tracking.replaceFirst(':id', orderId));
  }

  // Franchise routes
  static void goFranchiseDashboard(BuildContext context) {
    context.go(AppRoutes.franchiseDashboard);
  }

  static void goFranchiseInventory(BuildContext context) {
    context.go(AppRoutes.franchiseInventory);
  }

  static void goFranchiseCompliance(BuildContext context) {
    context.go(AppRoutes.franchiseCompliance);
  }

  // Warehouse routes
  static void goWarehouseTasks(BuildContext context) {
    context.go(AppRoutes.warehouseTasks);
  }

  static void goPickTask(BuildContext context, String taskId) {
    context.go(AppRoutes.pickTask.replaceFirst(':id', taskId));
  }

  // Driver routes
  static void goDriverRoute(BuildContext context) {
    context.go(AppRoutes.driverRoute);
  }

  static void goDeliveryDetail(BuildContext context, String deliveryId) {
    context.go(AppRoutes.driverDeliveryDetail.replaceFirst(':id', deliveryId));
  }

  // Institutional routes
  static void goInstitutionalCatalog(BuildContext context) {
    context.go(AppRoutes.institutionalCatalog);
  }

  static void goPoCreation(BuildContext context) {
    context.go(AppRoutes.poCreation);
  }

  static void goPoDetail(BuildContext context, String poId) {
    context.go(AppRoutes.poDetail.replaceFirst(':id', poId));
  }

  static void goPoApproval(BuildContext context, String poId) {
    context.go(AppRoutes.poApproval.replaceFirst(':id', poId));
  }

  // Admin routes
  static void goAdminUsers(BuildContext context) {
    context.go(AppRoutes.adminUsers);
  }

  static void goAdminOrders(BuildContext context) {
    context.go(AppRoutes.adminOrders);
  }

  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

/// Deep link handler
class DeepLinkHandler {
  static String? getDeepLink(Uri uri) {
    switch (uri.host) {
      case 'product':
        return AppRoutes.productDetail.replaceFirst(':id', uri.pathSegments[1]);
      case 'order':
        return AppRoutes.orderDetail.replaceFirst(':id', uri.pathSegments[1]);
      case 'tracking':
        return AppRoutes.tracking.replaceFirst(':id', uri.pathSegments[1]);
      case 'po':
        return AppRoutes.poDetail.replaceFirst(':id', uri.pathSegments[1]);
      default:
        return null;
    }
  }
}

/// Route transition animations
class AppRouteTransitions {
  static PageRoute<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static PageRoute<T> slideTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  static PageRoute<T> scaleTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(scale: animation, child: child);
      },
    );
  }
}

/// Error page for undefined routes
class UndefinedRoutePage extends StatelessWidget {
  final String? location;

  const UndefinedRoutePage({this.location, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (location != null) ...[
              const SizedBox(height: 8),
              Text('Route: $location'),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
