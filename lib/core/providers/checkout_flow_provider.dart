import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/models/address.dart';

// ==================== CHECKOUT FLOW MODELS ====================

/// Represents a saved payment method
class PaymentMethod {
  final String id;
  final String type; // 'card', 'bank_transfer', 'ussd', 'wallet'
  final String displayName; // e.g., "Mastercard ••••1234"
  final String? lastFour;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.displayName,
    this.lastFour,
    this.isDefault = false,
    required this.createdAt,
  });

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethod(
      id: doc.id,
      type: data['type'] ?? 'card',
      displayName: data['displayName'] ?? 'Payment Method',
      lastFour: data['lastFour'],
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a copy with modified properties
  PaymentMethod copyWith({
    String? id,
    String? type,
    String? displayName,
    String? lastFour,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      lastFour: lastFour ?? this.lastFour,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Complete checkout state
class CheckoutFlowState {
  final Address? selectedAddress;
  final PaymentMethod? selectedPaymentMethod;
  final String? deliveryMethod; // 'home_delivery' or 'office_collection'
  final String? promoCode;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String
      currentStep; // 'cart', 'address', 'delivery', 'payment', 'confirmation'

  CheckoutFlowState({
    this.selectedAddress,
    this.selectedPaymentMethod,
    this.deliveryMethod,
    this.promoCode,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.currentStep = 'cart',
  });

  CheckoutFlowState copyWith({
    Address? selectedAddress,
    PaymentMethod? selectedPaymentMethod,
    String? deliveryMethod,
    String? promoCode,
    bool? isLoading,
    String? error,
    String? successMessage,
    String? currentStep,
  }) {
    return CheckoutFlowState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      promoCode: promoCode ?? this.promoCode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

// ==================== STATE NOTIFIERS ====================

/// Manages the entire checkout flow
class CheckoutFlowNotifier extends Notifier<CheckoutFlowState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  CheckoutFlowState build() {
    return CheckoutFlowState();
  }

  /// Set selected delivery address
  void setAddress(Address address) {
    state = state.copyWith(selectedAddress: address);
  }

  /// Set selected payment method
  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  /// Set delivery method
  void setDeliveryMethod(String method) {
    if (method == 'home_delivery' || method == 'office_collection') {
      state = state.copyWith(deliveryMethod: method);
    }
  }

  /// Apply promo code
  Future<bool> applyPromoCode(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Validate promo code
      final snap = await _firestore.collection('promo_codes').doc(code).get();

      if (!snap.exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid promo code',
        );
        return false;
      }

      final data = snap.data() as Map<String, dynamic>;
      if (data['active'] != true) {
        state = state.copyWith(
          isLoading: false,
          error: 'This promo code is no longer active',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        promoCode: code,
        successMessage: 'Promo code applied successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error applying promo code: $e',
      );
      return false;
    }
  }

  /// Move to next step in checkout
  void nextStep() {
    final steps = ['cart', 'address', 'delivery', 'payment', 'confirmation'];
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex < steps.length - 1) {
      state = state.copyWith(currentStep: steps[currentIndex + 1]);
    }
  }

  /// Move to previous step
  void previousStep() {
    final steps = ['cart', 'address', 'delivery', 'payment', 'confirmation'];
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex > 0) {
      state = state.copyWith(currentStep: steps[currentIndex - 1]);
    }
  }

  /// Reset checkout state
  void reset() {
    state = CheckoutFlowState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ==================== PROVIDERS ====================

/// Checkout flow state provider
final checkoutFlowProvider =
    NotifierProvider<CheckoutFlowNotifier, CheckoutFlowState>(
  CheckoutFlowNotifier.new,
);

/// Watch user's saved payment methods
final userPaymentMethodsProvider =
    StreamProvider.family<List<PaymentMethod>, String>(
  (ref, userId) {
    final firestore = FirebaseFirestore.instance;
    return firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .orderBy('isDefault', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentMethod.fromFirestore(doc))
            .toList());
  },
);

/// Validate address before checkout
final validateAddressProvider =
    FutureProvider.family<bool, Address>((ref, address) async {
  // Ensure address has all required fields
  return address.street.isNotEmpty &&
      address.city.isNotEmpty &&
      address.state.isNotEmpty &&
      address.zipCode.isNotEmpty;
});

/// Calculate order total with all fees
class OrderCalculation {
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double promoDiscount;
  final double total;

  OrderCalculation({
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.promoDiscount,
    required this.total,
  });
}

/// Calculate order totals
final orderCalculationProvider =
    FutureProvider.family<OrderCalculation, Map<String, dynamic>>(
  (ref, params) async {
    final subtotal = params['subtotal'] as double;
    final promoCode = params['promoCode'] as String?;

    // Calculate tax (7.5% in Nigeria)
    const taxRate = 0.075;
    final tax = subtotal * taxRate;

    // Determine delivery fee based on location/amount
    final deliveryFee = subtotal > 50000 ? 0.0 : 2500.0;

    // Calculate promo discount
    double promoDiscount = 0;
    if (promoCode != null && promoCode.isNotEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('promo_codes')
            .doc(promoCode)
            .get();

        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          final discountPercent =
              (data['discountPercent'] as num?)?.toDouble() ?? 0;
          promoDiscount = subtotal * (discountPercent / 100);
        }
      } catch (_) {
        // Promo code lookup failed, skip discount
      }
    }

    final total = subtotal + tax + deliveryFee - promoDiscount;

    return OrderCalculation(
      subtotal: subtotal,
      tax: tax,
      deliveryFee: deliveryFee,
      promoDiscount: promoDiscount,
      total: total,
    );
  },
);

/// Track order creation status
class OrderCreationResult {
  final bool success;
  final String? orderId;
  final String? error;
  final String? paymentUrl; // For payment gateway redirect

  OrderCreationResult({
    required this.success,
    this.orderId,
    this.error,
    this.paymentUrl,
  });
}

/// Create order (future provider - not a stream)
final createOrderProvider =
    FutureProvider.family<OrderCreationResult, Map<String, dynamic>>(
  (ref, params) async {
    try {
      final userId = params['userId'] as String;
      final items = params['items'] ?? params['cartItems'] as List;
      final selectedAddress =
          params['selectedAddress'] ?? params['address'] as Address?;
      final selectedPaymentMethod = params['selectedPaymentMethod'] ??
          params['paymentMethod'] as PaymentMethod?;
      final addressId = params['addressId'] as String?;
      final paymentMethodId = params['paymentMethodId'] as String?;
      final promoCode = params['promoCode'] as String?;

      // Get address if only ID was provided
      Address? address = selectedAddress;
      if (address == null && addressId != null) {
        final firestore = FirebaseFirestore.instance;
        final addressDoc = await firestore
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(addressId)
            .get();
        if (addressDoc.exists) {
          address = Address.fromMap(
              addressDoc.data() as Map<String, dynamic>, addressId);
        }
      }

      // Get payment method if only ID was provided
      PaymentMethod? paymentMethod = selectedPaymentMethod;
      if (paymentMethod == null && paymentMethodId != null) {
        final firestore = FirebaseFirestore.instance;
        final paymentDoc = await firestore
            .collection('users')
            .doc(userId)
            .collection('payment_methods')
            .doc(paymentMethodId)
            .get();
        if (paymentDoc.exists) {
          final paymentData = paymentDoc.data() as Map<String, dynamic>;
          paymentMethod = PaymentMethod(
            id: paymentMethodId,
            type: paymentData['type'] ?? 'card',
            displayName: paymentData['displayName'] ?? 'Payment Method',
            lastFour: paymentData['lastFour'],
            isDefault: paymentData['isDefault'] ?? false,
            createdAt: (paymentData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          );
        }
      }

      if (address == null) {
        return OrderCreationResult(
          success: false,
          error: 'Shipping address not found',
        );
      }

      if (paymentMethod == null) {
        return OrderCreationResult(
          success: false,
          error: 'Payment method not found',
        );
      }

      // Get order calculation if not provided
      double subtotal = params['subtotal'] ?? 0.0;
      double tax = params['tax'] ?? 0.0;
      double deliveryFee = params['deliveryFee'] ?? 0.0;
      double total = params['total'] ?? 0.0;

      if (total == 0.0 && items.isNotEmpty) {
        // Recalculate if totals not provided
        subtotal = 0.0;
        for (final item in items) {
          if (item is Map) {
            final quantity = (item['quantity'] ?? 1) as int;
            final price =
                (item['product']?['price'] ?? item['price'] ?? 0.0) as double;
            subtotal += quantity * price;
          }
        }
        // Standard tax 10% and delivery 5%
        tax = subtotal * 0.1;
        deliveryFee = 50.0;
        total = subtotal + tax + deliveryFee;
      }

      // Create order document in Firestore
      final firestore = FirebaseFirestore.instance;
      final orderRef = firestore.collection('orders').doc();

      await orderRef.set({
        'orderId': orderRef.id,
        'userId': userId,
        'items': items,
        'shippingAddress': address.toMap(),
        'paymentMethodId': paymentMethod.id,
        'paymentMethod': paymentMethod.type,
        'promoCode': promoCode,
        'subtotal': subtotal,
        'tax': tax,
        'deliveryFee': deliveryFee,
        'totalAmount': total,
        'status': 'pending_payment',
        'paymentStatus': 'awaiting_payment',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Return success with order ID
      return OrderCreationResult(
        success: true,
        orderId: orderRef.id,
      );
    } catch (e) {
      return OrderCreationResult(
        success: false,
        error: 'Failed to create order: $e',
      );
    }
  },
);

/// Provides user's cart items
final userCartItemsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    if (userId.isEmpty) return [];

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  },
);
