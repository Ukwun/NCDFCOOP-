import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../core/providers/home_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    // Show login prompt if user not authenticated
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 80,
                color: AppColors.muted,
              ),
              const SizedBox(height: 24),
              Text(
                'Sign in to view your profile',
                style: AppTextStyles.h3.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/signin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'Go to Login',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Watch real user data providers
    final memberData = ref.watch(memberDataProvider(currentUser.id));
    final userOrdersAsync = ref.watch(_userOrdersProvider(currentUser.id));

    return memberData.when(
      data: (memberInfo) {
        final displayMemberData = memberInfo ??
            MemberData(
              memberId: currentUser.id,
              tier: 'bronze',
              rewardsPoints: 0,
              lifetimePoints: 0,
              memberSince: DateTime.now(),
              isActive: true,
              discountPercentage: 0.0,
              ordersCount: 0,
              totalSpent: 0.0,
            );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                _buildHeader(context),

                // Profile Card - NOW WITH REAL USER DATA
                _buildProfileCard(currentUser, displayMemberData),

                // Real Stats Section - fetched from database
                _buildStatsSection(context, displayMemberData, currentUser.id),

                // Recent Activity - shows real order history
                userOrdersAsync.when(
                  data: (orders) => _buildActivitySection(orders),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => const SizedBox.shrink(),
                ),

                // Menu Items
                _buildMenuSection(context),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:45',
                style: AppTextStyles.h4.copyWith(color: AppColors.surface),
              ),
              Row(
                spacing: 6,
                children: [
                  _buildStatusIcon('assets/icons/signal.png'),
                  _buildStatusIcon('assets/icons/wifi.png'),
                  _buildStatusIcon('assets/icons/battery.png'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Profile',
                style: AppTextStyles.h2.copyWith(color: AppColors.surface),
              ),
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.surface,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String assetPath) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.muted, width: 0.5),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(dynamic currentUser, dynamic memberData) {
    // Calculate member days
    final daysSinceMember =
        DateTime.now().difference(memberData.memberSince).inDays;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.smList,
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Center(
              child: currentUser.photoUrl != null &&
                      currentUser.photoUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        currentUser.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primary,
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // User Name - REAL DATA
          Text(
            currentUser.name ?? 'User',
            style: AppTextStyles.h3.copyWith(color: AppColors.text),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Email - REAL DATA
          Text(
            currentUser.email ?? 'No email',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Member Badge - Shows real tier
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.accent, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Icon(Icons.star, color: AppColors.accent, size: 16),
                Text(
                  '${memberData.tier.toUpperCase()} Member • ${daysSinceMember} days',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
      BuildContext context, dynamic memberData, String userId) {
    // Real data from member info
    final totalOrders = memberData.ordersCount;
    final pointsBalance = memberData.rewardsPoints;
    final totalSavings =
        memberData.totalSpent * (memberData.discountPercentage / 100);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.subtleList,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => context.pushNamed('orders'),
            child: _StatItem(
              value: '$totalOrders',
              label: 'Orders',
              color: AppColors.primary,
            ),
          ),
          GestureDetector(
            onTap: () => context.pushNamed('my-rewards'),
            child: _StatItem(
              value: '$pointsBalance',
              label: 'Points',
              color: Colors.amber,
            ),
          ),
          GestureDetector(
            onTap: () => context.pushNamed('member-benefits'),
            child: _StatItem(
              value: '₦${totalSavings.toStringAsFixed(0)}',
              label: 'Saved',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get last 3 orders
    final recentOrders = orders.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: AppTextStyles.h3.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 12),
          ...recentOrders.map((order) {
            // Extract order data
            final orderId = order['orderId'] ?? 'N/A';
            final date =
                (order['date'] as Timestamp?)?.toDate() ?? DateTime.now();
            final amount = order['totalAmount'] ?? 0.0;
            final status = order['status'] ?? 'pending';

            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${orderId.toString().substring(0, 8).toUpperCase()}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₦${amount.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toString().toUpperCase(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _getStatusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'completed' || 'delivered' => Colors.green,
      'pending' || 'processing' => Colors.orange,
      'cancelled' => Colors.red,
      _ => AppColors.muted,
    };
  }

  Widget _buildMenuSection(BuildContext context) {
    final menuItems = [
      {
        'icon': Icons.shopping_bag_outlined,
        'label': 'My Orders',
        'subtitle': 'Track and manage orders',
        'route': 'orders',
      },
      {
        'icon': Icons.favorite_outline,
        'label': 'Saved Items',
        'subtitle': 'Your wishlist items',
        'route': 'saved-items',
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Payment Methods',
        'subtitle': 'Manage cards and wallets',
        'route': 'payment-methods',
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'Addresses',
        'subtitle': 'Delivery addresses',
        'route': 'addresses',
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'subtitle': 'Push & email preferences',
        'route': 'notifications',
      },
      {
        'icon': Icons.help_outline,
        'label': 'Help & Support',
        'subtitle': 'FAQs and contact support',
        'route': 'help-support',
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'subtitle': 'Account and app settings',
        'route': 'settings',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account & Settings',
            style: AppTextStyles.h3.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 16),
          ...menuItems.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;
            bool isLast = index == menuItems.length - 1;

            return Column(
              children: [
                _buildMenuItem(
                  icon: item['icon'],
                  label: item['label'],
                  subtitle: item['subtitle'],
                  onTap: () {
                    context.pushNamed(item['route']);
                  },
                ),
                if (!isLast)
                  Divider(
                    color: AppColors.border,
                    height: 1,
                    thickness: 1,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.muted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for displaying stats
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.muted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Provider to fetch user orders from Firestore
final _userOrdersProvider =
    FutureProvider.family<List<dynamic>, String>((ref, userId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  } catch (e) {
    print('❌ Error fetching orders: $e');
    return [];
  }
});
