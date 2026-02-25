import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/services/auth/firebase_auth_service.dart';
import 'package:coop_commerce/services/auth/auth_storage_service.dart';
import 'package:coop_commerce/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  bool obscurePassword = true;
  bool rememberMe = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final authStorageService = AuthStorageService();
      final rememberMeEnabled = await authStorageService.isRememberMeEnabled();
      if (rememberMeEnabled) {
        final credentials =
            await authStorageService.loadRememberedCredentials();
        if (credentials != null && mounted) {
          setState(() {
            emailController.text = credentials['email'] ?? '';
            rememberMe = true;
          });
        }
      }
    } catch (e) {
      // Silently fail - user can re-enter email
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _validateAndLogin() async {
    setState(() => errorMessage = null);

    // Validation
    if (emailController.text.isEmpty) {
      setState(() => errorMessage = 'Please enter your email');
      return;
    }

    if (!_isValidEmail(emailController.text)) {
      setState(() => errorMessage = 'Please enter a valid email');
      return;
    }

    if (passwordController.text.isEmpty) {
      setState(() => errorMessage = 'Please enter your password');
      return;
    }

    if (passwordController.text.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = FirebaseAuthService();
      final user = await authService.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (user != null && mounted) {
        // Save credentials if "Remember Me" is checked
        if (rememberMe) {
          final authStorageService = AuthStorageService();
          await authStorageService.saveCredentials(
            user: User(
              id: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
              photoUrl: user.photoURL,
            ),
            token: await user.getIdToken(),
            rememberMe: true,
            email: emailController.text.trim(),
            password: passwordController.text,
            provider: 'email',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Login successful!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        if (mounted) context.go('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Login failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _loginWithGoogle() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authService = FirebaseAuthService();
      final user = await authService.signInWithGoogle();

      if (user != null && mounted) {
        // Save credentials if "Remember Me" is checked
        if (rememberMe) {
          final authStorageService = AuthStorageService();
          await authStorageService.saveCredentials(
            user: User(
              id: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
              photoUrl: user.photoURL,
            ),
            token: await user.getIdToken(),
            rememberMe: true,
            provider: 'google',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Google login successful!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        if (mounted) context.go('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Google login failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _loginWithFacebook() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authService = FirebaseAuthService();
      final user = await authService.signInWithFacebook();

      if (user != null && mounted) {
        // Save credentials if "Remember Me" is checked
        if (rememberMe) {
          final authStorageService = AuthStorageService();
          await authStorageService.saveCredentials(
            user: User(
              id: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
              photoUrl: user.photoURL,
            ),
            token: await user.getIdToken(),
            rememberMe: true,
            provider: 'facebook',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Facebook login successful!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        if (mounted) context.go('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Facebook login failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _loginWithApple() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authService = FirebaseAuthService();
      final user = await authService.signInWithApple();

      if (user != null && mounted) {
        // Save credentials if "Remember Me" is checked
        if (rememberMe) {
          final authStorageService = AuthStorageService();
          await authStorageService.saveCredentials(
            user: User(
              id: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
              photoUrl: user.photoURL,
            ),
            token: await user.getIdToken(),
            rememberMe: true,
            provider: 'apple',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Apple login successful!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        if (mounted) context.go('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Apple login failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to your account to continue shopping',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Error message
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    border: Border.all(color: AppColors.error),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (errorMessage != null) const SizedBox(height: 16),

              // Email field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email Address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'your@email.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Password field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Remember Me checkbox
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() => rememberMe = value ?? false);
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Text(
                    'Remember Me',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Navigate to password reset
                    // context.push('/auth/forgot-password');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔑 Forgot password flow'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _validateAndLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or continue with',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),

              const SizedBox(height: 16),

              // Social login buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '🔵 Google',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _loginWithFacebook,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '👤 Facebook',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Apple Sign In button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isLoading ? null : _loginWithApple,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '🍎 Sign in with Apple',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign up link
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: _TapGestureRecognizer(
                          onTap: () {
                            context.push('/auth/sign-up');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapGestureRecognizer extends GestureRecognizer {
  final VoidCallback onTap;

  _TapGestureRecognizer({required this.onTap});

  @override
  void addPointer(PointerDownEvent event) {
    super.addPointer(event);
    onTap();
  }
}
