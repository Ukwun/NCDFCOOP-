library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Client facade for server-controlled Flutterwave operations.
/// No provider secret or card data is handled by the Flutter application.
class FlutterwavePaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> initialize() async {}

  Future<Map<String, dynamic>> initiatePayment({
    required String email,
    required double amount,
    required String orderId,
    required String customerId,
    required String customerName,
    required String phoneNumber,
    required String paymentType,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('initializeFlutterwavePayment')
          .call(<String, dynamic>{
        'orderId': orderId,
        'paymentType': paymentType,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return <String, dynamic>{'success': true, ...data};
    } on FirebaseFunctionsException catch (error) {
      return {
        'success': false,
        'error': error.message ?? 'Unable to initialize payment.',
      };
    }
  }

  Future<Map<String, dynamic>> verifyPayment(String paymentId) async {
    final snapshot =
        await _firestore.collection('payments').doc(paymentId).get();
    if (!snapshot.exists) {
      return {'success': false, 'error': 'Payment was not found.'};
    }
    final data = snapshot.data()!;
    return {
      'success': data['status'] == 'completed',
      'status': data['status'] ?? 'pending',
      'amount': (data['amount'] as num?)?.toDouble() ?? 0,
      'reference': data['txRef'] ?? paymentId,
    };
  }

  Future<Map<String, dynamic>> processRefund({
    required String reference,
    required double amount,
  }) async {
    return {
      'success': false,
      'error': 'Refunds require a support-approved server request.',
    };
  }

  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    final snapshot =
        await _firestore.collection('payments').doc(paymentId).get();
    return snapshot.data();
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    throw UnsupportedError('Payment status can only be updated by the server.');
  }

  Future<void> logTransaction({
    required String paymentId,
    required String orderId,
    required String customerId,
    required String type,
    required double amount,
    required String status,
    Map<String, dynamic>? details,
  }) async {
    // Transaction records are produced by verified payment webhooks.
  }

  Future<Map<String, dynamic>> getBankTransferDetails({
    required String orderId,
    required double amount,
  }) async {
    return {
      'success': false,
      'error': 'Use the temporary bank account shown on Flutterwave checkout.',
    };
  }
}
