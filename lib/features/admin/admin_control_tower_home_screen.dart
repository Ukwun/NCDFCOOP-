import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Provider for admin dashboard metrics
final adminMetricsProvider = FutureProvider<AdminMetrics>((ref) async {
  // TODO: Integrate with actual admin service
  await Future.delayed(const Duration(milliseconds: 500));
  return AdminMetrics(
    totalUsers: 2543,
    activeUsers: 1847,
    priceOverridesPending: 12,
    complianceIssues: 3,
    auditLogsThisMonth: 5832,
    averageResponseTime: 'Excellent',
  );
});

/// Data model for admin metrics
class AdminMetrics {
  final int totalUsers;
  final int activeUsers;
  final int priceOverridesPending;
  final int complianceIssues;
  final int auditLogsThisMonth;
  final String averageResponseTime;

  AdminMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.priceOverridesPending,
    required this.complianceIssues,
    required this.auditLogsThisMonth,
    required this.averageResponseTime,
  });
}

/// Admin Control Tower Home Screen
class AdminControlTowerHomeScreen extends ConsumerWidget {
  const AdminControlTowerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Tower'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Admin',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading dashboard: $error'),
            ],
          ),
        ),
        data: (metrics) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Cards
              _buildKPISection(context, metrics),
              const SizedBox(height: 32),

              // Quick Action Buttons
              _buildQuickActionsSection(context),
              const SizedBox(height: 32),

              // System Health
              _buildSystemHealthSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPISection(BuildContext context, AdminMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _KPICard(
              title: 'Total Users',
              value: metrics.totalUsers.toString(),
              subtitle: '${metrics.activeUsers} active',
              color: AppColors.primary,
              icon: Icons.people,
            ),
            _KPICard(
              title: 'Pending Approvals',
              value: metrics.priceOverridesPending.toString(),
              subtitle: 'Price overrides',
              color: Colors.orange,
              icon: Icons.pending_actions,
            ),
            _KPICard(
              title: 'Compliance Issues',
              value: metrics.complianceIssues.toString(),
              subtitle: 'Require attention',
              color: Colors.red,
              icon: Icons.warning,
            ),
            _KPICard(
              title: 'Audit Logs',
              value: metrics.auditLogsThisMonth.toString(),
              subtitle: 'This month',
              color: AppColors.accent,
              icon: Icons.history,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ActionButton(
              icon: Icons.person_add,
              label: 'User Management',
              onTap: () => context.pushNamed('admin-users'),
            ),
            _ActionButton(
              icon: Icons.check_circle,
              label: 'Approvals',
              onTap: () => context.pushNamed('admin-approvals'),
            ),
            _ActionButton(
              icon: Icons.assessment,
              label: 'Compliance',
              onTap: () => context.pushNamed('admin-compliance'),
            ),
            _ActionButton(
              icon: Icons.history,
              label: 'Audit Logs',
              onTap: () => context.pushNamed('admin-audit-logs'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemHealthSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Health',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _HealthMetric(
                  label: 'Database Status',
                  status: 'Healthy',
                  statusColor: Colors.green,
                  icon: Icons.cloud,
                ),
                const Divider(),
                _HealthMetric(
                  label: 'API Response Time',
                  status: 'Excellent (125ms)',
                  statusColor: Colors.green,
                  icon: Icons.speed,
                ),
                const Divider(),
                _HealthMetric(
                  label: 'Uptime',
                  status: '99.8%',
                  statusColor: Colors.green,
                  icon: Icons.check_circle,
                ),
                const Divider(),
                _HealthMetric(
                  label: 'Firestore Quota',
                  status: '28% Used',
                  statusColor: Colors.orange,
                  icon: Icons.storage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// KPI Card Widget
class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _KPICard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: AppColors.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Health Metric Widget
class _HealthMetric extends StatelessWidget {
  final String label;
  final String status;
  final Color statusColor;
  final IconData icon;

  const _HealthMetric({
    required this.label,
    required this.status,
    required this.statusColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: statusColor, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
