import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/providers/franchise_providers.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Franchise inventory management screen
class FranchiseInventoryScreen extends ConsumerStatefulWidget {
  final String storeId;

  const FranchiseInventoryScreen({
    super.key,
    required this.storeId,
  });

  @override
  ConsumerState<FranchiseInventoryScreen> createState() =>
      _FranchiseInventoryScreenState();
}

class _FranchiseInventoryScreenState
    extends ConsumerState<FranchiseInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync =
        ref.watch(franchiseInventoryProvider(widget.storeId));
    final lowStockAsync = ref.watch(franchiseLowStockProvider(widget.storeId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All Items'),
            Tab(text: 'Low Stock'),
            Tab(text: 'Reorder'),
          ],
        ),
      ),
      body: inventoryAsync.when(
        data: (inventory) {
          final filteredInventory = inventory
              .where((item) =>
                  item.productName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  item.productId
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // All Items Tab
              _buildAllItemsTab(filteredInventory),
              // Low Stock Tab
              _buildLowStockTab(inventory),
              // Reorder Tab
              _buildReorderTab(inventory),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
        onPressed: () => _showAddStockDialog(),
      ),
    );
  }

  Widget _buildAllItemsTab(List<FranchiseInventoryItem> inventory) {
    return CustomScrollView(
      slivers: [
        // Search Bar
        SliverAppBar(
          pinned: true,
          floating: true,
          elevation: 0,
          backgroundColor: Colors.grey[50],
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),

        // Summary Cards
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSummaryCards(inventory),
              const SizedBox(height: 16),
            ]),
          ),
        ),

        // Inventory Items
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = inventory[index];
                return _InventoryItemCard(
                  item: item,
                  onEdit: () => _showEditStockDialog(item),
                  onReorder: () => _showReorderDialog(item),
                );
              },
              childCount: inventory.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockTab(List<FranchiseInventoryItem> inventory) {
    final lowStockItems = inventory.where((item) => item.isLowStock).toList();

    if (lowStockItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              'All items are well stocked!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${lowStockItems.length} items below minimum stock level',
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Low Stock Items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lowStockItems.length,
            itemBuilder: (context, index) {
              final item = lowStockItems[index];
              return _InventoryItemCard(
                item: item,
                highlighted: true,
                onEdit: () => _showEditStockDialog(item),
                onReorder: () => _showReorderDialog(item),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReorderTab(List<FranchiseInventoryItem> inventory) {
    final reorderItems = inventory
        .where((item) => item.quantity < item.minimumLevel * 1.5)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${reorderItems.length} items recommended for reorder',
                    style: TextStyle(color: Colors.blue[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (reorderItems.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.thumb_up, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No reorder needed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reorderItems.length,
              itemBuilder: (context, index) {
                final item = reorderItems[index];
                return _ReorderItemCard(
                  item: item,
                  onReorder: () => _showReorderDialog(item),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<FranchiseInventoryItem> inventory) {
    final totalValue = inventory.fold<double>(0, (a, b) => a + b.profit);
    final lowStockCount = inventory.where((item) => item.isLowStock).length;
    final totalItems = inventory.fold<int>(0, (a, b) => a + b.quantity);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Items',
            value: '$totalItems',
            icon: Icons.inventory_2,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Value',
            value: '\$${totalValue.toStringAsFixed(0)}',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Low Stock',
            value: '$lowStockCount',
            icon: Icons.warning,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  void _showAddStockDialog() {
    final productNameController = TextEditingController();
    final quantityController = TextEditingController();
    final costController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stock'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productNameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Cost Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Retail Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditStockDialog(FranchiseInventoryItem item) {
    final quantityController =
        TextEditingController(text: item.quantity.toString());
    final minimumController =
        TextEditingController(text: item.minimumLevel.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Stock'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                decoration:
                    const InputDecoration(labelText: 'Current Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minimumController,
                decoration: const InputDecoration(labelText: 'Minimum Level'),
                keyboardType: TextInputType.number,
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReorderDialog(FranchiseInventoryItem item) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Product: ${item.productName}'),
              const SizedBox(height: 12),
              Text('Current Stock: ${item.quantity}'),
              const SizedBox(height: 12),
              Text('Minimum Level: ${item.minimumLevel}'),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration:
                    const InputDecoration(labelText: 'Reorder Quantity'),
                keyboardType: TextInputType.number,
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reorder request submitted')),
              );
            },
            child: const Text('Submit Reorder'),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final FranchiseInventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onReorder;
  final bool highlighted;

  const _InventoryItemCard({
    required this.item,
    required this.onEdit,
    required this.onReorder,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: highlighted ? Colors.red[50] : null,
      border: highlighted ? Border.all(color: Colors.red[200]!) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'ID: ${item.productId}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (item.isLowStock)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Low Stock',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      '${item.quantity} units',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Minimum',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      '${item.minimumLevel} units',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:
                    (item.quantity / (item.minimumLevel * 2)).clamp(0.0, 1.0),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  onPressed: onEdit,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart, size: 16),
                  label: const Text('Reorder'),
                  onPressed: onReorder,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReorderItemCard extends StatelessWidget {
  final FranchiseInventoryItem item;
  final VoidCallback onReorder;

  const _ReorderItemCard({
    required this.item,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.inventory, color: Colors.orange[600]),
        title: Text(item.productName),
        subtitle:
            Text('Current: ${item.quantity} | Minimum: ${item.minimumLevel}'),
        trailing: ElevatedButton(
          onPressed: onReorder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Reorder'),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
