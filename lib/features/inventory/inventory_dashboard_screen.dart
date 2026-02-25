import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/inventory_providers.dart';
import 'package:coop_commerce/models/inventory_models.dart';

/// Inventory Dashboard Screen
/// Real-time overview of inventory across all locations
class InventoryDashboardScreen extends ConsumerWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(inventoryDashboardStatsProvider);
    final locationsAsync = ref.watch(warehouseLocationsProvider);
    final alertsAsync = ref.watch(locationAlertsProvider(
      (locationId: '', severity: null),
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Inventory Dashboard',
          style: AppTextStyles.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(inventoryDashboardStatsProvider);
              ref.refresh(warehouseLocationsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(inventoryDashboardStatsProvider);
          ref.refresh(warehouseLocationsProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              statsAsync.when(
                data: (stats) => _buildStatsSection(context, stats),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
                error: (err, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading statistics: $err'),
                ),
              ),

              const SizedBox(height: 24),

              // Locations Overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Warehouse Locations',
                  style: AppTextStyles.titleLarge,
                ),
              ),
              const SizedBox(height: 12),

              locationsAsync.when(
                data: (locations) {
                  if (locations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No warehouse locations found',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      return _buildLocationCard(context, ref, locations[index]);
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
                error: (err, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading locations: $err'),
                ),
              ),

              const SizedBox(height: 24),

              // Recent Alerts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Alerts',
                      style: AppTextStyles.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to alerts screen
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              alertsAsync.when(
                data: (alerts) {
                  final recentAlerts = alerts.take(5).toList();
                  if (recentAlerts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 48, color: Colors.green),
                            const SizedBox(height: 16),
                            Text(
                              'No active alerts',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentAlerts.length,
                    itemBuilder: (context, index) {
                      return _buildAlertCard(context, recentAlerts[index]);
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
                error: (err, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading alerts: $err'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(
      BuildContext context, InventoryDashboardStats stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Items',
                  value: stats.totalItems.toString(),
                  icon: Icons.inventory_2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Inventory Value',
                  value:
                      '₦${NumberFormat('#,##0').format(stats.totalValue.toInt())}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Low Stock Items',
                  value: stats.lowStockItems.toString(),
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Critical Alerts',
                  value: stats.criticalAlerts.toString(),
                  icon: Icons.error,
                  color: Colors.red,
                  showBadge: stats.criticalAlerts > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool showBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          if (showBadge)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Alert',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    WidgetRef ref,
    InventoryLocation location,
  ) {
    final summaryAsync =
        ref.watch(locationSummaryProvider(location.locationId));
    final alertsAsync = ref.watch(locationAlertsProvider(
      (locationId: location.locationId, severity: null),
    ));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    location.type == 'warehouse'
                        ? Icons.warehouse
                        : Icons.store,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: AppTextStyles.titleSmall,
                      ),
                      Text(
                        location.address,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Active',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (summary) {
                if (summary == null) {
                  return Text(
                    'No inventory data',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  );
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Stock',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          summary.totalStock.toString(),
                          style: AppTextStyles.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inventory Value',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          '₦${NumberFormat('#,##0').format(summary.totalValue.toInt())}',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Low Stock Items',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          summary.lowStockItems.toString(),
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, st) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to warehouse management
                    },
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('Manage'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to reorder management
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Reorder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, InventoryAlert alert) {
    late Color bgColor;
    late Color textColor;
    late IconData icon;

    switch (alert.severity) {
      case 'critical':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.warning;
        break;
      default:
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, HH:mm').format(alert.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              // Resolve alert
            },
          ),
        ],
      ),
    );
  }
}
