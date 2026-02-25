import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/auth/role.dart';
import '../../welcome/auth_provider.dart';

/// Role Selection Screen
///
/// Appears immediately after signup to let users choose their primary role.
/// This is a critical step in the onboarding journey - it determines what
/// features, pricing, and experience they see in the app.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;

  const RoleSelectionScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
  });

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  final List<_RoleOptionModel> roleOptions = [
    _RoleOptionModel(
      role: UserRole.consumer,
      title: '🛍️ Regular Shopper',
      subtitle: 'Shop individually with retail pricing',
      description:
          'Perfect for personal shopping. Browse our full catalog of groceries, products, and essentials with convenient retail pricing.',
      benefits: [
        '✓ Personal shopping cart',
        '✓ Fast checkout',
        '✓ Home delivery',
        '✓ Easy returns',
      ],
      color: const Color(0xFF6B5B95),
      icon: Icons.shopping_cart_outlined,
    ),
    _RoleOptionModel(
      role: UserRole.coopMember,
      title: '🤝 Cooperative Member',
      subtitle: 'Join our community & get wholesale prices',
      description:
          'Become part of our cooperative. Buy in bulk, earn loyalty rewards, share profits, and have a voice in community decisions.',
      benefits: [
        '✓ Wholesale pricing (10-30% off)',
        '✓ Loyalty points & rewards',
        '✓ Share yearly profits',
        '✓ Vote on cooperative decisions',
        '✓ Team ordering features',
        '✓ Priority customer support',
      ],
      color: const Color(0xFF8B6F47),
      icon: Icons.people_alt_outlined,
    ),
    _RoleOptionModel(
      role: UserRole.institutionalBuyer,
      title: '🏢 Wholesale Buyer',
      subtitle: 'For businesses, institutions & bulk orders',
      description:
          'For companies, schools, hospitals, and organizations. Get wholesale pricing, bulk discounts, flexible payment terms, and dedicated support.',
      benefits: [
        '✓ Wholesale bulk pricing',
        '✓ Multiple delivery locations',
        '✓ Flexible payment terms',
        '✓ Dedicated account manager',
        '✓ Custom pricing agreements',
        '✓ Invoice billing available',
      ],
      color: const Color(0xFF2E5090),
      icon: Icons.business_outlined,
    ),
  ];

  void _selectRole(UserRole role) {
    setState(() => _selectedRole = role);
  }

  Future<void> _continue() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role to continue'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    print('🔄 Starting role selection for: $_selectedRole');

    try {
      // Update the user's role in the auth controller
      // This will persist the role to local storage and update the current user
      print('📝 Calling selectUserRole for: ${_selectedRole!.name}');
      await ref
          .read(authControllerProvider.notifier)
          .selectUserRole(_selectedRole!);

      print('✅ Role selection completed successfully');

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        print('🚀 Navigating to /home');
        // Navigate to home - the role-aware home screen will use the user's new role
        context.go('/');
      }
    } catch (e) {
      print('❌ Error during role selection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        print('🛑 Loading stopped');
      }
    }
  }

  Future<void> _skipForNow() async {
    // Allow users to skip and use as consumer by default
    context.go('/home', extra: {'selectedRole': UserRole.consumer});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Choose Your Experience',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: _skipForNow,
          child: const Icon(
            Icons.close,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header description
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Welcome, ${widget.userName}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How would you like to use CoopCommerce? Each option gives you a personalized experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Role options
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: roleOptions.length,
                itemBuilder: (context, index) {
                  final option = roleOptions[index];
                  final isSelected = _selectedRole == option.role;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => _selectRole(option.role),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? option.color
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: isSelected
                              ? option.color.withOpacity(0.05)
                              : Colors.white,
                        ),
                        child: Column(
                          children: [
                            // Header with icon and checkbox
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: option.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      option.icon,
                                      color: option.color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          option.subtitle,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? option.color
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            size: 14,
                                            color: option.color,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),

                            // Divider
                            Container(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),

                            // Description and benefits
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...option.benefits.map(
                                    (benefit) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        benefit,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedRole != null
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Skip for now
                  GestureDetector(
                    onTap: _skipForNow,
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.underline,
                      ),
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
}

/// Model for role selection options
class _RoleOptionModel {
  final UserRole role;
  final String title;
  final String subtitle;
  final String description;
  final List<String> benefits;
  final Color color;
  final IconData icon;

  _RoleOptionModel({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.benefits,
    required this.color,
    required this.icon,
  });
}
