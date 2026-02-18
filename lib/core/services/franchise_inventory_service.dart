import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Franchise inventory management with nightly sync + real-time cache
/// Architecture: Nightly batch updates Firestore; Redis cache (optional) for real-time
class FranchiseInventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _franchiseInventoryCollection = 'franchise_inventory';
  static const String _reorderHistoryCollection = 'reorder_history';

  // ===================== INVENTORY TRACKING =====================

  /// Record inventory for a franchise on a specific date (called nightly)
  Future<void> recordInventorySnapshot({
    required String franchiseId,
    required String storeId,
    required Map<String, InventoryItem> inventory,
    DateTime? recordDate,
  }) async {
    try {
      final date = (recordDate ?? DateTime.now());
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection(_franchiseInventoryCollection)
          .doc(franchiseId)
          .collection('store_snapshots')
          .doc(storeId)
          .collection('history')
          .doc(dateKey)
          .set({
        'date': FieldValue.serverTimestamp(),
        'recordedAt': dateKey,
        'items': {
          for (var entry in inventory.entries)
            entry.key: entry.value.toFirestore()
        },
        'summary': {
          'totalItems': inventory.length,
          'totalValue': _calculateTotalInventoryValue(inventory),
          'criticalStockItems': _getCriticalStockCount(inventory),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to record inventory snapshot: $e');
    }
  }

  /// Get current inventory for a franchise store
  Future<Map<String, InventoryItem>> getCurrentInventory(
    String franchiseId,
    String storeId,
  ) async {
    try {
      final doc = await _firestore
          .collection(_franchiseInventoryCollection)
          .doc(franchiseId)
          .collection('store_inventory')
          .doc(storeId)
          .get();

      if (!doc.exists) return {};

      final data = doc.data() as Map<String, dynamic>;
      final items = (data['items'] as Map<String, dynamic>? ?? {});

      return {
        for (var entry in items.entries)
          entry.key: InventoryItem.fromFirestore(entry.value)
      };
    } catch (e) {
      throw Exception('Failed to get current inventory: $e');
    }
  }

  /// Update single item inventory
  Future<void> updateInventoryItem({
    required String franchiseId,
    required String storeId,
    required String productId,
    required int newQuantity,
    String? reason, // 'sale', 'restock', 'damage', 'adjustment'
  }) async {
    try {
      final inventoryRef = _firestore
          .collection(_franchiseInventoryCollection)
          .doc(franchiseId)
          .collection('store_inventory')
          .doc(storeId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(inventoryRef);
        final currentData = doc.data() ?? {};
        final items = currentData['items'] as Map<String, dynamic>? ?? {};
        final currentItem = items[productId] != null
            ? InventoryItem.fromFirestore(items[productId])
            : null;

        if (currentItem != null) {
          final previousQty = currentItem.quantity;
          final updatedItem = currentItem.copyWith(quantity: newQuantity);

          transaction.set(
            inventoryRef,
            {
              'items': {productId: updatedItem.toFirestore()},
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // Log the change
          await _logInventoryChange(
            franchiseId,
            storeId,
            productId,
            previousQty,
            newQuantity,
            reason ?? 'manual',
          );
        }
      });
    } catch (e) {
      throw Exception('Failed to update inventory item: $e');
    }
  }

  // ===================== DAYS-OF-COVER CALCULATION =====================

  /// Calculate days-of-cover for all products in a store
  /// DOC = Current Qty / Avg Daily Sales
  Future<Map<String, int>> calculateDaysOfCover({
    required String franchiseId,
    required String storeId,
    int lookbackDays = 30,
  }) async {
    try {
      // Get current inventory
      final currentInventory = await getCurrentInventory(franchiseId, storeId);

      // Get average daily sales for last N days
      final avgDailySales =
          await _getAverageDailySales(franchiseId, storeId, lookbackDays);

      // Calculate DOC for each product
      final doc = <String, int>{};
      for (var entry in currentInventory.entries) {
        final productId = entry.key;
        final item = entry.value;
        final avgDaily = avgDailySales[productId] ?? 0;

        if (avgDaily > 0) {
          doc[productId] = (item.quantity / avgDaily).ceil();
        } else {
          doc[productId] = 999; // No sales data, assume high DOC
        }
      }

      return doc;
    } catch (e) {
      throw Exception('Failed to calculate days-of-cover: $e');
    }
  }

  /// Get products with critical stock (DOC < 5 days)
  Future<List<CriticalStockAlert>> getCriticalStockAlerts({
    required String franchiseId,
    required String storeId,
    int criticalThresholdDays = 5,
  }) async {
    try {
      final doc = await calculateDaysOfCover(
        franchiseId: franchiseId,
        storeId: storeId,
      );

      final inventory = await getCurrentInventory(franchiseId, storeId);

      final alerts = <CriticalStockAlert>[];
      for (var entry in doc.entries) {
        if (entry.value < criticalThresholdDays) {
          final item = inventory[entry.key];
          if (item != null) {
            alerts.add(CriticalStockAlert(
              productId: entry.key,
              productName: item.productName,
              currentQuantity: item.quantity,
              daysOfCover: entry.value,
              alertLevel:
                  entry.value <= 2 ? AlertLevel.critical : AlertLevel.warning,
            ));
          }
        }
      }

      // Sort by urgency
      alerts.sort((a, b) => a.daysOfCover.compareTo(b.daysOfCover));
      return alerts;
    } catch (e) {
      throw Exception('Failed to get critical stock alerts: $e');
    }
  }

  // ===================== REORDER AUTOMATION =====================

  /// Check inventory levels and auto-trigger reorders
  /// Called during nightly sync job
  Future<List<AutoReorderSuggestion>> getReorderSuggestions({
    required String franchiseId,
    required String storeId,
    int minDaysOfCover = 10,
    int maxDaysOfCover = 30,
  }) async {
    try {
      final doc = await calculateDaysOfCover(
        franchiseId: franchiseId,
        storeId: storeId,
      );

      final inventory = await getCurrentInventory(franchiseId, storeId);

      final suggestions = <AutoReorderSuggestion>[];
      for (var entry in doc.entries) {
        final daysOfCover = entry.value;

        // Suggest reorder if DOC drops below minimum
        if (daysOfCover < minDaysOfCover) {
          final item = inventory[entry.key];
          if (item != null && !item.isOutOfStock) {
            final targetQty = _calculateOptimalReorderQty(
              currentQty: item.quantity,
              targetDays: maxDaysOfCover,
              avgDailySales: (item.quantity / daysOfCover).ceil(),
            );

            suggestions.add(AutoReorderSuggestion(
              productId: entry.key,
              productName: item.productName,
              currentQuantity: item.quantity,
              suggestedOrderQuantity: targetQty,
              reason:
                  'Days-of-cover below minimum ($daysOfCover/$minDaysOfCover)',
              priority: daysOfCover <= 3
                  ? ReorderPriority.urgent
                  : ReorderPriority.high,
            ));
          }
        }
      }

      return suggestions;
    } catch (e) {
      throw Exception('Failed to get reorder suggestions: $e');
    }
  }

  /// Create automatic reorder purchase order
  Future<String> createAutoReorder({
    required String franchiseId,
    required String storeId,
    required List<AutoReorderSuggestion> suggestions,
  }) async {
    try {
      final poId = const Uuid().v4();

      await _firestore
          .collection(_franchiseInventoryCollection)
          .doc(franchiseId)
          .collection('auto_reorders')
          .doc(poId)
          .set({
        'poId': poId,
        'storeId': storeId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'auto_generated', // awaiting_approval, approved, ordered
        'items': [
          for (var suggestion in suggestions)
            {
              'productId': suggestion.productId,
              'productName': suggestion.productName,
              'quantity': suggestion.suggestedOrderQuantity,
              'reason': suggestion.reason,
              'priority': suggestion.priority.toString(),
            }
        ],
        'totalItems': suggestions.length,
        'approvedBy': null,
        'approvedAt': null,
      });

      // Create reorder history record
      await _firestore
          .collection(_reorderHistoryCollection)
          .doc(franchiseId)
          .collection('store_history')
          .doc(storeId)
          .collection('records')
          .doc(poId)
          .set({
        'poId': poId,
        'type': 'auto_generated',
        'createdAt': FieldValue.serverTimestamp(),
        'itemCount': suggestions.length,
      });

      return poId;
    } catch (e) {
      throw Exception('Failed to create auto reorder: $e');
    }
  }

  // ===================== HELPERS =====================

  double _calculateTotalInventoryValue(
    Map<String, InventoryItem> inventory,
  ) {
    return inventory.values.fold(
      0,
      (sum, item) => sum + (item.costPrice * item.quantity),
    );
  }

  int _getCriticalStockCount(Map<String, InventoryItem> inventory) {
    return inventory.values
        .where((item) => item.quantity <= item.minStockLevel)
        .length;
  }

  Future<Map<String, double>> _getAverageDailySales(
    String franchiseId,
    String storeId,
    int days,
  ) async {
    try {
      // This queries order history for the store
      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('orders')
          .where('storeId', isEqualTo: storeId)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .get();

      final salesByProduct = <String, List<int>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List? ?? [];

        for (final item in items) {
          final productId = item['productId'];
          final qty = (item['quantity'] as num).toInt();

          if (!salesByProduct.containsKey(productId)) {
            salesByProduct[productId] = [];
          }
          salesByProduct[productId]!.add(qty);
        }
      }

      // Calculate average per product
      final avgDaily = <String, double>{};
      for (var entry in salesByProduct.entries) {
        final total = entry.value.fold<int>(0, (sum, qty) => sum + qty);
        avgDaily[entry.key] = total / days;
      }

      return avgDaily;
    } catch (e) {
      throw Exception('Failed to calculate average daily sales: $e');
    }
  }

  int _calculateOptimalReorderQty({
    required int currentQty,
    required int targetDays,
    required int avgDailySales,
  }) {
    final targetQty = avgDailySales * targetDays;
    return (targetQty - currentQty).ceil();
  }

  Future<void> _logInventoryChange(
    String franchiseId,
    String storeId,
    String productId,
    int previousQty,
    int newQty,
    String reason,
  ) async {
    try {
      await _firestore
          .collection(_franchiseInventoryCollection)
          .doc(franchiseId)
          .collection('store_inventory')
          .doc(storeId)
          .collection('change_log')
          .add({
        'productId': productId,
        'previousQuantity': previousQty,
        'newQuantity': newQty,
        'change': newQty - previousQty,
        'reason': reason,
        'changedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - logging should not block operations
      print('Failed to log inventory change: $e');
    }
  }
}

// ===================== DATA MODELS =====================

class InventoryItem {
  final String productId;
  final String productName;
  final int quantity;
  final int minStockLevel;
  final double costPrice;
  final double retailPrice;
  final String unit;
  final bool isOutOfStock;
  final DateTime lastRestocked;

  InventoryItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.minStockLevel,
    required this.costPrice,
    required this.retailPrice,
    required this.unit,
    this.isOutOfStock = false,
    required this.lastRestocked,
  });

  InventoryItem copyWith({
    int? quantity,
    bool? isOutOfStock,
  }) {
    return InventoryItem(
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      minStockLevel: minStockLevel,
      costPrice: costPrice,
      retailPrice: retailPrice,
      unit: unit,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      lastRestocked: lastRestocked,
    );
  }

  factory InventoryItem.fromFirestore(dynamic data) {
    if (data is Map<String, dynamic>) {
      return InventoryItem(
        productId: data['productId'] as String,
        productName: data['productName'] as String,
        quantity: data['quantity'] as int,
        minStockLevel: data['minStockLevel'] as int,
        costPrice: (data['costPrice'] as num).toDouble(),
        retailPrice: (data['retailPrice'] as num).toDouble(),
        unit: data['unit'] as String,
        isOutOfStock: data['isOutOfStock'] as bool? ?? false,
        lastRestocked: DateTime.parse(data['lastRestocked'] as String),
      );
    }
    return InventoryItem(
      productId: '',
      productName: '',
      quantity: 0,
      minStockLevel: 0,
      costPrice: 0,
      retailPrice: 0,
      unit: 'unit',
      lastRestocked: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'minStockLevel': minStockLevel,
      'costPrice': costPrice,
      'retailPrice': retailPrice,
      'unit': unit,
      'isOutOfStock': isOutOfStock,
      'lastRestocked': lastRestocked.toIso8601String(),
    };
  }
}

class CriticalStockAlert {
  final String productId;
  final String productName;
  final int currentQuantity;
  final int daysOfCover;
  final AlertLevel alertLevel;

  CriticalStockAlert({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.daysOfCover,
    required this.alertLevel,
  });
}

class AutoReorderSuggestion {
  final String productId;
  final String productName;
  final int currentQuantity;
  final int suggestedOrderQuantity;
  final String reason;
  final ReorderPriority priority;

  AutoReorderSuggestion({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.suggestedOrderQuantity,
    required this.reason,
    required this.priority,
  });
}

enum AlertLevel { warning, critical }

enum ReorderPriority { normal, high, urgent }
