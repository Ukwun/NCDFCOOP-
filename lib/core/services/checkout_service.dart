import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/services/pricing_engine_service.dart';
import 'package:coop_commerce/core/services/cart_service.dart';

/// Checkout order with pricing breakdown
class CheckoutOrder {
  final String id;
  final String cartId;
  final String customerId;
  final String storeId;
  final String customerRole;
  final List<CartItemWithPricing> items;
  final double subtotal; // Sum of all items at final prices
  final double deliveryFee;
  final double tax; // Calculated as 7.5% of subtotal
  final double totalAmount; // subtotal + tax + delivery
  final String shippingAddress;
  final String billingAddress;
  final String deliveryMethod; // 'delivery' or 'pickup'
  final DateTime? deliveryDate;
  final String? deliverySlot; // e.g., "09:00-12:00"
  final String? promoCode;
  final double? promoDiscount;
  final String? specialInstructions;
  final String
      status; // 'pending', 'confirmed', 'processing', 'shipped', 'delivered'
  final List<PriceBreakdownItem> priceBreakdown;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  CheckoutOrder({
    required this.id,
    required this.cartId,
    required this.customerId,
    required this.storeId,
    required this.customerRole,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.totalAmount,
    required this.shippingAddress,
    required this.billingAddress,
    required this.deliveryMethod,
    this.deliveryDate,
    this.deliverySlot,
    this.promoCode,
    this.promoDiscount,
    this.specialInstructions,
    this.status = 'pending',
    required this.priceBreakdown,
    required this.createdAt,
    this.confirmedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cartId': cartId,
        'customerId': customerId,
        'storeId': storeId,
        'customerRole': customerRole,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'tax': tax,
        'totalAmount': totalAmount,
        'shippingAddress': shippingAddress,
        'billingAddress': billingAddress,
        'deliveryMethod': deliveryMethod,
        'deliveryDate': deliveryDate?.toIso8601String(),
        'deliverySlot': deliverySlot,
        'promoCode': promoCode,
        'promoDiscount': promoDiscount,
        'specialInstructions': specialInstructions,
        'status': status,
        'priceBreakdown': priceBreakdown.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
      };
}

/// Price breakdown item for transparency
class PriceBreakdownItem {
  final String label; // e.g., "Subtotal", "Tax", "Delivery Fee", "Spring Sale"
  final double amount;
  final String? description; // Optional explanation

  PriceBreakdownItem({
    required this.label,
    required this.amount,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'description': description,
      };
}

/// Checkout service with integrated pricing
class CheckoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PricingEngineService _pricingEngine;
  final CartService _cartService;

  CheckoutService(this._pricingEngine, this._cartService);

  static const String _ordersCollection = 'orders';
  static const double _taxRate = 0.075; // 7.5% tax

  /// Create checkout order from cart
  Future<CheckoutOrder> createCheckoutOrder({
    required String cartId,
    required String customerId,
    required String storeId,
    required String customerRole,
    required String shippingAddress,
    required String billingAddress,
    required String deliveryMethod,
    DateTime? deliveryDate,
    String? deliverySlot,
    String? promoCode,
    String? specialInstructions,
  }) async {
    try {
      // Get cart with pricing
      final cart = await _cartService.getCart(cartId);

      if (cart.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Calculate totals
      final subtotal = cart.subtotal;
      final deliveryFee = deliveryMethod == 'pickup' ? 0.0 : cart.deliveryFee;
      final taxableAmount = subtotal + deliveryFee;
      final tax = (taxableAmount * _taxRate).toStringAsFixed(2);
      final taxAmount = double.parse(tax);

      // Build price breakdown for transparency
      final priceBreakdown = <PriceBreakdownItem>[
        PriceBreakdownItem(
          label: 'Subtotal',
          amount: subtotal,
          description: 'Sum of all items at applied prices',
        ),
        if (cart.totalSavings > 0)
          PriceBreakdownItem(
            label: 'Total Savings',
            amount: -cart.totalSavings,
            description: 'Member discounts and promotions',
          ),
        if (deliveryFee > 0)
          PriceBreakdownItem(
            label: 'Delivery Fee',
            amount: deliveryFee,
            description: 'Free delivery on orders over ₦50,000',
          ),
        PriceBreakdownItem(
          label: 'Tax (7.5%)',
          amount: taxAmount,
          description: 'Applied tax',
        ),
      ];

      // Handle promo codes (placeholder for future promo engine)
      double promoDiscount = 0;
      if (promoCode != null && promoCode.isNotEmpty) {
        // TODO: Implement promo code validation and discount calculation
        // For now, skip promo processing
      }

      final totalAmount = subtotal + deliveryFee + taxAmount - promoDiscount;

      // Create order
      final orderId =
          'ORD_${DateTime.now().millisecondsSinceEpoch}_${customerId.substring(0, 4)}';

      final order = CheckoutOrder(
        id: orderId,
        cartId: cartId,
        customerId: customerId,
        storeId: storeId,
        customerRole: customerRole,
        items: cart.items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        tax: taxAmount,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        billingAddress: billingAddress,
        deliveryMethod: deliveryMethod,
        deliveryDate: deliveryDate,
        deliverySlot: deliverySlot,
        promoCode: promoCode,
        promoDiscount: promoDiscount > 0 ? promoDiscount : null,
        specialInstructions: specialInstructions,
        status: 'pending',
        priceBreakdown: priceBreakdown,
        createdAt: DateTime.now(),
      );

      // Save order to Firestore
      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .set(order.toJson());

      // Log in audit trail
      await _pricingEngine.logPriceCalculation(
        productId: 'order_checkout',
        calculationType: 'checkout_summary',
        basePrice: subtotal,
        finalPrice: totalAmount,
        context: {
          'orderId': orderId,
          'customerId': customerId,
          'storeId': storeId,
          'itemCount': cart.itemCount,
          'deliveryMethod': deliveryMethod,
          'hasDeliveryFee': deliveryFee > 0,
          'hasTaxes': taxAmount > 0,
        },
      );

      return order;
    } catch (e) {
      print('Error creating checkout order: $e');
      rethrow;
    }
  }

  /// Get checkout order by ID
  Future<CheckoutOrder?> getCheckoutOrder(String orderId) async {
    try {
      final doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!doc.exists) return null;

      // TODO: Parse and deserialize order from Firestore document
      return null;
    } catch (e) {
      print('Error getting checkout order: $e');
      rethrow;
    }
  }

  /// Confirm order (transition from pending to confirmed)
  Future<void> confirmCheckoutOrder(String orderId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': 'confirmed',
        'confirmedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error confirming checkout order: $e');
      rethrow;
    }
  }

  /// Update order shipping address
  Future<void> updateShippingAddress(
    String orderId,
    String newAddress,
  ) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'shippingAddress': newAddress,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating shipping address: $e');
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  /// Get user's orders as stream for real-time updates
  Stream<List<CheckoutOrder>> watchUserOrders(String customerId) {
    return _firestore
        .collection(_ordersCollection)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            // TODO: Implement deserialization
            return null;
          })
          .whereType<CheckoutOrder>()
          .toList();
    });
  }

  /// Get all orders (admin only) with pagination
  Future<List<CheckoutOrder>> getAllOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? storeId,
    DateTime? dateFrom,
  }) async {
    try {
      Query query = _firestore.collection(_ordersCollection);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (storeId != null) {
        query = query.where('storeId', isEqualTo: storeId);
      }

      if (dateFrom != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: dateFrom);
      }

      query = query.orderBy('createdAt', descending: true);

      final offset = (page - 1) * pageSize;
      // Note: Firestore doesn't support native offset, use pagination with documents
      final snapshot = await query.limit(pageSize * page).get();

      return snapshot.docs
          .skip(offset)
          .take(pageSize)
          .map((doc) {
            // TODO: Implement deserialization
            return null;
          })
          .whereType<CheckoutOrder>()
          .toList();
    } catch (e) {
      print('Error getting all orders: $e');
      rethrow;
    }
  }

  /// Calculate checkout totals for preview (before placing order)
  Future<Map<String, dynamic>> calculateCheckoutTotals({
    required String cartId,
    required String deliveryMethod,
  }) async {
    try {
      final cart = await _cartService.getCart(cartId);

      final subtotal = cart.subtotal;
      final deliveryFee = deliveryMethod == 'pickup' ? 0 : cart.deliveryFee;
      final taxableAmount = subtotal + deliveryFee;
      final tax = (taxableAmount * _taxRate).toStringAsFixed(2);
      final taxAmount = double.parse(tax);
      final totalAmount = subtotal + deliveryFee + taxAmount;

      return {
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'tax': taxAmount,
        'total': totalAmount,
        'savings': cart.totalSavings,
        'savingsPercentage': cart.savingsPercentage,
        'itemCount': cart.itemCount,
      };
    } catch (e) {
      print('Error calculating checkout totals: $e');
      rethrow;
    }
  }
}
