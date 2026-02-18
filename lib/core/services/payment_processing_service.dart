import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:coop_commerce/core/security/audit_log_service.dart';

enum PaymentStatus {
  pending,
  processing,
  successful,
  failed,
  cancelled,
  refunded
}

enum PaymentMethod {
  creditCard,
  debitCard,
  bankTransfer,
  mobileWallet,
  invoice
}

/// Service for handling payment processing
class PaymentProcessingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLogService;
  static const String _paymentsCollection = 'payments';
  static const String _transactionsCollection = 'transactions';
  static const _uuid = Uuid();

  PaymentProcessingService({
    AuditLogService? auditLogService,
  }) : _auditLogService = auditLogService ?? AuditLogService();

  /// Create a payment for an order with audit logging
  Future<String> createPayment({
    required String orderId,
    required String buyerId,
    required double amount,
    required PaymentMethod method,
    required String paymentMethodId,
    required String currency,
    String? invoiceNumber,
    String? notes,
  }) async {
    try {
      final paymentId = _uuid.v4();

      final payment = {
        'paymentId': paymentId,
        'orderId': orderId,
        'buyerId': buyerId,
        'amount': amount,
        'method': method.toString().split('.').last,
        'paymentMethodId': paymentMethodId,
        'currency': currency,
        'status': PaymentStatus.pending.toString().split('.').last,
        'invoiceNumber': invoiceNumber,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'processedAt': null,
        'refundedAt': null,
        'refundAmount': null,
        'transactionId': null,
      };

      await _firestore
          .collection(_paymentsCollection)
          .doc(paymentId)
          .set(payment);

      // Log payment creation
      await _auditLogService.logAction(
        buyerId,
        'consumer',
        AuditAction.dataAccessed,
        'payment',
        resourceId: paymentId,
        severity: AuditSeverity.info,
        details: {
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'method': method.toString().split('.').last,
          'invoice_number': invoiceNumber,
        },
      );

      return paymentId;
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  /// Process payment with audit logging
  Future<PaymentResult> processPayment({
    required String paymentId,
    required String gatewayTransactionId,
    String? authorizationCode,
    String? processingUserId,
  }) async {
    try {
      final paymentDoc =
          await _firestore.collection(_paymentsCollection).doc(paymentId).get();

      if (!paymentDoc.exists) {
        throw Exception('Payment not found');
      }

      final paymentData = paymentDoc.data() as Map<String, dynamic>;
      final buyerId = paymentData['buyerId'] as String;
      final amount = (paymentData['amount'] as num).toDouble();
      final orderId = paymentData['orderId'] as String;

      // Log transaction
      final transactionId = await _logTransaction(
        paymentId: paymentId,
        orderId: orderId,
        amount: amount,
        status: PaymentStatus.processing.toString().split('.').last,
        gatewayTransactionId: gatewayTransactionId,
        authorizationCode: authorizationCode,
      );

      // Update payment status
      await _firestore.collection(_paymentsCollection).doc(paymentId).update({
        'status': PaymentStatus.successful.toString().split('.').last,
        'processedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'transactionId': transactionId,
      });

      // Log successful payment processing
      await _auditLogService.logAction(
        processingUserId ?? buyerId,
        'admin',
        AuditAction.dataModified,
        'payment',
        resourceId: paymentId,
        severity: AuditSeverity.warning,
        details: {
          'order_id': orderId,
          'buyer_id': buyerId,
          'amount': amount,
          'transaction_id': transactionId,
          'gateway_transaction_id': gatewayTransactionId,
          'authorization_code': authorizationCode,
        },
      );

      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.successful,
        transactionId: transactionId,
        message: 'Payment processed successfully',
      );
    } catch (e) {
      // Log failed transaction
      await _firestore.collection(_paymentsCollection).doc(paymentId).update({
        'status': PaymentStatus.failed.toString().split('.').last,
        'failureReason': e.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log payment failure
      final paymentDoc =
          await _firestore.collection(_paymentsCollection).doc(paymentId).get();
      if (paymentDoc.exists) {
        final paymentData = paymentDoc.data() as Map<String, dynamic>;
        await _auditLogService.logAction(
          processingUserId ?? paymentData['buyerId'] as String,
          'admin',
          AuditAction.error,
          'payment',
          resourceId: paymentId,
          severity: AuditSeverity.error,
          details: {
            'reason': e.toString(),
            'gateway_transaction_id': gatewayTransactionId,
          },
        );
      }

      throw Exception('Failed to process payment: $e');
    }
  }

  /// Process refund with audit logging
  Future<RefundResult> processRefund({
    required String paymentId,
    required double refundAmount,
    required String reason,
    String? processingUserId,
  }) async {
    try {
      final paymentDoc =
          await _firestore.collection(_paymentsCollection).doc(paymentId).get();

      if (!paymentDoc.exists) {
        throw Exception('Payment not found');
      }

      final paymentData = paymentDoc.data() as Map<String, dynamic>;
      final originalAmount = (paymentData['amount'] as num).toDouble();
      final buyerId = paymentData['buyerId'] as String;
      final orderId = paymentData['orderId'] as String;

      if (refundAmount > originalAmount) {
        // Log invalid refund attempt
        await _auditLogService.logAction(
          processingUserId ?? buyerId,
          'admin',
          AuditAction.error,
          'payment',
          resourceId: paymentId,
          severity: AuditSeverity.error,
          details: {
            'reason': 'Refund amount exceeds original payment',
            'original_amount': originalAmount,
            'requested_refund': refundAmount,
          },
        );
        throw Exception('Refund amount exceeds original payment');
      }

      final refundId = _uuid.v4();

      // Log refund transaction
      await _logTransaction(
        paymentId: paymentId,
        orderId: orderId,
        amount: -refundAmount,
        status: PaymentStatus.refunded.toString().split('.').last,
        refundId: refundId,
        notes: reason,
      );

      // Update payment
      await _firestore.collection(_paymentsCollection).doc(paymentId).update({
        'status': PaymentStatus.refunded.toString().split('.').last,
        'refundedAt': FieldValue.serverTimestamp(),
        'refundAmount': refundAmount,
        'refundId': refundId,
        'refundReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log successful refund
      await _auditLogService.logAction(
        processingUserId ?? buyerId,
        'admin',
        AuditAction.dataModified,
        'payment',
        resourceId: paymentId,
        severity: AuditSeverity.warning,
        details: {
          'order_id': orderId,
          'buyer_id': buyerId,
          'original_amount': originalAmount,
          'refund_amount': refundAmount,
          'refund_id': refundId,
          'reason': reason,
        },
      );

      return RefundResult(
        refundId: refundId,
        paymentId: paymentId,
        refundAmount: refundAmount,
        status: PaymentStatus.refunded,
        message: 'Refund processed successfully',
      );
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  /// Get payment details
  Future<PaymentData?> getPayment(String paymentId) async {
    try {
      final doc =
          await _firestore.collection(_paymentsCollection).doc(paymentId).get();

      if (!doc.exists) return null;

      return PaymentData.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch payment: $e');
    }
  }

  /// Get payments for an order
  Future<List<PaymentData>> getOrderPayments(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection(_paymentsCollection)
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentData.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch order payments: $e');
    }
  }

  /// Get user payment history
  Future<List<PaymentData>> getUserPayments({
    required String buyerId,
    PaymentStatus? status,
    int limit = 50,
    DateTime? startDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_paymentsCollection)
          .where('buyerId', isEqualTo: buyerId);

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThan: startDate);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => PaymentData.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user payments: $e');
    }
  }

  /// Get payment method details (stub for integration with payment gateway)
  Future<PaymentMethodData?> getPaymentMethod(String paymentMethodId) async {
    try {
      final doc = await _firestore
          .collection('payment_methods')
          .doc(paymentMethodId)
          .get();

      if (!doc.exists) return null;

      return PaymentMethodData.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch payment method: $e');
    }
  }

  /// Log transaction
  Future<String> _logTransaction({
    required String paymentId,
    required String orderId,
    required double amount,
    required String status,
    String? gatewayTransactionId,
    String? authorizationCode,
    String? refundId,
    String? notes,
  }) async {
    try {
      final transactionId = _uuid.v4();

      final transaction = {
        'transactionId': transactionId,
        'paymentId': paymentId,
        'orderId': orderId,
        'amount': amount,
        'status': status,
        'gatewayTransactionId': gatewayTransactionId,
        'authorizationCode': authorizationCode,
        'refundId': refundId,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_paymentsCollection)
          .doc(paymentId)
          .collection(_transactionsCollection)
          .doc(transactionId)
          .set(transaction);

      return transactionId;
    } catch (e) {
      throw Exception('Failed to log transaction: $e');
    }
  }
}

/// Payment result model
class PaymentResult {
  final String paymentId;
  final PaymentStatus status;
  final String transactionId;
  final String message;

  PaymentResult({
    required this.paymentId,
    required this.status,
    required this.transactionId,
    required this.message,
  });
}

/// Refund result model
class RefundResult {
  final String refundId;
  final String paymentId;
  final double refundAmount;
  final PaymentStatus status;
  final String message;

  RefundResult({
    required this.refundId,
    required this.paymentId,
    required this.refundAmount,
    required this.status,
    required this.message,
  });
}

/// Payment data model
class PaymentData {
  final String paymentId;
  final String orderId;
  final String buyerId;
  final double amount;
  final String method;
  final String paymentMethodId;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? processedAt;
  final DateTime? refundedAt;
  final double? refundAmount;
  final String? invoiceNumber;
  final String? transactionId;
  final String? refundId;
  final String? notes;

  PaymentData({
    required this.paymentId,
    required this.orderId,
    required this.buyerId,
    required this.amount,
    required this.method,
    required this.paymentMethodId,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
    this.refundedAt,
    this.refundAmount,
    this.invoiceNumber,
    this.transactionId,
    this.refundId,
    this.notes,
  });

  factory PaymentData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PaymentData(
      paymentId: data['paymentId'] as String,
      orderId: data['orderId'] as String,
      buyerId: data['buyerId'] as String,
      amount: (data['amount'] as num).toDouble(),
      method: data['method'] as String,
      paymentMethodId: data['paymentMethodId'] as String,
      currency: data['currency'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      refundedAt: data['refundedAt'] != null
          ? (data['refundedAt'] as Timestamp).toDate()
          : null,
      refundAmount: data['refundAmount'] != null
          ? (data['refundAmount'] as num).toDouble()
          : null,
      invoiceNumber: data['invoiceNumber'] as String?,
      transactionId: data['transactionId'] as String?,
      refundId: data['refundId'] as String?,
      notes: data['notes'] as String?,
    );
  }
}

/// Payment method data model
class PaymentMethodData {
  final String id;
  final String buyerId;
  final String type; // creditCard, debitCard, bankTransfer, mobileWallet
  final String lastFour;
  final String holderName;
  final String expiryMonth;
  final String expiryYear;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethodData({
    required this.id,
    required this.buyerId,
    required this.type,
    required this.lastFour,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
    required this.createdAt,
  });

  factory PaymentMethodData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PaymentMethodData(
      id: doc.id,
      buyerId: data['buyerId'] as String,
      type: data['type'] as String,
      lastFour: data['lastFour'] as String,
      holderName: data['holderName'] as String,
      expiryMonth: data['expiryMonth'] as String,
      expiryYear: data['expiryYear'] as String,
      isDefault: data['isDefault'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
