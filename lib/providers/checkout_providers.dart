import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';

// ============================================================================
// CHECKOUT STATE - TIER 1 CRITICAL
// ============================================================================

class CheckoutState {
  final String? deliveryAddressId;
  final String? selectedPaymentMethod;
  final bool isProcessing;
  final String? processingError;
  final Order? createdOrder;

  CheckoutState({
    this.deliveryAddressId,
    this.selectedPaymentMethod,
    this.isProcessing = false,
    this.processingError,
    this.createdOrder,
  });

  CheckoutState copyWith({
    String? deliveryAddressId,
    String? selectedPaymentMethod,
    bool? isProcessing,
    String? processingError,
    Order? createdOrder,
  }) {
    return CheckoutState(
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      processingError: processingError ?? this.processingError,
      createdOrder: createdOrder ?? this.createdOrder,
    );
  }
}

// ============================================================================
// CHECKOUT NOTIFIER
// ============================================================================

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    return CheckoutState();
  }

  void setDeliveryAddress(String addressId) {
    state = state.copyWith(deliveryAddressId: addressId);
  }

  void setPaymentMethod(String paymentMethod) {
    state = state.copyWith(selectedPaymentMethod: paymentMethod);
  }

  void setProcessing(bool isProcessing) {
    state = state.copyWith(isProcessing: isProcessing);
  }

  void setError(String? error) {
    state = state.copyWith(processingError: error);
  }

  void setCreatedOrder(Order order) {
    state = state.copyWith(createdOrder: order);
  }

  void reset() {
    state = CheckoutState();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

final checkoutStateProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  () => CheckoutNotifier(),
);

// User delivery addresses
final userAddressesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // TODO: Implement address fetching from Firestore
  // For now, return empty list
  return [];
});

// Cart totals calculation
final cartTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  // TODO: Integrate with real cart provider when available
  return {
    'subtotal': 0.0,
    'tax': 0.0,
    'shipping': 0.0,
    'total': 0.0,
  };
});

// Order confirmation
final orderConfirmationProvider = FutureProvider<Order?>((ref) {
  final checkout = ref.watch(checkoutStateProvider);
  return Future.value(checkout.createdOrder);
});

// ============================================================================
// SUPPORT PROVIDERS
// ============================================================================

final userCartProvider = FutureProvider<Cart?>((ref) async {
  // TODO: Implement cart fetching
  return null;
});
