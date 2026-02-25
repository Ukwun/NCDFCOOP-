import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/models/analytics_models.dart';

/// Analytics service for computing and fetching metrics
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get sales metrics for a date range
  Future<SalesMetrics?> getSalesMetrics(DateTime date) async {
    try {
      final doc = await _firestore
          .collection('analytics')
          .doc('sales_metrics')
          .collection('daily')
          .doc(_dateKey(date))
          .get();

      if (!doc.exists) return null;
      return SalesMetrics.fromFirestore(doc);
    } catch (e) {
      print('Error fetching sales metrics: $e');
      return null;
    }
  }

  /// Get last 7 days sales metrics
  Future<List<SalesMetrics>> getSalesMetricsLast7Days() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));

      final docs = await _firestore
          .collection('analytics')
          .doc('sales_metrics')
          .collection('daily')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      return docs.docs.map((doc) => SalesMetrics.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching sales metrics: $e');
      return [];
    }
  }

  /// Get engagement metrics
  Future<EngagementMetrics?> getEngagementMetrics(DateTime date) async {
    try {
      final doc = await _firestore
          .collection('analytics')
          .doc('engagement_metrics')
          .collection('daily')
          .doc(_dateKey(date))
          .get();

      if (!doc.exists) return null;
      return EngagementMetrics.fromFirestore(doc);
    } catch (e) {
      print('Error fetching engagement metrics: $e');
      return null;
    }
  }

  /// Get inventory analytics
  Future<InventoryAnalytics?> getInventoryAnalytics(DateTime date) async {
    try {
      final doc = await _firestore
          .collection('analytics')
          .doc('inventory_analytics')
          .collection('daily')
          .doc(_dateKey(date))
          .get();

      if (!doc.exists) return null;
      return InventoryAnalytics.fromFirestore(doc);
    } catch (e) {
      print('Error fetching inventory analytics: $e');
      return null;
    }
  }

  /// Get logistics performance
  Future<LogisticsPerformance?> getLogisticsPerformance(DateTime date) async {
    try {
      final doc = await _firestore
          .collection('analytics')
          .doc('logistics_performance')
          .collection('daily')
          .doc(_dateKey(date))
          .get();

      if (!doc.exists) return null;
      return LogisticsPerformance.fromFirestore(doc);
    } catch (e) {
      print('Error fetching logistics performance: $e');
      return null;
    }
  }

  /// Get review analytics
  Future<ReviewAnalytics?> getReviewAnalytics(DateTime date) async {
    try {
      final doc = await _firestore
          .collection('analytics')
          .doc('review_analytics')
          .collection('daily')
          .doc(_dateKey(date))
          .get();

      if (!doc.exists) return null;
      return ReviewAnalytics.fromFirestore(doc);
    } catch (e) {
      print('Error fetching review analytics: $e');
      return null;
    }
  }

  /// Get member analytics
  Future<MemberAnalytics?> getMemberAnalytics(DateTime date) async {
    try {
      final doc = await _firestore
          .collection('analytics')
          .doc('member_analytics')
          .collection('daily')
          .doc(_dateKey(date))
          .get();

      if (!doc.exists) return null;
      return MemberAnalytics.fromFirestore(doc);
    } catch (e) {
      print('Error fetching member analytics: $e');
      return null;
    }
  }

  /// Get top products by revenue
  Future<List<ProductPerformance>> getTopProductsByRevenue({
    required int limit,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final docs = await _firestore
          .collection('analytics')
          .doc('product_performance')
          .collection('products')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('revenue', descending: true)
          .limit(limit)
          .get();

      return docs.docs
          .map((doc) => ProductPerformance.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching top products: $e');
      return [];
    }
  }

  /// Get top products by rating
  Future<List<ProductPerformance>> getTopProductsByRating({
    required int limit,
  }) async {
    try {
      final docs = await _firestore
          .collection('analytics')
          .doc('product_performance')
          .collection('products')
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();

      return docs.docs
          .map((doc) => ProductPerformance.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching top products by rating: $e');
      return [];
    }
  }

  /// Get dashboard summary
  Future<DashboardKPISummary> getDashboardSummary() async {
    final today = DateTime.now();

    final salesMetrics = await getSalesMetrics(today);
    final engagementMetrics = await getEngagementMetrics(today);
    final inventoryAnalytics = await getInventoryAnalytics(today);
    final logisticsMetrics = await getLogisticsPerformance(today);
    final reviewAnalytics = await getReviewAnalytics(today);
    final memberAnalytics = await getMemberAnalytics(today);

    return DashboardKPISummary(
      salesMetrics: salesMetrics,
      engagementMetrics: engagementMetrics,
      inventoryAnalytics: inventoryAnalytics,
      logisticsMetrics: logisticsMetrics,
      reviewAnalytics: reviewAnalytics,
      memberAnalytics: memberAnalytics,
    );
  }

  /// Watch dashboard summary in real-time
  Stream<DashboardKPISummary> watchDashboardSummary() {
    return Stream.fromFutures([
      getDashboardSummary(),
    ]).map((summary) => summary);
  }

  /// Calculate daily metrics (called by Cloud Functions)
  Future<void> calculateDailyMetrics(DateTime date) async {
    try {
      await Future.wait([
        _calculateSalesMetrics(date),
        _calculateEngagementMetrics(date),
        _calculateInventoryAnalytics(date),
        _calculateLogisticsPerformance(date),
        _calculateReviewAnalytics(date),
        _calculateMemberAnalytics(date),
      ]);
    } catch (e) {
      print('Error calculating daily metrics: $e');
    }
  }

  /// Calculate sales metrics for the day
  Future<void> _calculateSalesMetrics(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final orders = await _firestore
          .collection('shipments')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      double totalRevenue = 0;
      int totalOrders = orders.docs.length;

      for (final doc in orders.docs) {
        final amount = (doc['totalAmount'] as num).toDouble();
        totalRevenue += amount;
      }

      final averageOrderValue =
          totalOrders > 0 ? (totalRevenue / totalOrders).toDouble() : 0.0;

      // Fetch new customers (created today)
      final newMembers = await _firestore
          .collection('members')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Calculate conversion rate (orders / sessions * 100)
      final conversionRate =
          totalOrders > 0 ? ((totalOrders / 1000) * 100).toDouble() : 0.0;

      // Calculate hourly revenue
      final revenueByHour = <HourlyRevenue>[];
      for (int hour = 0; hour < 24; hour++) {
        final hourStart = DateTime(date.year, date.month, date.day, hour, 0, 0);
        final hourEnd = DateTime(date.year, date.month, date.day, hour, 59, 59);

        final hourOrders = await _firestore
            .collection('shipments')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(hourStart),
                isLessThanOrEqualTo: Timestamp.fromDate(hourEnd))
            .get();

        double hourRevenue = 0;
        for (final doc in hourOrders.docs) {
          hourRevenue += (doc['totalAmount'] as num).toDouble();
        }

        revenueByHour.add(HourlyRevenue(
          hour: hour,
          revenue: hourRevenue,
          orderCount: hourOrders.docs.length,
        ));
      }

      final metrics = SalesMetrics(
        date: startOfDay,
        totalRevenue: totalRevenue.toDouble(),
        averageOrderValue: averageOrderValue,
        totalOrders: totalOrders,
        newCustomers: newMembers.docs.length,
        conversionRate: conversionRate,
        revenueByHour: revenueByHour,
      );

      await _firestore
          .collection('analytics')
          .doc('sales_metrics')
          .collection('daily')
          .doc(_dateKey(date))
          .set(metrics.toMap());
    } catch (e) {
      print('Error calculating sales metrics: $e');
    }
  }

  /// Calculate engagement metrics
  Future<void> _calculateEngagementMetrics(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Total users
      final totalUsers = await _firestore.collection('members').count().get();

      // New users today
      final newUsers = await _firestore
          .collection('members')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .count()
          .get();

      // Active users (performed activity today)
      final activeUsers = await _firestore
          .collectionGroup('activities')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final uniqueActiveUsers =
          activeUsers.docs.map((doc) => doc['userId'] as String).toSet().length;

      const retentionRate = 75.0; // Placeholder
      const bounceRate = 15.0; // Placeholder
      const averageSessionDuration = 300.0; // 5 minutes
      const totalSessions = 1000; // Placeholder

      final metrics = EngagementMetrics(
        date: startOfDay,
        totalUsers: totalUsers.count ?? 0,
        newUsers: newUsers.count ?? 0,
        activeUsers: uniqueActiveUsers,
        retentionRate: retentionRate,
        bounceRate: bounceRate,
        averageSessionDuration: averageSessionDuration,
        totalSessions: totalSessions,
      );

      await _firestore
          .collection('analytics')
          .doc('engagement_metrics')
          .collection('daily')
          .doc(_dateKey(date))
          .set(metrics.toMap());
    } catch (e) {
      print('Error calculating engagement metrics: $e');
    }
  }

  /// Calculate inventory analytics
  Future<void> _calculateInventoryAnalytics(DateTime date) async {
    try {
      final inventory = await _firestore.collectionGroup('items').get();

      final totalSKUs = inventory.docs.length;
      int lowStockItems = 0;
      int deadStockItems = 0;
      double totalStock = 0;

      for (final doc in inventory.docs) {
        final quantity = (doc['quantity'] as num).toDouble();
        final minStock = (doc['minimumStock'] as num?)?.toDouble() ?? 10;

        totalStock += quantity;

        if (quantity < minStock) {
          lowStockItems++;
        }
        if (quantity == 0) {
          deadStockItems++;
        }
      }

      final averageStock =
          totalSKUs > 0 ? (totalStock / totalSKUs).toDouble() : 0.0;
      const stockTurnover = 4.5; // Quarterly turnover
      const warehouseUtilization = 78.0; // Percentage

      final inventoryByCategory = <CategoryInventory>[];
      final categories = <String>{};

      for (final doc in inventory.docs) {
        final category = doc['category'] as String? ?? 'Uncategorized';
        categories.add(category);
      }

      for (final category in categories) {
        final categoryItems =
            inventory.docs.where((doc) => doc['category'] == category).toList();

        double categoryStock = 0;
        for (final doc in categoryItems) {
          categoryStock += (doc['quantity'] as num).toDouble();
        }

        inventoryByCategory.add(CategoryInventory(
          category: category,
          itemCount: categoryItems.length,
          turnover: stockTurnover,
          stockLevel: categoryStock.toInt(),
        ));
      }

      final metrics = InventoryAnalytics(
        date: date,
        totalSKUs: totalSKUs,
        stockTurnover: stockTurnover.toDouble(),
        lowStockItems: lowStockItems,
        deadStockItems: deadStockItems,
        averageStockLevel: averageStock,
        warehouseUtilization: warehouseUtilization,
        inventoryByCategory: inventoryByCategory,
      );

      await _firestore
          .collection('analytics')
          .doc('inventory_analytics')
          .collection('daily')
          .doc(_dateKey(date))
          .set(metrics.toMap());
    } catch (e) {
      print('Error calculating inventory analytics: $e');
    }
  }

  /// Calculate logistics performance
  Future<void> _calculateLogisticsPerformance(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final shipments = await _firestore
          .collection('shipments')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final totalShipments = shipments.docs.length;
      int deliveredShipments = 0;
      int delayedShipments = 0;
      double totalDeliveryTime = 0;

      for (final doc in shipments.docs) {
        final status = doc['status'] as String;
        if (status == 'delivered') {
          deliveredShipments++;
        }
        if (status == 'delayed') {
          delayedShipments++;
        }

        if (doc['deliveryDate'] != null &&
            doc['expectedDeliveryDate'] != null) {
          final delivered = (doc['deliveryDate'] as Timestamp).toDate();
          final expected = (doc['expectedDeliveryDate'] as Timestamp).toDate();
          totalDeliveryTime +=
              delivered.difference(expected).inHours.abs().toDouble();
        }
      }

      final averageDeliveryTime = totalShipments > 0
          ? (totalDeliveryTime / totalShipments).toDouble()
          : 0.0;
      final onTimeDeliveryRate = totalShipments > 0
          ? (((deliveredShipments - delayedShipments) / totalShipments) * 100)
              .toDouble()
          : 0.0;

      final metrics = LogisticsPerformance(
        date: startOfDay,
        totalShipments: totalShipments,
        deliveredShipments: deliveredShipments,
        delayedShipments: delayedShipments,
        averageDeliveryTime: averageDeliveryTime,
        onTimeDeliveryRate: onTimeDeliveryRate,
        carrierMetrics: const [], // Populated by Cloud Function
      );

      await _firestore
          .collection('analytics')
          .doc('logistics_performance')
          .collection('daily')
          .doc(_dateKey(date))
          .set(metrics.toMap());
    } catch (e) {
      print('Error calculating logistics performance: $e');
    }
  }

  /// Calculate review analytics
  Future<void> _calculateReviewAnalytics(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final reviews = await _firestore
          .collection('product_reviews_enhanced')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final totalReviews = reviews.docs.length;
      double totalRating = 0;
      int pendingApproval = 0;
      int flaggedAsInappropriate = 0;

      for (final doc in reviews.docs) {
        totalRating += (doc['rating'] as num).toDouble();
        if (doc['moderationStatus'] == 'pending') {
          pendingApproval++;
        }
        if (doc['flagged'] == true) {
          flaggedAsInappropriate++;
        }
      }

      final averageRating =
          totalReviews > 0 ? (totalRating / totalReviews).toDouble() : 0.0;

      // Calculate rating distribution
      final ratingDistribution = <RatingDistribution>[];
      for (int stars = 1; stars <= 5; stars++) {
        final count =
            reviews.docs.where((doc) => (doc['rating'] as int) == stars).length;
        final percentage =
            totalReviews > 0 ? ((count / totalReviews) * 100).toDouble() : 0.0;

        ratingDistribution.add(RatingDistribution(
          stars: stars,
          count: count,
          percentage: percentage,
        ));
      }

      final metrics = ReviewAnalytics(
        date: startOfDay,
        totalReviews: totalReviews,
        averageRating: averageRating,
        pendingApproval: pendingApproval,
        flaggedAsInappropriate: flaggedAsInappropriate,
        ratingDistribution: ratingDistribution,
      );

      await _firestore
          .collection('analytics')
          .doc('review_analytics')
          .collection('daily')
          .doc(_dateKey(date))
          .set(metrics.toMap());
    } catch (e) {
      print('Error calculating review analytics: $e');
    }
  }

  /// Calculate member analytics
  Future<void> _calculateMemberAnalytics(DateTime date) async {
    try {
      final members = await _firestore.collection('members').get();

      final totalMembers = members.docs.length;
      int goldMembers = 0;
      int platinumMembers = 0;
      int standardMembers = 0;
      double totalLoyaltyPoints = 0;

      for (final doc in members.docs) {
        final tier = doc['membershipTier'] as String? ?? 'standard';
        final points = (doc['loyaltyPoints'] as num?)?.toDouble() ?? 0;

        switch (tier) {
          case 'gold':
            goldMembers++;
            break;
          case 'platinum':
            platinumMembers++;
            break;
          default:
            standardMembers++;
        }

        totalLoyaltyPoints += points;
      }

      final averageLoyaltyPoints = totalMembers > 0
          ? (totalLoyaltyPoints / totalMembers).toDouble()
          : 0.0;

      final metrics = MemberAnalytics(
        date: date,
        totalMembers: totalMembers,
        goldMembers: goldMembers,
        platinumMembers: platinumMembers,
        standardMembers: standardMembers,
        totalLoyaltyPoints: totalLoyaltyPoints,
        averageLoyaltyPoints: averageLoyaltyPoints,
      );

      await _firestore
          .collection('analytics')
          .doc('member_analytics')
          .collection('daily')
          .doc(_dateKey(date))
          .set(metrics.toMap());
    } catch (e) {
      print('Error calculating member analytics: $e');
    }
  }

  /// Helper: convert date to string key
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Export analytics to CSV (for reporting)
  Future<String> exportSalesMetricsToCSV(List<SalesMetrics> metrics) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Date,Total Revenue,Average Order Value,Total Orders,New Customers,Conversion Rate');

    for (final metric in metrics) {
      buffer.writeln(
          '${metric.date},${metric.totalRevenue},${metric.averageOrderValue},${metric.totalOrders},${metric.newCustomers},${metric.conversionRate}');
    }

    return buffer.toString();
  }
}
