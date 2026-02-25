import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/services/auth/auth_storage_service.dart';
import 'package:coop_commerce/services/auth/firebase_auth_service.dart';

// Import auth provider
// import 'package:coop_commerce/providers/auth_provider.dart';
// import 'package:coop_commerce/core/theme/app_colors.dart';

/// Splash Screen
///
/// Displays on app startup for 2-3 seconds
/// Handles initialization and routes user to appropriate screen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeAppAndNavigate();
  }

  /// Setup fade-in animation for splash screen
  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  /// Initialize app and handle navigation
  Future<void> _initializeAppAndNavigate() async {
    try {
      // Wait for splash to display (2 seconds minimum)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Check for "Remember Me" and auto-login
      final authStorageService = AuthStorageService();
      final isRememberMeEnabled =
          await authStorageService.isRememberMeEnabled();

      if (isRememberMeEnabled) {
        try {
          final savedUser = await authStorageService.loadSavedUser();
          if (savedUser != null) {
            // User has saved credentials and Remember Me is enabled
            // User is already authenticated via Firebase
            if (mounted) {
              context.go('/home');
              return;
            }
          }
        } catch (e) {
          debugPrint('Error loading saved user: $e');
          // Clear saved credentials if loading fails
          await authStorageService.clearAll();
        }
      }

      // Check if user is authenticated
      final authService = FirebaseAuthService();
      if (authService.isUserLoggedIn) {
        // User is logged in - go to home
        if (mounted) {
          context.go('/home');
        }
      } else {
        // User not logged in - go to login
        if (mounted) {
          context.go('/auth/login');
        }
      }
    } catch (e) {
      debugPrint('Error during splash initialization: $e');
      if (mounted) {
        context.go('/auth/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A472A), // CoopCommerce green
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo (placeholder)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // App Name
              const Text(
                'CoopCommerce',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Tagline
              Text(
                'Quality Products, Fair Prices',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 60),

              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alternative Splash Screen with Lottie Animation
/// 
/// Requires: lottie: ^2.4.0 in pubspec.yaml
/// 
/// Usage:
/// ```dart
/// import 'package:lottie/lottie.dart';
/// 
/// // In build method:
/// Lottie.asset(
///   'assets/animations/splash_animation.json',
///   repeat: false,
///   onLoaded: (composition) {
///     // Animation loaded
///   },
/// )
/// ```
