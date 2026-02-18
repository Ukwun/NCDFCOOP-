import 'package:cloud_firestore/cloud_firestore.dart';

/// Refund processor service
class RefundProcessorService {
  final FirebaseFirestore _firestore;

  RefundProcessorService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Initiate refund request
  Future<Refund> initiateRefundRequest({
    required String orderId,
    required String customerId,
    required RefundType type,
    required double amount,
    required String reason,
    required String? notes,
  }) async {
    try {
      // Validate order exists
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw RefundException('Order not found: $orderId');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final orderAmount = (orderData['total_amount'] as num).toDouble();

      // Validate refund amount
      if (amount > orderAmount) {
        throw RefundException(
            'Refund amount exceeds order total: $amount > $orderAmount');
      }

      final refundId = _firestore.collection('refunds').doc().id;
      final refund = Refund(
        id: refundId,
        orderId: orderId,
        customerId: customerId,
        amount: amount,
        type: type,
        reason: reason,
        notes: notes,
        status: 'requested',
        requestedAt: DateTime.now(),
      );

      // Store refund request
      await _firestore.collection('refunds').doc(refundId).set({
        'id': refundId,
        'order_id': orderId,
        'customer_id': customerId,
        'amount': amount,
        'type': type.toString().split('.').last,
        'reason': reason,
        'notes': notes,
        'status': 'requested',
        'requested_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      // Create audit entry
      await _addRefundAuditEntry(refundId, 'Refund requested', reason);

      return refund;
    } catch (e) {
      throw RefundException('Failed to initiate refund: $e');
    }
  }

  /// Approve refund request
  Future<void> approveRefund({
    required String refundId,
    required String approvedBy,
    required String? approvalNotes,
  }) async {
    try {
      final refundDoc =
          await _firestore.collection('refunds').doc(refundId).get();

      if (!refundDoc.exists) {
        throw RefundException('Refund not found: $refundId');
      }

      final refundData = refundDoc.data() as Map<String, dynamic>;

      if (refundData['status'] != 'requested') {
        throw RefundException(
            'Cannot approve refund with status: ${refundData['status']}');
      }

      await _firestore.collection('refunds').doc(refundId).update({
        'status': 'approved',
        'approved_by': approvedBy,
        'approval_notes': approvalNotes,
        'approved_at': FieldValue.serverTimestamp(),
      });

      // Create audit entry
      await _addRefundAuditEntry(
          refundId, 'Refund approved', approvalNotes ?? 'Approved');
    } catch (e) {
      throw RefundException('Failed to approve refund: $e');
    }
  }

  /// Reject refund request
  Future<void> rejectRefund({
    required String refundId,
    required String rejectionReason,
    required String rejectedBy,
  }) async {
    try {
      final refundDoc =
          await _firestore.collection('refunds').doc(refundId).get();

      if (!refundDoc.exists) {
        throw RefundException('Refund not found: $refundId');
      }

      final refundData = refundDoc.data() as Map<String, dynamic>;

      if (refundData['status'] != 'requested') {
        throw RefundException(
            'Cannot reject refund with status: ${refundData['status']}');
      }

      await _firestore.collection('refunds').doc(refundId).update({
        'status': 'rejected',
        'rejection_reason': rejectionReason,
        'rejected_by': rejectedBy,
        'rejected_at': FieldValue.serverTimestamp(),
      });

      // Create audit entry
      await _addRefundAuditEntry(refundId, 'Refund rejected', rejectionReason);
    } catch (e) {
      throw RefundException('Failed to reject refund: $e');
    }
  }

  /// Process approved refund (initiate reverse transaction)
  Future<void> processApprovedRefund({
    required String refundId,
    required String paymentReference,
    required String paymentMethod,
  }) async {
    try {
      final refundDoc =
          await _firestore.collection('refunds').doc(refundId).get();

      if (!refundDoc.exists) {
        throw RefundException('Refund not found: $refundId');
      }

      final refundData = refundDoc.data() as Map<String, dynamic>;

      if (refundData['status'] != 'approved') {
        throw RefundException('Refund must be approved before processing');
      }

      final refundAmount = (refundData['amount'] as num).toDouble();
      final orderId = refundData['order_id'];

      // Process reverse based on payment method
      String reversalStatus = 'pending';
      String reversalReference = _generateReversalReference();

      switch (paymentMethod.toLowerCase()) {
        case 'card':
          reversalStatus =
              await _processCardReversal(refundAmount, paymentReference);
          break;
        case 'bank_transfer':
          reversalStatus = await _processBankTransferReversal(refundAmount);
          break;
        case 'ussd':
        case 'mobile_money':
          reversalStatus =
              await _processMobileMoneyReversal(refundAmount, paymentReference);
          break;
        default:
          throw RefundException('Unsupported payment method: $paymentMethod');
      }

      // Update refund status
      await _firestore.collection('refunds').doc(refundId).update({
        'status': 'processing',
        'reversal_reference': reversalReference,
        'reversal_status': reversalStatus,
        'processing_started_at': FieldValue.serverTimestamp(),
      });

      // Update order refund status
      await _firestore.collection('orders').doc(orderId).update({
        'refund_status': 'processing',
        'refund_amount': refundAmount,
        'refund_reference': refundId,
      });

      // Create audit entry
      await _addRefundAuditEntry(refundId, 'Refund processing initiated',
          'Method: $paymentMethod, Reference: $reversalReference');
    } catch (e) {
      throw RefundException('Failed to process refund: $e');
    }
  }

  /// Complete processed refund
  Future<void> completeRefund({
    required String refundId,
    required String completionNote,
  }) async {
    try {
      final refundDoc =
          await _firestore.collection('refunds').doc(refundId).get();

      if (!refundDoc.exists) {
        throw RefundException('Refund not found: $refundId');
      }

      final refundData = refundDoc.data() as Map<String, dynamic>;

      if (refundData['status'] != 'processing') {
        throw RefundException('Only processing refunds can be completed');
      }

      await _firestore.collection('refunds').doc(refundId).update({
        'status': 'completed',
        'completion_note': completionNote,
        'completed_at': FieldValue.serverTimestamp(),
      });

      // Update order
      final orderId = refundData['order_id'];
      await _firestore.collection('orders').doc(orderId).update({
        'refund_status': 'completed',
        'refund_completed_at': FieldValue.serverTimestamp(),
      });

      // Create audit entry
      await _addRefundAuditEntry(refundId, 'Refund completed', completionNote);
    } catch (e) {
      throw RefundException('Failed to complete refund: $e');
    }
  }

  /// Get refund details
  Future<Refund> getRefund(String refundId) async {
    try {
      final doc = await _firestore.collection('refunds').doc(refundId).get();

      if (!doc.exists) {
        throw RefundException('Refund not found: $refundId');
      }

      final data = doc.data() as Map<String, dynamic>;

      return Refund(
        id: refundId,
        orderId: data['order_id'],
        customerId: data['customer_id'],
        amount: (data['amount'] as num).toDouble(),
        type: RefundType.values
            .firstWhere((e) => e.toString().split('.').last == data['type']),
        reason: data['reason'],
        notes: data['notes'],
        status: data['status'],
        requestedAt:
            (data['requested_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        approvedAt: (data['approved_at'] as Timestamp?)?.toDate(),
        rejectedAt: (data['rejected_at'] as Timestamp?)?.toDate(),
        completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      throw RefundException('Failed to get refund: $e');
    }
  }

  /// Get refunds for order
  Future<List<Refund>> getOrderRefunds(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('refunds')
          .where('order_id', isEqualTo: orderId)
          .orderBy('requested_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Refund(
          id: doc.id,
          orderId: data['order_id'],
          customerId: data['customer_id'],
          amount: (data['amount'] as num).toDouble(),
          type: RefundType.values
              .firstWhere((e) => e.toString().split('.').last == data['type']),
          reason: data['reason'],
          notes: data['notes'],
          status: data['status'],
          requestedAt:
              (data['requested_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          approvedAt: (data['approved_at'] as Timestamp?)?.toDate(),
          rejectedAt: (data['rejected_at'] as Timestamp?)?.toDate(),
          completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      throw RefundException('Failed to get order refunds: $e');
    }
  }

  /// Get refunds for customer
  Future<List<Refund>> getCustomerRefunds(
    String customerId, {
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('refunds')
          .where('customer_id', isEqualTo: customerId)
          .orderBy('requested_at', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Refund(
          id: doc.id,
          orderId: data['order_id'],
          customerId: data['customer_id'],
          amount: (data['amount'] as num).toDouble(),
          type: RefundType.values
              .firstWhere((e) => e.toString().split('.').last == data['type']),
          reason: data['reason'],
          notes: data['notes'],
          status: data['status'],
          requestedAt:
              (data['requested_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          approvedAt: (data['approved_at'] as Timestamp?)?.toDate(),
          rejectedAt: (data['rejected_at'] as Timestamp?)?.toDate(),
          completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      throw RefundException('Failed to get customer refunds: $e');
    }
  }

  /// Get refund audit trail
  Future<List<RefundAuditEntry>> getRefundAuditTrail(String refundId) async {
    try {
      final snapshot = await _firestore
          .collection('refunds')
          .doc(refundId)
          .collection('audit')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RefundAuditEntry(
          action: data['action'],
          details: data['details'],
          createdAt: (data['created_at'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      throw RefundException('Failed to get refund audit trail: $e');
    }
  }

  // Private helper methods

  Future<void> _addRefundAuditEntry(
    String refundId,
    String action,
    String details,
  ) async {
    await _firestore
        .collection('refunds')
        .doc(refundId)
        .collection('audit')
        .add({
      'action': action,
      'details': details,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _processCardReversal(
      double amount, String paymentReference) async {
    // TODO: Implement card reversal via Stripe/Flutterwave
    // For now, return pending status
    return 'pending';
  }

  Future<String> _processBankTransferReversal(double amount) async {
    // TODO: Implement bank transfer reversal
    // This requires reverse transfer to customer's bank account
    return 'pending';
  }

  Future<String> _processMobileMoneyReversal(
    double amount,
    String paymentReference,
  ) async {
    // TODO: Implement mobile money reversal
    return 'pending';
  }

  String _generateReversalReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'REV-$timestamp';
  }
}

/// Refund type enum
enum RefundType {
  full,
  partial,
}

/// Refund model
class Refund {
  final String id;
  final String orderId;
  final String customerId;
  final double amount;
  final RefundType type;
  final String reason;
  final String? notes;
  final String status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? completedAt;

  Refund({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.reason,
    this.notes,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.rejectedAt,
    this.completedAt,
  });

  bool get isPending => status == 'requested';
  bool get isApproved => status == 'approved';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';

  Duration? get processingTime {
    if (completedAt == null) return null;
    return completedAt!.difference(requestedAt);
  }
}

/// Refund audit entry
class RefundAuditEntry {
  final String action;
  final String details;
  final DateTime createdAt;

  RefundAuditEntry({
    required this.action,
    required this.details,
    required this.createdAt,
  });
}

class RefundException implements Exception {
  final String message;
  RefundException(this.message);

  @override
  String toString() => 'RefundException: $message';
}
