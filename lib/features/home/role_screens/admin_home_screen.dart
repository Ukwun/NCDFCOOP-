import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/core/providers/home_providers.dart';
import 'package:coop_commerce/core/providers/order_providers.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final metrics = ref.watch(systemMetricsProvider);
    final pendingApprovals =
        ref.watch(pendingApprovalsCountProvider(user?.id ?? ''));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Admin Panel - ${user?.name ?? "Admin"}',
          style: TextStyle(color: Colors.grey[800], fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: metrics.when(
          data: (data) => Column(
            children: [
              // System Status Banner
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Status',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Systems',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Operating Normally',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Quick Metrics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Platform Metrics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _MetricCard(
                    title: 'Active Users',
                    value: '${data.activeUsers}',
                    icon: Icons.people_outline,
                  ),
                  _MetricCard(
                    title: 'Total Orders',
                    value: '${data.totalOrders}',
                    icon: Icons.shopping_cart_outlined,
                  ),
                  _MetricCard(
                    title: 'Revenue',
                    value: '₦${(data.totalRevenue / 1000).toStringAsFixed(1)}K',
                    icon: Icons.attach_money_outlined,
                  ),
                  _MetricCard(
                    title: 'Pending Approvals',
                    value: '${data.pendingApprovals}',
                    icon: Icons.assignment_outlined,
                  ),
                  _MetricCard(
                    title: 'This Month Orders',
                    value: '${data.ordersThisMonth}',
                    icon: Icons.trending_up_outlined,
                  ),
                  _MetricCard(
                    title: 'New Users',
                    value: '${data.newUsersThisMonth}',
                    icon: Icons.person_add_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Admin Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Management',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _AdminControlCard(
                      title: 'User Management',
                      subtitle: 'Manage users and permissions',
                      icon: Icons.admin_panel_settings_outlined,
                      onTap: () => context.push('/admin/users'),
                    ),
                    _AdminControlCard(
                      title: 'Order Management',
                      subtitle: 'View and manage all orders',
                      icon: Icons.assignment_outlined,
                      count: data.ordersThisMonth,
                      onTap: () => context.push('/admin/orders'),
                    ),
                    _AdminControlCard(
                      title: 'Pending Approvals',
                      subtitle: 'Review and approve orders',
                      icon: Icons.approval_outlined,
                      count: data.pendingApprovals,
                      onTap: () => context.push('/admin/approvals'),
                    ),
                    _AdminControlCard(
                      title: 'Franchise Management',
                      subtitle: 'Manage franchise partners',
                      icon: Icons.store_outlined,
                      onTap: () => context.push('/franchise'),
                    ),
                    _AdminControlCard(
                      title: 'Content Management',
                      subtitle: 'Update products and categories',
                      icon: Icons.inventory_2_outlined,
                      onTap: () => context.push('/admin/products'),
                    ),
                    _AdminControlCard(
                      title: 'Reports & Analytics',
                      subtitle: 'View detailed analytics',
                      icon: Icons.analytics_outlined,
                      onTap: () => context.push('/admin/analytics'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text('Error loading metrics'),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AdminControlCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final int? count;

  const _AdminControlCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (count != null && count! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
