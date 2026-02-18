import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment reconciliation service
class PaymentReconciliationService {
  final FirebaseFirestore _firestore;

  PaymentReconciliationService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Reconcile payments with orders
  Future<ReconciliationReport> reconcileDailyPayments({
    required DateTime date,
  }) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd =
          dayStart.add(Duration(days: 1)).subtract(Duration(seconds: 1));

      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('verified_at', isGreaterThanOrEqualTo: dayStart)
          .where('verified_at', isLessThanOrEqualTo: dayEnd)
          .get();

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('paid_at', isGreaterThanOrEqualTo: dayStart)
          .where('paid_at', isLessThanOrEqualTo: dayEnd)
          .get();

      final payments = paymentsSnapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc.data()))
          .toList();

      final orders = ordersSnapshot.docs
          .map((doc) => OrderRecord.fromFirestore(doc.data()))
          .toList();

      final reconciled = _matchPaymentsToOrders(payments, orders);
      final discrepancies = _findDiscrepancies(payments, orders);

      final totalPayments =
          payments.fold<double>(0, (sum, p) => sum + p.amount);
      final totalOrders =
          orders.fold<double>(0, (sum, o) => sum + o.totalAmount);

      final report = ReconciliationReport(
        date: date,
        totalPayments: totalPayments,
        totalOrders: totalOrders,
        matchedCount: reconciled.length,
        discrepancyCount: discrepancies.length,
        reconciled: reconciled,
        discrepancies: discrepancies,
      );

      // Store reconciliation report
      await _firestore.collection('reconciliation_reports').add({
        'date': date,
        'total_payments': totalPayments,
        'total_orders': totalOrders,
        'matched_count': reconciled.length,
        'discrepancy_count': discrepancies.length,
        'created_at': FieldValue.serverTimestamp(),
        'status': discrepancies.isEmpty ? 'balanced' : 'has_discrepancies',
      });

      return report;
    } catch (e) {
      throw ReconciliationException('Failed to reconcile payments: $e');
    }
  }

  /// Reconcile specific order with payment
  Future<bool> reconcileOrderPayment({
    required String orderId,
    required String paymentReference,
    required double amount,
  }) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw ReconciliationException('Order not found: $orderId');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final orderAmount = (orderData['total_amount'] as num).toDouble();

      // Verify amount matches (tolerance: ±0.01)
      if ((amount - orderAmount).abs() > 0.01) {
        // Amount mismatch - create discrepancy record
        await _firestore.collection('reconciliation_discrepancies').add({
          'order_id': orderId,
          'payment_reference': paymentReference,
          'expected_amount': orderAmount,
          'actual_amount': amount,
          'difference': amount - orderAmount,
          'type': 'amount_mismatch',
          'status': 'unresolved',
          'created_at': FieldValue.serverTimestamp(),
        });

        return false;
      }

      // Match found - update order
      await _firestore.collection('orders').doc(orderId).update({
        'payment_reference': paymentReference,
        'payment_verified': true,
        'verified_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw ReconciliationException('Failed to reconcile order payment: $e');
    }
  }

  /// Get monthly settlement report
  Future<SettlementReport> getMonthlySettlement({
    required int month,
    required int year,
  }) async {
    try {
      final monthStart = DateTime(year, month, 1);
      final monthEnd =
          DateTime(year, month + 1, 1).subtract(Duration(seconds: 1));

      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('verified_at', isGreaterThanOrEqualTo: monthStart)
          .where('verified_at', isLessThanOrEqualTo: monthEnd)
          .get();

      final payments = paymentsSnapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc.data()))
          .toList();

      // Group by provider
      final byProvider = <String, List<PaymentRecord>>{};
      for (final payment in payments) {
        byProvider.putIfAbsent(payment.provider, () => []).add(payment);
      }

      final providerSummaries = <ProviderSummary>[];
      for (final entry in byProvider.entries) {
        final providerPayments = entry.value;
        final total =
            providerPayments.fold<double>(0, (sum, p) => sum + p.amount);
        final count = providerPayments.length;
        final fees = _calculateProviderFees(entry.key, total);
        final netAmount = total - fees;

        providerSummaries.add(
          ProviderSummary(
            provider: entry.key,
            totalAmount: total,
            paymentCount: count,
            fees: fees,
            netAmount: netAmount,
          ),
        );
      }

      final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
      final totalFees =
          providerSummaries.fold<double>(0, (sum, s) => sum + s.fees);

      final report = SettlementReport(
        month: month,
        year: year,
        totalAmount: totalAmount,
        totalPayments: payments.length,
        totalFees: totalFees,
        netAmount: totalAmount - totalFees,
        providerSummaries: providerSummaries,
      );

      // Store settlement report
      await _firestore.collection('settlement_reports').add({
        'month': month,
        'year': year,
        'total_amount': totalAmount,
        'total_payments': payments.length,
        'total_fees': totalFees,
        'net_amount': totalAmount - totalFees,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'generated',
      });

      return report;
    } catch (e) {
      throw ReconciliationException('Failed to get settlement report: $e');
    }
  }

  /// Get reconciliation discrepancies
  Future<List<ReconciliationDiscrepancy>> getDiscrepancies({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = _firestore.collection('reconciliation_discrepancies');

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (fromDate != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: fromDate);
      }

      if (toDate != null) {
        query = query.where('created_at', isLessThanOrEqualTo: toDate);
      }

      final snapshot =
          await query.orderBy('created_at', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ReconciliationDiscrepancy(
          id: doc.id,
          orderId: data['order_id'],
          paymentReference: data['payment_reference'],
          expectedAmount: (data['expected_amount'] as num).toDouble(),
          actualAmount: (data['actual_amount'] as num).toDouble(),
          difference: (data['difference'] as num).toDouble(),
          type: data['type'],
          status: data['status'],
          createdAt: (data['created_at'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      throw ReconciliationException('Failed to get discrepancies: $e');
    }
  }

  /// Resolve discrepancy
  Future<void> resolveDiscrepancy({
    required String discrepancyId,
    required String resolutionNote,
    required String action, // 'adjust_order', 'refund', 'manual_approval'
  }) async {
    try {
      await _firestore
          .collection('reconciliation_discrepancies')
          .doc(discrepancyId)
          .update({
        'status': 'resolved',
        'resolution_action': action,
        'resolution_note': resolutionNote,
        'resolved_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ReconciliationException('Failed to resolve discrepancy: $e');
    }
  }

  /// Generate reconciliation audit trail
  Future<AuditTrail> getAuditTrail(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw ReconciliationException('Order not found: $orderId');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;

      final paymentSnapshot = await _firestore
          .collection('payments')
          .where('order_id', isEqualTo: orderId)
          .get();

      final events = <AuditEvent>[];

      // Order created
      events.add(AuditEvent(
        timestamp: (orderData['created_at'] as Timestamp).toDate(),
        action: 'Order Created',
        details: 'Order created with amount ${orderData['total_amount']}',
      ));

      // Payment events
      for (final paymentDoc in paymentSnapshot.docs) {
        final paymentData = paymentDoc.data();
        if (paymentData.containsKey('verified_at')) {
          events.add(AuditEvent(
            timestamp: (paymentData['verified_at'] as Timestamp).toDate(),
            action: 'Payment Verified',
            details: 'Payment ${paymentData['reference']} verified',
          ));
        }
      }

      // Reconciliation
      if (orderData.containsKey('verified_at')) {
        events.add(AuditEvent(
          timestamp: (orderData['verified_at'] as Timestamp).toDate(),
          action: 'Reconciled',
          details: 'Order reconciled with payment',
        ));
      }

      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return AuditTrail(orderId: orderId, events: events);
    } catch (e) {
      throw ReconciliationException('Failed to get audit trail: $e');
    }
  }

  double _calculateProviderFees(String provider, double amount) {
    // Provider fee structure
    final feePercentages = {
      'paystack': 0.015, // 1.5%
      'flutterwave': 0.014, // 1.4%
      'stripe': 0.029, // 2.9%
      'bank_transfer': 0.005, // 0.5%
    };

    final percentage = feePercentages[provider.toLowerCase()] ?? 0.02;
    return amount * percentage;
  }

  List<ReconciledPayment> _matchPaymentsToOrders(
    List<PaymentRecord> payments,
    List<OrderRecord> orders,
  ) {
    final reconciled = <ReconciledPayment>[];

    for (final payment in payments) {
      final matchingOrder = orders.firstWhere(
        (order) =>
            order.customerId == payment.customerId &&
            (payment.amount - order.totalAmount).abs() < 0.01,
        orElse: () => OrderRecord.empty(),
      );

      if (matchingOrder.id.isNotEmpty) {
        reconciled.add(ReconciledPayment(
          payment: payment,
          order: matchingOrder,
        ));
      }
    }

    return reconciled;
  }

  List<ReconciliationDiscrepancy> _findDiscrepancies(
    List<PaymentRecord> payments,
    List<OrderRecord> orders,
  ) {
    final discrepancies = <ReconciliationDiscrepancy>[];
    final reconciled = _matchPaymentsToOrders(payments, orders);
    final reconciledPaymentIds = reconciled.map((r) => r.payment.id).toSet();

    for (final payment in payments) {
      if (!reconciledPaymentIds.contains(payment.id)) {
        discrepancies.add(ReconciliationDiscrepancy(
          id: '',
          orderId: '',
          paymentReference: payment.reference,
          expectedAmount: 0,
          actualAmount: payment.amount,
          difference: payment.amount,
          type: 'unmatched_payment',
          status: 'unresolved',
          createdAt: DateTime.now(),
        ));
      }
    }

    return discrepancies;
  }
}

/// Payment record
class PaymentRecord {
  final String id;
  final String customerId;
  final double amount;
  final String provider;
  final String reference;
  final DateTime verifiedAt;

  PaymentRecord({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.provider,
    required this.reference,
    required this.verifiedAt,
  });

  factory PaymentRecord.fromFirestore(Map<String, dynamic> data) {
    return PaymentRecord(
      id: data['id'] ?? '',
      customerId: data['customer_id'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      provider: data['provider'] ?? '',
      reference: data['reference'] ?? '',
      verifiedAt: (data['verified_at'] as Timestamp).toDate(),
    );
  }
}

/// Order record
class OrderRecord {
  final String id;
  final String customerId;
  final double totalAmount;

  OrderRecord({
    required this.id,
    required this.customerId,
    required this.totalAmount,
  });

  factory OrderRecord.empty() {
    return OrderRecord(id: '', customerId: '', totalAmount: 0);
  }

  factory OrderRecord.fromFirestore(Map<String, dynamic> data) {
    return OrderRecord(
      id: data['id'] ?? '',
      customerId: data['customer_id'] ?? '',
      totalAmount: (data['total_amount'] as num).toDouble(),
    );
  }
}

/// Reconciliation report
class ReconciliationReport {
  final DateTime date;
  final double totalPayments;
  final double totalOrders;
  final int matchedCount;
  final int discrepancyCount;
  final List<ReconciledPayment> reconciled;
  final List<ReconciliationDiscrepancy> discrepancies;

  ReconciliationReport({
    required this.date,
    required this.totalPayments,
    required this.totalOrders,
    required this.matchedCount,
    required this.discrepancyCount,
    required this.reconciled,
    required this.discrepancies,
  });

  bool get isBalanced => discrepancyCount == 0;
}

/// Reconciled payment
class ReconciledPayment {
  final PaymentRecord payment;
  final OrderRecord order;

  ReconciledPayment({
    required this.payment,
    required this.order,
  });
}

/// Settlement report
class SettlementReport {
  final int month;
  final int year;
  final double totalAmount;
  final int totalPayments;
  final double totalFees;
  final double netAmount;
  final List<ProviderSummary> providerSummaries;

  SettlementReport({
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.totalPayments,
    required this.totalFees,
    required this.netAmount,
    required this.providerSummaries,
  });
}

/// Provider settlement summary
class ProviderSummary {
  final String provider;
  final double totalAmount;
  final int paymentCount;
  final double fees;
  final double netAmount;

  ProviderSummary({
    required this.provider,
    required this.totalAmount,
    required this.paymentCount,
    required this.fees,
    required this.netAmount,
  });
}

/// Reconciliation discrepancy
class ReconciliationDiscrepancy {
  final String id;
  final String orderId;
  final String paymentReference;
  final double expectedAmount;
  final double actualAmount;
  final double difference;
  final String type;
  final String status;
  final DateTime createdAt;

  ReconciliationDiscrepancy({
    required this.id,
    required this.orderId,
    required this.paymentReference,
    required this.expectedAmount,
    required this.actualAmount,
    required this.difference,
    required this.type,
    required this.status,
    required this.createdAt,
  });
}

/// Audit trail
class AuditTrail {
  final String orderId;
  final List<AuditEvent> events;

  AuditTrail({required this.orderId, required this.events});
}

/// Audit event
class AuditEvent {
  final DateTime timestamp;
  final String action;
  final String details;

  AuditEvent({
    required this.timestamp,
    required this.action,
    required this.details,
  });
}

class ReconciliationException implements Exception {
  final String message;
  ReconciliationException(this.message);

  @override
  String toString() => 'ReconciliationException: $message';
}
