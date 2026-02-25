import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/core/services/cart_persistence_service.dart';
import 'package:coop_commerce/core/services/cart_activity_logger.dart';
import 'package:coop_commerce/core/services/activity_tracking_service.dart';

/// Cart item model
class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double memberPrice;
  final double marketPrice;
  int quantity;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.memberPrice,
    required this.marketPrice,
    this.quantity = 1,
    this.imageUrl,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'memberPrice': memberPrice,
        'marketPrice': marketPrice,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };

  /// Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        memberPrice: (json['memberPrice'] as num).toDouble(),
        marketPrice: (json['marketPrice'] as num).toDouble(),
        quantity: json['quantity'] as int,
        imageUrl: json['imageUrl'] as String?,
      );

  /// Calculate total price for this item (member price)
  double get totalPrice => memberPrice * quantity;

  /// Calculate market price for this item
  double get totalMarketPrice => marketPrice * quantity;

  /// Calculate savings for this item
  double get totalSavings => totalMarketPrice - totalPrice;

  /// Create a copy with modified fields
  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? memberPrice,
    double? marketPrice,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      memberPrice: memberPrice ?? this.memberPrice,
      marketPrice: marketPrice ?? this.marketPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Cart state model
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  const CartState({this.items = const [], this.isLoading = false, this.error});

  /// Total number of items in cart
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total price (member price) - subtotal
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Total market price
  double get totalMarketPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalMarketPrice);

  /// Total savings across all items
  double get totalSavings =>
      items.fold(0.0, (sum, item) => sum + item.totalSavings);

  /// Delivery fee: Free for orders above ₦50,000, ₦5,000 otherwise
  double get deliveryFee => subtotal > 50000 ? 0 : 5000;

  /// Total with delivery fee
  double get totalPrice => subtotal + deliveryFee;

  /// Savings percentage
  double get savingsPercentage {
    if (totalMarketPrice == 0) return 0;
    return (totalSavings / totalMarketPrice) * 100;
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Create a copy with modified fields
  CartState copyWith({List<CartItem>? items, bool? isLoading, String? error}) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Cart provider using StateNotifier
class CartNotifier extends Notifier<CartState> {
  late CartPersistenceService _persistenceService;
  late FirebaseAuth _auth;

  @override
  CartState build() {
    _persistenceService = CartPersistenceService();
    _auth = FirebaseAuth.instance;
    return const CartState();
  }

  /// Initialize cart from Firestore (call on app startup)
  Future<void> initializeCart() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final user = _auth.currentUser;
      if (user != null) {
        final items = await _persistenceService.loadCart(user.uid);
        state = state.copyWith(items: items, isLoading: false, error: null);
      } else {
        state = state.copyWith(items: const [], isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load cart: $e',
      );
    }
  }

  /// Add item to cart
  Future<void> addItem(CartItem item) async {
    try {
      final existingIndex = state.items.indexWhere(
        (i) => i.productId == item.productId,
      );

      if (existingIndex >= 0) {
        // Item already exists, increase quantity
        final updatedItem = state.items[existingIndex].copyWith(
          quantity: state.items[existingIndex].quantity + 1,
        );
        final updatedItems = [...state.items];
        updatedItems[existingIndex] = updatedItem;
        state = state.copyWith(items: updatedItems, error: null);
      } else {
        // New item, add to cart
        state = state.copyWith(
          items: [...state.items, item],
          error: null,
        );
      }

      // Persist to Firestore if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _persistenceService.saveCart(user.uid, state.items);
        
        // Log cart activity
        try {
          final cartLogger = CartActivityLogger(ActivityTrackingService());
          await cartLogger.logCartItemAdded(
            productId: item.productId,
            productName: item.productName,
            category: 'Uncategorized', // Category available in product detail
            price: item.memberPrice,
            quantity: item.quantity,
          );
          debugPrint('✅ Cart add logged: ${item.productName}');
        } catch (logError) {
          debugPrint('⚠️ Error logging cart add: $logError');
          // Silent fail - don't block UI
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add item: $e');
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String productId) async {
    try {
      // Get item before removal for logging
      final removedItem = state.items.firstWhere(
        (item) => item.productId == productId,
        orElse: () => CartItem(
          id: '', productId: '', productName: '', 
          memberPrice: 0, marketPrice: 0
        ),
      );
      
      final updatedItems =
          state.items.where((item) => item.productId != productId).toList();
      state = state.copyWith(items: updatedItems, error: null);

      // Persist to Firestore if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _persistenceService.removeItemFromCart(user.uid, productId);
        
        // Log cart activity
        if (removedItem.productName.isNotEmpty) {
          try {
            final cartLogger = CartActivityLogger(ActivityTrackingService());
            await cartLogger.logCartItemRemoved(
              productId: removedItem.productId,
              productName: removedItem.productName,
              category: 'Uncategorized',
              price: removedItem.memberPrice,
              quantity: removedItem.quantity,
            );
            debugPrint('✅ Cart remove logged: ${removedItem.productName}');
          } catch (logError) {
            debugPrint('⚠️ Error logging cart remove: $logError');
            // Silent fail - don't block UI
          }
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove item: $e');
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeItem(productId);
        return;
      }

      final itemIndex = state.items.indexWhere((i) => i.productId == productId);
      if (itemIndex >= 0) {
        final oldQuantity = state.items[itemIndex].quantity;
        final updatedItem = state.items[itemIndex].copyWith(quantity: quantity);
        final updatedItems = [...state.items];
        updatedItems[itemIndex] = updatedItem;
        state = state.copyWith(items: updatedItems, error: null);

        // Persist to Firestore if user is logged in
        final user = _auth.currentUser;
        if (user != null) {
          await _persistenceService.updateItemQuantity(user.uid, productId, quantity);
          
          // Log cart activity
          try {
            final cartLogger = CartActivityLogger(ActivityTrackingService());
            await cartLogger.logCartQuantityUpdated(
              productId: productId,
              productName: updatedItem.productName,
              category: 'Uncategorized',
              price: updatedItem.memberPrice,
              oldQuantity: oldQuantity,
              newQuantity: quantity,
            );
            debugPrint('✅ Cart quantity updated: ${updatedItem.productName} ($oldQuantity → $quantity)');
          } catch (logError) {
            debugPrint('⚠️ Error logging quantity update: $logError');
            // Silent fail - don't block UI
          }
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update quantity: $e');
    }
  }

  /// Increment item quantity
  Future<void> incrementQuantity(String productId) async {
    final itemIndex = state.items.indexWhere((i) => i.productId == productId);
    if (itemIndex >= 0) {
      await updateQuantity(productId, state.items[itemIndex].quantity + 1);
    }
  }

  /// Decrement item quantity
  Future<void> decrementQuantity(String productId) async {
    final itemIndex = state.items.indexWhere((i) => i.productId == productId);
    if (itemIndex >= 0) {
      await updateQuantity(productId, state.items[itemIndex].quantity - 1);
    }
  }

  /// Clear all items from cart
  Future<void> clearCart() async {
    try {
      final itemCount = state.itemCount;
      final totalValue = state.subtotal;
      
      state = const CartState();

      // Persist to Firestore if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _persistenceService.clearCart(user.uid);
        
        // Log cart activity
        try {
          final cartLogger = CartActivityLogger(ActivityTrackingService());
          await cartLogger.logCartCleared(
            itemCount: itemCount,
            totalValue: totalValue,
          );
          debugPrint('✅ Cart cleared logged: $itemCount items (₦${totalValue.toStringAsFixed(2)})');
        } catch (logError) {
          debugPrint('⚠️ Error logging cart clear: $logError');
          // Silent fail - don't block UI
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear cart: $e');
    }
  }

  /// Sync local cart to Firestore (when user logs in)
  Future<void> syncToFirebase(List<CartItem> localItems) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = const CartState();
        return;
      }

      // Sync local items to Firestore
      await _persistenceService.syncLocalCartToFirestore(user.uid, localItems);
      
      // Reload cart from Firestore
      await initializeCart();
    } catch (e) {
      state = state.copyWith(error: 'Failed to sync cart: $e');
    }
  }

  /// Handle user logout
  void handleUserLogout() {
    state = const CartState();
  }

  /// Get item by product ID
  CartItem? getItem(String productId) {
    try {
      return state.items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    return state.items.any((item) => item.productId == productId);
  }

  /// Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set error state
  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

/// Riverpod provider for cart state
final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

/// Provider for total price
final cartTotalPriceProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.totalPrice;
});

/// Provider for total savings
final cartTotalSavingsProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.totalSavings;
});

/// Provider for total market price
final cartTotalMarketPriceProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.totalMarketPrice;
});

/// Provider for item count
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.itemCount;
});

/// Provider for savings percentage
final cartSavingsPercentageProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.savingsPercentage;
});

/// Provider to check if cart is empty
final cartIsEmptyProvider = Provider<bool>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.isEmpty;
});
