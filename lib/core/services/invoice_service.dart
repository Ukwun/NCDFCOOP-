import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Invoice service for generating PDF invoices
/// Integrates with pdf package for generation and printing package for display
class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();

  factory InvoiceService() => _instance;

  InvoiceService._internal();

  /// Generate invoice data for retail order
  Future<Map<String, dynamic>> generateRetailInvoice({
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String customerAddress,
    required List<OrderLineItem> items,
    required double subtotal,
    required double taxAmount,
    required double shippingCost,
    required double totalAmount,
    required String paymentMethod,
    required DateTime orderDate,
  }) async {
    try {
      return {
        'invoiceNumber': 'INV-RETAIL-${orderId.toUpperCase()}',
        'invoiceType': 'Retail Order Invoice',
        'orderDate': DateFormat('MMM dd, yyyy').format(orderDate),
        'dueDate': DateFormat('MMM dd, yyyy').format(orderDate.add(Duration(days: 30))),
        'billTo': {
          'name': customerName,
          'email': customerEmail,
          'phone': customerPhone,
          'address': customerAddress,
        },
        'lineItems': items.map((item) {
          return {
            'description': item.productName,
            'sku': item.sku,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'total': item.quantity * item.unitPrice,
          };
        }).toList(),
        'summary': {
          'subtotal': subtotal,
          'tax': taxAmount,
          'shipping': shippingCost,
          'total': totalAmount,
        },
        'paymentMethod': paymentMethod,
        'terms': 'Thank you for your purchase!',
        'notes': 'Please keep this invoice for your records. For support, contact support@coopcommerce.ng',
      };
    } catch (e) {
      print('Failed to generate retail invoice: $e');
      return {};
    }
  }

  /// Generate invoice data for institutional/PO order
  Future<Map<String, dynamic>> generateInstitutionalInvoice({
    required String poId,
    required String buyerName,
    required String buyerEmail,
    required String buyerPhone,
    required String buyerAddress,
    required String institutionName,
    required List<OrderLineItem> items,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double totalAmount,
    required String paymentTerms,
    required DateTime poDate,
    required DateTime dueDate,
  }) async {
    try {
      return {
        'invoiceNumber': 'INV-PO-${poId.toUpperCase()}',
        'invoiceType': 'Purchase Order Invoice',
        'poNumber': poId,
        'orderDate': DateFormat('MMM dd, yyyy').format(poDate),
        'dueDate': DateFormat('MMM dd, yyyy').format(dueDate),
        'billTo': {
          'institution': institutionName,
          'contactName': buyerName,
          'email': buyerEmail,
          'phone': buyerPhone,
          'address': buyerAddress,
        },
        'lineItems': items.map((item) {
          return {
            'description': item.productName,
            'sku': item.sku,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'total': item.quantity * item.unitPrice,
          };
        }).toList(),
        'summary': {
          'subtotal': subtotal,
          'discount': discountAmount,
          'tax': taxAmount,
          'total': totalAmount,
        },
        'paymentTerms': paymentTerms,
        'notes':
            'This is an invoice for your purchase order. Payment terms: $paymentTerms. For inquiries, contact po-support@coopcommerce.ng',
      };
    } catch (e) {
      print('Failed to generate institutional invoice: $e');
      return {};
    }
  }

  /// Generate invoice data for wholesale order
  Future<Map<String, dynamic>> generateWholesaleInvoice({
    required String orderId,
    required String buyerName,
    required String buyerEmail,
    required String buyerPhone,
    required String buyerAddress,
    required List<OrderLineItem> items,
    required double subtotal,
    required double wholesaleDiscount,
    required double taxAmount,
    required double totalAmount,
    required DateTime orderDate,
  }) async {
    try {
      return {
        'invoiceNumber': 'INV-WHOLESALE-${orderId.toUpperCase()}',
        'invoiceType': 'Wholesale Order Invoice',
        'orderDate': DateFormat('MMM dd, yyyy').format(orderDate),
        'dueDate': DateFormat('MMM dd, yyyy').format(orderDate.add(Duration(days: 15))),
        'billTo': {
          'name': buyerName,
          'email': buyerEmail,
          'phone': buyerPhone,
          'address': buyerAddress,
        },
        'lineItems': items.map((item) {
          return {
            'description': item.productName,
            'sku': item.sku,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'total': item.quantity * item.unitPrice,
          };
        }).toList(),
        'summary': {
          'subtotal': subtotal,
          'wholesaleDiscount': wholesaleDiscount,
          'tax': taxAmount,
          'total': totalAmount,
        },
        'termsOfPayment': 'Net 15',
        'notes':
            'Wholesale pricing applied. Thank you for your bulk purchase. For support, contact wholesale@coopcommerce.ng',
      };
    } catch (e) {
      print('Failed to generate wholesale invoice: $e');
      return {};
    }
  }

  /// Convert invoice data to PDF bytes (requires pdf package)
  /// This is template - actual PDF generation in next phase
  Future<Uint8List> generatePDF({
    required Map<String, dynamic> invoiceData,
  }) async {
    try {
      // In v1.1, this will use pdf package to generate actual PDF
      // For now, return empty bytes (UI will show preview)
      // Actual implementation:
      // final pdf = pw.Document();
      // pdf.addPage(...);
      // return pdf.save();

      final dummyPdf = Uint8List.fromList([
        0x25, 0x50, 0x44, 0x46, // PDF header
        0x2D, 0x31, 0x2E, 0x34, // -1.4
      ]);

      return dummyPdf;
    } catch (e) {
      print('Failed to generate PDF: $e');
      return Uint8List(0);
    }
  }

  /// Generate HTML representation of invoice (for web/preview)
  Future<String> generateInvoiceHTML({
    required Map<String, dynamic> invoiceData,
  }) async {
    try {
      final buffer = StringBuffer();
      buffer.write('''
<!DOCTYPE html>
<html>
<head>
  <title>${invoiceData['invoiceNumber']}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    .header { text-align: center; margin-bottom: 30px; }
    .invoice-info { margin-bottom: 20px; }
    .bill-to { margin-bottom: 20px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background-color: #f5f5f5; }
    .summary { float: right; width: 300px; }
    .summary-row { display: flex; justify-content: space-between; padding: 5px 0; }
    .total { font-weight: bold; font-size: 18px; border-top: 2px solid #333; }
  </style>
</head>
<body>
  <div class="header">
    <h1>INVOICE</h1>
    <p><strong>${invoiceData['invoiceNumber']}</strong></p>
    <p>${invoiceData['invoiceType']}</p>
  </div>

  <div class="invoice-info">
    <p><strong>Date:</strong> ${invoiceData['orderDate']}</p>
    <p><strong>Due Date:</strong> ${invoiceData['dueDate']}</p>
  </div>

  <div class="bill-to">
    <h3>Bill To:</h3>
    <p><strong>${invoiceData['billTo']['name']}</strong></p>
    <p>${invoiceData['billTo']['address']}</p>
    <p>Email: ${invoiceData['billTo']['email']}</p>
    <p>Phone: ${invoiceData['billTo']['phone']}</p>
  </div>

  <table>
    <thead>
      <tr>
        <th>Description</th>
        <th>Quantity</th>
        <th>Unit Price</th>
        <th>Total</th>
      </tr>
    </thead>
    <tbody>
''');

      for (var item in invoiceData['lineItems']) {
        buffer.write('''
      <tr>
        <td>${item['description']}</td>
        <td>${item['quantity']}</td>
        <td>₦${item['unitPrice'].toStringAsFixed(2)}</td>
        <td>₦${item['total'].toStringAsFixed(2)}</td>
      </tr>
''');
      }

      buffer.write('''
    </tbody>
  </table>

  <div class="summary">
    <div class="summary-row">
      <span>Subtotal:</span>
      <span>₦${invoiceData['summary']['subtotal'].toStringAsFixed(2)}</span>
    </div>
''');

      if (invoiceData['summary'].containsKey('discount')) {
        buffer.write('''
    <div class="summary-row">
      <span>Discount:</span>
      <span>-₦${invoiceData['summary']['discount'].toStringAsFixed(2)}</span>
    </div>
''');
      }

      if (invoiceData['summary'].containsKey('wholesaleDiscount')) {
        buffer.write('''
    <div class="summary-row">
      <span>Wholesale Discount:</span>
      <span>-₦${invoiceData['summary']['wholesaleDiscount'].toStringAsFixed(2)}</span>
    </div>
''');
      }

      buffer.write('''
    <div class="summary-row">
      <span>Tax:</span>
      <span>₦${invoiceData['summary']['tax'].toStringAsFixed(2)}</span>
    </div>
    <div class="summary-row total">
      <span>Total:</span>
      <span>₦${invoiceData['summary']['total'].toStringAsFixed(2)}</span>
    </div>
  </div>

  <div style="clear: both; margin-top: 50px; border-top: 1px solid #ddd; padding-top: 20px;">
    <p><strong>Payment Method:</strong> ${invoiceData['paymentMethod'] ?? 'Not specified'}</p>
    <p><strong>Notes:</strong> ${invoiceData['notes'] ?? ''}</p>
    <p style="margin-top: 30px; font-size: 12px; color: #666;">
      Thank you for your business!
    </p>
  </div>
</body>
</html>
''');

      return buffer.toString();
    } catch (e) {
      print('Failed to generate invoice HTML: $e');
      return '';
    }
  }

  /// Get invoice by order ID (mock data)
  Future<Map<String, dynamic>?> getInvoiceByOrderId(String orderId) async {
    try {
      // In production, fetch from Firestore
      return {
        'invoiceNumber': 'INV-RETAIL-$orderId',
        'invoiceType': 'Retail Order Invoice',
        'orderDate': DateFormat('MMM dd, yyyy').format(DateTime.now()),
        'dueDate': DateFormat('MMM dd, yyyy').format(DateTime.now().add(Duration(days: 30))),
        'billTo': {
          'name': 'John Doe',
          'email': 'john@example.com',
          'phone': '+234 810 1234 567',
          'address': '123 Main Street, Lagos, Nigeria',
        },
        'lineItems': [
          {
            'description': 'Parboiled Rice 50kg',
            'sku': 'RICE-50KG',
            'quantity': 2,
            'unitPrice': 18000.0,
            'total': 36000.0,
          },
        ],
        'summary': {
          'subtotal': 36000.0,
          'tax': 5400.0,
          'shipping': 2000.0,
          'total': 43400.0,
        },
        'paymentMethod': 'Card',
      };
    } catch (e) {
      print('Failed to get invoice: $e');
      return null;
    }
  }
}

/// Data class for order line items
class OrderLineItem {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;

  OrderLineItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
  });
}

/// Riverpod provider for invoice service
final invoiceServiceProvider = Provider((ref) => InvoiceService());
