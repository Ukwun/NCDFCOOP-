import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/features/home/home_screen.dart';
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

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    routes: [
      // Splash Route (Initial Screen)
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
        builder: (context, state) => const CreateNewPasswordScreen(),
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
                builder: (context, state) => const HomeScreen(),
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
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Cart Screen'))),
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
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Profile Screen'))),
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
        path: '/product/:productId',
        name: 'product-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final productId = state.pathParameters['productId'];
          return Scaffold(
            appBar: AppBar(title: const Text('Product Details')),
            body: Center(child: Text('Product: $productId')),
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Checkout')),
            body: const Center(child: Text('Checkout Screen')),
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
      GoRoute(
        path: '/order-tracking/:orderId',
        name: 'order-tracking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'];
          return Scaffold(
            appBar: AppBar(title: const Text('Order Tracking')),
            body: Center(child: Text('Tracking Order: $orderId')),
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
}
