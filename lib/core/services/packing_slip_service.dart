import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/security/audit_log_service.dart';
import 'package:coop_commerce/core/auth/role.dart' as auth_role;

/// Packing Slip Data Model
class PackingSlip {
  final String id;
  final String orderId;
  final String pickListId;
  final String warehouseId;
  final String? packingCompletedId;
  final List<PackingSlipItem> items;
  final int totalItems;
  final int totalBoxes;
  final DateTime createdAt;
  final DateTime? printedAt;
  final String status; // draft, printed, completed

  PackingSlip({
    required this.id,
    required this.orderId,
    required this.pickListId,
    required this.warehouseId,
    this.packingCompletedId,
    required this.items,
    required this.totalItems,
    required this.totalBoxes,
    required this.createdAt,
    this.printedAt,
    required this.status,
  });

  factory PackingSlip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackingSlip(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      pickListId: data['pickListId'] ?? '',
      warehouseId: data['warehouseId'] ?? '',
      packingCompletedId: data['packingCompletedId'],
      items: (data['items'] as List?)
              ?.map((item) => PackingSlipItem.fromMap(item))
              .toList() ??
          [],
      totalItems: data['totalItems'] ?? 0,
      totalBoxes: data['totalBoxes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      printedAt: (data['printedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'draft',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'pickListId': pickListId,
        'warehouseId': warehouseId,
        'packingCompletedId': packingCompletedId,
        'items': items.map((i) => i.toMap()).toList(),
        'totalItems': totalItems,
        'totalBoxes': totalBoxes,
        'createdAt': FieldValue.serverTimestamp(),
        'printedAt': printedAt,
        'status': status,
      };
}

/// Item on packing slip
class PackingSlipItem {
  final String sku;
  final String productName;
  final int quantity;
  final int boxNumber;
  final String? binLocation;

  PackingSlipItem({
    required this.sku,
    required this.productName,
    required this.quantity,
    required this.boxNumber,
    this.binLocation,
  });

  factory PackingSlipItem.fromMap(Map<String, dynamic> data) {
    return PackingSlipItem(
      sku: data['sku'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      boxNumber: data['boxNumber'] ?? 0,
      binLocation: data['binLocation'],
    );
  }

  Map<String, dynamic> toMap() => {
        'sku': sku,
        'productName': productName,
        'quantity': quantity,
        'boxNumber': boxNumber,
        'binLocation': binLocation,
      };
}

/// Service for generating packing slips
class PackingSlipService {
  static final PackingSlipService _instance = PackingSlipService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLogService = AuditLogService();

  factory PackingSlipService() {
    return _instance;
  }

  PackingSlipService._internal();

  /// Generate packing slip from pick list
  Future<String> generatePackingSlip({
    required String orderId,
    required String pickListId,
    required String warehouseId,
    required List<PackingSlipItem> items,
    required int totalBoxes,
  }) async {
    try {
      final packingSlip = PackingSlip(
        id: _firestore.collection('dummy').doc().id,
        orderId: orderId,
        pickListId: pickListId,
        warehouseId: warehouseId,
        items: items,
        totalItems: items.fold(0, (sum, item) => sum + item.quantity),
        totalBoxes: totalBoxes,
        createdAt: DateTime.now(),
        status: 'draft',
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('packing_slips')
          .add(packingSlip.toFirestore());

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark packing slip as printed
  Future<void> markAsPrinted(String warehouseId, String slipId) async {
    try {
      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('packing_slips')
          .doc(slipId)
          .update({
        'printedAt': FieldValue.serverTimestamp(),
        'status': 'printed',
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get packing slip content for PDF generation
  Future<PackingSlip?> getPackingSlip(String warehouseId, String slipId) async {
    try {
      final doc = await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('packing_slips')
          .doc(slipId)
          .get();

      if (doc.exists) {
        return PackingSlip.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generate PDF content (returns formatted text for display)
  String generatePackingSlipPDF(
    PackingSlip slip,
    String companyName,
    String warehouseName,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('═' * 80);
    buffer.writeln(' ' * 20 + companyName.toUpperCase());
    buffer.writeln('Packing Slip #${slip.id.substring(0, 8).toUpperCase()}');
    buffer.writeln('═' * 80);
    buffer.writeln('');

    // Order & Warehouse Info
    buffer.writeln('ORDER INFORMATION');
    buffer.writeln('─' * 80);
    buffer.writeln('Order ID: ${slip.orderId}');
    buffer.writeln('Pick List: ${slip.pickListId}');
    buffer.writeln('Warehouse: $warehouseName');
    buffer.writeln('Generated: ${_formatDate(slip.createdAt)}');
    buffer.writeln('');

    // Items
    buffer.writeln('PACKED ITEMS');
    buffer.writeln('─' * 80);
    buffer.writeln('SKU         | PRODUCT NAME           | QTY | BOX');
    buffer.writeln('─' * 80);

    for (final item in slip.items) {
      buffer.writeln(
        '${item.sku.padRight(11)} | ${item.productName.padRight(22)} | ${item.quantity.toString().padRight(3)} | ${item.boxNumber}',
      );
    }

    buffer.writeln('─' * 80);
    buffer.writeln('Total Items: ${slip.totalItems} | Total Boxes: ${slip.totalBoxes}');
    buffer.writeln('');

    // Footer
    buffer.writeln('═' * 80);
    buffer.writeln('Packed by: _________________  Date: _________________');
    buffer.writeln('Verified by: ________________  Date: _________________');
    buffer.writeln('═' * 80);

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get all packing slips for warehouse
  Future<List<PackingSlip>> getWarehousePackingSlips(
    String warehouseId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('packing_slips')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PackingSlip.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Mark packing slip as completed (ready for shipping)
  Future<void> markAsCompleted(
    String warehouseId,
    String slipId,
    String completedBy,
  ) async {
    try {
      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('packing_slips')
          .doc(slipId)
          .update({
        'packingCompletedId': completedBy,
        'status': 'completed',
      });

      // Audit log
      await _auditLogService.logAction(
        completedBy,
        auth_role.UserRole.warehouseStaff.name,
        AuditAction.PACKING_COMPLETED,
        'packing_slip',
        resourceId: slipId,
        severity: AuditSeverity.INFO,
        details: {
          'warehouse_id': warehouseId,
          'slip_id': slipId,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

final packingSlipServiceProvider = Provider<PackingSlipService>((ref) {
  return PackingSlipService();
});
