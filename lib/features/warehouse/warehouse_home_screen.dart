import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/warehouse_providers.dart';
import 'package:coop_commerce/core/services/warehouse_service.dart';

class WarehouseHomeScreen extends ConsumerWidget {
  const WarehouseHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Metrics Summary
            _buildMetricsSummary(context, ref),
            const SizedBox(height: AppSpacing.xl),

            // Active Pick Lists
            _buildActivePickLists(context, ref),
            const SizedBox(height: AppSpacing.xl),

            // Ready for Packing
            _buildReadyForPacking(context, ref),
            const SizedBox(height: AppSpacing.xl),

            // Inventory Status
            _buildInventoryStatus(context, ref),
            const SizedBox(height: AppSpacing.xl),

            // Low Stock Alerts
            _buildLowStockAlerts(context, ref),
          ],
        ),
      ),
    );
  }

  // Metrics Summary Cards
  Widget _buildMetricsSummary(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dailyMetricsProvider);

    return metricsAsync.when(
      data: (metrics) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Performance',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.2,
            children: [
              _buildMetricCard(
                'Items Picked',
                '${metrics.itemsPicked}',
                Icons.shopping_basket,
                AppColors.primary,
              ),
              _buildMetricCard(
                'Items Packed',
                '${metrics.itemsPacked}',
                Icons.inventory_2,
                AppColors.secondary,
              ),
              _buildMetricCard(
                'QC Passed',
                '${metrics.qcPassed}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildMetricCard(
                'Avg Pick Time',
                '${metrics.averagePickTime}s',
                Icons.schedule,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error loading metrics: $error'),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Active Pick Lists Section
  Widget _buildActivePickLists(BuildContext context, WidgetRef ref) {
    final pickListsAsync = ref.watch(activePickListsProvider);
    final pendingCountAsync = ref.watch(pendingPickListsCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Pick Lists',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
            ),
            pendingCountAsync.when(
              data: (count) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              loading: () => const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Text('Error'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        pickListsAsync.when(
          data: (pickLists) {
            final pending = pickLists
                .where((pl) => pl.status == 'created' || pl.status == 'picking')
                .take(5)
                .toList();

            if (pending.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'All pick lists completed!',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final pickList = pending[index];
                return _buildPickListTile(context, pickList);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error loading pick lists: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildPickListTile(BuildContext context, PickList pickList) {
    final statusColor = _getStatusColor(pickList.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.list_alt, color: statusColor),
        ),
        title: Text(
          'Pick List ${pickList.listId.substring(0, 8)}',
          style: AppTextStyles.labelSmall,
        ),
        subtitle: Text(
          'Order: ${pickList.orderId} • ${pickList.items.length} items',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Chip(
          label: Text(
            _formatStatus(pickList.status),
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: statusColor,
        ),
        onTap: () {
          // Navigate to pick list detail
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (_) => PickListDetailScreen(pickListId: pickList.listId),
          // ));
        },
      ),
    );
  }

  // Ready for Packing Section
  Widget _buildReadyForPacking(BuildContext context, WidgetRef ref) {
    final readyAsync = ref.watch(readyForPackingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready for Packing',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        readyAsync.when(
          data: (readyLists) {
            if (readyLists.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'No pick lists ready for packing',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: readyLists.length,
              itemBuilder: (context, index) {
                final pickList = readyLists[index];
                return _buildReadyForPackingTile(context, pickList);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyForPackingTile(BuildContext context, PickList pickList) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_shipping, color: Colors.orange),
        ),
        title: Text(
          'Pack Order ${pickList.orderId.substring(0, 8)}',
          style: AppTextStyles.labelSmall,
        ),
        subtitle: Text(
          '${pickList.items.length} items to pack',
          style: AppTextStyles.bodySmall,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to packing screen
        },
      ),
    );
  }

  // Inventory Status Section
  Widget _buildInventoryStatus(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Warehouse Inventory',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        inventoryAsync.when(
          data: (stats) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _buildInventoryStat(
                  'Total Items',
                  '${stats.totalItems}',
                  'items in stock',
                ),
                const Divider(height: AppSpacing.xl),
                _buildInventoryStat(
                  'Reserved Items',
                  '${stats.totalReserved}',
                  'items reserved for orders',
                ),
                const Divider(height: AppSpacing.xl),
                _buildInventoryStat(
                  'Available',
                  '${stats.availableItems}',
                  'items ready to pick',
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryStat(String label, String value, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.labelSmall,
            ),
          ],
        ),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Low Stock Alerts
  Widget _buildLowStockAlerts(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockItemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Low Stock Items',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        lowStockAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'All items have sufficient stock',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildLowStockTile(item);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockTile(InventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning, color: Colors.red, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Available: ${item.availableQuantity} / Min: ${item.minimumLevel}',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Trigger reorder
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reorder', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'created' => Colors.orange,
      'picking' => Colors.blue,
      'picked' => Colors.green,
      'ready_for_pack' => Colors.purple,
      'completed' => Colors.grey,
      _ => Colors.grey,
    };
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
