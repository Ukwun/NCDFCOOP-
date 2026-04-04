import 'dart:async';
import 'package:dio/dio.dart';
import 'payment_models.dart';

/// Abstract payment service interface
abstract class PaymentService {
  /// Initialize payment service with API credentials
  Future<void> initialize({
    required String publicKey,
    required String secretKey,
    bool testMode = true,
  });

  /// Initiate a payment transaction
  Future<PaymentResponse> initiatePayment(PaymentRequest request);

  /// Verify payment status
  Future<PaymentResponse> verifyPayment(String reference);

  /// Get payment methods available for the provider
  Future<List<PaymentMethod>> getAvailableMethods();

  /// Process refund
  Future<bool> processRefund(String reference, double amount);

  /// Get transaction history
  Future<List<PaymentTransaction>> getTransactionHistory({
    int page = 1,
    int limit = 10,
  });
}

/// Paystack payment implementation
class PaystackPaymentService implements PaymentService {
  late String _secretKey;
  late Dio _dio;

  static const String _baseUrl = 'https://api.paystack.co';

  @override
  Future<void> initialize({
    required String publicKey,
    required String secretKey,
    bool testMode = true,
  }) async {
    _secretKey = secretKey;

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  @override
  Future<PaymentResponse> initiatePayment(PaymentRequest request) async {
    try {
      final response = await _dio.post(
        '/transaction/initialize',
        data: {
          'email': request.customerEmail,
          'amount': (request.amount * 100).toInt(), // Paystack uses kobo
          'currency': request.currency,
          'metadata': {
            'custom_fields': [
              {
                'display_name': 'Customer Name',
                'variable_name': 'customer_name',
                'value': request.customerName,
              },
              {
                'display_name': 'Customer Phone',
                'variable_name': 'customer_phone',
                'value': request.customerPhone,
              },
            ],
            'transaction_id': request.transactionId,
            'payment_method': request.method.name,
            ...?request.metadata,
          },
        },
      );

      final data = response.data['data'];

      return PaymentResponse(
        transactionId: request.transactionId,
        paymentId: data['reference'],
        status: 'pending',
        amount: request.amount,
        currency: request.currency,
        provider: 'paystack',
        timestamp: DateTime.now(),
        authorizationUrl: data['authorization_url'],
        rawResponse: response.data,
      );
    } on DioException catch (e) {
      return PaymentResponse(
        transactionId: request.transactionId,
        status: 'failed',
        amount: request.amount,
        currency: request.currency,
        provider: 'paystack',
        timestamp: DateTime.now(),
        message: 'Payment initialization failed: ${e.message}',
      );
    }
  }

  @override
  Future<PaymentResponse> verifyPayment(String reference) async {
    try {
      final response = await _dio.get('/transaction/verify/$reference');

      final data = response.data['data'];
      final status = data['status'];

      return PaymentResponse(
        transactionId: data['metadata']['transaction_id'],
        paymentId: reference,
        status: _parsePaystackStatusString(status),
        amount: (data['amount'] / 100).toDouble(),
        currency: data['currency'],
        provider: 'paystack',
        timestamp: DateTime.parse(data['created_at']),
        message: data['gateway_response'],
        rawResponse: response.data,
      );
    } on DioException catch (e) {
      return PaymentResponse(
        transactionId: reference,
        status: 'failed',
        amount: 0,
        currency: 'NGN',
        provider: 'paystack',
        timestamp: DateTime.now(),
        message: 'Verification failed: ${e.message}',
      );
    }
  }

  @override
  Future<List<PaymentMethod>> getAvailableMethods() async {
    return [
      PaymentMethod.card,
      PaymentMethod.bankTransfer,
      PaymentMethod.ussd,
      PaymentMethod.mobileWallet,
    ];
  }

  @override
  Future<bool> processRefund(String reference, double amount) async {
    try {
      await _dio.post(
        '/refund',
        data: {'transaction': reference, 'amount': (amount * 100).toInt()},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<PaymentTransaction>> getTransactionHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/transaction',
        queryParameters: {'perPage': limit, 'page': page},
      );

      final transactions = (response.data['data'] as List?)
              ?.map(
                (t) => PaymentTransaction(
                  id: t['id'].toString(),
                  paymentId: t['reference'],
                  orderId: t['metadata']?['transaction_id'],
                  amount: (t['amount'] / 100).toDouble(),
                  currency: t['currency'],
                  provider: PaymentProvider.paystack,
                  method: _parsePaymentMethod(t['channel']),
                  status: _parsePaystackStatus(t['status']),
                  createdAt: DateTime.parse(t['created_at']),
                  reference: t['reference'],
                ),
              )
              .toList() ??
          [];

      return transactions;
    } catch (e) {
      return [];
    }
  }

  PaymentStatus _parsePaystackStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'pending':
        return PaymentStatus.pending;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  String _parsePaystackStatusString(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'success';
      case 'pending':
        return 'pending';
      case 'failed':
        return 'failed';
      default:
        return 'pending';
    }
  }

  PaymentMethod _parsePaymentMethod(String channel) {
    switch (channel.toLowerCase()) {
      case 'card':
        return PaymentMethod.card;
      case 'bank':
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'ussd':
        return PaymentMethod.ussd;
      case 'mobile_money':
        return PaymentMethod.mobileWallet;
      default:
        return PaymentMethod.card;
    }
  }
}
