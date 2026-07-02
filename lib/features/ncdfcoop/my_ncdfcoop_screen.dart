import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart'
    as auth_controller;
import 'package:coop_commerce/core/auth/role.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class MyNCDFCOOPScreen extends ConsumerWidget {
  const MyNCDFCOOPScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isInstitutionalUser =
        user?.hasRole(UserRole.institutionalBuyer) == true ||
            user?.hasRole(UserRole.institutionalApprover) == true;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: ListView(
        padding: EdgeInsets.only(bottom: 80),
        children: [
          // Test: Simple colored container
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    'M',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  user?.name ?? 'Member Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user?.email ?? 'email@example.com',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.card_membership,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membership Status',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${user?.membershipTier ?? 'Bronze'} Member',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pushNamed('membership'),
                    child: Text('Manage'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Stats
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text('24',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Orders',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text('3,250',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Points',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Menu Items
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text('My Orders'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.pushNamed('profile-orders'),
                ),
                ListTile(
                  leading: Icon(Icons.savings),
                  title: Text('Savings Account'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.pushNamed('member-savings'),
                ),
                ListTile(
                  leading: Icon(Icons.card_giftcard),
                  title: Text('Loyalty Points'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.pushNamed('my-rewards'),
                ),
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Addresses'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.pushNamed('addresses'),
                ),
                ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('Payment Methods'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.pushNamed('payment-methods'),
                ),
                if (isInstitutionalUser)
                  _buildInstitutionalToolsSection(context),
                ListTile(
                  leading: Icon(Icons.favorite),
                  title: Text('Wishlist'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.pushNamed('wishlist'),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Logout
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Logout?'),
                    content: Text('Are you sure?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            await ref
                                .read(auth_controller
                                    .authControllerProvider.notifier)
                                .signOut();
                            if (context.mounted) {
                              context.go('/signin');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Logout failed: $e')),
                              );
                            }
                          }
                        },
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionalToolsSection(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Institutional Tools',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.pie_chart_outline),
          title: Text('Monthly Budget Overview'),
          trailing: Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => context.pushNamed('institutional-budget-overview'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.group_outlined),
          title: Text('Manage Approvers'),
          trailing: Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => context.pushNamed('approval-dashboard'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.help_outline),
          title: Text('Help & Support'),
          trailing: Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => context.pushNamed('help-support'),
        ),
        const Divider(height: 24),
      ],
    );
  }
}
