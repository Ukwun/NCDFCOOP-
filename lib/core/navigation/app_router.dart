import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/features/home/screens/home_screen.dart';
import 'package:coop_commerce/features/auth/screens/login_screen.dart';
import 'package:coop_commerce/features/auth/screens/signup_screen.dart';
import 'package:coop_commerce/features/auth/screens/password_reset_screen.dart';
import 'package:coop_commerce/features/products/screens/product_list_screen.dart';
import 'package:coop_commerce/features/products/screens/product_detail_screen.dart';
import 'package:coop_commerce/features/cart/screens/cart_display_screen.dart';
import 'package:coop_commerce/features/checkout/screens/checkout_confirmation_screen.dart';
import 'package:coop_commerce/features/checkout/screens/payment_form_screen.dart';
import 'package:coop_commerce/features/checkout/screens/order_placed_screen.dart';
import 'package:coop_commerce/features/orders/screens/order_history_screen.dart';
import 'package:coop_commerce/features/profile/screens/user_profile_screen.dart';
import 'package:coop_commerce/features/member/notifications_center_screen.dart';

/// Navigation routes for the app
/// Uses GoRouter for type-safe, deep-linkable routing
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      // TODO: Check authentication state
      // If user not authenticated and not on auth routes, redirect to login
      // final isLoggedIn = ref.read(authProvider).isLoggedIn;
      // if (!isLoggedIn && !state.location.startsWith('/auth')) {
      //   return '/auth/login';
      // }
      return null;
    },
    routes: [
      // ==================== HOME ====================
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ==================== AUTHENTICATION ====================
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'signup',
            name: 'signup',
            builder: (context, state) => const SignupScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            builder: (context, state) {
              // Get email if passed as extra
              final email = state.extra as String?;
              return PasswordResetScreen(email: email);
            },
          ),
        ],
      ),

      // ==================== PRODUCTS ====================
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductListingScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'product-detail',
            builder: (context, state) {
              final productId = state.pathParameters['id']!;
              return ProductDetailScreen(productId: productId);
            },
          ),
        ],
      ),

      // ==================== CART ====================
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartDisplayScreen(),
      ),

      // ==================== CHECKOUT ====================
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) {
          // Get order data from extra if passed
          final orderData = state.extra as Map<String, dynamic>?;
          return CheckoutConfirmationScreen(orderData: orderData);
        },
        routes: [
          GoRoute(
            path: 'payment',
            name: 'payment',
            builder: (context, state) {
              // Get total from extra
              final total = state.extra as double? ?? 0.0;
              return PaymentFormScreen(
                totalAmount: total,
              );
            },
          ),
          GoRoute(
            path: 'success',
            name: 'order-placed',
            builder: (context, state) {
              // Get order details from extra
              final orderId = state.extra as String? ?? 'ORD-2026-001';
              return OrderPlacedScreen(orderId: orderId);
            },
          ),
        ],
      ),

      // ==================== ORDERS ====================
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),

      // ==================== NOTIFICATIONS ====================
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsCenterScreen(),
      ),

      // ==================== PROFILE ====================
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) {
          // Get userId if passed as extra
          final userId = state.extra as String?;
          return UserProfileScreen(userId: userId);
        },
      ),

      // ==================== ERROR PAGES ====================
      GoRoute(
        path: '/error-404',
        name: 'error-404',
        builder: (context, state) => const ErrorPage(
          title: 'Page Not Found',
          message: 'The page you are looking for does not exist.',
        ),
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(
      title: 'Navigation Error',
      message: state.error?.message ?? 'An unexpected error occurred',
    ),
  );
}

/// Error page for invalid routes
class ErrorPage extends StatelessWidget {
  final String title;
  final String message;

  const ErrorPage({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
