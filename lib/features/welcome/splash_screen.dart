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

    // Navigate after 2 seconds based on auth status
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateBasedOnAuthStatus();
      }
    });
  }

  void _navigateBasedOnAuthStatus() {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final currentUser = ref.read(global_auth.currentUserProvider);

    if (isAuthenticated && currentUser != null) {
      // User is authenticated
      if (!currentUser.roleSelectionCompleted) {
        // Role not selected yet, go to role selection
        context.go('/role-selection');
      } else {
        // Role selected, go to home
        context.go('/');
      }
    } else {
      // User is not authenticated, show onboarding
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
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

            // Status Bar (Simulated to match design)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '9:45',
                        style: TextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          _buildStatusIcon(),
                          const SizedBox(width: 6),
                          _buildStatusIcon(),
                          const SizedBox(width: 6),
                          _buildStatusIcon(width: 30),
                        ],
                      ),
                    ],
                  ),
                ),
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
