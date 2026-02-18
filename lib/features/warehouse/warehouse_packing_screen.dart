import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/providers/warehouse_providers.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class WarehousePackingScreen extends ConsumerStatefulWidget {
  final String pickListId;

  const WarehousePackingScreen({
    Key? key,
    required this.pickListId,
  }) : super(key: key);

  @override
  ConsumerState<WarehousePackingScreen> createState() =>
      _WarehousePackingScreenState();
}

class _WarehousePackingScreenState extends ConsumerState<WarehousePackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, String> packedBoxes = {};
  final Map<String, bool> itemPackedStatus = {};
  int currentBoxNumber = 1;
  final TextEditingController boxWeightController = TextEditingController();
  final TextEditingController boxDimensionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    boxWeightController.dispose();
    boxDimensionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickListAsync = ref.watch(pickListDetailProvider(widget.pickListId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing Workflow'),
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Items'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Boxes'),
            Tab(icon: Icon(Icons.receipt), text: 'Summary'),
          ],
        ),
      ),
      body: pickListAsync.when(
        data: (pickList) => _buildPackingContent(context, pickList),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: ${err.toString()}'),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goBackToPicking,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _validateAndPrintSlip,
                icon: const Icon(Icons.print),
                label: const Text('Print & QC'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPackingContent(BuildContext context, dynamic pickList) {
    final items = (pickList['items'] as List?) ?? [];

    return TabBarView(
      controller: _tabController,
      children: [
        // Items Tab
        _buildItemsTab(items),
        // Boxes Tab
        _buildBoxesTab(),
        // Summary Tab
        _buildSummaryTab(items),
      ],
    );
  }

  Widget _buildItemsTab(List items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items Ready for Packing',
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'No items to pack',
                  style: TextStyle(color: Colors.blue.shade700),
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
                return _buildPackItemCard(item, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPackItemCard(dynamic item, int index) {
    final itemId = item['itemId'] as String? ?? 'item_$index';
    final productName = item['productName'] as String? ?? 'Product $index';
    final quantity = item['quantity'] as int? ?? 1;
    final sku = item['sku'] as String? ?? 'SKU-$index';
    final weight = item['weight'] as double? ?? 0.5;

    final isPacked = itemPackedStatus[itemId] ?? false;
    final assignedBox = packedBoxes[itemId] ?? 'Unassigned';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isPacked ? Colors.green.shade300 : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
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
                Checkbox(
                  value: isPacked,
                  onChanged: (val) => _toggleItemPacked(itemId),
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailChip('Qty: $quantity', Icons.inventory_2),
                _buildDetailChip('Wt: ${weight}kg', Icons.scale),
                _buildDetailChip('Box: $assignedBox', Icons.local_shipping),
              ],
            ),
            const SizedBox(height: 12),

            // Assign to Box Dropdown
            DropdownButton<String>(
              value: assignedBox,
              isExpanded: true,
              hint: const Text('Assign to box...'),
              items: _buildBoxDropdownItems(),
              onChanged: (value) {
                if (value != null) {
                  _assignItemToBox(itemId, value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildBoxDropdownItems() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: 'Unassigned',
        child: Text('Unassigned'),
      ),
    ];

    for (int i = 1; i <= currentBoxNumber; i++) {
      items.add(
        DropdownMenuItem(
          value: 'Box $i',
          child: Text('Box $i'),
        ),
      );
    }

    items.add(
      const DropdownMenuItem(
        value: 'NEW',
        child: Text('+ New Box'),
      ),
    );

    return items;
  }

  Widget _buildBoxesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boxes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentBoxNumber,
            itemBuilder: (context, index) {
              return _buildBoxCard(index + 1);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addNewBox,
            icon: const Icon(Icons.add),
            label: const Text('Add New Box'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxCard(int boxNumber) {
    final itemsInBox =
        packedBoxes.entries.where((e) => e.value == 'Box $boxNumber').length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Box #$boxNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text('$itemsInBox items'),
                  backgroundColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Weight (kg)',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                prefixIcon: const Icon(Icons.scale),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // Store weight for box
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Dimensions (L x W x H cm)',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                prefixIcon: const Icon(Icons.straighten),
              ),
              onChanged: (value) {
                // Store dimensions for box
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editBox(boxNumber),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _deleteBox(boxNumber),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(List items) {
    final totalItems = items.length;
    final packedItems = itemPackedStatus.values.where((v) => v).length;
    final totalBoxes = currentBoxNumber;
    final totalWeight =
        packedBoxes.isNotEmpty ? totalBoxes * 5.0 : 0.0; // Placeholder

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Packing Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard('Total Items', '$totalItems'),
          _buildSummaryCard('Items Packed', '$packedItems / $totalItems'),
          _buildSummaryCard('Total Boxes', '$totalBoxes'),
          _buildSummaryCard(
              'Total Weight', '${totalWeight.toStringAsFixed(1)} kg'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ensure all items are packed before proceeding to QC',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleItemPacked(String itemId) {
    setState(() {
      itemPackedStatus[itemId] = !(itemPackedStatus[itemId] ?? false);
    });
  }

  void _assignItemToBox(String itemId, String boxName) {
    if (boxName == 'NEW') {
      setState(() {
        currentBoxNumber++;
        packedBoxes[itemId] = 'Box $currentBoxNumber';
      });
    } else {
      setState(() {
        packedBoxes[itemId] = boxName;
      });
    }
  }

  void _addNewBox() {
    setState(() {
      currentBoxNumber++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Box #$currentBoxNumber added'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editBox(int boxNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Box #$boxNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Weight (kg)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Dimensions (L x W x H)',
              ),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Box updated'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteBox(int boxNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Box'),
        content: Text('Delete Box #$boxNumber? Items will be unassigned.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                packedBoxes
                    .removeWhere((key, value) => value == 'Box $boxNumber');
                currentBoxNumber--;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _goBackToPicking() {
    Navigator.pop(context);
  }

  void _validateAndPrintSlip() {
    if (itemPackedStatus.isEmpty || !itemPackedStatus.values.every((v) => v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pack all items before proceeding'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            WarehouseQCVerificationScreen(pickListId: widget.pickListId),
      ),
    );
  }
}

// Placeholder for QC verification screen
class WarehouseQCVerificationScreen extends StatelessWidget {
  final String pickListId;

  const WarehouseQCVerificationScreen({
    Key? key,
    required this.pickListId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QC Verification'),
      ),
      body: const Center(
        child: Text('QC verification screen coming next...'),
      ),
    );
  }
}
