import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'payment_models.dart';
import 'payment_service.dart';
import 'firebase_payment_service.dart';
import 'payment_config.dart';

class PaymentState {
  final bool isLoading;
  final String? error;

  const PaymentState({this.isLoading = false, this.error});
}

class PaymentController extends Notifier<PaymentState> {
  @override
  PaymentState build() => const PaymentState();

  Future<void> processPayment(
      PaymentRequest request, BuildContext context) async {
    state = const PaymentState(isLoading: true);

    try {
      if (request.provider == PaymentProvider.flutterwave) {
        await _handleFlutterwave(request, context);
      } else {
        throw UnimplementedError(
            'Provider ${request.provider} not implemented');
      }

      state = const PaymentState(isLoading: false);
    } catch (e) {
      state = PaymentState(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> _handleFlutterwave(
      PaymentRequest request, BuildContext context) async {
    try {
      // Create customer object
      final Customer customer = Customer(
        name: request.customerName,
        phoneNumber: request.customerPhone,
        email: request.customerEmail,
      );

      // Initialize Flutterwave with test credentials
      final Flutterwave flutterwave = Flutterwave(
        publicKey: PaymentConfig.flutterwavePublicKey,
        currency: request.currency,
        redirectUrl: "https://google.com",
        txRef: request.transactionId,
        amount: request.amount.toString(),
        customer: customer,
        paymentOptions: "card, payattitude, barter, bank transfer, ussd",
        customization: Customization(title: "Coop Commerce"),
        isTestMode: true,
      );

      // Call charge with timeout to prevent infinite hanging
      final ChargeResponse response = await flutterwave.charge(context).timeout(
            const Duration(minutes: 5),
            onTimeout: () => throw TimeoutException(
              'Payment gateway timeout - please try again',
            ),
          );

      // Check if payment was successful
      if (response.success != true) {
        throw Exception(response.status ?? "Payment failed or was cancelled");
      }
    } on TimeoutException catch (e) {
      throw Exception('Payment timeout: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}

final paymentControllerProvider =
    NotifierProvider<PaymentController, PaymentState>(
  PaymentController.new,
);

/// Firebase Payment Service Provider
///
/// Provides access to Firebase Cloud Functions for payment processing.
/// Automatically initializes with Paystack credentials from environment.
final firebasePaymentServiceProvider = Provider<PaymentService>((ref) {
  return FirebasePaymentService(
    auth: FirebaseAuth.instance,
  );
});

/// Active Payment Service Provider
///
/// Determines which payment service to use based on environment.
/// Falls back to Firebase if local/production backends are unavailable.
final activePaymentServiceProvider = Provider<PaymentService>((ref) {
  // For now, default to Firebase Cloud Functions
  // In the future, can switch based on backend detection
  return FirebasePaymentService(
    auth: FirebaseAuth.instance,
  );
});
