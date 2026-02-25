import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/inventory_providers.dart';
import 'package:coop_commerce/models/inventory_models.dart';

/// Warehouse Management Screen
/// Manage inventory items per warehouse location
class WarehouseManagementScreen extends ConsumerStatefulWidget {
  final String locationId;

  const WarehouseManagementScreen({
    super.key,
    required this.locationId,
  });

  @override
  ConsumerState<WarehouseManagementScreen> createState() =>
      _WarehouseManagementScreenState();
}

class _WarehouseManagementScreenState
    extends ConsumerState<WarehouseManagementScreen> {
  String _sortBy = 'name'; // name, stock, value
  String _filterStatus = 'all'; // all, low_stock, out_of_stock

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(locationSummaryProvider(widget.locationId));
    final alertsAsync = ref.watch(locationAlertsProvider(
      (locationId: widget.locationId, severity: null),
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Warehouse Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.refresh(locationSummaryProvider(widget.locationId)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: summaryAsync.when(
              data: (summary) {
                if (summary == null) {
                  return const Text('No inventory data');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Stock',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              summary.totalStock.toString(),
                              style: AppTextStyles.headlineSmall,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory Value',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              '₦${NumberFormat('#,##0').format(summary.totalValue.toInt())}',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Low Stock',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              summary.lowStockItems.toString(),
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
            ),
          ),
          const Divider(height: 1),

          // Filters & Sort
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterStatus == 'all',
                    onSelected: (selected) {
                      setState(() => _filterStatus = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Low Stock'),
                    selected: _filterStatus == 'low_stock',
                    onSelected: (selected) {
                      setState(() => _filterStatus = 'low_stock');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Out of Stock'),
                    selected: _filterStatus == 'out_of_stock',
                    onSelected: (selected) {
                      setState(() => _filterStatus = 'out_of_stock');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Inventory Items List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.refresh(locationSummaryProvider(widget.locationId));
              },
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Inventory Items',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  _buildInventoryItemsList(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItemsList(BuildContext context, WidgetRef ref) {
    // This is a placeholder - in a real implementation, you would fetch
    // inventory items from Firestore for this specific location
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildInventoryItemCard(
          productName: 'Premium Basmati Rice 1kg',
          productId: 'prod_rice_1kg',
          currentStock: 45,
          safetyLevel: 10,
          reorderPoint: 20,
          value: 157500,
          status: 'low_stock',
        ),
        _buildInventoryItemCard(
          productName: 'Extra Virgin Olive Oil 500ml',
          productId: 'prod_oil_500ml',
          currentStock: 0,
          safetyLevel: 15,
          reorderPoint: 25,
          value: 0,
          status: 'out_of_stock',
        ),
        _buildInventoryItemCard(
          productName: 'Organic Tomato Paste 400g',
          productId: 'prod_paste_400g',
          currentStock: 180,
          safetyLevel: 10,
          reorderPoint: 25,
          value: 291600,
          status: 'in_stock',
        ),
      ],
    );
  }

  Widget _buildInventoryItemCard({
    required String productName,
    required String productId,
    required int currentStock,
    required int safetyLevel,
    required int reorderPoint,
    required double value,
    required String status,
  }) {
    late Color statusColor;
    late String statusLabel;

    switch (status) {
      case 'out_of_stock':
        statusColor = Colors.red;
        statusLabel = 'Out of Stock';
        break;
      case 'low_stock':
        statusColor = Colors.orange;
        statusLabel = 'Low Stock';
        break;
      default:
        statusColor = Colors.green;
        statusLabel = 'In Stock';
    }

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: AppTextStyles.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $productId',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock Levels Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Stock',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            currentStock.toString(),
                            style: AppTextStyles.titleSmall,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safety Level',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            safetyLevel.toString(),
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reorder Point',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            reorderPoint.toString(),
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Value',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            '₦${NumberFormat('#,##0').format(value.toInt())}',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showTransactionDialog(context, productName, 'inbound');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Stock'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showTransactionDialog(context, productName, 'outbound');
                    },
                    icon: const Icon(Icons.remove),
                    label: const Text('Remove Stock'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showTransactionDialog(
                          context, productName, 'adjustment');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Adjust'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDialog(
    BuildContext context,
    String productName,
    String type,
  ) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${type == 'inbound' ? 'Add' : type == 'outbound' ? 'Remove' : 'Adjust'} Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: $productName'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Process transaction
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Stock ${type == 'inbound' ? 'added' : 'removed'} successfully',
                  ),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
