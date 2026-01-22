import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes for error handling or navigation
    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next is AsyncData && !next.isLoading) {
        // On success, navigate to home
        // Note: In a real app, the router might listen to authStateProvider directly
        context.go('/');
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header with Back Button
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.text),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.text,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Illustration
                SizedBox(
                  height: 200,
                  child: Image.asset(
                    'assets/images/unlock illustration.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image is missing
                      return Icon(
                        Icons.lock_open_rounded,
                        size: 100,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  "Let's get you in!",
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Social Buttons
                if (isLoading)
                  const CircularProgressIndicator()
                else ...[
                  _SocialButton(
                    icon: Icons.facebook,
                    label: 'Continue with Facebook',
                    onTap: () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithFacebook(),
                  ),
                  const SizedBox(height: 16),
                  _SocialButton(
                    icon: Icons.g_mobiledata,
                    label: 'Continue with Google',
                    onTap: () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(),
                  ),
                  const SizedBox(height: 16),
                  _SocialButton(
                    icon: Icons.apple,
                    label: 'Continue with Apple',
                    onTap: () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithApple(),
                  ),
                ],

                const SizedBox(height: 30),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Or', style: AppTextStyles.bodyMedium),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),

                const SizedBox(height: 30),

                // Remember Me Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Text(
                      'Remember me',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Password Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to password sign in form
                      // context.push('/login-form');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Sign in with password',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot Password Link
                TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Up Link
                GestureDetector(
                  onTap: () {
                    context.push('/signup');
                  },
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium,
                      children: [
                        const TextSpan(text: 'Don’t have an account? '),
                        TextSpan(
                          text: 'Sign Up',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppColors.text),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
