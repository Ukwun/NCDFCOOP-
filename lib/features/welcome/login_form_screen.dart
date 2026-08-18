import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/core/config/social_auth_config.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'auth_provider.dart';

class LoginFormScreen extends ConsumerStatefulWidget {
  const LoginFormScreen({this.returnTo, super.key});

  final String? returnTo;

  @override
  ConsumerState<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends ConsumerState<LoginFormScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            email,
            password,
            rememberMe: _rememberMe,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'Sign in is taking too long. Check your connection and try again.',
            ),
          );
      final result = ref.read(authControllerProvider);
      if (result.hasError) throw result.error!;
      if (mounted) context.go(_safeReturnTo());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyLoginError(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyLoginError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid-credential') ||
        message.contains('wrong-password') ||
        message.contains('user-not-found')) {
      return 'The email or password is incorrect.';
    }
    if (message.contains('network') || message.contains('too long')) {
      return 'We could not reach the sign-in service. Check your connection and try again.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Sign in failed. Please try again.';
  }

  String _safeReturnTo() {
    final candidate = widget.returnTo;
    if (candidate == null ||
        !candidate.startsWith('/') ||
        candidate.startsWith('//') ||
        candidate.startsWith('/signin') ||
        candidate.startsWith('/splash')) {
      return '/';
    }
    return candidate;
  }

  Future<void> _handleSocialSignIn(Future<void> Function() action) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await action().timeout(const Duration(seconds: 30));
      final result = ref.read(authControllerProvider);
      if (result.hasError) throw result.error!;
      if (mounted) context.go(_safeReturnTo());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyLoginError(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.watch(authControllerProvider);
    final isLoading = _isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        title: Text(
          'Sign In',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email Field
                Text(
                  'Email',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Email is required';
                    }
                    if (!value!.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Password Field
                Text(
                  'Password',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Password is required';
                    }
                    if ((value?.length ?? 0) < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() => _rememberMe = value ?? true),
                  title: const Text('Keep me signed in'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                ),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot Password?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: AppTextStyles.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                if (SocialAuthConfig.isFacebookConfigured) ...[
                  _ProviderButton(
                    icon: Icons.facebook,
                    label: 'Continue with Facebook',
                    onPressed: isLoading
                        ? null
                        : () => _handleSocialSignIn(() => ref
                            .read(authControllerProvider.notifier)
                            .signInWithFacebook(rememberMe: _rememberMe)),
                  ),
                  const SizedBox(height: 12),
                ],
                _ProviderButton(
                  icon: Icons.g_mobiledata,
                  label: 'Continue with Google',
                  onPressed: isLoading
                      ? null
                      : () => _handleSocialSignIn(() => ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(rememberMe: _rememberMe)),
                ),
                const SizedBox(height: 12),
                _ProviderButton(
                  icon: Icons.apple,
                  label: 'Continue with Apple',
                  onPressed: isLoading
                      ? null
                      : () => _handleSocialSignIn(() => ref
                          .read(authControllerProvider.notifier)
                          .signInWithApple(rememberMe: _rememberMe)),
                ),
                const SizedBox(height: 24),

                // Sign Up Link
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/signup'),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: 'Don\'t have an account? '),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 26),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
