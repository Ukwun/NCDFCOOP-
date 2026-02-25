import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_models.dart';
import 'payment_service.dart' as base_service;

/// Firebase Cloud Functions Payment Service with Flutterwave
///
/// This service handles payment processing through Firebase Cloud Functions,
/// supporting Flutterwave as payment provider and bank transfers.
class FirebasePaymentService implements base_service.PaymentService {
  late Dio _dio;
  late String _firebaseUrl;
  final FirebaseAuth _auth;

  static const String _baseUrl =
      'https://us-central1-coop-commerce.cloudfunctions.net/payments';

  FirebasePaymentService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> initialize({
    required String publicKey,
    required String secretKey,
    bool testMode = true,
  }) async {
    _firebaseUrl = _baseUrl;

    // Get Firebase ID token for authentication
    final user = _auth.currentUser;
    final idToken = await user?.getIdToken();

    _dio = Dio(
      BaseOptions(
        baseUrl: _firebaseUrl,
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  @override
  Future<PaymentResponse> initiatePayment(PaymentRequest request) async {
    try {
      final response = await _dio.post(
        '/initiatePayment',
        data: {
          'amount': request.amount,
          'currency': request.currency,
          'email': request.customerEmail,
          'customerName': request.customerName,
          'customerPhone': request.customerPhone,
          'customerId': request.customerId,
          'orderId': request.orderId,
          'description': request.description,
          'paymentMethod': _mapPaymentMethod(request.method),
        },
      );

      final data = response.data as Map<String, dynamic>;

      return PaymentResponse(
        success: data['success'] ?? false,
        reference: data['txRef'] ?? '',
        message: data['message'] ?? 'Payment initiated',
        accessCode: data['txRef'],
        authorizationUrl: data['authorizationUrl'],
        data: data,
      );
    } on DioException catch (e) {
      throw PaymentInitializationException(
        'Failed to initiate payment: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<PaymentResponse> verifyPayment(String reference) async {
    try {
      final response = await _dio.post(
        '/verifyPayment',
        data: {'txRef': reference},
      );

      final data = response.data as Map<String, dynamic>;

      return PaymentResponse(
        success: data['success'] ?? false,
        reference: data['txRef'] ?? reference,
        message: data['message'] ?? 'Payment verified',
        data: data,
      );
    } on DioException catch (e) {
      throw PaymentVerificationException(
        'Failed to verify payment: ${e.message}',
        reference: reference,
      );
    }
  }

  @override
  Future<List<PaymentMethod>> getAvailableMethods() async {
    try {
      final response = await _dio.get('/availablePaymentMethods');

      final data = response.data as Map<String, dynamic>;
      final methods = data['methods'] as List<dynamic>? ?? [];

      // Convert to enum values
      final methodList = <PaymentMethod>[];
      for (final m in methods) {
        final type = (m['type'] ?? '').toString().toLowerCase();
        if (type.contains('card')) {
          methodList.add(PaymentMethod.card);
        } else if (type.contains('bank')) {
          methodList.add(PaymentMethod.bankTransfer);
        } else if (type.contains('ussd')) {
          methodList.add(PaymentMethod.ussd);
        } else if (type.contains('mobile')) {
          methodList.add(PaymentMethod.mobileMoney);
        }
      }
      return methodList;
    } on DioException catch (e) {
      throw PaymentException(
        'Failed to fetch payment methods: ${e.message}',
      );
    }
  }

  @override
  Future<bool> processRefund(String reference, double amount) async {
    try {
      final response = await _dio.post(
        '/processRefund',
        data: {
          'txRef': reference,
          'amount': amount,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] ?? false;
    } on DioException catch (e) {
      throw PaymentException(
        'Failed to process refund: ${e.message}',
      );
    }
  }

  @override
  Future<List<PaymentTransaction>> getTransactionHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/transactionHistory',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final payments = data['payments'] as List<dynamic>? ?? [];

      return payments
          .map((t) => PaymentTransaction(
                id: t['id'] ?? '',
                reference: t['txRef'] ?? '',
                amount: (t['amount'] as num).toDouble(),
                provider: t['provider'] == 'flutterwave'
                    ? PaymentProvider.flutterwave
                    : PaymentProvider.paystack,
                method: _parsePaymentMethod(t['paymentMethod'] ?? 'card'),
                status: _parseStatus(t['status'] ?? 'pending'),
                createdAt: t['createdAt'] != null
                    ? DateTime.parse(t['createdAt'].toString())
                    : DateTime.now(),
              ))
          .toList();
    } on DioException catch (e) {
      throw PaymentException(
        'Failed to fetch transaction history: ${e.message}',
      );
    }
  }

  /// Process webhook from Flutterwave
  /// This is called by Firebase Functions when Flutterwave sends webhooks
  Future<bool> processWebhook(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '/webhooks/flutterwave',
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      return data['success'] ?? false;
    } on DioException catch (e) {
      throw PaymentException(
        'Failed to process webhook: ${e.message}',
      );
    }
  }

  /// Map PaymentMethod enum to string for API
  String _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.mobileWallet:
        return 'mobile_wallet';
      case PaymentMethod.ussd:
        return 'ussd';
    }
  }

  /// Parse payment method string to enum
  PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return PaymentMethod.card;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'mobile_money':
      case 'mobile_wallet':
        return PaymentMethod.mobileMoney;
      case 'ussd':
        return PaymentMethod.ussd;
      default:
        return PaymentMethod.card;
    }
  }

  /// Helper method to parse payment status
  PaymentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
      case 'success':
      case 'successful':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// Custom Payment Exceptions
class PaymentException implements Exception {
  final String message;

  PaymentException(this.message);

  @override
  String toString() => message;
}

class PaymentInitializationException extends PaymentException {
  final int? statusCode;

  PaymentInitializationException(
    super.message, {
    this.statusCode,
  });
}

class PaymentVerificationException extends PaymentException {
  final String reference;

  PaymentVerificationException(
    super.message, {
    required this.reference,
  });
}
