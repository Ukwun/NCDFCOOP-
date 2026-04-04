import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Inventory Warning Service
/// Monitors stock levels and provides real-time inventory warnings
class InventoryWarningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _productsCollection = 'products';

  /// Get current stock level for a product
  Future<int> getStockLevel(String productId) async {
    try {
      final doc =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!doc.exists) {
        debugPrint('⚠️ Product not found: $productId');
        return 0;
      }

      final stock = doc.get('stock') as int? ?? 0;
      debugPrint('📦 Stock for $productId: $stock units');
      return stock;
    } catch (e) {
      debugPrint('❌ Error getting stock level: $e');
      return 0;
    }
  }

  /// Get real-time stock stream for a product
  Stream<int> watchStockLevel(String productId) {
    return _firestore
        .collection(_productsCollection)
        .doc(productId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 0;
      final stock = doc.get('stock') as int? ?? 0;
      return stock;
    }).handleError((e) {
      debugPrint('❌ Error watching stock: $e');
      return 0;
    });
  }

  /// Get inventory status for a product
  InventoryStatus getInventoryStatus(int currentStock) {
    if (currentStock <= 0) {
      return InventoryStatus.outOfStock;
    } else if (currentStock < 5) {
      return InventoryStatus.criticalLow;
    } else if (currentStock < 10) {
      return InventoryStatus.low;
    } else {
      return InventoryStatus.available;
    }
  }

  /// Get user-friendly message based on stock level
  String getStockMessage(int stock) {
    if (stock <= 0) {
      return '❌ Out of Stock';
    } else if (stock == 1) {
      return '⚠️ Only 1 left in stock!';
    } else if (stock < 5) {
      return '⚠️ Only $stock left in stock!';
    } else if (stock < 10) {
      return '📦 Limited stock: $stock available';
    } else {
      return '✅ In Stock';
    }
  }

  /// Validate if quantity is available
  bool canAddToCart(int currentStock, int requestedQuantity) {
    return currentStock >= requestedQuantity;
  }

  /// Check if product can be purchased
  bool isAvailableForPurchase(int stock) {
    return stock > 0;
  }

  /// Get color for inventory status
  /// Green = Available, Yellow = Low, Red = Out of Stock
  String getStatusColor(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.available:
        return '#10B981'; // Green
      case InventoryStatus.low:
        return '#F59E0B'; // Amber
      case InventoryStatus.criticalLow:
        return '#EF4444'; // Red
      case InventoryStatus.outOfStock:
        return '#DC2626'; // Dark Red
    }
  }

  /// Deduct stock from inventory (called after successful order)
  Future<bool> deductStock(String productId, int quantity) async {
    try {
      debugPrint('📉 Deducting $quantity units from $productId');

      final doc =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!doc.exists) {
        debugPrint('❌ Product not found: $productId');
        return false;
      }

      final currentStock = doc.get('stock') as int? ?? 0;

      if (currentStock < quantity) {
        debugPrint('❌ Insufficient stock: need $quantity, have $currentStock');
        return false;
      }

      // Update stock
      await _firestore.collection(_productsCollection).doc(productId).update({
        'stock': currentStock - quantity,
        'lastStockUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '✅ Stock deducted: $productId ($currentStock → ${currentStock - quantity})');
      return true;
    } catch (e) {
      debugPrint('❌ Error deducting stock: $e');
      return false;
    }
  }

  /// Restore stock (for cancelled orders)
  Future<bool> restoreStock(String productId, int quantity) async {
    try {
      debugPrint('📈 Restoring $quantity units to $productId');

      final doc =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!doc.exists) {
        debugPrint('❌ Product not found: $productId');
        return false;
      }

      final currentStock = doc.get('stock') as int? ?? 0;

      await _firestore.collection(_productsCollection).doc(productId).update({
        'stock': currentStock + quantity,
        'lastStockUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '✅ Stock restored: $productId ($currentStock → ${currentStock + quantity})');
      return true;
    } catch (e) {
      debugPrint('❌ Error restoring stock: $e');
      return false;
    }
  }

  /// Bulk check stock for multiple products
  Future<Map<String, int>> getBulkStockLevels(List<String> productIds) async {
    try {
      final results = <String, int>{};

      for (final productId in productIds) {
        final stock = await getStockLevel(productId);
        results[productId] = stock;
      }

      return results;
    } catch (e) {
      debugPrint('❌ Error getting bulk stock levels: $e');
      return {};
    }
  }

  /// Check if all items in cart are available
  Future<bool> validateCartInventory(
    Map<String, int> cartItems,
  ) async {
    try {
      for (final entry in cartItems.entries) {
        final productId = entry.key;
        final requestedQty = entry.value;
        final stock = await getStockLevel(productId);

        if (stock < requestedQty) {
          debugPrint(
              '❌ Insufficient stock for $productId: need $requestedQty, have $stock');
          return false;
        }
      }

      debugPrint('✅ All cart items have sufficient stock');
      return true;
    } catch (e) {
      debugPrint('❌ Error validating cart: $e');
      return false;
    }
  }
}

/// Inventory Status Enum
enum InventoryStatus {
  available, // 10+ in stock
  low, // 5-9 in stock
  criticalLow, // 1-4 in stock
  outOfStock, // 0 in stock
}
