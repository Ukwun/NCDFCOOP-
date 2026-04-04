import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'flutterwave_payment_service.dart';

/// Checkout-specific service that orchestrates Flutterwave payment flows
/// Handles both card payments and bank transfer payment types
class FlutterwaveCheckoutPaymentService {
  final FlutterwavePaymentService _paymentService;
  final FirebaseFirestore _firestore;

  FlutterwaveCheckoutPaymentService({
    required FlutterwavePaymentService paymentService,
    required FirebaseFirestore firestore,
  })  : _paymentService = paymentService,
        _firestore = firestore;

  /// Initiates card payment flow
  /// Returns: payment reference for tracking
  Future<String?> initiateCardPayment({
    required String orderId,
    required double amount,
    required String customerEmail,
    required String customerName,
    required String phoneNumber,
    required String customerId,
  }) async {
    try {
      final result = await _paymentService.initiatePayment(
        email: customerEmail,
        amount: amount,
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        phoneNumber: phoneNumber,
        paymentType: 'card',
      );

      if (result['success'] == true) {
        return result['reference'];
      }

      throw Exception(result['error'] ?? 'Failed to initiate card payment');
    } catch (e) {
      debugPrint('Card payment initiation error: $e');
      rethrow;
    }
  }

  /// Initiates bank transfer payment flow
  /// Returns: payment details including account information
  Future<Map<String, dynamic>> initiateBankTransferPayment({
    required String orderId,
    required double amount,
    required String customerEmail,
    required String customerName,
    required String phoneNumber,
    required String customerId,
  }) async {
    try {
      // Create payment record in Flutterwave
      final paymentResult = await _paymentService.initiatePayment(
        email: customerEmail,
        amount: amount,
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        phoneNumber: phoneNumber,
        paymentType: 'bank_transfer',
      );

      if (paymentResult['success'] != true) {
        throw Exception(
            paymentResult['error'] ?? 'Failed to initiate bank transfer');
      }

      // Get bank details for display to customer
      final bankDetails = await _paymentService.getBankTransferDetails(
        orderId: orderId,
        amount: amount,
      );

      return {
        'success': true,
        'reference': paymentResult['reference'],
        'paymentId': paymentResult['paymentId'],
        'bankDetails': bankDetails,
        'amount': amount,
        'orderId': orderId,
      };
    } catch (e) {
      debugPrint('Bank transfer initiation error: $e');
      rethrow;
    }
  }

  /// Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String reference) async {
    try {
      return await _paymentService.verifyPayment(reference);
    } catch (e) {
      debugPrint('Payment status check error: $e');
      rethrow;
    }
  }

  /// Wait for webhook confirmation (polling fallback)
  /// Useful if user wants to wait for payment confirmation before navigating
  Future<bool> waitForPaymentConfirmation({
    required String orderId,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      try {
        final orderDoc =
            await _firestore.collection('orders').doc(orderId).get();

        if (!orderDoc.exists) {
          return false;
        }

        final status = orderDoc.get('status') as String?;

        // Payment confirmed by webhook
        if (status == 'confirmed' || status == 'payment_pending_verification') {
          return true;
        }

        // Wait before retrying
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Payment confirmation polling error: $e');
      }
    }

    // Timeout reached
    return false;
  }

  /// Get bank transfer verification status
  /// Used to check if manual verification is still pending
  Future<bool> isBankTransferVerified(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) return false;

      final status = orderDoc.get('status') as String?;
      return status == 'confirmed';
    } catch (e) {
      debugPrint('Bank transfer verification check error: $e');
      return false;
    }
  }

  /// Get payment details from Firestore
  Future<Map<String, dynamic>?> getPaymentDetails(String orderId) async {
    try {
      final paymentDocs = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (paymentDocs.docs.isEmpty) return null;

      return paymentDocs.docs.first.data();
    } catch (e) {
      debugPrint('Get payment details error: $e');
      return null;
    }
  }

  /// Process refund for a payment
  Future<Map<String, dynamic>> processRefund({
    required String reference,
    required double amount,
    required String reason,
  }) async {
    try {
      return await _paymentService.processRefund(
        reference: reference,
        amount: amount,
      );
    } catch (e) {
      debugPrint('Refund processing error: $e');
      rethrow;
    }
  }

  /// Get formatted bank details for display
  /// Returns HTML-formatted string for UI display
  String formatBankTransferDetails(Map<String, dynamic> bankDetails) {
    try {
      final bankName = bankDetails['bankName'] as String? ?? 'N/A';
      final accountName = bankDetails['accountName'] as String? ?? 'N/A';
      final accountNumber = bankDetails['accountNumber'] as String? ?? 'N/A';
      final reference = bankDetails['reference'] as String? ?? 'N/A';

      return '''
Bank Transfer Details:
━━━━━━━━━━━━━━━━━━━━━━
Bank: $bankName
Account Name: $accountName
Account Number: $accountNumber
Reference: $reference

Instructions:
1. Open your bank app
2. Select "Transfer" or "Send Money"
3. Enter the account details above
4. Use the reference as the payment description
5. Confirm and complete the transfer

Your order will be confirmed once we receive your payment.
      '''
          .trim();
    } catch (e) {
      return 'Bank transfer details unavailable';
    }
  }
}
