import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Total price (member price)
  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Total market price
  double get totalMarketPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalMarketPrice);

  /// Total savings across all items
  double get totalSavings =>
      items.fold(0.0, (sum, item) => sum + item.totalSavings);

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
  @override
  CartState build() => const CartState();

  /// Add item to cart
  void addItem(CartItem item) {
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
      state = state.copyWith(items: updatedItems);
    } else {
      // New item, add to cart
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  /// Remove item from cart
  void removeItem(String productId) {
    final updatedItems = state.items
        .where((item) => item.productId != productId)
        .toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final itemIndex = state.items.indexWhere((i) => i.productId == productId);
    if (itemIndex >= 0) {
      final updatedItem = state.items[itemIndex].copyWith(quantity: quantity);
      final updatedItems = [...state.items];
      updatedItems[itemIndex] = updatedItem;
      state = state.copyWith(items: updatedItems);
    }
  }

  /// Increment item quantity
  void incrementQuantity(String productId) {
    final itemIndex = state.items.indexWhere((i) => i.productId == productId);
    if (itemIndex >= 0) {
      updateQuantity(productId, state.items[itemIndex].quantity + 1);
    }
  }

  /// Decrement item quantity
  void decrementQuantity(String productId) {
    final itemIndex = state.items.indexWhere((i) => i.productId == productId);
    if (itemIndex >= 0) {
      updateQuantity(productId, state.items[itemIndex].quantity - 1);
    }
  }

  /// Clear all items from cart
  void clearCart() {
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
