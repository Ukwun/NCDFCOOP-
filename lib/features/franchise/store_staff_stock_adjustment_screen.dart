import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/store_staff_service.dart';
import 'package:coop_commerce/models/store_staff_models.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/auth_provider.dart';

/// Store Staff Stock Adjustment Screen
/// Allows staff to adjust inventory with audit trail
class StoreStaffStockAdjustmentScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const StoreStaffStockAdjustmentScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  ConsumerState<StoreStaffStockAdjustmentScreen> createState() =>
      _StoreStaffStockAdjustmentScreenState();
}

class _StoreStaffStockAdjustmentScreenState
    extends ConsumerState<StoreStaffStockAdjustmentScreen> {
  late Future<List<StoreInventoryItem>> _inventoryFuture;
  late Future<List<StockAdjustment>> _adjustmentHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final service = StoreStaffService();
    setState(() {
      _inventoryFuture = service.getStoreInventory(widget.storeId);
      _adjustmentHistoryFuture = service.getAdjustmentHistory(widget.storeId);
    });
  }

  void _showAdjustmentDialog(StoreInventoryItem item) {
    final newQuantityController =
        TextEditingController(text: item.quantity.toString());
    String selectedReason = 'stock_count';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Stock'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('SKU: ${item.sku}',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              Text('Current Quantity: ${item.quantity}'),
              const SizedBox(height: 12),
              TextField(
                controller: newQuantityController,
                decoration: const InputDecoration(labelText: 'New Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedReason,
                onChanged: (value) {
                  setState(() => selectedReason = value ?? 'stock_count');
                },
                items: [
                  ('stock_count', 'Physical Count'),
                  ('damage', 'Damaged Goods'),
                  ('theft', 'Theft/Loss'),
                  ('admin_adjustment', 'Admin Adjustment'),
                ]
                    .map((item) => DropdownMenuItem(
                          value: item.$1,
                          child: Text(item.$2),
                        ))
                    .toList(),
                decoration:
                    const InputDecoration(labelText: 'Adjustment Reason'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newQuantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter new quantity')),
                );
                return;
              }

              final newQuantity = int.parse(newQuantityController.text);
              final user = ref.read(currentUserProvider);
              if (user == null) return;

              final service = StoreStaffService();
              try {
                await service.adjustStock(
                  storeId: widget.storeId,
                  staffId: user.id,
                  staffName: user.name ?? 'Staff',
                  productId: item.productId,
                  productName: item.productName,
                  previousQuantity: item.quantity,
                  newQuantity: newQuantity,
                  reason: selectedReason,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock adjusted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('Stock Management - ${widget.storeName}'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Inventory'),
              Tab(text: 'Adjustment History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Inventory Tab
            FutureBuilder<List<StoreInventoryItem>>(
              future: _inventoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final inventory = snapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total Items',
                              value: '${inventory.length}',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Low Stock',
                              value:
                                  '${inventory.where((i) => i.isLowStock).length}',
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Inventory List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: inventory.length,
                        itemBuilder: (context, index) {
                          final item = inventory[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(item.productName),
                              subtitle: Text('SKU: ${item.sku}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.quantity} units',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item.isLowStock
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  if (item.isLowStock)
                                    Text(
                                      'Low Stock ⚠️',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () => _showAdjustmentDialog(item),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            // Adjustment History Tab
            FutureBuilder<List<StockAdjustment>>(
              future: _adjustmentHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final adjustments = snapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (adjustments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No adjustments yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: adjustments.length,
                          itemBuilder: (context, index) {
                            final adj = adjustments[index];
                            final isIncrease = adj.adjustmentAmount > 0;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(
                                  isIncrease
                                      ? Icons.add_circle
                                      : Icons.remove_circle,
                                  color: isIncrease ? Colors.green : Colors.red,
                                ),
                                title: Text(adj.productName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${adj.staffName} • ${adj.reason.replaceAll('_', ' ')}',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    if (adj.notes != null)
                                      Text(
                                        adj.notes!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  '${isIncrease ? '+' : ''}${adj.adjustmentAmount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isIncrease ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
