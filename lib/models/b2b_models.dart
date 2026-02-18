import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Purchase Order
class PurchaseOrder {
  final String id;
  final String institutionId;
  final String institutionName;
  final String
      status; // draft, pending, approved, rejected, processing, shipped, delivered
  final List<PurchaseOrderLineItem> lineItems;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String paymentTerms; // e.g., "Net 30", "COD"
  final double creditLimit;
  final double creditUsed;
  final DateTime createdDate;
  final DateTime expectedDeliveryDate;
  final String deliveryAddress;
  final String specialInstructions;
  final String createdBy; // User ID
  final List<String> approvalChain; // User IDs in approval order
  final Map<String, dynamic>
      approvalStatus; // {userId: {approved: bool, timestamp: Timestamp}}
  final String? notes;

  PurchaseOrder({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.status,
    required this.lineItems,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentTerms,
    required this.creditLimit,
    required this.creditUsed,
    required this.createdDate,
    required this.expectedDeliveryDate,
    required this.deliveryAddress,
    required this.specialInstructions,
    required this.createdBy,
    required this.approvalChain,
    required this.approvalStatus,
    this.notes,
  });

  factory PurchaseOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseOrder(
      id: doc.id,
      institutionId: data['institutionId'] ?? '',
      institutionName: data['institutionName'] ?? '',
      status: data['status'] ?? 'draft',
      lineItems: (data['lineItems'] as List?)
              ?.map((item) => PurchaseOrderLineItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentTerms: data['paymentTerms'] ?? 'Net 30',
      creditLimit: (data['creditLimit'] ?? 0).toDouble(),
      creditUsed: (data['creditUsed'] ?? 0).toDouble(),
      createdDate:
          (data['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedDeliveryDate:
          (data['expectedDeliveryDate'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      specialInstructions: data['specialInstructions'] ?? '',
      createdBy: data['createdBy'] ?? '',
      approvalChain: List<String>.from(data['approvalChain'] ?? []),
      approvalStatus: data['approvalStatus'] ?? {},
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'institutionId': institutionId,
      'institutionName': institutionName,
      'status': status,
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'paymentTerms': paymentTerms,
      'creditLimit': creditLimit,
      'creditUsed': creditUsed,
      'createdDate': Timestamp.fromDate(createdDate),
      'expectedDeliveryDate': Timestamp.fromDate(expectedDeliveryDate),
      'deliveryAddress': deliveryAddress,
      'specialInstructions': specialInstructions,
      'createdBy': createdBy,
      'approvalChain': approvalChain,
      'approvalStatus': approvalStatus,
      'notes': notes,
    };
  }
}

/// Line item in a Purchase Order
class PurchaseOrderLineItem {
  final String productId;
  final String productName;
  final String sku;
  final double quantity;
  final String unit; // "case", "box", "unit"
  final double unitPrice;
  final double totalPrice;
  final int minimumOrderQuantity;
  final int casePack;

  PurchaseOrderLineItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.minimumOrderQuantity,
    required this.casePack,
  });

  factory PurchaseOrderLineItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderLineItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      sku: map['sku'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'case',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      minimumOrderQuantity: map['minimumOrderQuantity'] ?? 1,
      casePack: map['casePack'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'minimumOrderQuantity': minimumOrderQuantity,
      'casePack': casePack,
    };
  }

  /// Check if quantity meets minimum order quantity
  bool meetsMinimumOrderQuantity() {
    return quantity >= minimumOrderQuantity;
  }

  /// Check if quantity is valid case pack
  bool isValidCasePack() {
    return quantity % casePack == 0;
  }
}

/// Contract pricing for institutional buyers
class ContractPrice {
  final String id;
  final String institutionId;
  final String productId;
  final String productName;
  final String sku;
  final double contractPrice;
  final double retailPrice;
  final int minimumOrderQuantity;
  final int casePack;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String discountType; // "percentage", "fixed", "tiered"
  final double discountValue;

  ContractPrice({
    required this.id,
    required this.institutionId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.contractPrice,
    required this.retailPrice,
    required this.minimumOrderQuantity,
    required this.casePack,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.discountType,
    required this.discountValue,
  });

  factory ContractPrice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContractPrice(
      id: doc.id,
      institutionId: data['institutionId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      sku: data['sku'] ?? '',
      contractPrice: (data['contractPrice'] ?? 0).toDouble(),
      retailPrice: (data['retailPrice'] ?? 0).toDouble(),
      minimumOrderQuantity: data['minimumOrderQuantity'] ?? 1,
      casePack: data['casePack'] ?? 1,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      discountType: data['discountType'] ?? 'fixed',
      discountValue: (data['discountValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'institutionId': institutionId,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'contractPrice': contractPrice,
      'retailPrice': retailPrice,
      'minimumOrderQuantity': minimumOrderQuantity,
      'casePack': casePack,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'discountType': discountType,
      'discountValue': discountValue,
    };
  }

  double calculateDiscount() {
    if (discountType == 'percentage') {
      return retailPrice * (discountValue / 100);
    } else if (discountType == 'fixed') {
      return discountValue;
    }
    return 0;
  }

  double getSavingsPercentage() {
    if (retailPrice == 0) return 0;
    return ((retailPrice - contractPrice) / retailPrice * 100);
  }
}

/// Invoice for order
class Invoice {
  final String id;
  final String poId;
  final String institutionId;
  final String institutionName;
  final String status; // draft, issued, paid, overdue, cancelled
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double amountPaid;
  final String paymentTerms;
  final DateTime issuedDate;
  final DateTime dueDate;
  final String deliveryAddress;
  final String notes;

  Invoice({
    required this.id,
    required this.poId,
    required this.institutionId,
    required this.institutionName,
    required this.status,
    required this.lineItems,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.paymentTerms,
    required this.issuedDate,
    required this.dueDate,
    required this.deliveryAddress,
    required this.notes,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice(
      id: doc.id,
      poId: data['poId'] ?? '',
      institutionId: data['institutionId'] ?? '',
      institutionName: data['institutionName'] ?? '',
      status: data['status'] ?? 'draft',
      lineItems: (data['lineItems'] as List?)
              ?.map((item) => InvoiceLineItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
      paymentTerms: data['paymentTerms'] ?? 'Net 30',
      issuedDate:
          (data['issuedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryAddress: data['deliveryAddress'] ?? '',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'poId': poId,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'status': status,
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'paymentTerms': paymentTerms,
      'issuedDate': Timestamp.fromDate(issuedDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'deliveryAddress': deliveryAddress,
      'notes': notes,
    };
  }

  double getOutstandingBalance() {
    return totalAmount - amountPaid;
  }

  bool isOverdue() {
    return DateTime.now().isAfter(dueDate) && status != 'paid';
  }
}

/// Invoice line item
class InvoiceLineItem {
  final String productId;
  final String productName;
  final String sku;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;

  InvoiceLineItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      sku: map['sku'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'case',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}
