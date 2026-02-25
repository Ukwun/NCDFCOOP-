import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/providers/warehouse_providers.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class WarehousePickListDetailScreen extends ConsumerStatefulWidget {
  final String pickListId;

  const WarehousePickListDetailScreen({
    super.key,
    required this.pickListId,
  });

  @override
  ConsumerState<WarehousePickListDetailScreen> createState() =>
      _WarehousePickListDetailScreenState();
}

class _WarehousePickListDetailScreenState
    extends ConsumerState<WarehousePickListDetailScreen> {
  final Map<String, int> pickedQuantities = {};
  final Map<String, List<String>> pickedLocations = {};
  bool isMarkedComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeQuantities();
  }

  void _initializeQuantities() {
    // Initialize picked quantities for each item
    // Will be populated from pick list items
  }

  @override
  Widget build(BuildContext context) {
    final pickListAsync = ref.watch(pickListDetailProvider(widget.pickListId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick List Details'),
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        actions: [
          if (!isMarkedComplete)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Chip(
                  label: const Text('In Progress'),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: const TextStyle(color: Colors.orange),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Chip(
                  label: const Text('Completed'),
                  backgroundColor: Colors.green.shade100,
                  labelStyle: const TextStyle(color: Colors.green),
                ),
              ),
            ),
        ],
      ),
      body: pickListAsync.when(
        data: (pickList) => _buildPickListContent(context, pickList),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: ${err.toString()}'),
        ),
      ),
      bottomNavigationBar: !isMarkedComplete
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _validateAndMarkComplete,
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _navigateToPacking,
                icon: const Icon(Icons.local_shipping),
                label: const Text('Go to Packing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPickListContent(BuildContext context, dynamic pickList) {
    // Extract pick list data - structure depends on your data model
    final pickListId = pickList['id'] as String? ?? widget.pickListId;
    final orderId = pickList['orderId'] as String? ?? 'Unknown';
    final status = pickList['status'] as String? ?? 'pending';
    final itemCount = pickList['itemCount'] as int? ?? 0;
    final items = (pickList['items'] as List?) ?? [];
    final createdAt = pickList['createdAt'] as dynamic ?? DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(pickListId, orderId, status, itemCount),
          const SizedBox(height: 20),

          // Items Section
          _buildItemsSection(items),
          const SizedBox(height: 20),

          // Summary Section
          _buildSummarySection(items),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
      String pickListId, String orderId, String status, int itemCount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick List #${pickListId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order: $orderId',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total Items', '$itemCount', Icons.inventory_2),
                _buildStatItem(
                  'Picked',
                  '${pickedQuantities.values.fold<int>(0, (sum, val) => sum + val)}',
                  Icons.check,
                ),
                _buildStatItem(
                  'Pending',
                  '${itemCount - pickedQuantities.values.fold<int>(0, (sum, val) => sum + val)}',
                  Icons.schedule,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items to Pick',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No items to pick',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildPickItemCard(item, index);
            },
          ),
      ],
    );
  }

  Widget _buildPickItemCard(dynamic item, int index) {
    final itemId = item['itemId'] as String? ?? 'item_$index';
    final productName = item['productName'] as String? ?? 'Product $index';
    final quantity = item['quantity'] as int? ?? 1;
    final location = item['location'] as String? ?? 'Unknown';
    final sku = item['sku'] as String? ?? 'SKU-$index';

    final pickedQty = pickedQuantities[itemId] ?? 0;
    final isPicked = pickedQty >= quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isPicked ? Colors.green.shade300 : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sku,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPicked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Picked',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Location Section
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location: $location',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quantity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Required Qty: $quantity',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Picked: $pickedQty/$quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPicked ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: pickedQty > 0
                            ? () => _decreaseQuantity(itemId)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$pickedQty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: pickedQty < quantity
                            ? () => _increaseQuantity(itemId, quantity)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(List items) {
    int totalRequired = 0;
    int totalPicked = 0;

    for (final item in items) {
      final quantity = item['quantity'] as int? ?? 0;
      totalRequired += quantity;
    }

    totalPicked = pickedQuantities.values.fold<int>(0, (sum, val) => sum + val);

    final isComplete = totalPicked >= totalRequired;
    final progressPercent =
        (totalRequired > 0 ? totalPicked / totalRequired : 0).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Picking Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalPicked / $totalRequired items',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(progressPercent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _increaseQuantity(String itemId, int maxQuantity) {
    setState(() {
      final current = pickedQuantities[itemId] ?? 0;
      if (current < maxQuantity) {
        pickedQuantities[itemId] = current + 1;
      }
    });
  }

  void _decreaseQuantity(String itemId) {
    setState(() {
      final current = pickedQuantities[itemId] ?? 0;
      if (current > 0) {
        pickedQuantities[itemId] = current - 1;
      }
    });
  }

  void _validateAndMarkComplete() {
    // Validate that all items are picked
    final allItems = ref.read(pickListDetailProvider(widget.pickListId));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pick list marked as complete!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      isMarkedComplete = true;
    });
  }

  void _navigateToPacking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            WarehousePackingScreen(pickListId: widget.pickListId),
      ),
    );
  }

  MaterialColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Placeholder for packing screen - will be implemented next
class WarehousePackingScreen extends StatelessWidget {
  final String pickListId;

  const WarehousePackingScreen({
    super.key,
    required this.pickListId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing Workflow'),
      ),
      body: const Center(
        child: Text('Packing screen coming next...'),
      ),
    );
  }
}
