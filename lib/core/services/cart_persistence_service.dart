import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/providers/cart_provider.dart';

/// Cart persistence service - Saves cart to Firestore
class CartPersistenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cartsCollection = 'shopping_carts';

  /// Save cart to Firestore (persistent across sessions)
  Future<void> saveCart(String userId, List<CartItem> items) async {
    try {
      debugPrint('💾 Saving cart to Firestore for user: $userId');

      final cartData = {
        'userId': userId,
        'items': items.map((item) => item.toJson()).toList(),
        'itemCount': items.fold(0, (sum, item) => sum + item.quantity),
        'subtotal': items.fold(0.0, (sum, item) => sum + item.totalPrice),
        'totalMarketPrice': items.fold(0.0, (sum, item) => sum + item.totalMarketPrice),
        'totalSavings': items.fold(0.0, (sum, item) => sum + item.totalSavings),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_cartsCollection)
          .doc(userId)
          .set(cartData, SetOptions(merge: true));

      debugPrint('✅ Cart saved: ${items.length} items');
    } catch (e) {
      debugPrint('❌ Error saving cart: $e');
    }
  }

  /// Load cart from Firestore
  Future<List<CartItem>> loadCart(String userId) async {
    try {
      debugPrint('📦 Loading cart from Firestore for user: $userId');

      final doc = await _firestore
          .collection(_cartsCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️  No saved cart found, returning empty cart');
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      final itemsList = data['items'] as List<dynamic>? ?? [];

      final items = itemsList.map((itemJson) {
        return CartItem.fromJson(itemJson as Map<String, dynamic>);
      }).toList();

      debugPrint('✅ Cart loaded: ${items.length} items');
      return items;
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
      return [];
    }
  }

  /// Clear cart from Firestore
  Future<void> clearCart(String userId) async {
    try {
      debugPrint('🗑️  Clearing cart for user: $userId');

      await _firestore
          .collection(_cartsCollection)
          .doc(userId)
          .update({'items': []});

      debugPrint('✅ Cart cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cart: $e');
    }
  }

  /// Delete cart document completely
  Future<void> deleteCart(String userId) async {
    try {
      debugPrint('❌ Deleting cart for user: $userId');

      await _firestore
          .collection(_cartsCollection)
          .doc(userId)
          .delete();

      debugPrint('✅ Cart deleted');
    } catch (e) {
      debugPrint('❌ Error deleting cart: $e');
    }
  }

  /// Add single item to persisted cart
  Future<void> addItemToCart(String userId, CartItem item) async {
    try {
      debugPrint('➕ Adding item to cart: ${item.productName}');

      final doc = await _firestore
          .collection(_cartsCollection)
          .doc(userId)
          .get();

      List<CartItem> items = [];
      if (doc.exists) {
        final itemsList = doc.get('items') as List<dynamic>? ?? [];
        items = itemsList.map((itemJson) {
          return CartItem.fromJson(itemJson as Map<String, dynamic>);
        }).toList();
      }

      // Check if item already in cart
      final existingIndex = items.indexWhere((i) => i.productId == item.productId);
      if (existingIndex >= 0) {
        // Update quantity
        items[existingIndex] = items[existingIndex].copyWith(
          quantity: items[existingIndex].quantity + item.quantity,
        );
      } else {
        // Add new item
        items.add(item);
      }

      // Save updated cart
      await saveCart(userId, items);
    } catch (e) {
      debugPrint('❌ Error adding item to cart: $e');
    }
  }

  /// Remove item from persisted cart
  Future<void> removeItemFromCart(String userId, String productId) async {
    try {
      debugPrint('➖ Removing item from cart: $productId');

      final doc = await _firestore
          .collection(_cartsCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return;

      final itemsList = doc.get('items') as List<dynamic>? ?? [];
      final items = itemsList.map((itemJson) {
        return CartItem.fromJson(itemJson as Map<String, dynamic>);
      }).toList();

      // Remove the item
      items.removeWhere((item) => item.productId == productId);

      // Save updated cart
      await saveCart(userId, items);
    } catch (e) {
      debugPrint('❌ Error removing item from cart: $e');
    }
  }

  /// Update item quantity in persisted cart
  Future<void> updateItemQuantity(
    String userId,
    String productId,
    int newQuantity,
  ) async {
    try {
      debugPrint('🔄 Updating quantity for product: $productId to $newQuantity');

      final doc = await _firestore
          .collection(_cartsCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return;

      final itemsList = doc.get('items') as List<dynamic>? ?? [];
      final items = itemsList.map((itemJson) {
        return CartItem.fromJson(itemJson as Map<String, dynamic>);
      }).toList();

      // Update quantity
      final index = items.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        if (newQuantity <= 0) {
          items.removeAt(index);
        } else {
          items[index] = items[index].copyWith(quantity: newQuantity);
        }
      }

      // Save updated cart
      await saveCart(userId, items);
    } catch (e) {
      debugPrint('❌ Error updating item quantity: $e');
    }
  }

  /// Stream cart in real-time
  Stream<List<CartItem>> streamCart(String userId) {
    return _firestore
        .collection(_cartsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return [];

          final itemsList = doc.get('items') as List<dynamic>? ?? [];
          return itemsList.map((itemJson) {
            return CartItem.fromJson(itemJson as Map<String, dynamic>);
          }).toList();
        });
  }

  /// Move cart to persisted storage (used when user logs in)
  Future<void> syncLocalCartToFirestore(
    String userId,
    List<CartItem> localItems,
  ) async {
    try {
      debugPrint('🔄 Syncing local cart to Firestore for user: $userId');

      // Load existing cart from Firestore
      final firestoreItems = await loadCart(userId);

      // Merge: Firestore items take priority, but add new local items
      final mergedItems = [...firestoreItems];

      for (final localItem in localItems) {
        final index = mergedItems.indexWhere(
          (item) => item.productId == localItem.productId,
        );

        if (index >= 0) {
          // Item exists, update quantity
          mergedItems[index] = mergedItems[index].copyWith(
            quantity: mergedItems[index].quantity + localItem.quantity,
          );
        } else {
          // New item, add it
          mergedItems.add(localItem);
        }
      }

      // Save merged cart
      await saveCart(userId, mergedItems);
      debugPrint('✅ Cart synced: ${mergedItems.length} items');
    } catch (e) {
      debugPrint('❌ Error syncing cart: $e');
    }
  }

  /// Get cart summary
  Future<Map<String, dynamic>> getCartSummary(String userId) async {
    try {
      final doc = await _firestore
          .collection(_cartsCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return {
          'itemCount': 0,
          'subtotal': 0.0,
          'totalSavings': 0.0,
          'deliveryFee': 0.0,
        };
      }

      final data = doc.data() as Map<String, dynamic>;
      final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0.0;
      final deliveryFee = subtotal > 50000 ? 0.0 : 5000.0;

      return {
        'itemCount': data['itemCount'] ?? 0,
        'subtotal': subtotal,
        'totalSavings': data['totalSavings'] ?? 0.0,
        'deliveryFee': deliveryFee,
        'total': subtotal + deliveryFee,
      };
    } catch (e) {
      debugPrint('❌ Error getting cart summary: $e');
      return {};
    }
  }
}
