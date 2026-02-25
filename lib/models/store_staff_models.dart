import 'package:cloud_firestore/cloud_firestore.dart';

/// Store Staff Models for POS, Sales, and Inventory Management

/// POS Transaction - single item sale
class POSTransaction {
  final String id;
  final String storeId;
  final String staffId;
  final String staffName;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String paymentMethod; // cash, card, mobile_money
  final String status; // completed, pending, cancelled
  final DateTime timestamp;
  final String? notes;
  final String? receiptNumber;

  POSTransaction({
    required this.id,
    required this.storeId,
    required this.staffId,
    required this.staffName,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.timestamp,
    this.notes,
    this.receiptNumber,
  });

  factory POSTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return POSTransaction(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      staffId: data['staffId'] ?? '',
      staffName: data['staffName'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 0,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? 'cash',
      status: data['status'] ?? 'completed',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      receiptNumber: data['receiptNumber'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'storeId': storeId,
        'staffId': staffId,
        'staffName': staffName,
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'subtotal': subtotal,
        'taxAmount': taxAmount,
        'total': total,
        'paymentMethod': paymentMethod,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'notes': notes,
        'receiptNumber': receiptNumber,
      };
}

/// Daily Sales Summary
class DailySalesSummary {
  final String id;
  final String storeId;
  final String storeName;
  final DateTime date;
  final int totalTransactions;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final double averageTransaction;
  final Map<String, int> paymentMethodBreakdown; // {cash: 5, card: 3, ...}
  final int topProductCount;
  final List<TopProduct> topProducts;
  final int activeStaffCount;
  final String status; // open, closed, reconciled

  DailySalesSummary({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.date,
    required this.totalTransactions,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.averageTransaction,
    required this.paymentMethodBreakdown,
    required this.topProductCount,
    required this.topProducts,
    required this.activeStaffCount,
    required this.status,
  });

  factory DailySalesSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailySalesSummary(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalTransactions: data['totalTransactions'] ?? 0,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalCost: (data['totalCost'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (data['totalProfit'] as num?)?.toDouble() ?? 0.0,
      averageTransaction: (data['averageTransaction'] as num?)?.toDouble() ?? 0.0,
      paymentMethodBreakdown:
          Map<String, int>.from(data['paymentMethodBreakdown'] ?? {}),
      topProductCount: data['topProductCount'] ?? 0,
      topProducts: (data['topProducts'] as List?)
              ?.map((p) => TopProduct.fromMap(p))
              .toList() ??
          [],
      activeStaffCount: data['activeStaffCount'] ?? 0,
      status: data['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'storeId': storeId,
        'storeName': storeName,
        'date': FieldValue.serverTimestamp(),
        'totalTransactions': totalTransactions,
        'totalRevenue': totalRevenue,
        'totalCost': totalCost,
        'totalProfit': totalProfit,
        'averageTransaction': averageTransaction,
        'paymentMethodBreakdown': paymentMethodBreakdown,
        'topProductCount': topProductCount,
        'topProducts': topProducts.map((p) => p.toMap()).toList(),
        'activeStaffCount': activeStaffCount,
        'status': status,
      };
}

/// Top performing product
class TopProduct {
  final String productId;
  final String productName;
  final int unitsSold;
  final double revenue;

  TopProduct({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.revenue,
  });

  factory TopProduct.fromMap(Map<String, dynamic> data) {
    return TopProduct(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      unitsSold: data['unitsSold'] ?? 0,
      revenue: (data['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'unitsSold': unitsSold,
        'revenue': revenue,
      };
}

/// Store inventory item accessible to store staff
class StoreInventoryItem {
  final String id;
  final String storeId;
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final int minimumLevel;
  final double costPrice;
  final double salePrice;
  final DateTime lastAdjustment;
  final String? adjustmentNotes;

  StoreInventoryItem({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.minimumLevel,
    required this.costPrice,
    required this.salePrice,
    required this.lastAdjustment,
    this.adjustmentNotes,
  });

  factory StoreInventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreInventoryItem(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      sku: data['sku'] ?? '',
      quantity: data['quantity'] ?? 0,
      minimumLevel: data['minimumLevel'] ?? 5,
      costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
      lastAdjustment: (data['lastAdjustment'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adjustmentNotes: data['adjustmentNotes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'storeId': storeId,
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'quantity': quantity,
        'minimumLevel': minimumLevel,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'lastAdjustment': FieldValue.serverTimestamp(),
        'adjustmentNotes': adjustmentNotes,
      };

  bool get isLowStock => quantity <= minimumLevel;
}

/// Stock Adjustment Log
class StockAdjustment {
  final String id;
  final String storeId;
  final String productId;
  final String productName;
  final String staffId;
  final String staffName;
  final int previousQuantity;
  final int newQuantity;
  final int adjustmentAmount;
  final String reason; // stock_count, damage, theft, admin_adjustment
  final String? notes;
  final DateTime timestamp;

  StockAdjustment({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.staffId,
    required this.staffName,
    required this.previousQuantity,
    required this.newQuantity,
    required this.adjustmentAmount,
    required this.reason,
    this.notes,
    required this.timestamp,
  });

  factory StockAdjustment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockAdjustment(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      staffId: data['staffId'] ?? '',
      staffName: data['staffName'] ?? '',
      previousQuantity: data['previousQuantity'] ?? 0,
      newQuantity: data['newQuantity'] ?? 0,
      adjustmentAmount: data['adjustmentAmount'] ?? 0,
      reason: data['reason'] ?? 'admin_adjustment',
      notes: data['notes'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'storeId': storeId,
        'productId': productId,
        'productName': productName,
        'staffId': staffId,
        'staffName': staffName,
        'previousQuantity': previousQuantity,
        'newQuantity': newQuantity,
        'adjustmentAmount': adjustmentAmount,
        'reason': reason,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      };
}
