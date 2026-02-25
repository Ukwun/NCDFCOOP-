import 'package:cloud_firestore/cloud_firestore.dart';

/// Sales metrics for dashboard
class SalesMetrics {
  final DateTime date;
  final double totalRevenue;
  final double averageOrderValue;
  final int totalOrders;
  final int newCustomers;
  final double conversionRate;
  final List<HourlyRevenue> revenueByHour;

  SalesMetrics({
    required this.date,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalOrders,
    required this.newCustomers,
    required this.conversionRate,
    required this.revenueByHour,
  });

  factory SalesMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesMetrics(
      date: (data['date'] as Timestamp).toDate(),
      totalRevenue: (data['totalRevenue'] as num).toDouble(),
      averageOrderValue: (data['averageOrderValue'] as num).toDouble(),
      totalOrders: data['totalOrders'] as int,
      newCustomers: data['newCustomers'] as int,
      conversionRate: (data['conversionRate'] as num).toDouble(),
      revenueByHour: (data['revenueByHour'] as List)
          .cast<Map<String, dynamic>>()
          .map((h) => HourlyRevenue.fromMap(h))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'totalRevenue': totalRevenue,
        'averageOrderValue': averageOrderValue,
        'totalOrders': totalOrders,
        'newCustomers': newCustomers,
        'conversionRate': conversionRate,
        'revenueByHour': revenueByHour.map((h) => h.toMap()).toList(),
      };
}

/// Hourly revenue breakdown
class HourlyRevenue {
  final int hour;
  final double revenue;
  final int orderCount;

  HourlyRevenue({
    required this.hour,
    required this.revenue,
    required this.orderCount,
  });

  factory HourlyRevenue.fromMap(Map<String, dynamic> data) {
    return HourlyRevenue(
      hour: data['hour'] as int,
      revenue: (data['revenue'] as num).toDouble(),
      orderCount: data['orderCount'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'hour': hour,
        'revenue': revenue,
        'orderCount': orderCount,
      };
}

/// User engagement metrics
class EngagementMetrics {
  final DateTime date;
  final int totalUsers;
  final int newUsers;
  final int activeUsers;
  final double retentionRate;
  final double bounceRate;
  final double averageSessionDuration;
  final int totalSessions;

  EngagementMetrics({
    required this.date,
    required this.totalUsers,
    required this.newUsers,
    required this.activeUsers,
    required this.retentionRate,
    required this.bounceRate,
    required this.averageSessionDuration,
    required this.totalSessions,
  });

  factory EngagementMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EngagementMetrics(
      date: (data['date'] as Timestamp).toDate(),
      totalUsers: data['totalUsers'] as int,
      newUsers: data['newUsers'] as int,
      activeUsers: data['activeUsers'] as int,
      retentionRate: (data['retentionRate'] as num).toDouble(),
      bounceRate: (data['bounceRate'] as num).toDouble(),
      averageSessionDuration:
          (data['averageSessionDuration'] as num).toDouble(),
      totalSessions: data['totalSessions'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'totalUsers': totalUsers,
        'newUsers': newUsers,
        'activeUsers': activeUsers,
        'retentionRate': retentionRate,
        'bounceRate': bounceRate,
        'averageSessionDuration': averageSessionDuration,
        'totalSessions': totalSessions,
      };
}

/// Inventory analytics
class InventoryAnalytics {
  final DateTime date;
  final int totalSKUs;
  final double stockTurnover;
  final int lowStockItems;
  final int deadStockItems;
  final double averageStockLevel;
  final double warehouseUtilization;
  final List<CategoryInventory> inventoryByCategory;

  InventoryAnalytics({
    required this.date,
    required this.totalSKUs,
    required this.stockTurnover,
    required this.lowStockItems,
    required this.deadStockItems,
    required this.averageStockLevel,
    required this.warehouseUtilization,
    required this.inventoryByCategory,
  });

  factory InventoryAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryAnalytics(
      date: (data['date'] as Timestamp).toDate(),
      totalSKUs: data['totalSKUs'] as int,
      stockTurnover: (data['stockTurnover'] as num).toDouble(),
      lowStockItems: data['lowStockItems'] as int,
      deadStockItems: data['deadStockItems'] as int,
      averageStockLevel: (data['averageStockLevel'] as num).toDouble(),
      warehouseUtilization: (data['warehouseUtilization'] as num).toDouble(),
      inventoryByCategory: (data['inventoryByCategory'] as List)
          .cast<Map<String, dynamic>>()
          .map((c) => CategoryInventory.fromMap(c))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'totalSKUs': totalSKUs,
        'stockTurnover': stockTurnover,
        'lowStockItems': lowStockItems,
        'deadStockItems': deadStockItems,
        'averageStockLevel': averageStockLevel,
        'warehouseUtilization': warehouseUtilization,
        'inventoryByCategory':
            inventoryByCategory.map((c) => c.toMap()).toList(),
      };
}

/// Inventory by category
class CategoryInventory {
  final String category;
  final int itemCount;
  final double turnover;
  final int stockLevel;

  CategoryInventory({
    required this.category,
    required this.itemCount,
    required this.turnover,
    required this.stockLevel,
  });

  factory CategoryInventory.fromMap(Map<String, dynamic> data) {
    return CategoryInventory(
      category: data['category'] as String,
      itemCount: data['itemCount'] as int,
      turnover: (data['turnover'] as num).toDouble(),
      stockLevel: data['stockLevel'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'itemCount': itemCount,
        'turnover': turnover,
        'stockLevel': stockLevel,
      };
}

/// Product performance metrics
class ProductPerformance {
  final String productId;
  final String productName;
  final int unitsSold;
  final double revenue;
  final double averageRating;
  final int reviewCount;
  final double profitMargin;
  final int views;
  final double conversionRate;

  ProductPerformance({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.revenue,
    required this.averageRating,
    required this.reviewCount,
    required this.profitMargin,
    required this.views,
    required this.conversionRate,
  });

  factory ProductPerformance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductPerformance(
      productId: data['productId'] as String,
      productName: data['productName'] as String,
      unitsSold: data['unitsSold'] as int,
      revenue: (data['revenue'] as num).toDouble(),
      averageRating: (data['averageRating'] as num).toDouble(),
      reviewCount: data['reviewCount'] as int,
      profitMargin: (data['profitMargin'] as num).toDouble(),
      views: data['views'] as int,
      conversionRate: (data['conversionRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'unitsSold': unitsSold,
        'revenue': revenue,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'profitMargin': profitMargin,
        'views': views,
        'conversionRate': conversionRate,
      };
}

/// Logistics performance
class LogisticsPerformance {
  final DateTime date;
  final int totalShipments;
  final int deliveredShipments;
  final int delayedShipments;
  final double averageDeliveryTime;
  final double onTimeDeliveryRate;
  final List<CarrierPerformance> carrierMetrics;

  LogisticsPerformance({
    required this.date,
    required this.totalShipments,
    required this.deliveredShipments,
    required this.delayedShipments,
    required this.averageDeliveryTime,
    required this.onTimeDeliveryRate,
    required this.carrierMetrics,
  });

  factory LogisticsPerformance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogisticsPerformance(
      date: (data['date'] as Timestamp).toDate(),
      totalShipments: data['totalShipments'] as int,
      deliveredShipments: data['deliveredShipments'] as int,
      delayedShipments: data['delayedShipments'] as int,
      averageDeliveryTime: (data['averageDeliveryTime'] as num).toDouble(),
      onTimeDeliveryRate: (data['onTimeDeliveryRate'] as num).toDouble(),
      carrierMetrics: (data['carrierMetrics'] as List)
          .cast<Map<String, dynamic>>()
          .map((c) => CarrierPerformance.fromMap(c))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'totalShipments': totalShipments,
        'deliveredShipments': deliveredShipments,
        'delayedShipments': delayedShipments,
        'averageDeliveryTime': averageDeliveryTime,
        'onTimeDeliveryRate': onTimeDeliveryRate,
        'carrierMetrics': carrierMetrics.map((c) => c.toMap()).toList(),
      };
}

/// Carrier performance metrics
class CarrierPerformance {
  final String carrierName;
  final int shipmentsDelivered;
  final double onTimeRate;
  final double averageDeliveryTime;
  final double costPerShipment;

  CarrierPerformance({
    required this.carrierName,
    required this.shipmentsDelivered,
    required this.onTimeRate,
    required this.averageDeliveryTime,
    required this.costPerShipment,
  });

  factory CarrierPerformance.fromMap(Map<String, dynamic> data) {
    return CarrierPerformance(
      carrierName: data['carrierName'] as String,
      shipmentsDelivered: data['shipmentsDelivered'] as int,
      onTimeRate: (data['onTimeRate'] as num).toDouble(),
      averageDeliveryTime: (data['averageDeliveryTime'] as num).toDouble(),
      costPerShipment: (data['costPerShipment'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'carrierName': carrierName,
        'shipmentsDelivered': shipmentsDelivered,
        'onTimeRate': onTimeRate,
        'averageDeliveryTime': averageDeliveryTime,
        'costPerShipment': costPerShipment,
      };
}

/// Review analytics
class ReviewAnalytics {
  final DateTime date;
  final int totalReviews;
  final double averageRating;
  final int pendingApproval;
  final int flaggedAsInappropriate;
  final List<RatingDistribution> ratingDistribution;

  ReviewAnalytics({
    required this.date,
    required this.totalReviews,
    required this.averageRating,
    required this.pendingApproval,
    required this.flaggedAsInappropriate,
    required this.ratingDistribution,
  });

  factory ReviewAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewAnalytics(
      date: (data['date'] as Timestamp).toDate(),
      totalReviews: data['totalReviews'] as int,
      averageRating: (data['averageRating'] as num).toDouble(),
      pendingApproval: data['pendingApproval'] as int,
      flaggedAsInappropriate: data['flaggedAsInappropriate'] as int,
      ratingDistribution: (data['ratingDistribution'] as List)
          .cast<Map<String, dynamic>>()
          .map((r) => RatingDistribution.fromMap(r))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'totalReviews': totalReviews,
        'averageRating': averageRating,
        'pendingApproval': pendingApproval,
        'flaggedAsInappropriate': flaggedAsInappropriate,
        'ratingDistribution': ratingDistribution.map((r) => r.toMap()).toList(),
      };
}

/// Rating distribution (1-5 stars)
class RatingDistribution {
  final int stars;
  final int count;
  final double percentage;

  RatingDistribution({
    required this.stars,
    required this.count,
    required this.percentage,
  });

  factory RatingDistribution.fromMap(Map<String, dynamic> data) {
    return RatingDistribution(
      stars: data['stars'] as int,
      count: data['count'] as int,
      percentage: (data['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'stars': stars,
        'count': count,
        'percentage': percentage,
      };
}

/// Member analytics
class MemberAnalytics {
  final DateTime date;
  final int totalMembers;
  final int goldMembers;
  final int platinumMembers;
  final int standardMembers;
  final double totalLoyaltyPoints;
  final double averageLoyaltyPoints;

  MemberAnalytics({
    required this.date,
    required this.totalMembers,
    required this.goldMembers,
    required this.platinumMembers,
    required this.standardMembers,
    required this.totalLoyaltyPoints,
    required this.averageLoyaltyPoints,
  });

  factory MemberAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberAnalytics(
      date: (data['date'] as Timestamp).toDate(),
      totalMembers: data['totalMembers'] as int,
      goldMembers: data['goldMembers'] as int,
      platinumMembers: data['platinumMembers'] as int,
      standardMembers: data['standardMembers'] as int,
      totalLoyaltyPoints: (data['totalLoyaltyPoints'] as num).toDouble(),
      averageLoyaltyPoints: (data['averageLoyaltyPoints'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'totalMembers': totalMembers,
        'goldMembers': goldMembers,
        'platinumMembers': platinumMembers,
        'standardMembers': standardMembers,
        'totalLoyaltyPoints': totalLoyaltyPoints,
        'averageLoyaltyPoints': averageLoyaltyPoints,
      };
}

/// Dashboard KPI summary
class DashboardKPISummary {
  final SalesMetrics? salesMetrics;
  final EngagementMetrics? engagementMetrics;
  final InventoryAnalytics? inventoryAnalytics;
  final LogisticsPerformance? logisticsMetrics;
  final ReviewAnalytics? reviewAnalytics;
  final MemberAnalytics? memberAnalytics;

  DashboardKPISummary({
    this.salesMetrics,
    this.engagementMetrics,
    this.inventoryAnalytics,
    this.logisticsMetrics,
    this.reviewAnalytics,
    this.memberAnalytics,
  });

  /// Calculate growth metrics
  double getMonthlySalesGrowth(SalesMetrics? previousMonth) {
    if (previousMonth == null || salesMetrics == null) return 0;
    if (previousMonth.totalRevenue == 0) return 0;
    return ((salesMetrics!.totalRevenue - previousMonth.totalRevenue) /
            previousMonth.totalRevenue) *
        100;
  }

  /// Calculate user growth
  double getMonthlyUserGrowth(EngagementMetrics? previousMonth) {
    if (previousMonth == null || engagementMetrics == null) return 0;
    if (previousMonth.totalUsers == 0) return 0;
    return ((engagementMetrics!.totalUsers - previousMonth.totalUsers) /
            previousMonth.totalUsers) *
        100;
  }

  /// Get health status
  String getHealthStatus() {
    if (salesMetrics == null || engagementMetrics == null) {
      return 'LOADING';
    }

    if (salesMetrics!.totalOrders > 1000 &&
        engagementMetrics!.activeUsers > 5000) {
      return 'EXCELLENT';
    } else if (salesMetrics!.totalOrders > 500 &&
        engagementMetrics!.activeUsers > 2500) {
      return 'GOOD';
    } else if (salesMetrics!.totalOrders > 100 &&
        engagementMetrics!.activeUsers > 500) {
      return 'FAIR';
    } else {
      return 'NEEDS_ATTENTION';
    }
  }
}
