import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  // Selection state: 0 for SMS, 1 for Email
  int _selectedIndex = -1;
  final String _maskedPhone = '(555)*****67';
  final String _maskedEmail = 'sa*******er@yahoo.com';

  void _handleSubmit() {
    if (_selectedIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recovery method'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedIndex == 0) {
      // SMS Logic (Simulated with hardcoded phone for now)
      // In a real app, you'd likely ask the user to input their phone or use the one on file
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset code sent via SMS'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      // Email Logic
      ref
          .read(authControllerProvider.notifier)
          .forgotPassword('sample@email.com'); // Using sample email for UI demo
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next is AsyncData && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Go back to sign in
      }
    });

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
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/sign-in');
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Forgot password',
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Illustration
                Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/forgot password illustration.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.lock_reset,
                        size: 80,
                        color: AppColors.muted,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Select contact details to reset password with',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 24),

                // SMS Option
                _RecoveryOptionCard(
                  isSelected: _selectedIndex == 0,
                  icon: Icons.sms,
                  label: 'via SMS',
                  value: _maskedPhone,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),

                const SizedBox(height: 16),

                // Email Option
                _RecoveryOptionCard(
                  isSelected: _selectedIndex == 1,
                  icon: Icons.email,
                  label: 'via Email',
                  value: _maskedEmail,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),

                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Continue',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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

class _RecoveryOptionCard extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _RecoveryOptionCard({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFB7B7B7),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x7FD9D9D9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFB7B7B7),
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
