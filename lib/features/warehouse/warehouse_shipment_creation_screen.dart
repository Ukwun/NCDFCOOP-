import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/features/warehouse/services/warehouse_service.dart';
import 'package:coop_commerce/features/warehouse/models/warehouse_models.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/auth_provider.dart';

/// Warehouse Staff Shipment Creation Screen
/// Creates shipments from completed pack and QC jobs
class WarehouseShipmentCreationScreen extends ConsumerStatefulWidget {
  final String warehouseId;
  final String warehouseName;

  const WarehouseShipmentCreationScreen({
    super.key,
    required this.warehouseId,
    required this.warehouseName,
  });

  @override
  ConsumerState<WarehouseShipmentCreationScreen> createState() =>
      _WarehouseShipmentCreationScreenState();
}

class _WarehouseShipmentCreationScreenState
    extends ConsumerState<WarehouseShipmentCreationScreen> {
  late final _firestore = FirebaseFirestore.instance;
  late List<WarehouseShipment> _shipments = [];
  String? _selectedOrderId;
  String _carrierName = 'Standard Shipping';
  final String _trackingNumberPrefix = 'TRK';

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  void _loadShipments() async {
    // Mock load - in production would fetch from service
    setState(() {
      _shipments = [
        WarehouseShipment(
          id: 'SHIP-001',
          orderId: 'ORD-2026-001',
          warehouseId: widget.warehouseId,
          pickJobIds: ['PICK-001'],
          packJobIds: ['PACK-001'],
          status: ShipmentStatus.ready,
          createdAt: DateTime.now().subtract(Duration(hours: 2)),
        ),
      ];
    });
  }

  void _showCreateShipmentDialog() {
    final weightController = TextEditingController();
    final dimensionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Shipment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedOrderId,
                onChanged: (value) {
                  setState(() => _selectedOrderId = value);
                },
                items: ['ORD-2026-001', 'ORD-2026-002', 'ORD-2026-003']
                    .map((id) => DropdownMenuItem(
                          value: id,
                          child: Text(id),
                        ))
                    .toList(),
                decoration: const InputDecoration(labelText: 'Order ID'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _carrierName,
                onChanged: (value) {
                  setState(() => _carrierName = value ?? 'Standard Shipping');
                },
                items: ['Standard Shipping', 'Express Shipping', 'Overnight']
                    .map((carrier) => DropdownMenuItem(
                          value: carrier,
                          child: Text(carrier),
                        ))
                    .toList(),
                decoration: const InputDecoration(labelText: 'Carrier'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dimensionsController,
                decoration:
                    const InputDecoration(labelText: 'Dimensions (L×W×H cm)'),
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
              if (_selectedOrderId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an order')),
                );
                return;
              }

              await _createShipment(
                orderId: _selectedOrderId!,
                weight: weightController.text.isNotEmpty
                    ? double.tryParse(weightController.text)
                    : null,
                dimensions: dimensionsController.text.isNotEmpty
                    ? dimensionsController.text
                    : null,
              );

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Create Shipment'),
          ),
        ],
      ),
    );
  }

  Future<void> _createShipment({
    required String orderId,
    double? weight,
    String? dimensions,
  }) async {
    try {
      final service = WarehouseService();
      final user = ref.read(currentUserProvider);

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // In production, would get actual pick/pack job IDs
      final shipmentId = await service.createShipment(
        orderId: orderId,
        warehouseId: widget.warehouseId,
        pickJobIds: ['PICK-${DateTime.now().millisecondsSinceEpoch}'],
        packJobIds: ['PACK-${DateTime.now().millisecondsSinceEpoch}'],
      );

      // Update shipment with tracking details
      await _firestore
          .collection('warehouses')
          .doc(widget.warehouseId)
          .collection('shipments')
          .doc(shipmentId)
          .update({
        'carrier': _carrierName,
        'trackingNumber':
            '$_trackingNumberPrefix${DateTime.now().millisecondsSinceEpoch}',
        'weight': weight,
        'dimensions': dimensions,
        'status': 'ready',
      });

      _loadShipments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipment created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _shipPackage(WarehouseShipment shipment) async {
    try {
      final service = WarehouseService();
      await service.updateShipmentStatus(
        shipment.id,
        ShipmentStatus.shipped,
      );

      _loadShipments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipment marked as shipped'),
          backgroundColor: Colors.blue,
        ),
      );
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
        title: Text('Shipment Management - ${widget.warehouseName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShipments,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Shipment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateShipmentDialog,
                icon: const Icon(Icons.local_shipping),
                label: const Text('Create New Shipment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Shipment Statistics
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Shipments',
                    value: '${_shipments.length}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Ready to Ship',
                    value:
                        '${_shipments.where((s) => s.status == ShipmentStatus.ready).length}',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Shipped',
                    value:
                        '${_shipments.where((s) => s.status == ShipmentStatus.shipped).length}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Shipments List
            Text(
              'Active Shipments',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_shipments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No shipments found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _shipments.length,
                itemBuilder: (context, index) {
                  final shipment = _shipments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text('Order: ${shipment.orderId}'),
                      subtitle: Text(
                        'Status: ${shipment.status.name.toUpperCase()}',
                        style: TextStyle(
                          color: _getStatusColor(shipment.status),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DetailRow('Shipment ID', shipment.id),
                              _DetailRow('Warehouse', widget.warehouseName),
                              _DetailRow(
                                'Created',
                                shipment.createdAt.toString().split('.')[0],
                              ),
                              _DetailRow(
                                'Pick Jobs',
                                shipment.pickJobIds.length.toString(),
                              ),
                              _DetailRow(
                                'Pack Jobs',
                                shipment.packJobIds.length.toString(),
                              ),
                              const SizedBox(height: 16),
                              if (shipment.status == ShipmentStatus.ready)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _shipPackage(shipment),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Mark as Shipped'),
                                  ),
                                ),
                            ],
                          ),
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

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.created:
        return Colors.grey;
      case ShipmentStatus.ready:
        return Colors.orange;
      case ShipmentStatus.shipped:
        return Colors.blue;
      case ShipmentStatus.delivered:
        return Colors.green;
      case ShipmentStatus.cancelled:
        return Colors.red;
    }
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
      padding: const EdgeInsets.all(12),
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
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
