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
  final normalizedCode = code.trim().toUpperCase();
  if (normalizedCode.isEmpty) {
    return {'valid': false, 'discount': 0.0, 'message': 'Enter a promo code'};
  }

  final snapshot = await FirebaseFirestore.instance
      .collection('promotions')
      .where('code', isEqualTo: normalizedCode)
      .limit(1)
      .get();
  if (snapshot.docs.isEmpty) {
    return {'valid': false, 'discount': 0.0, 'message': 'Invalid promo code'};
  }
  final data = snapshot.docs.first.data();
  final now = DateTime.now();
  final startsAt = (data['startDate'] as Timestamp?)?.toDate();
  final endsAt = (data['endDate'] as Timestamp?)?.toDate();
  final active = data['status'] == 'active' &&
      (startsAt == null || !now.isBefore(startsAt)) &&
      (endsAt == null || now.isBefore(endsAt));
  final rawDiscount = (data['discountRate'] ?? data['discount'] ?? 0) as num;
  final discount = rawDiscount > 1 ? rawDiscount / 100 : rawDiscount.toDouble();
  if (!active || discount <= 0 || discount > 1) {
    return {
      'valid': false,
      'discount': 0.0,
      'message': 'This promo code is not active'
    };
  }
  return {
    'valid': true,
    'discount': discount,
    'promotionId': snapshot.docs.first.id,
    'message': 'Promo code applied'
  };
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
