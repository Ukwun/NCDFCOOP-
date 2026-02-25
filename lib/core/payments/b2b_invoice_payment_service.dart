import 'package:cloud_firestore/cloud_firestore.dart';
import '../email/email_service.dart';

/// B2B Invoice payment service
class B2BInvoicePaymentService {
  final FirebaseFirestore _firestore;
  final EmailService _emailService;

  B2BInvoicePaymentService({
    required FirebaseFirestore firestore,
    EmailService? emailService,
  })  : _firestore = firestore,
        _emailService = emailService ?? createEmailService();

  /// Create invoice for order
  Future<Invoice> createInvoice({
    required String orderId,
    required String customerId,
    required double amount,
    required String currency,
    required List<InvoiceItem> items,
    required int dueDays,
    required String? notes,
  }) async {
    try {
      final invoiceId = _firestore.collection('invoices').doc().id;
      final now = DateTime.now();
      final dueDate = now.add(Duration(days: dueDays));

      final invoice = Invoice(
        id: invoiceId,
        orderId: orderId,
        customerId: customerId,
        amount: amount,
        currency: currency,
        items: items,
        status: 'draft',
        issuedAt: now,
        dueDate: dueDate,
        notes: notes,
        invoiceNumber: _generateInvoiceNumber(),
        taxAmount: _calculateTax(items),
        discountAmount: 0,
      );

      await _firestore.collection('invoices').doc(invoiceId).set({
        'id': invoice.id,
        'order_id': invoice.orderId,
        'customer_id': invoice.customerId,
        'invoice_number': invoice.invoiceNumber,
        'amount': invoice.amount,
        'currency': invoice.currency,
        'items': invoice.items
            .map((item) => {
                  'description': item.description,
                  'quantity': item.quantity,
                  'unit_price': item.unitPrice,
                  'total': item.total,
                })
            .toList(),
        'status': invoice.status,
        'issued_at': invoice.issuedAt,
        'due_date': invoice.dueDate,
        'tax_amount': invoice.taxAmount,
        'discount_amount': invoice.discountAmount,
        'notes': invoice.notes,
        'created_at': FieldValue.serverTimestamp(),
      });

      return invoice;
    } catch (e) {
      throw InvoiceException('Failed to create invoice: $e');
    }
  }

  /// Send invoice to customer
  Future<void> sendInvoice({
    required String invoiceId,
    required String customerEmail,
    required String? customerName,
  }) async {
    try {
      final invoiceDoc =
          await _firestore.collection('invoices').doc(invoiceId).get();

      if (!invoiceDoc.exists) {
        throw InvoiceException('Invoice not found: $invoiceId');
      }

      final data = invoiceDoc.data() as Map<String, dynamic>;
      final invoiceNumber = data['invoice_number'] as String;
      final amount = (data['amount'] as num).toDouble();
      final currency = data['currency'] as String? ?? 'NGN';
      final dueDate = (data['due_date'] as Timestamp).toDate();
      final notes = data['notes'] as String?;

      // Send invoice email
      final emailSent = await _emailService.sendInvoiceEmail(
        to: customerEmail,
        customerName: customerName ?? 'Valued Customer',
        invoiceNumber: invoiceNumber,
        amount: amount,
        currency: currency,
        dueDate: dueDate,
        notes: notes,
      );

      if (!emailSent) {
        throw InvoiceException(
            'Failed to send invoice email to $customerEmail');
      }

      // Mark as sent in database
      await _firestore.collection('invoices').doc(invoiceId).update({
        'sent_at': FieldValue.serverTimestamp(),
        'sent_to': customerEmail,
        'status': 'sent',
      });
    } catch (e) {
      throw InvoiceException('Failed to send invoice: $e');
    }
  }

  /// Record partial payment for invoice
  Future<void> recordPartialPayment({
    required String invoiceId,
    required double amount,
    required String paymentReference,
    required String paymentMethod,
  }) async {
    try {
      final invoiceDoc =
          await _firestore.collection('invoices').doc(invoiceId).get();

      if (!invoiceDoc.exists) {
        throw InvoiceException('Invoice not found: $invoiceId');
      }

      final data = invoiceDoc.data() as Map<String, dynamic>;
      final invoiceAmount = (data['amount'] as num).toDouble();
      final paidAmount = (data['paid_amount'] as num?)?.toDouble() ?? 0;
      final newPaidAmount = paidAmount + amount;

      String newStatus = 'partial';
      if ((newPaidAmount - invoiceAmount).abs() < 0.01) {
        newStatus = 'paid';
      }

      // Add payment record
      await _firestore
          .collection('invoices')
          .doc(invoiceId)
          .collection('payments')
          .add({
        'amount': amount,
        'reference': paymentReference,
        'method': paymentMethod,
        'paid_at': FieldValue.serverTimestamp(),
      });

      // Update invoice
      await _firestore.collection('invoices').doc(invoiceId).update({
        'paid_amount': newPaidAmount,
        'status': newStatus,
        'last_payment_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw InvoiceException('Failed to record payment: $e');
    }
  }

  /// Get invoice details
  Future<Invoice> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore.collection('invoices').doc(invoiceId).get();

      if (!doc.exists) {
        throw InvoiceException('Invoice not found: $invoiceId');
      }

      final data = doc.data() as Map<String, dynamic>;

      return Invoice(
        id: invoiceId,
        invoiceNumber: data['invoice_number'],
        orderId: data['order_id'],
        customerId: data['customer_id'],
        amount: (data['amount'] as num).toDouble(),
        currency: data['currency'] ?? 'NGN',
        status: data['status'],
        issuedAt: (data['issued_at'] as Timestamp).toDate(),
        dueDate: (data['due_date'] as Timestamp).toDate(),
        items: (data['items'] as List<dynamic>)
            .map((item) => InvoiceItem(
                  description: item['description'],
                  quantity: item['quantity'],
                  unitPrice: (item['unit_price'] as num).toDouble(),
                ))
            .toList(),
        taxAmount: (data['tax_amount'] as num?)?.toDouble() ?? 0,
        discountAmount: (data['discount_amount'] as num?)?.toDouble() ?? 0,
        notes: data['notes'],
        paidAmount: (data['paid_amount'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      throw InvoiceException('Failed to get invoice: $e');
    }
  }

  /// Get invoices for customer
  Future<List<Invoice>> getCustomerInvoices(
    String customerId, {
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('invoices')
          .where('customer_id', isEqualTo: customerId)
          .orderBy('issued_at', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) =>
              Invoice.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw InvoiceException('Failed to get customer invoices: $e');
    }
  }

  /// Generate payment link for invoice
  Future<String> generatePaymentLink(String invoiceId) async {
    try {
      final invoiceDoc =
          await _firestore.collection('invoices').doc(invoiceId).get();

      if (!invoiceDoc.exists) {
        throw InvoiceException('Invoice not found: $invoiceId');
      }

      final data = invoiceDoc.data() as Map<String, dynamic>;

      // Generate unique payment link
      final paymentLinkId = _firestore.collection('payment_links').doc().id;

      await _firestore.collection('payment_links').doc(paymentLinkId).set({
        'invoice_id': invoiceId,
        'amount': data['amount'],
        'currency': data['currency'],
        'customer_id': data['customer_id'],
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': DateTime.now().add(Duration(days: 30)),
      });

      return 'https://coop-commerce.com/pay/$paymentLinkId';
    } catch (e) {
      throw InvoiceException('Failed to generate payment link: $e');
    }
  }

  /// Set invoice reminder
  Future<void> setPaymentReminder({
    required String invoiceId,
    required int daysBefore,
  }) async {
    try {
      final invoiceDoc =
          await _firestore.collection('invoices').doc(invoiceId).get();

      if (!invoiceDoc.exists) {
        throw InvoiceException('Invoice not found: $invoiceId');
      }

      await _firestore.collection('invoice_reminders').add({
        'invoice_id': invoiceId,
        'days_before': daysBefore,
        'status': 'scheduled',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw InvoiceException('Failed to set reminder: $e');
    }
  }

  /// Generate invoice PDF
  Future<String> generateInvoicePDF(String invoiceId) async {
    try {
      final invoice = await getInvoice(invoiceId);

      // TODO: Implement PDF generation using pdf package
      // For now, return placeholder
      return 'Invoice PDF generated for ${invoice.invoiceNumber}';
    } catch (e) {
      throw InvoiceException('Failed to generate PDF: $e');
    }
  }

  /// Void invoice
  Future<void> voidInvoice({
    required String invoiceId,
    required String reason,
  }) async {
    try {
      final invoiceDoc =
          await _firestore.collection('invoices').doc(invoiceId).get();

      if (!invoiceDoc.exists) {
        throw InvoiceException('Invoice not found: $invoiceId');
      }

      await _firestore.collection('invoices').doc(invoiceId).update({
        'status': 'voided',
        'void_reason': reason,
        'voided_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw InvoiceException('Failed to void invoice: $e');
    }
  }

  /// Get invoice payment history
  Future<List<InvoicePayment>> getPaymentHistory(String invoiceId) async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .doc(invoiceId)
          .collection('payments')
          .orderBy('paid_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return InvoicePayment(
          reference: data['reference'],
          amount: (data['amount'] as num).toDouble(),
          method: data['method'],
          paidAt: (data['paid_at'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      throw InvoiceException('Failed to get payment history: $e');
    }
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final date =
        '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = DateTime.now().millisecond;
    return 'INV-$date-$random';
  }

  double _calculateTax(List<InvoiceItem> items) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    return subtotal * 0.075; // 7.5% VAT
  }
}

/// Invoice model
class Invoice {
  final String id;
  final String invoiceNumber;
  final String orderId;
  final String customerId;
  final double amount;
  final String currency;
  final List<InvoiceItem> items;
  final String status;
  final DateTime issuedAt;
  final DateTime dueDate;
  final double taxAmount;
  final double discountAmount;
  final String? notes;
  final double paidAmount;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.currency,
    required this.items,
    required this.status,
    required this.issuedAt,
    required this.dueDate,
    required this.taxAmount,
    required this.discountAmount,
    this.notes,
    this.paidAmount = 0,
  });

  factory Invoice.fromFirestore(Map<String, dynamic> data) {
    return Invoice(
      id: data['id'],
      invoiceNumber: data['invoice_number'],
      orderId: data['order_id'],
      customerId: data['customer_id'],
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] ?? 'NGN',
      items: (data['items'] as List<dynamic>)
          .map((item) => InvoiceItem(
                description: item['description'],
                quantity: item['quantity'],
                unitPrice: (item['unit_price'] as num).toDouble(),
              ))
          .toList(),
      status: data['status'],
      issuedAt: (data['issued_at'] as Timestamp).toDate(),
      dueDate: (data['due_date'] as Timestamp).toDate(),
      taxAmount: (data['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (data['discount_amount'] as num?)?.toDouble() ?? 0,
      notes: data['notes'],
      paidAmount: (data['paid_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  double get remainingAmount => (amount - paidAmount).clamp(0, amount);
  bool get isPaid => (remainingAmount) < 0.01;
  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isPaid;
}

/// Invoice item
class InvoiceItem {
  final String description;
  final int quantity;
  final double unitPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

/// Invoice payment record
class InvoicePayment {
  final String reference;
  final double amount;
  final String method;
  final DateTime paidAt;

  InvoicePayment({
    required this.reference,
    required this.amount,
    required this.method,
    required this.paidAt,
  });
}

class InvoiceException implements Exception {
  final String message;
  InvoiceException(this.message);

  @override
  String toString() => 'InvoiceException: $message';
}
