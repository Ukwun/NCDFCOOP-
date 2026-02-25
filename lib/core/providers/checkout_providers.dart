import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/audit/audit_service.dart';
import 'package:coop_commerce/core/services/address_service.dart';
import 'package:coop_commerce/models/address.dart';

// ==================== SERVICE PROVIDERS ====================

// Address service provider - manages user addresses
final addressServiceProvider = Provider((ref) {
  final auditService = AuditService();
  return AddressService(auditService);
});

// ==================== DATA PROVIDERS ====================

// Stream of user addresses from Firebase
final userAddressesProvider = StreamProvider.family<List<Address>, String>(
  (ref, userId) {
    final firestore = FirebaseFirestore.instance;
    return firestore
        .collection('addresses')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Address.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  },
);

// Validate promo code
final validatePromoCodeProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, code) async {
  // Simulate API call
  await Future.delayed(const Duration(milliseconds: 500));

  if (code.isEmpty) {
    return {'valid': false, 'discount': 0.0, 'message': 'Enter a promo code'};
  }

  // Mock promo codes - replace with actual service call
  const validCodes = {
    'SAVE30': 0.30,
    'MEMBER20': 0.20,
    'BULK15': 0.15,
    'FIRST10': 0.10,
  };

  if (validCodes.containsKey(code)) {
    return {
      'valid': true,
      'discount': validCodes[code]!,
      'message': 'Promo code applied!'
    };
  }

  return {'valid': false, 'discount': 0.0, 'message': 'Invalid promo code'};
});

// ==================== STATE MANAGEMENT ====================

// Checkout state model
class CheckoutState {
  final Address? selectedAddress;
  final String selectedPaymentMethod;
  final bool saveCard;
  final String promoCode;
  final bool isLoading;
  final String? error;
  final ({String date, String time})? deliverySlot;

  CheckoutState({
    this.selectedAddress,
    this.selectedPaymentMethod = 'card',
    this.saveCard = false,
    this.promoCode = '',
    this.isLoading = false,
    this.error,
    this.deliverySlot,
  });

  CheckoutState copyWith({
    Address? selectedAddress,
    String? selectedPaymentMethod,
    bool? saveCard,
    String? promoCode,
    bool? isLoading,
    String? error,
    ({String date, String time})? deliverySlot,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      saveCard: saveCard ?? this.saveCard,
      promoCode: promoCode ?? this.promoCode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      deliverySlot: deliverySlot ?? this.deliverySlot,
    );
  }
}

// State notifier for checkout
class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => CheckoutState();

  void selectAddress(Address address) {
    state = state.copyWith(selectedAddress: address);
  }

  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void toggleSaveCard(bool save) {
    state = state.copyWith(saveCard: save);
  }

  void applyPromoCode(String code) {
    state = state.copyWith(promoCode: code);
  }

  void selectDeliverySlot(String date, String time) {
    state = state.copyWith(deliverySlot: (date: date, time: time));
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = CheckoutState();
  }
}

// Checkout state provider
final checkoutStateProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(
  () => CheckoutNotifier(),
);
