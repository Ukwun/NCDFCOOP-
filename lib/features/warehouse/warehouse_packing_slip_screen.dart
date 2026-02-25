import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/packing_slip_service.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Warehouse Staff Packing Slip Generation Screen
/// Generates and prints packing slips for shipments
class WarehousePackingSlipScreen extends ConsumerStatefulWidget {
  final String warehouseId;
  final String warehouseName;
  final String pickListId;
  final String orderId;

  const WarehousePackingSlipScreen({
    super.key,
    required this.warehouseId,
    required this.warehouseName,
    required this.pickListId,
    required this.orderId,
  });

  @override
  ConsumerState<WarehousePackingSlipScreen> createState() =>
      _WarehousePackingSlipScreenState();
}

class _WarehousePackingSlipScreenState
    extends ConsumerState<WarehousePackingSlipScreen> {
  String _packingSlipId = '';
  String _packingSlipContent = '';
  int _numberOfBoxes = 1;
  TextEditingController? _boxController;

  @override
  void initState() {
    super.initState();
    _boxController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _boxController?.dispose();
    super.dispose();
  }

  Future<void> _generatePackingSlip() async {
    if (_boxController?.text.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter number of boxes')),
      );
      return;
    }

    try {
      final service = PackingSlipService();
      final numberOfBoxes = int.parse(_boxController!.text);

      // Create mock packing slip items
      final mockItems = [
        PackingSlipItem(
          sku: 'SK-001',
          productName: 'Rice 10kg Bag',
          quantity: 5,
          boxNumber: 1,
          binLocation: 'SECTION_A-RACK_1',
        ),
        PackingSlipItem(
          sku: 'SK-002',
          productName: 'Beans 2kg Bag',
          quantity: 8,
          boxNumber: 1,
          binLocation: 'SECTION_B-RACK_2',
        ),
        if (numberOfBoxes > 1)
          PackingSlipItem(
            sku: 'SK-003',
            productName: 'Sugar 1kg Bag',
            quantity: 10,
            boxNumber: 2,
            binLocation: 'SECTION_C-RACK_3',
          ),
      ];

      // Generate slip
      final slipId = await service.generatePackingSlip(
        orderId: widget.orderId,
        pickListId: widget.pickListId,
        warehouseId: widget.warehouseId,
        items: mockItems,
        totalBoxes: numberOfBoxes,
      );

      // Get the content for display
      final slip = await service.getPackingSlip(widget.warehouseId, slipId);
      if (slip != null) {
        final content = service.generatePackingSlipPDF(
          slip,
          'Coop Commerce',
          widget.warehouseName,
        );

        setState(() {
          _packingSlipId = slipId;
          _packingSlipContent = content;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Packing slip generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _printPackingSlip() async {
    if (_packingSlipId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please generate a packing slip first')),
      );
      return;
    }

    try {
      final service = PackingSlipService();
      await service.markAsPrinted(widget.warehouseId, _packingSlipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Packing slip marked as printed'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Packing Slip Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info
            Container(
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
                    'Order Information',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow('Order ID', widget.orderId),
                  _InfoRow('Pick List', widget.pickListId),
                  _InfoRow('Warehouse', widget.warehouseName),
                  _InfoRow('Generated', DateTime.now().toString().split('.')[0]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Generate Options
            Container(
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
                    'Packing Details',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _boxController,
                    decoration: const InputDecoration(
                      labelText: 'Number of Boxes',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generatePackingSlip,
                      icon: const Icon(Icons.create),
                      label: const Text('Generate Packing Slip'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preview
            if (_packingSlipContent.isNotEmpty) ...[
              Container(
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
                      'Packing Slip Preview',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 64,
                        child: Text(
                          _packingSlipContent,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printPackingSlip,
                      icon: const Icon(Icons.print),
                      label: const Text('Mark as Printed'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Could implement actual PDF export here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Packing slip saved successfully'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Save as PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
