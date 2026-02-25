import 'package:cloud_firestore/cloud_firestore.dart';

/// Store Manager Analytics Models

/// Product performance metrics
class ProductPerformance {
  final String productId;
  final String productName;
  final String sku;
  final int quantitySold;
  final double totalRevenue;
  final double averagePrice;
  final int stockLevel;
  final int minimumStock;
  final double turnoverRate;
  final double profitMargin;
  final DateTime periodStart;
  final DateTime periodEnd;

  ProductPerformance({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantitySold,
    required this.totalRevenue,
    required this.averagePrice,
    required this.stockLevel,
    required this.minimumStock,
    required this.turnoverRate,
    required this.profitMargin,
    required this.periodStart,
    required this.periodEnd,
  });

  factory ProductPerformance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductPerformance(
      productId: doc.id,
      productName: data['productName'] ?? '',
      sku: data['sku'] ?? '',
      quantitySold: (data['quantitySold'] as num?)?.toInt() ?? 0,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      stockLevel: (data['stockLevel'] as num?)?.toInt() ?? 0,
      minimumStock: (data['minimumStock'] as num?)?.toInt() ?? 0,
      turnoverRate: (data['turnoverRate'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (data['profitMargin'] as num?)?.toDouble() ?? 0.0,
      periodStart: (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd: (data['periodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'productName': productName,
        'sku': sku,
        'quantitySold': quantitySold,
        'totalRevenue': totalRevenue,
        'averagePrice': averagePrice,
        'stockLevel': stockLevel,
        'minimumStock': minimumStock,
        'turnoverRate': turnoverRate,
        'profitMargin': profitMargin,
        'periodStart': Timestamp.fromDate(periodStart),
        'periodEnd': Timestamp.fromDate(periodEnd),
      };

  /// Check if stock is running low
  bool get isLowStock => stockLevel <= minimumStock;
}

/// Staff performance metrics
class StaffPerformance {
  final String staffId;
  final String staffName;
  final String role;
  final int transactionsProcessed;
  final double totalSalesGenerated;
  final double averageTransactionValue;
  final int customersSaved;
  final double performanceScore;
  final DateTime periodStart;
  final DateTime periodEnd;

  StaffPerformance({
    required this.staffId,
    required this.staffName,
    required this.role,
    required this.transactionsProcessed,
    required this.totalSalesGenerated,
    required this.averageTransactionValue,
    required this.customersSaved,
    required this.performanceScore,
    required this.periodStart,
    required this.periodEnd,
  });

  factory StaffPerformance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StaffPerformance(
      staffId: doc.id,
      staffName: data['staffName'] ?? '',
      role: data['role'] ?? '',
      transactionsProcessed:
          (data['transactionsProcessed'] as num?)?.toInt() ?? 0,
      totalSalesGenerated:
          (data['totalSalesGenerated'] as num?)?.toDouble() ?? 0.0,
      averageTransactionValue:
          (data['averageTransactionValue'] as num?)?.toDouble() ?? 0.0,
      customersSaved: (data['customersSaved'] as num?)?.toInt() ?? 0,
      performanceScore: (data['performanceScore'] as num?)?.toDouble() ?? 0.0,
      periodStart: (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd: (data['periodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'staffName': staffName,
        'role': role,
        'transactionsProcessed': transactionsProcessed,
        'totalSalesGenerated': totalSalesGenerated,
        'averageTransactionValue': averageTransactionValue,
        'customersSaved': customersSaved,
        'performanceScore': performanceScore,
        'periodStart': Timestamp.fromDate(periodStart),
        'periodEnd': Timestamp.fromDate(periodEnd),
      };

  /// Get performance rating
  String get performanceRating {
    if (performanceScore >= 90) return 'Excellent';
    if (performanceScore >= 75) return 'Good';
    if (performanceScore >= 60) return 'Satisfactory';
    return 'Needs Improvement';
  }
}

/// Inventory health metrics
class InventoryHealth {
  final String warehouseId;
  final int totalItems;
  final int lowStockItems;
  final int overstockedItems;
  final double averageTurnoverRate;
  final double deadStockPercentage;
  final double inventoryValue;
  final DateTime lastUpdated;

  InventoryHealth({
    required this.warehouseId,
    required this.totalItems,
    required this.lowStockItems,
    required this.overstockedItems,
    required this.averageTurnoverRate,
    required this.deadStockPercentage,
    required this.inventoryValue,
    required this.lastUpdated,
  });

  factory InventoryHealth.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryHealth(
      warehouseId: doc.id,
      totalItems: (data['totalItems'] as num?)?.toInt() ?? 0,
      lowStockItems: (data['lowStockItems'] as num?)?.toInt() ?? 0,
      overstockedItems: (data['overstockedItems'] as num?)?.toInt() ?? 0,
      averageTurnoverRate:
          (data['averageTurnoverRate'] as num?)?.toDouble() ?? 0.0,
      deadStockPercentage:
          (data['deadStockPercentage'] as num?)?.toDouble() ?? 0.0,
      inventoryValue: (data['inventoryValue'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'totalItems': totalItems,
        'lowStockItems': lowStockItems,
        'overstockedItems': overstockedItems,
        'averageTurnoverRate': averageTurnoverRate,
        'deadStockPercentage': deadStockPercentage,
        'inventoryValue': inventoryValue,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  /// Get inventory health status
  String get healthStatus {
    if (lowStockItems > 0) return 'Low Stock Alert';
    if (deadStockPercentage > 20) return 'Excess Dead Stock';
    if (averageTurnoverRate < 2) return 'Slow Moving';
    return 'Healthy';
  }
}

/// Daily/Period sales metrics
class StoreSalesMetrics {
  final String storeId;
  final double totalRevenue;
  final int transactionCount;
  final double averageTransactionValue;
  final double profitMargin;
  final int customersServed;
  final Map<String, double> paymentMethodBreakdown;
  final List<String> topProducts;
  final DateTime periodStart;
  final DateTime periodEnd;

  StoreSalesMetrics({
    required this.storeId,
    required this.totalRevenue,
    required this.transactionCount,
    required this.averageTransactionValue,
    required this.profitMargin,
    required this.customersServed,
    required this.paymentMethodBreakdown,
    required this.topProducts,
    required this.periodStart,
    required this.periodEnd,
  });

  factory StoreSalesMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreSalesMetrics(
      storeId: doc.id,
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (data['transactionCount'] as num?)?.toInt() ?? 0,
      averageTransactionValue:
          (data['averageTransactionValue'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (data['profitMargin'] as num?)?.toDouble() ?? 0.0,
      customersServed: (data['customersServed'] as num?)?.toInt() ?? 0,
      paymentMethodBreakdown:
          Map<String, double>.from(data['paymentMethodBreakdown'] ?? {}),
      topProducts:
          List<String>.from(data['topProducts'] as List? ?? []),
      periodStart: (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd: (data['periodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'totalRevenue': totalRevenue,
        'transactionCount': transactionCount,
        'averageTransactionValue': averageTransactionValue,
        'profitMargin': profitMargin,
        'customersServed': customersServed,
        'paymentMethodBreakdown': paymentMethodBreakdown,
        'topProducts': topProducts,
        'periodStart': Timestamp.fromDate(periodStart),
        'periodEnd': Timestamp.fromDate(periodEnd),
      };
}

/// Complete store analytics summary
class StoreAnalyticsSummary {
  final String storeId;
  final String storeName;
  final double totalRevenue;
  final int transactionCount;
  final double profitMargin;
  final int customersServed;
  final int topProductCount;
  final int staffCount;
  final double averageStaffPerformance;
  final String inventoryStatus;
  final DateTime generatedAt;

  StoreAnalyticsSummary({
    required this.storeId,
    required this.storeName,
    required this.totalRevenue,
    required this.transactionCount,
    required this.profitMargin,
    required this.customersServed,
    required this.topProductCount,
    required this.staffCount,
    required this.averageStaffPerformance,
    required this.inventoryStatus,
    required this.generatedAt,
  });

  factory StoreAnalyticsSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreAnalyticsSummary(
      storeId: doc.id,
      storeName: data['storeName'] ?? '',
      totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (data['transactionCount'] as num?)?.toInt() ?? 0,
      profitMargin: (data['profitMargin'] as num?)?.toDouble() ?? 0.0,
      customersServed: (data['customersServed'] as num?)?.toInt() ?? 0,
      topProductCount: (data['topProductCount'] as num?)?.toInt() ?? 0,
      staffCount: (data['staffCount'] as num?)?.toInt() ?? 0,
      averageStaffPerformance:
          (data['averageStaffPerformance'] as num?)?.toDouble() ?? 0.0,
      inventoryStatus: data['inventoryStatus'] ?? 'Unknown',
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'storeName': storeName,
        'totalRevenue': totalRevenue,
        'transactionCount': transactionCount,
        'profitMargin': profitMargin,
        'customersServed': customersServed,
        'topProductCount': topProductCount,
        'staffCount': staffCount,
        'averageStaffPerformance': averageStaffPerformance,
        'inventoryStatus': inventoryStatus,
        'generatedAt': Timestamp.fromDate(generatedAt),
      };
}
