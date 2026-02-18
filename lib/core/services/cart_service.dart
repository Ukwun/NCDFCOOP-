import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/services/pricing_engine_service.dart';
import 'package:coop_commerce/models/pricing/pricing_models.dart';

/// Cart item with integrated pricing
class CartItemWithPricing {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final String? imageUrl;
  final PriceCalculationResult priceCalculation;
  final double basePrice; // Store original price for comparison
  final DateTime addedAt;

  const CartItemWithPricing({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceCalculation,
    required this.basePrice,
    this.imageUrl,
    required this.addedAt,
  });

  /// Get total price for this line item (finalPrice × quantity)
  double get lineTotal => priceCalculation.finalPrice * quantity;

  /// Get base subtotal before pricing (for comparison)
  double get baseSubtotal => basePrice * quantity;

  /// Get total savings for this line item
  double get lineSavings => priceCalculation.discountAmount * quantity;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'basePrice': basePrice,
        'priceCalculation': {
          'basePrice': priceCalculation.basePrice,
          'discountAmount': priceCalculation.discountAmount,
          'discountPercentage': priceCalculation.discountPercentage,
          'finalPrice': priceCalculation.finalPrice,
          'hadEssentialBasketCap': priceCalculation.hadEssentialBasketCap,
          'hadPriceOverride': priceCalculation.hadPriceOverride,
        },
        'addedAt': addedAt.toIso8601String(),
      };
}

/// Cart state with integrated pricing
class CartWithPricing {
  final List<CartItemWithPricing> items;
  final bool isLoading;
  final String? error;

  const CartWithPricing({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  /// Total number of items in cart
  int get itemCount => items.fold(0, (prev, item) => prev + item.quantity);

  /// Subtotal (sum of all line items at final prices)
  double get subtotal => items.fold(0.0, (prev, item) => prev + item.lineTotal);

  /// Total base price before any discounts
  double get totalBasePrice =>
      items.fold(0.0, (prev, item) => prev + item.baseSubtotal);

  /// Total savings across all items
  double get totalSavings =>
      items.fold(0.0, (prev, item) => prev + item.lineSavings);

  /// Delivery fee: Free for orders above ₦50,000, ₦5,000 otherwise
  double get deliveryFee => subtotal > 50000 ? 0 : 5000;

  /// Total with delivery fee
  double get totalPrice => subtotal + deliveryFee;

  /// Savings percentage
  double get savingsPercentage {
    if (totalBasePrice == 0) return 0;
    return (totalSavings / totalBasePrice) * 100;
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if any item has price override applied
  bool get hasAnyPriceOverride =>
      items.any((item) => item.priceCalculation.hadPriceOverride);

  /// Check if any item has essential basket cap applied
  bool get hasAnyEssentialBasketCap =>
      items.any((item) => item.priceCalculation.hadEssentialBasketCap);

  /// Create a copy with modified fields
  CartWithPricing copyWith({
    List<CartItemWithPricing>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartWithPricing(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Cart service with integrated pricing engine
class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PricingEngineService _pricingEngine;

  CartService(this._pricingEngine);

  static const String _cartsCollection = 'shopping_carts';

  /// Add item to cart with real pricing calculation
  Future<CartItemWithPricing> addItemToCart({
    required String cartId,
    required String productId,
    required String productName,
    required int quantity,
    required double basePrice,
    required String? imageUrl,
    required String storeId,
    required String? customerId,
    required String customerRole,
  }) async {
    try {
      // Calculate actual price using pricing engine
      final priceCalculation = await _pricingEngine.calculateRetailPrice(
        productId: productId,
        storeId: storeId,
        customerId: customerId ?? 'anonymous',
        customerRole: customerRole,
      );

      // Create cart item with calculated price
      final cartItem = CartItemWithPricing(
        id: '${productId}_${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        productName: productName,
        quantity: quantity,
        imageUrl: imageUrl,
        priceCalculation: priceCalculation,
        basePrice: basePrice,
        addedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection(_cartsCollection)
          .doc(cartId)
          .collection('items')
          .doc(cartItem.id)
          .set(cartItem.toJson());

      // Log in audit trail
      await _pricingEngine.logPriceCalculation(
        productId: productId,
        calculationType: 'retail_add_to_cart',
        basePrice: basePrice,
        finalPrice: priceCalculation.finalPrice,
        context: {
          'storeId': storeId,
          'customerId': customerId,
          'cartId': cartId,
          'quantity': quantity,
        },
      );

      return cartItem;
    } catch (e) {
      rethrow;
    }
  }

  /// Get cart with pricing calculations
  Future<CartWithPricing> getCart(String cartId) async {
    try {
      final snapshot = await _firestore
          .collection(_cartsCollection)
          .doc(cartId)
          .collection('items')
          .get();

      final items = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          final priceData = data['priceCalculation'] as Map<String, dynamic>?;

          return CartItemWithPricing(
            id: data['id'],
            productId: data['productId'],
            productName: data['productName'],
            quantity: data['quantity'],
            imageUrl: data['imageUrl'],
            basePrice: (data['basePrice'] as num).toDouble(),
            priceCalculation: PriceCalculationResult(
              basePrice: (priceData?['basePrice'] as num?)?.toDouble() ?? 0,
              discountAmount:
                  (priceData?['discountAmount'] as num?)?.toDouble() ?? 0,
              discountPercentage:
                  (priceData?['discountPercentage'] as num?)?.toDouble() ?? 0,
              finalPrice: (priceData?['finalPrice'] as num?)?.toDouble() ?? 0,
              hadEssentialBasketCap:
                  priceData?['hadEssentialBasketCap'] as bool? ?? false,
              hadPriceOverride:
                  priceData?['hadPriceOverride'] as bool? ?? false,
              components: [],
            ),
            addedAt: DateTime.parse(
                data['addedAt'] ?? DateTime.now().toIso8601String()),
          );
        } catch (e) {
          rethrow;
        }
      }).toList();

      return CartWithPricing(items: items);
    } catch (e) {
      rethrow;
    }
  }

  /// Update item quantity in cart (recalculates pricing if needed)
  Future<void> updateItemQuantity({
    required String cartId,
    required String itemId,
    required int newQuantity,
  }) async {
    try {
      if (newQuantity <= 0) {
        await removeItem(cartId, itemId);
        return;
      }

      await _firestore
          .collection(_cartsCollection)
          .doc(cartId)
          .collection('items')
          .doc(itemId)
          .update({
        'quantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating item quantity: $e');
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String cartId, String itemId) async {
    try {
      await _firestore
          .collection(_cartsCollection)
          .doc(cartId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error removing item from cart: $e');
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clearCart(String cartId) async {
    try {
      final snapshot = await _firestore
          .collection(_cartsCollection)
          .doc(cartId)
          .collection('items')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }

  /// Get cart items as stream for real-time updates
  Stream<CartWithPricing> watchCart(String cartId) {
    return _firestore
        .collection(_cartsCollection)
        .doc(cartId)
        .collection('items')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              final priceData =
                  data['priceCalculation'] as Map<String, dynamic>?;

              return CartItemWithPricing(
                id: data['id'],
                productId: data['productId'],
                productName: data['productName'],
                quantity: data['quantity'],
                imageUrl: data['imageUrl'],
                basePrice: (data['basePrice'] as num).toDouble(),
                priceCalculation: PriceCalculationResult(
                  basePrice: (priceData?['basePrice'] as num?)?.toDouble() ?? 0,
                  discountAmount:
                      (priceData?['discountAmount'] as num?)?.toDouble() ?? 0,
                  discountPercentage:
                      (priceData?['discountPercentage'] as num?)?.toDouble() ??
                          0,
                  finalPrice:
                      (priceData?['finalPrice'] as num?)?.toDouble() ?? 0,
                  hadEssentialBasketCap:
                      priceData?['hadEssentialBasketCap'] as bool? ?? false,
                  hadPriceOverride:
                      priceData?['hadPriceOverride'] as bool? ?? false,
                  components: [],
                ),
                addedAt: DateTime.parse(
                    data['addedAt'] ?? DateTime.now().toIso8601String()),
              );
            } catch (e) {
              print('Error parsing cart item in stream: $e');
              return null;
            }
          })
          .whereType<CartItemWithPricing>()
          .toList();

      return CartWithPricing(items: items);
    });
  }

  /// Recalculate all prices in cart (useful for refreshing after pricing rules change)
  Future<void> recalculateCartPrices({
    required String cartId,
    required String storeId,
    required String? customerId,
    required String customerRole,
  }) async {
    try {
      final currentCart = await getCart(cartId);

      for (var item in currentCart.items) {
        // Recalculate price
        final updatedPrice = await _pricingEngine.calculateRetailPrice(
          productId: item.productId,
          storeId: storeId,
          customerId: customerId ?? 'anonymous',
          customerRole: customerRole,
        );

        // Update in Firestore
        await _firestore
            .collection(_cartsCollection)
            .doc(cartId)
            .collection('items')
            .doc(item.id)
            .update({
          'priceCalculation': {
            'basePrice': updatedPrice.basePrice,
            'discountAmount': updatedPrice.discountAmount,
            'discountPercentage': updatedPrice.discountPercentage,
            'finalPrice': updatedPrice.finalPrice,
            'hadEssentialBasketCap': updatedPrice.hadEssentialBasketCap,
            'hadPriceOverride': updatedPrice.hadPriceOverride,
          },
          'recalculatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error recalculating cart prices: $e');
      rethrow;
    }
  }
}
