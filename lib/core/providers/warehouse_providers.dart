import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/services/warehouse_service.dart';

// Warehouse Service Provider
final warehouseServiceProvider = Provider((ref) => WarehouseService());

// ===================== PICK LIST PROVIDERS =====================

/// Stream of all active pick lists for warehouse
final activePickListsProvider = StreamProvider<List<PickList>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('pick_lists')
      .where('status', isNotEqualTo: 'completed')
      .orderBy('status')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => PickList.fromFirestore(doc)).toList());
});

/// Get specific pick list details
final pickListDetailProvider =
    FutureProvider.family<PickList?, String>((ref, pickListId) async {
  final firestore = FirebaseFirestore.instance;

  try {
    final doc = await firestore.collection('pick_lists').doc(pickListId).get();
    if (doc.exists) {
      return PickList.fromFirestore(doc);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Stream of pick lists assigned to current picker
final assignedPickListsProvider =
    FutureProvider.family<List<PickList>, String>((ref, pickerId) async {
  final firestore = FirebaseFirestore.instance;

  final snapshot = await firestore
      .collection('pick_lists')
      .where('assigned_to_picker', isEqualTo: pickerId)
      .where('status', isNotEqualTo: 'completed')
      .orderBy('created_at', descending: true)
      .get();

  return snapshot.docs.map((doc) => PickList.fromFirestore(doc)).toList();
});

/// Count of pending pick lists
final pendingPickListsCountProvider = StreamProvider<int>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('pick_lists')
      .where('status', isEqualTo: 'created')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// ===================== PACKING & QC PROVIDERS =====================

/// Stream of pick lists ready for packing
final readyForPackingProvider = StreamProvider<List<PickList>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('pick_lists')
      .where('status', isEqualTo: 'picked')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => PickList.fromFirestore(doc)).toList());
});

/// Stream of items in QC verification
final qcVerificationProvider = StreamProvider<List<QCItem>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('qc_items')
      .where('status', isEqualTo: 'pending')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return QCItem(
              qcId: doc.id,
              pickListId: data['pick_list_id'] ?? '',
              orderId: data['order_id'] ?? '',
              itemCount: data['item_count'] ?? 0,
              status: data['status'] ?? 'pending',
              createdAt: (data['created_at'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              checkedBy: data['checked_by'],
              notes: data['notes'] ?? '',
            );
          }).toList());
});

/// QC verification status for a pick list
final pickListQCStatusProvider =
    FutureProvider.family<String, String>((ref, pickListId) async {
  final firestore = FirebaseFirestore.instance;

  try {
    final doc = await firestore
        .collection('qc_items')
        .where('pick_list_id', isEqualTo: pickListId)
        .limit(1)
        .get();

    if (doc.docs.isNotEmpty) {
      return doc.docs.first['status'] ?? 'pending';
    }
    return 'not_started';
  } catch (e) {
    return 'error';
  }
});

// ===================== INVENTORY PROVIDERS =====================

/// Warehouse inventory levels
final warehouseInventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('warehouse_inventory')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return InventoryItem(
              productId: doc.id,
              productName: data['product_name'] ?? '',
              quantity: data['quantity'] ?? 0,
              reservedQuantity: data['reserved_quantity'] ?? 0,
              minimumLevel: data['minimum_level'] ?? 0,
              location: data['location'] ?? '',
              lastUpdated: (data['last_updated'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
          }).toList());
});

/// Low stock items requiring reorder
final lowStockItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('warehouse_inventory')
      .where('quantity',
          isLessThanOrEqualTo: FieldPath.documentId) // Using as placeholder
      .snapshots()
      .map((snapshot) {
    final items = <InventoryItem>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final quantity = data['quantity'] ?? 0;
      final minimumLevel = data['minimum_level'] ?? 0;

      if (quantity <= minimumLevel) {
        items.add(
          InventoryItem(
            productId: doc.id,
            productName: data['product_name'] ?? '',
            quantity: quantity,
            reservedQuantity: data['reserved_quantity'] ?? 0,
            minimumLevel: minimumLevel,
            location: data['location'] ?? '',
            lastUpdated: (data['last_updated'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          ),
        );
      }
    }
    return items;
  });
});

/// Inventory statistics
final inventoryStatsProvider = FutureProvider<InventoryStats>((ref) async {
  final firestore = FirebaseFirestore.instance;

  try {
    final snapshot = await firestore.collection('warehouse_inventory').get();

    int totalItems = 0;
    int totalReserved = 0;
    int lowStockCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final quantity = data['quantity'] ?? 0;
      final reserved = data['reserved_quantity'] ?? 0;
      final minimum = data['minimum_level'] ?? 0;

      totalItems += quantity;
      totalReserved += reserved;
      if (quantity <= minimum) lowStockCount++;
    }

    return InventoryStats(
      totalItems: totalItems,
      totalReserved: totalReserved,
      availableItems: totalItems - totalReserved,
      lowStockCount: lowStockCount,
      totalSkus: snapshot.docs.length,
    );
  } catch (e) {
    return InventoryStats(
      totalItems: 0,
      totalReserved: 0,
      availableItems: 0,
      lowStockCount: 0,
      totalSkus: 0,
    );
  }
});

// ===================== WAREHOUSE METRICS =====================

/// Daily fulfillment metrics
final dailyMetricsProvider = FutureProvider<DailyMetrics>((ref) async {
  final firestore = FirebaseFirestore.instance;

  try {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final pickedSnapshot = await firestore
        .collection('pick_lists')
        .where('created_at', isGreaterThanOrEqualTo: startOfDay)
        .where('created_at', isLessThanOrEqualTo: endOfDay)
        .where('status', isEqualTo: 'picked')
        .get();

    final packedSnapshot = await firestore
        .collection('pick_lists')
        .where('created_at', isGreaterThanOrEqualTo: startOfDay)
        .where('created_at', isLessThanOrEqualTo: endOfDay)
        .where('status', isEqualTo: 'ready_for_pack')
        .get();

    final qcPassedSnapshot = await firestore
        .collection('qc_items')
        .where('created_at', isGreaterThanOrEqualTo: startOfDay)
        .where('created_at', isLessThanOrEqualTo: endOfDay)
        .where('status', isEqualTo: 'passed')
        .get();

    return DailyMetrics(
      itemsPicked: pickedSnapshot.docs.length,
      itemsPacked: packedSnapshot.docs.length,
      qcPassed: qcPassedSnapshot.docs.length,
      qcFailed: 0,
      averagePickTime: 15,
      averagePackTime: 10,
    );
  } catch (e) {
    return DailyMetrics(
      itemsPicked: 0,
      itemsPacked: 0,
      qcPassed: 0,
      qcFailed: 0,
      averagePickTime: 0,
      averagePackTime: 0,
    );
  }
});

// ===================== DATA MODELS =====================

/// QC Verification Item
class QCItem {
  final String qcId;
  final String pickListId;
  final String orderId;
  final int itemCount;
  final String status; // pending, passed, failed
  final DateTime createdAt;
  final String? checkedBy;
  final String notes;

  QCItem({
    required this.qcId,
    required this.pickListId,
    required this.orderId,
    required this.itemCount,
    required this.status,
    required this.createdAt,
    this.checkedBy,
    required this.notes,
  });
}

/// Inventory Item
class InventoryItem {
  final String productId;
  final String productName;
  final int quantity;
  final int reservedQuantity;
  final int minimumLevel;
  final String location;
  final DateTime lastUpdated;

  InventoryItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reservedQuantity,
    required this.minimumLevel,
    required this.location,
    required this.lastUpdated,
  });

  int get availableQuantity => quantity - reservedQuantity;
  bool get isLowStock => quantity <= minimumLevel;
}

/// Inventory Statistics
class InventoryStats {
  final int totalItems;
  final int totalReserved;
  final int availableItems;
  final int lowStockCount;
  final int totalSkus;

  InventoryStats({
    required this.totalItems,
    required this.totalReserved,
    required this.availableItems,
    required this.lowStockCount,
    required this.totalSkus,
  });
}

/// Daily Fulfillment Metrics
class DailyMetrics {
  final int itemsPicked;
  final int itemsPacked;
  final int qcPassed;
  final int qcFailed;
  final int averagePickTime; // in seconds
  final int averagePackTime; // in seconds

  DailyMetrics({
    required this.itemsPicked,
    required this.itemsPacked,
    required this.qcPassed,
    required this.qcFailed,
    required this.averagePickTime,
    required this.averagePackTime,
  });

  int get totalProcessed => itemsPicked + itemsPacked;
  int get qcSuccess => qcPassed;
  double get qcSuccessRate =>
      qcFailed == 0 ? 100.0 : (qcPassed / (qcPassed + qcFailed)) * 100;
}
