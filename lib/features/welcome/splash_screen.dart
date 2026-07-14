import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';
import 'package:coop_commerce/providers/auth_provider.dart' as global_auth;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;
  Timer? _failsafeTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start animation
    _controller.forward();

    // Primary navigation after a short splash display
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateBasedOnAuthStatus();
      }
    });

    // Failsafe: never allow splash to hang indefinitely
    _failsafeTimer = Timer(const Duration(seconds: 8), () async {
      if (mounted && !_hasNavigated) {
        final onboardingCompleted =
            await ref.read(onboardingCompletedProvider.future);
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        context.go(onboardingCompleted ? '/signin' : '/onboarding');
      }
    });
  }

  Future<void> _navigateBasedOnAuthStatus() async {
    if (_hasNavigated) return;

    // Wait for Firebase and the app-level profile to agree before choosing a
    // destination. This prevents stale local users from reaching role setup.
    await ref.read(authControllerProvider.future);
    await ref.read(initializePersistedUserProvider.future);
    if (!mounted || _hasNavigated) return;

    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final currentUser = ref.read(global_auth.currentUserProvider);

    // Prefer persisted app user context first; Firebase stream can lag on some devices.
    if (currentUser != null) {
      _hasNavigated = true;
      if (!currentUser.roleSelectionCompleted) {
        // Role not selected yet, go to role selection
        context.go('/role-selection');
      } else {
        // Role selected, go to home
        context.go('/');
      }
      return;
    }

    if (isAuthenticated && currentUser != null) {
      _hasNavigated = true;
      context.go(currentUser.roleSelectionCompleted ? '/' : '/role-selection');
    } else {
      final onboardingCompleted =
          await ref.read(onboardingCompletedProvider.future);
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      context.go(onboardingCompleted ? '/signin' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _failsafeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12202F), // Dark background from Figma
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                "assets/images/splash_bg.png",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image fails
                  return Container(color: const Color(0xFF12202F));
                },
              ),
            ),

            // Centered Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage("assets/images/NCDF_logo1.png"),
                        fit: BoxFit.contain,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // "Welcome to" Text
                  const Text(
                    'Welcome to',
                    style: TextStyle(
                      color: Color(0xFFFAFAFA),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // "NCDF COOP" Text
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'NCDF ',
                          style: TextStyle(
                            color: Color(0xFF98D32A), // Lime Green from Figma
                            fontSize: 36,
                            fontFamily: 'Libre Baskerville',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: 'COOP',
                          style: TextStyle(
                            color: AppColors.accent, // Matches 0xFFF3951A
                            fontSize: 36,
                            fontFamily: 'Libre Baskerville',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon({double width = 20}) {
    return Container(
      width: width,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
