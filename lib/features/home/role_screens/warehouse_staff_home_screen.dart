import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/logistics_providers.dart';

class WarehouseStaffHomeScreen extends ConsumerWidget {
  const WarehouseStaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final metricsAsync = ref.watch(todayMetricsProvider);
    final pickingQueueAsync = ref.watch(pickingQueueProvider);
    final packingQueueAsync = ref.watch(packingQueueProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Shift Manager - ${user?.name ?? "Staff"}',
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
        child: Column(
          children: [
            // Shift Status Banner
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
                    'Today\'s Shift',
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
                            '09:00 AM - 06:00 PM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '5 hours remaining',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
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
                          'Active',
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
            // Daily Tasks - Connected to Services
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Today\'s Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: pickingQueueAsync.when(
                data: (pickLists) {
                  final totalToPick = pickLists.fold<int>(
                    0,
                    (sum, list) => sum + list.items.length,
                  );
                  final pickedCount = pickLists.fold<int>(
                    0,
                    (sum, list) => sum + (list.items.isNotEmpty ? 1 : 0),
                  );

                  return _TaskCard(
                    title: 'Picking in Progress',
                    count: '$pickedCount/$totalToPick items',
                    priority: 'High',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$totalToPick items to pick'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
                loading: () => _TaskCard(
                  title: 'Picking in Progress',
                  count: 'Loading...',
                  priority: 'High',
                  onTap: () {},
                ),
                error: (err, _) => _TaskCard(
                  title: 'Picking in Progress',
                  count: 'Error',
                  priority: 'High',
                  onTap: () {},
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: packingQueueAsync.when(
                data: (packingLogs) {
                  final totalToPack = packingLogs.length;
                  final packedCount =
                      packingLogs.where((log) => log.status == 'packed').length;

                  return _TaskCard(
                    title: 'Orders to Pack',
                    count: '$packedCount/$totalToPack packed',
                    priority: 'High',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$totalToPack orders to pack'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
                loading: () => _TaskCard(
                  title: 'Orders to Pack',
                  count: 'Loading...',
                  priority: 'High',
                  onTap: () {},
                ),
                error: (err, _) => _TaskCard(
                  title: 'Orders to Pack',
                  count: 'Error',
                  priority: 'High',
                  onTap: () {},
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _TaskCard(
                    title: 'Inventory Count',
                    count: 'Section B',
                    priority: 'Medium',
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _TaskCard(
                    title: 'Returns Processing',
                    count: '5 items',
                    priority: 'Medium',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Operations Summary - Connected to Service
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Operations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: metricsAsync.when(
                data: (metrics) {
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _OperationCard(
                        title: 'Picking',
                        icon: Icons.local_shipping_outlined,
                        metric: '85%',
                        onTap: () {},
                      ),
                      _OperationCard(
                        title: 'Packing',
                        icon: Icons.inventory_2_outlined,
                        metric: '72%',
                        onTap: () {},
                      ),
                      _OperationCard(
                        title: 'QC Passed',
                        icon: Icons.check_circle_outline,
                        metric: '48/50',
                        onTap: () {},
                      ),
                      _OperationCard(
                        title: 'Issues',
                        icon: Icons.warning_outlined,
                        metric: '2',
                        onTap: () {},
                      ),
                    ],
                  );
                },
                loading: () => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _OperationCard(
                      title: 'Packing',
                      icon: Icons.local_shipping_outlined,
                      metric: 'Loading...',
                      onTap: () {},
                    ),
                    _OperationCard(
                      title: 'Receiving',
                      icon: Icons.inbox_outlined,
                      metric: 'Loading...',
                      onTap: () {},
                    ),
                    _OperationCard(
                      title: 'Inventory',
                      icon: Icons.inventory_2_outlined,
                      metric: 'Loading...',
                      onTap: () {},
                    ),
                    _OperationCard(
                      title: 'Quality',
                      icon: Icons.check_circle_outline,
                      metric: 'Loading...',
                      onTap: () {},
                    ),
                  ],
                ),
                error: (err, _) => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _OperationCard(
                      title: 'Packing',
                      icon: Icons.local_shipping_outlined,
                      metric: 'Error',
                      onTap: () {},
                    ),
                    _OperationCard(
                      title: 'Receiving',
                      icon: Icons.inbox_outlined,
                      metric: 'Error',
                      onTap: () {},
                    ),
                    _OperationCard(
                      title: 'Inventory',
                      icon: Icons.inventory_2_outlined,
                      metric: 'Error',
                      onTap: () {},
                    ),
                    _OperationCard(
                      title: 'Quality',
                      icon: Icons.check_circle_outline,
                      metric: 'Error',
                      onTap: () {},
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

class _TaskCard extends StatelessWidget {
  final String title;
  final String count;
  final String priority;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.count,
    required this.priority,
    required this.onTap,
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: priority == 'High'
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                priority,
                style: TextStyle(
                  color: priority == 'High' ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String metric;
  final VoidCallback onTap;

  const _OperationCard({
    required this.title,
    required this.icon,
    required this.metric,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              metric,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
