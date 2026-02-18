import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_models.dart';
import 'payment_exceptions.dart'
    show CardProcessingException, CardValidationException;

/// Card payment processor for Stripe and Flutterwave
class CardProcessor {
  final Dio _dio;
  late String _secretKey;
  late PaymentProvider _provider;
  bool _testMode = true;

  CardProcessor({required Dio dio}) : _dio = dio;

  /// Initialize card processor with credentials
  Future<void> initialize({
    required String publicKey,
    required String secretKey,
    required PaymentProvider provider,
    bool testMode = true,
  }) async {
    _secretKey = secretKey;
    _provider = provider;
    _testMode = testMode;

    // Set default headers for API calls
    _dio.options.headers['Authorization'] = 'Bearer $_secretKey';
  }

  /// Process card payment
  Future<CardPaymentResponse> processCardPayment({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required double amount,
    required String currency,
    required String email,
    required String metadata,
  }) async {
    try {
      // Validate card details
      _validateCardDetails(
        cardNumber,
        expiryMonth,
        expiryYear,
        cvv,
      );

      late CardPaymentResponse response;

      if (_provider == PaymentProvider.flutterwave) {
        response = await _processFlutterwave(
          cardNumber: cardNumber,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          cvv: cvv,
          amount: amount,
          currency: currency,
          email: email,
          metadata: metadata,
        );
      } else {
        response = await _processStripe(
          cardNumber: cardNumber,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          cvv: cvv,
          amount: amount,
          currency: currency,
          email: email,
          metadata: metadata,
        );
      }

      return response;
    } catch (e) {
      throw CardProcessingException('Card payment failed: $e');
    }
  }

  /// Process payment with Flutterwave
  Future<CardPaymentResponse> _processFlutterwave({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required double amount,
    required String currency,
    required String email,
    required String metadata,
  }) async {
    try {
      final response = await _dio.post(
        _testMode
            ? 'https://api.flutterwave.com/v3/charges?type=card'
            : 'https://api.flutterwave.com/v3/charges?type=card',
        data: {
          'amount': amount,
          'currency': currency,
          'email': email,
          'tx_ref': 'txn_${DateTime.now().millisecondsSinceEpoch}',
          'card_number': cardNumber,
          'expiry_month': expiryMonth,
          'expiry_year': expiryYear,
          'cvv': cvv,
          'meta': {'metadata': metadata},
          'narration': 'COOP Commerce Payment',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final status = data['status'] ?? 'error';

        return CardPaymentResponse(
          success: status == 'success',
          reference: data['data']?['transaction_id']?.toString() ?? '',
          message: data['message'],
          authUrl: data['data']?['auth_url'],
          provider: PaymentProvider.flutterwave,
        );
      }

      throw Exception('Flutterwave request failed: ${response.statusCode}');
    } catch (e) {
      throw CardProcessingException('Flutterwave processing error: $e');
    }
  }

  /// Process payment with Stripe
  Future<CardPaymentResponse> _processStripe({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required double amount,
    required String currency,
    required String email,
    required String metadata,
  }) async {
    try {
      // Create payment method
      final pmResponse = await _dio.post(
        'https://api.stripe.com/v1/payment_methods',
        data: {
          'type': 'card',
          'card': {
            'number': cardNumber,
            'exp_month': expiryMonth,
            'exp_year': expiryYear,
            'cvc': cvv,
          },
          'billing_details': {
            'email': email,
          },
        },
      );

      if (pmResponse.statusCode != 200) {
        throw Exception('Payment method creation failed');
      }

      final paymentMethodId = pmResponse.data['id'];

      // Create payment intent
      final piResponse = await _dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: {
          'amount': (amount * 100).toInt(), // Stripe uses cents
          'currency': currency.toLowerCase(),
          'payment_method': paymentMethodId,
          'confirm': 'true',
          'metadata': metadata,
        },
      );

      if (piResponse.statusCode != 200) {
        throw Exception('Payment intent creation failed');
      }

      final piData = piResponse.data as Map<String, dynamic>;
      final status = piData['status'] ?? 'failed';

      return CardPaymentResponse(
        success: status == 'succeeded',
        reference: piData['id'] ?? '',
        message: piData['status'] ?? 'Payment failed',
        clientSecret: piData['client_secret'],
        provider: PaymentProvider.flutterwave,
      );
    } catch (e) {
      throw CardProcessingException('Stripe processing error: $e');
    }
  }

  /// Validate card details
  void _validateCardDetails(
    String cardNumber,
    String expiryMonth,
    String expiryYear,
    String cvv,
  ) {
    // Remove spaces and validate length
    final cleanCard = cardNumber.replaceAll(' ', '');
    if (cleanCard.length < 13 || cleanCard.length > 19) {
      throw CardValidationException('Invalid card number');
    }

    // Validate expiry
    try {
      final month = int.parse(expiryMonth);
      final year = int.parse(expiryYear);

      if (month < 1 || month > 12) {
        throw CardValidationException('Invalid expiry month');
      }

      final now = DateTime.now();
      final expiry = DateTime(year + 2000, month);

      if (expiry.isBefore(now)) {
        throw CardValidationException('Card has expired');
      }
    } catch (e) {
      throw CardValidationException('Invalid expiry date: $e');
    }

    // Validate CVV
    if (cvv.length < 3 || cvv.length > 4) {
      throw CardValidationException('Invalid CVV');
    }
  }

  /// Verify 3D Secure authentication
  Future<bool> verify3DSecure(
    String clientSecret,
    String otp,
  ) async {
    try {
      final response = await _dio.post(
        'https://api.stripe.com/v1/payment_intents/$clientSecret/confirm',
        data: {
          'payment_method_options[card][request_three_d_secure]': 'if_required',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw CardProcessingException('3D Secure verification failed: $e');
    }
  }

  /// Save card for future use
  Future<String> saveCard({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String email,
    required String cardholderName,
  }) async {
    try {
      _validateCardDetails(cardNumber, expiryMonth, expiryYear, cvv);

      final response = await _dio.post(
        'https://api.stripe.com/v1/payment_methods',
        data: {
          'type': 'card',
          'card': {
            'number': cardNumber,
            'exp_month': expiryMonth,
            'exp_year': expiryYear,
            'cvc': cvv,
          },
          'billing_details': {
            'email': email,
            'name': cardholderName,
          },
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save card');
      }

      return response.data['id'] ?? '';
    } catch (e) {
      throw CardProcessingException('Card save failed: $e');
    }
  }
}

/// Card payment response
class CardPaymentResponse {
  final bool success;
  final String reference;
  final String? message;
  final String? authUrl;
  final String? clientSecret;
  final PaymentProvider provider;

  CardPaymentResponse({
    required this.success,
    required this.reference,
    this.message,
    this.authUrl,
    this.clientSecret,
    required this.provider,
  });
}

/// Provider for card processor
final cardProcessorProvider = Provider((ref) => CardProcessor(dio: Dio()));
