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

    // A single coordinated timeline keeps startup smooth on low-end devices.
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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

    await ref.read(authControllerProvider.future);
    await ref.read(initializePersistedUserProvider.future);
    if (!mounted || _hasNavigated) return;

    final currentUser = ref.read(global_auth.currentUserProvider);
    if (currentUser != null) {
      _hasNavigated = true;
      context.go(currentUser.roleSelectionCompleted ? '/' : '/role-selection');
      return;
    }

    final onboardingCompleted =
        await ref.read(onboardingCompletedProvider.future);
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    context.go(onboardingCompleted ? '/signin' : '/onboarding');
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

            Positioned(
              top: -90,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: .12),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 18 * (1 - _controller.value)),
                  child: Transform.scale(
                    scale: .78 +
                        (.22 * Curves.elasticOut.transform(_controller.value)),
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 152,
                      height: 152,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: Tween<double>(begin: -.12, end: 1)
                                .animate(_controller),
                            child: Container(
                              width: 142,
                              height: 142,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: .7),
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF98D32A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 112,
                            height: 112,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.accent.withValues(alpha: .35),
                                  blurRadius: 28,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/coopx_launcher_source.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: MediaQuery.sizeOf(context)
                          .width
                          .clamp(260, 340)
                          .toDouble(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .18),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/coopx_brand_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'One marketplace. Every role connected.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 13,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
