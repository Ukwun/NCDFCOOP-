import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'payment_exceptions.dart';

/// Payment verification service
class PaymentVerificationService {
  final FirebaseFirestore _firestore;
  final Dio _dio;

  PaymentVerificationService({
    required FirebaseFirestore firestore,
    required Dio dio,
  })  : _firestore = firestore,
        _dio = dio;

  /// Verify payment from provider
  Future<VerificationResult> verifyPayment({
    required String reference,
    required String provider,
    required double expectedAmount,
    required String secretKey,
  }) async {
    try {
      late Map<String, dynamic> paymentData;

      if (provider == 'paystack') {
        paymentData = await _verifyPaystack(reference, secretKey);
      } else if (provider == 'flutterwave') {
        paymentData = await _verifyFlutterwave(reference, secretKey);
      } else {
        throw PaymentVerificationException(
            message: 'Unknown provider: $provider');
      }

      // Validate amount matches
      final actualAmount = (paymentData['amount'] as num).toDouble();
      if ((actualAmount - expectedAmount).abs() > 0.01) {
        throw PaymentVerificationException(
          message:
              'Amount mismatch: expected $expectedAmount, got $actualAmount',
        );
      }

      // Validate payment status
      final status = paymentData['status'] ?? 'failed';
      if (status != 'success') {
        return VerificationResult(
          verified: false,
          reference: reference,
          reason: 'Payment not successful: $status',
          paymentData: paymentData,
        );
      }

      return VerificationResult(
        verified: true,
        reference: reference,
        reason: 'Payment verified successfully',
        paymentData: paymentData,
      );
    } catch (e) {
      throw PaymentVerificationException(
          message: 'Payment verification error: $e');
    }
  }

  /// Verify Paystack payment
  Future<Map<String, dynamic>> _verifyPaystack(
    String reference,
    String secretKey,
  ) async {
    try {
      final response = await _dio.get(
        'https://api.paystack.co/transaction/verify/$reference',
        options: Options(
          headers: {
            'Authorization': 'Bearer $secretKey',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Paystack verification failed');
      }

      final data = response.data as Map<String, dynamic>;
      return {
        'amount': data['data']?['amount'] ?? 0,
        'status': data['data']?['status'] ?? 'failed',
        'reference': reference,
        'customer_email': data['data']?['customer']?['email'],
        'timestamp': data['data']?['paid_at'],
        'authorization': data['data']?['authorization'],
      };
    } catch (e) {
      throw PaymentVerificationException(
          message: 'Paystack verification error: $e');
    }
  }

  /// Verify Flutterwave payment
  Future<Map<String, dynamic>> _verifyFlutterwave(
    String reference,
    String secretKey,
  ) async {
    try {
      final response = await _dio.get(
        'https://api.flutterwave.com/v3/transactions/verify_by_reference',
        queryParameters: {'tx_ref': reference},
        options: Options(
          headers: {
            'Authorization': 'Bearer $secretKey',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Flutterwave verification failed');
      }

      final data = response.data as Map<String, dynamic>;
      final txData = data['data'] as Map<String, dynamic>;

      return {
        'amount': txData['amount'] ?? 0,
        'status': txData['status'] ?? 'failed',
        'reference': reference,
        'customer_email': txData['customer']?['email'],
        'timestamp': txData['created_at'],
        'transaction_id': txData['id'],
      };
    } catch (e) {
      throw PaymentVerificationException(
          message: 'Flutterwave verification error: $e');
    }
  }

  /// Store verified payment in Firestore
  Future<void> storeVerifiedPayment({
    required String reference,
    required String userId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      await _firestore.collection('payments').doc(reference).set({
        'reference': reference,
        'user_id': userId,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
        'status': 'verified',
        'verified_at': FieldValue.serverTimestamp(),
        'payment_data': paymentData,
        'metadata': {
          'customer_email': paymentData['customer_email'],
          'timestamp': paymentData['timestamp'],
        },
      }, SetOptions(merge: true));
    } catch (e) {
      throw PaymentStorageException('Failed to store verified payment: $e');
    }
  }

  /// Verify payment against stored order
  Future<bool> verifyPaymentForOrder({
    required String orderId,
    required String reference,
    required double amount,
  }) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw PaymentVerificationException(
            message: 'Order not found: $orderId');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final expectedAmount = (orderData['total_amount'] as num).toDouble();

      if ((expectedAmount - amount).abs() > 0.01) {
        throw PaymentVerificationException(
          message: 'Amount mismatch for order $orderId',
        );
      }

      // Store payment reference on order
      await _firestore.collection('orders').doc(orderId).update({
        'payment_reference': reference,
        'payment_status': 'verified',
        'payment_verified_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw PaymentVerificationException(
        message: 'Order payment verification error: $e',
      );
    }
  }

  /// Check payment status
  Future<String> checkPaymentStatus(String reference) async {
    try {
      final doc = await _firestore.collection('payments').doc(reference).get();

      if (!doc.exists) {
        return 'not_found';
      }

      return doc.data()?['status'] ?? 'unknown';
    } catch (e) {
      throw PaymentVerificationException(
          message: 'Payment status check error: $e');
    }
  }

  /// Get payment details
  Future<PaymentDetails> getPaymentDetails(String reference) async {
    try {
      final doc = await _firestore.collection('payments').doc(reference).get();

      if (!doc.exists) {
        throw PaymentVerificationException(
            message: 'Payment not found: $reference');
      }

      final data = doc.data() as Map<String, dynamic>;

      return PaymentDetails(
        reference: reference,
        amount: (data['amount'] as num).toDouble(),
        currency: data['currency'] ?? 'NGN',
        status: data['status'] ?? 'unknown',
        paymentMethod: data['payment_method'],
        verifiedAt: data['verified_at'],
        metadata: data['metadata'] ?? {},
      );
    } catch (e) {
      throw PaymentVerificationException(
          message: 'Get payment details error: $e');
    }
  }

  /// Validate payment webhook signature
  bool validateWebhookSignature({
    required String signature,
    required String payload,
    required String secretKey,
  }) {
    try {
      // Implementation depends on provider
      // This is a placeholder
      return signature.isNotEmpty && payload.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Verification result
class VerificationResult {
  final bool verified;
  final String reference;
  final String reason;
  final Map<String, dynamic> paymentData;

  VerificationResult({
    required this.verified,
    required this.reference,
    required this.reason,
    required this.paymentData,
  });
}

/// Payment details
class PaymentDetails {
  final String reference;
  final double amount;
  final String currency;
  final String status;
  final String? paymentMethod;
  final dynamic verifiedAt;
  final Map<String, dynamic> metadata;

  PaymentDetails({
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentMethod,
    this.verifiedAt,
    required this.metadata,
  });

  bool get isPaid => status == 'verified' || status == 'success';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}
