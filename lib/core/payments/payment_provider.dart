import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'payment_models.dart';

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
    final Customer customer = Customer(
      name: request.customerName,
      phoneNumber: request.customerPhone,
      email: request.customerEmail,
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey: const String.fromEnvironment('FLUTTERWAVE_PUBLIC_KEY',
          defaultValue: 'FLWPUBK_TEST-XXXXXXXXXX-X'),
      currency: request.currency,
      redirectUrl: "https://google.com",
      txRef: request.transactionId,
      amount: request.amount.toString(),
      customer: customer,
      paymentOptions: "card, payattitude, barter, bank transfer, ussd",
      customization: Customization(title: "Coop Commerce"),
      isTestMode: true,
    );

    final ChargeResponse response = await flutterwave.charge(context);

    if (response.success != true) {
      throw Exception(response.status ?? "Payment failed or cancelled");
    }
  }
}

final paymentControllerProvider =
    NotifierProvider<PaymentController, PaymentState>(
  PaymentController.new,
);
