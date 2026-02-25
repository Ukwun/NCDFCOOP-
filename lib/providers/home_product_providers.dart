import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

// ============================================================================
// PRODUCT PROVIDERS - TIER 1 CRITICAL
// ============================================================================

// Get featured products for home screen
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  // TODO: Connect to product service when available
  return [];
});

// Get product by ID for detail screen
final productDetailProvider =
    FutureProvider.family<Product, String>((ref, productId) async {
  // TODO: Connect to product service when available
  throw Exception('Product service not available');
});

// Search products with filters
final productSearchProvider = FutureProvider.family<
    List<Product>,
    ({
      String query,
      String? category,
      String sortBy,
      int page,
    })>((ref, params) async {
  // TODO: Connect to product service when available
  return [];
});

// Get products by category
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  // TODO: Connect to product service when available
  return [];
});

// ============================================================================
// ORDER PROVIDERS - TIER 1 CRITICAL
// ============================================================================

// Get recent orders for home screen
final userRecentOrdersProvider = FutureProvider<List<Order>>((ref) async {
  // TODO: Connect to order service when available
  return [];
});

// Get specific order by ID
final orderDetailProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
  // TODO: Connect to order service when available
  throw Exception('Order service not available');
});

// ============================================================================
// CART PROVIDERS - TIER 1 CRITICAL
// ============================================================================

class CartNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {
      'items': [],
      'totalQuantity': 0,
      'subtotal': 0.0,
    };
  }

  void addItem(Product product, int quantity) {
    final items = List<Map<String, dynamic>>.from(state['items'] as List);

    // Check if item already exists
    final existingIndex =
        items.indexWhere((item) => item['productId'] == product.id);

    if (existingIndex >= 0) {
      items[existingIndex]['quantity'] =
          (items[existingIndex]['quantity'] as int) + quantity;
    } else {
      items.add({
        'productId': product.id,
        'name': product.name,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'quantity': quantity,
      });
    }

    _updateCart(items);
  }

  void updateQuantity(String productId, int quantity) {
    final items = List<Map<String, dynamic>>.from(state['items'] as List);

    if (quantity <= 0) {
      items.removeWhere((item) => item['productId'] == productId);
    } else {
      final index = items.indexWhere((item) => item['productId'] == productId);
      if (index >= 0) {
        items[index]['quantity'] = quantity;
      }
    }

    _updateCart(items);
  }

  void removeItem(String productId) {
    final items = List<Map<String, dynamic>>.from(state['items'] as List);
    items.removeWhere((item) => item['productId'] == productId);
    _updateCart(items);
  }

  void _updateCart(List<Map<String, dynamic>> items) {
    int totalQuantity = 0;
    double subtotal = 0.0;

    for (var item in items) {
      final quantity = item['quantity'] as int;
      final price = (item['price'] as num).toDouble();

      totalQuantity += quantity;
      subtotal += price * quantity;
    }

    state = {
      'items': items,
      'totalQuantity': totalQuantity,
      'subtotal': subtotal,
    };
  }

  void clear() {
    state = {
      'items': [],
      'totalQuantity': 0,
      'subtotal': 0.0,
    };
  }
}

final cartNotifierProvider =
    NotifierProvider<CartNotifier, Map<String, dynamic>>(() {
  return CartNotifier();
});
