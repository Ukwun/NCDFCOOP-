import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/security/audit_log_service.dart';
import 'package:coop_commerce/core/auth/role.dart' as auth_role;

/// Data model for a picking task
class PickList {
  final String listId;
  final String orderId;
  final List<PickItem> items;
  final String? assignedToPicker;
  final String status; // 'created' | 'picking' | 'picked' | 'ready_for_pack'
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, int> lineItemsPicked; // {itemId: quantityPicked}

  PickList({
    required this.listId,
    required this.orderId,
    required this.items,
    this.assignedToPicker,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.lineItemsPicked,
  });

  factory PickList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PickList(
      listId: doc.id,
      orderId: data['orderId'] ?? '',
      items: List<PickItem>.from(
        (data['items'] ?? []).map((item) => PickItem.fromMap(item)),
      ),
      assignedToPicker: data['assigned_to_picker'],
      status: data['status'] ?? 'created',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
      lineItemsPicked: Map<String, int>.from(
        data['line_items_picked'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'items': items.map((item) => item.toMap()).toList(),
        'assigned_to_picker': assignedToPicker,
        'status': status,
        'created_at': createdAt,
        'completed_at': completedAt,
        'line_items_picked': lineItemsPicked,
      };
}

/// Individual item in a pick list
class PickItem {
  final String itemId;
  final String productId;
  final String productName;
  final int quantity;
  final String sku;
  final String warehouseLocation;

  PickItem({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sku,
    required this.warehouseLocation,
  });

  factory PickItem.fromMap(Map<String, dynamic> data) {
    return PickItem(
      itemId: data['itemId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      sku: data['sku'] ?? '',
      warehouseLocation: data['warehouseLocation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'sku': sku,
        'warehouseLocation': warehouseLocation,
      };
}

/// Packing task and verification
class PackingLog {
  final String packId;
  final String pickListId;
  final String orderId;
  final List<PackedItem> packedItems;
  final String assignedToPacker;
  final String status; // 'in_progress' | 'qc_ready' | 'qc_passed' | 'qc_failed'
  final bool qcChecked;
  final String? qcNotes;
  final DateTime packedAt;
  final DateTime? qcCheckedAt;

  PackingLog({
    required this.packId,
    required this.pickListId,
    required this.orderId,
    required this.packedItems,
    required this.assignedToPacker,
    required this.status,
    required this.qcChecked,
    this.qcNotes,
    required this.packedAt,
    this.qcCheckedAt,
  });

  factory PackingLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackingLog(
      packId: doc.id,
      pickListId: data['pickListId'] ?? '',
      orderId: data['orderId'] ?? '',
      packedItems: List<PackedItem>.from(
        (data['packed_items'] ?? []).map((item) => PackedItem.fromMap(item)),
      ),
      assignedToPacker: data['assigned_to_packer'] ?? '',
      status: data['status'] ?? 'in_progress',
      qcChecked: data['qc_checked'] ?? false,
      qcNotes: data['qc_notes'],
      packedAt: (data['packed_at'] as Timestamp).toDate(),
      qcCheckedAt: data['qc_checked_at'] != null
          ? (data['qc_checked_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'pickListId': pickListId,
        'orderId': orderId,
        'packed_items': packedItems.map((item) => item.toMap()).toList(),
        'assigned_to_packer': assignedToPacker,
        'status': status,
        'qc_checked': qcChecked,
        'qc_notes': qcNotes,
        'packed_at': packedAt,
        'qc_checked_at': qcCheckedAt,
      };
}

/// Item that has been packed into a box
class PackedItem {
  final String itemId;
  final int actualQuantity;
  final int boxNumber;

  PackedItem({
    required this.itemId,
    required this.actualQuantity,
    required this.boxNumber,
  });

  factory PackedItem.fromMap(Map<String, dynamic> data) {
    return PackedItem(
      itemId: data['itemId'] ?? '',
      actualQuantity: data['actualQuantity'] ?? 0,
      boxNumber: data['boxNumber'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'actualQuantity': actualQuantity,
        'boxNumber': boxNumber,
      };
}

/// Daily warehouse operations metrics
class WarehouseMetrics {
  final String date;
  final int ordersReceived;
  final int ordersPicked;
  final int ordersPacked;
  final int ordersReadyForDispatch;
  final double avgPickTimeMinutes;
  final double qcPassRate;
  final List<WarehouseIssue> issueLog;

  WarehouseMetrics({
    required this.date,
    required this.ordersReceived,
    required this.ordersPicked,
    required this.ordersPacked,
    required this.ordersReadyForDispatch,
    required this.avgPickTimeMinutes,
    required this.qcPassRate,
    required this.issueLog,
  });

  factory WarehouseMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WarehouseMetrics(
      date: data['date'] ?? '',
      ordersReceived: data['orders_received'] ?? 0,
      ordersPicked: data['orders_picked'] ?? 0,
      ordersPacked: data['orders_packed'] ?? 0,
      ordersReadyForDispatch: data['orders_ready_for_dispatch'] ?? 0,
      avgPickTimeMinutes: (data['avg_pick_time_minutes'] ?? 0).toDouble(),
      qcPassRate: (data['qc_pass_rate'] ?? 100).toDouble(),
      issueLog: List<WarehouseIssue>.from(
        (data['issue_log'] ?? []).map((issue) => WarehouseIssue.fromMap(issue)),
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'date': date,
        'orders_received': ordersReceived,
        'orders_picked': ordersPicked,
        'orders_packed': ordersPacked,
        'orders_ready_for_dispatch': ordersReadyForDispatch,
        'avg_pick_time_minutes': avgPickTimeMinutes,
        'qc_pass_rate': qcPassRate,
        'issue_log': issueLog.map((issue) => issue.toMap()).toList(),
      };
}

/// A warehouse issue (damage, discrepancy, etc.)
class WarehouseIssue {
  final DateTime time;
  final String type; // 'damage' | 'discrepancy' | 'missing_item' | 'qc_failure'
  final String orderId;
  final String notes;

  WarehouseIssue({
    required this.time,
    required this.type,
    required this.orderId,
    required this.notes,
  });

  factory WarehouseIssue.fromMap(Map<String, dynamic> data) {
    return WarehouseIssue(
      time: (data['time'] as Timestamp).toDate(),
      type: data['type'] ?? '',
      orderId: data['orderId'] ?? '',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'time': time,
        'type': type,
        'orderId': orderId,
        'notes': notes,
      };
}

/// Main warehouse service
class WarehouseService {
  final FirebaseFirestore _firestore;
  final AuditLogService _auditLogService;

  WarehouseService({
    required FirebaseFirestore firestore,
    AuditLogService? auditLogService,
  })  : _firestore = firestore,
        _auditLogService = auditLogService ?? AuditLogService();

  /// Check if user role has warehouse access
  bool _hasWarehouseAccess(auth_role.UserRole userRole) {
    return userRole == auth_role.UserRole.warehouseStaff ||
        userRole == auth_role.UserRole.admin ||
        userRole == auth_role.UserRole.superAdmin;
  }

  /// Generate pick list from order with permission check
  /// Converts order into picking tasks
  Future<PickList> generatePickList(
    String orderId, {
    String? userId,
    auth_role.UserRole? userRole,
  }) async {
    try {
      // Check permission to assign task
      if (userId != null && userRole != null) {
        final roleString = userRole.name;
        if (!_hasWarehouseAccess(userRole)) {
          await _auditLogService.logAction(
            userId,
            roleString,
            AuditAction.PERMISSION_CHECK_FAILED,
            'pick_list',
            resourceId: orderId,
            severity: AuditSeverity.WARNING,
            details: {'attempted_action': 'generate_pick_list'},
          );
          throw Exception(
            'User cannot generate pick lists',
          );
        }
      }

      // Get order
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found: $orderId');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final items = orderData['items'] ?? [];

      // Create pick items
      final pickItems = <PickItem>[];
      for (final item in items) {
        pickItems.add(
          PickItem(
            itemId: item['id'] ?? '',
            productId: item['productId'] ?? '',
            productName: item['productName'] ?? '',
            quantity: item['quantity'] ?? 0,
            sku: item['sku'] ?? '',
            warehouseLocation: item['warehouseLocation'] ??
                'SECTION_A-RACK_1-SHELF_3', // Mock location
          ),
        );
      }

      // Create pick list doc
      final listId = 'PL_${DateTime.now().yyyyMMdd}_${_generateId()}';
      final pickList = PickList(
        listId: listId,
        orderId: orderId,
        items: pickItems,
        assignedToPicker: null,
        status: 'created',
        createdAt: DateTime.now(),
        lineItemsPicked: {},
      );

      // Save to Firestore
      await _firestore
          .collection('pick_lists')
          .doc(listId)
          .set(pickList.toFirestore());

      // Update order status
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({'status': 'picking'});

      // Log task creation
      if (userId != null && userRole != null) {
        await _auditLogService.logAction(
          userId,
          userRole.name,
          AuditAction.TASK_ASSIGNED,
          'pick_list',
          resourceId: listId,
          severity: AuditSeverity.INFO,
          details: {
            'order_id': orderId,
            'item_count': pickItems.length,
            'action': 'generate_pick_list',
          },
        );
      }

      return pickList;
    } catch (e) {
      // Error generating pick list - rethrow for caller handling
      rethrow;
    }
  }

  /// Scan item barcode to update pick progress
  /// Returns true if item was found and updated
  Future<bool> scanItem(String pickListId, String barcode) async {
    try {
      final pickListDoc = _firestore.collection('pick_lists').doc(pickListId);
      final pickListSnapshot = await pickListDoc.get();

      if (!pickListSnapshot.exists) {
        throw Exception('Pick list not found: $pickListId');
      }

      final pickList = PickList.fromFirestore(pickListSnapshot);

      // Find item by SKU (assuming barcode == SKU)
      final item = pickList.items.firstWhere(
        (i) => i.sku == barcode,
        orElse: () => throw Exception('Item not found in pick list'),
      );

      // Increment picked count
      final currentPicked = pickList.lineItemsPicked[item.itemId] ?? 0;
      await updatePickProgress(pickListId, item.itemId, currentPicked + 1);
      return true;
    } catch (e) {
      // Error scanning item
      return false;
    }
  }

  /// Get all active pick lists
  Future<List<PickList>> getActivePickLists() async {
    try {
      final snapshot = await _firestore.collection('pick_lists').where('status',
          whereIn: ['created', 'picking', 'picked', 'ready_for_pack']).get();

      return snapshot.docs.map((doc) => PickList.fromFirestore(doc)).toList();
    } catch (e) {
      // Error fetching active pick lists
      rethrow;
    }
  }

  /// Update pick progress (staff marks items as picked)
  Future<void> updatePickProgress(
    String pickListId,
    String itemId,
    int quantityPicked,
  ) async {
    try {
      final pickListDoc = _firestore.collection('pick_lists').doc(pickListId);
      final pickListSnapshot = await pickListDoc.get();

      if (!pickListSnapshot.exists) {
        throw Exception('Pick list not found: $pickListId');
      }

      // Update line items picked
      await pickListDoc.update({
        'line_items_picked.$itemId': quantityPicked,
        'status': 'picking',
      });
    } catch (e) {
      // Error updating pick progress
      rethrow;
    }
  }

  /// Complete pick list and move to packing
  Future<void> completePickList(String pickListId) async {
    try {
      await _firestore.collection('pick_lists').doc(pickListId).update({
        'status': 'ready_for_pack',
        'completed_at': DateTime.now(),
      });
    } catch (e) {
      // Error completing pick list
      rethrow;
    }
  }

  /// Get packing task (create from pick list)
  Future<PackingLog> getPackingTask(String pickListId) async {
    try {
      final pickListDoc =
          await _firestore.collection('pick_lists').doc(pickListId).get();

      if (!pickListDoc.exists) {
        throw Exception('Pick list not found: $pickListId');
      }

      final pickList = PickList.fromFirestore(pickListDoc);

      // Create packing log
      final packId = 'PK_${DateTime.now().yyyyMMdd}_${_generateId()}';
      final packingLog = PackingLog(
        packId: packId,
        pickListId: pickListId,
        orderId: pickList.orderId,
        packedItems: [],
        assignedToPacker: '',
        status: 'in_progress',
        qcChecked: false,
        packedAt: DateTime.now(),
      );

      // Save packing log
      await _firestore
          .collection('packing_logs')
          .doc(packId)
          .set(packingLog.toFirestore());

      return packingLog;
    } catch (e) {
      // Error getting packing task
      rethrow;
    }
  }

  /// Add item to pack (verify items going into box)
  Future<void> addItemToPack(
    String packId,
    String itemId,
    int actualQuantity,
    int boxNumber,
  ) async {
    try {
      final packingLog = _firestore.collection('packing_logs').doc(packId);

      // Add to packed_items
      final packedItem = PackedItem(
        itemId: itemId,
        actualQuantity: actualQuantity,
        boxNumber: boxNumber,
      );

      await packingLog.update({
        'packed_items': FieldValue.arrayUnion([packedItem.toMap()]),
      });
    } catch (e) {
      // Error adding item to pack
      rethrow;
    }
  }

  /// Mark packing as ready for QC
  Future<void> readyForQC(String packId) async {
    try {
      await _firestore
          .collection('packing_logs')
          .doc(packId)
          .update({'status': 'qc_ready'});
    } catch (e) {
      // Error marking ready for QC
      rethrow;
    }
  }

  /// Perform QC check (pass/fail)
  Future<void> performQC(
    String packId,
    bool passed,
    String? notes,
  ) async {
    try {
      final packingLog = _firestore.collection('packing_logs').doc(packId);

      // Update packing log
      await packingLog.update({
        'qc_checked': true,
        'qc_checked_at': DateTime.now(),
        'status': passed ? 'qc_passed' : 'qc_failed',
        'qc_notes': notes,
      });

      // If QC passed, mark order ready for dispatch
      if (passed) {
        final packDoc = await packingLog.get();
        final orderId = packDoc['orderId'];
        await markReadyForDispatch(orderId);
      }
    } catch (e) {
      // Error performing QC
      rethrow;
    }
  }

  /// Mark order as ready for dispatch
  Future<void> markReadyForDispatch(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'ready_for_dispatch',
        'warehouse_completed_at': DateTime.now(),
      });
    } catch (e) {
      // Error marking ready for dispatch
      rethrow;
    }
  }

  /// Get today's warehouse metrics
  Future<WarehouseMetrics> getTodayMetrics() async {
    try {
      final date = DateTime.now().yyyyMMdd;
      final doc = await _firestore
          .collection('warehouse_operations')
          .doc('WAREHOUSE_$date')
          .get();

      if (doc.exists) {
        return WarehouseMetrics.fromFirestore(doc);
      }

      // Return empty metrics if not found
      return WarehouseMetrics(
        date: date,
        ordersReceived: 0,
        ordersPicked: 0,
        ordersPacked: 0,
        ordersReadyForDispatch: 0,
        avgPickTimeMinutes: 0,
        qcPassRate: 100,
        issueLog: [],
      );
    } catch (e) {
      // Error getting today metrics
      rethrow;
    }
  }

  /// Watch picking queue (active orders needing picking)
  Stream<List<Map<String, dynamic>>> watchPickingQueue() {
    try {
      return _firestore
          .collection('orders')
          .where('status', isEqualTo: 'picking')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      // Error watching picking queue
      rethrow;
    }
  }

  /// Watch packing queue (ready-to-pack items)
  Stream<List<PickList>> watchPackingQueue() {
    try {
      return _firestore
          .collection('pick_lists')
          .where('status', isEqualTo: 'ready_for_pack')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => PickList.fromFirestore(doc)).toList());
    } catch (e) {
      // Error watching packing queue
      rethrow;
    }
  }

  /// Log a warehouse issue
  Future<void> logIssue(
    String type,
    String orderId,
    String notes,
  ) async {
    try {
      final date = DateTime.now().yyyyMMdd;
      final docId = 'WAREHOUSE_$date';

      final issue = WarehouseIssue(
        time: DateTime.now(),
        type: type,
        orderId: orderId,
        notes: notes,
      );

      await _firestore.collection('warehouse_operations').doc(docId).update({
        'issue_log': FieldValue.arrayUnion([issue.toMap()]),
      });
    } catch (e) {
      // Error logging issue
      rethrow;
    }
  }

  /// Generate ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10);
  }
}

/// Extension for date formatting
extension DateFormatting on DateTime {
  String get yyyyMMdd {
    return '$year${month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}';
  }
}
