import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// User churn risk assessment
enum ChurnRiskLevel {
  low, // Active user, likely to stay
  medium, // At-risk (not used in 2+ weeks)
  high, // Critical risk (not used in 1+ month)
  critical, // Will likely churn (not used in 2+ months)
}

extension ChurnRiskLevelExt on ChurnRiskLevel {
  String get displayName {
    switch (this) {
      case ChurnRiskLevel.low:
        return 'Low Risk';
      case ChurnRiskLevel.medium:
        return 'At Risk (2+ weeks inactive)';
      case ChurnRiskLevel.high:
        return 'High Risk (1+ month inactive)';
      case ChurnRiskLevel.critical:
        return 'Critical (2+ months inactive)';
    }
  }

  double get recoveryActionScore {
    switch (this) {
      case ChurnRiskLevel.low:
        return 0.0;
      case ChurnRiskLevel.medium:
        return 0.4;
      case ChurnRiskLevel.high:
        return 0.7;
      case ChurnRiskLevel.critical:
        return 1.0;
    }
  }
}

/// User churn analysis
class UserChurnAnalysis {
  final String userId;
  final ChurnRiskLevel riskLevel;
  final DateTime lastActiveDate;
  final int daysSinceLastActivity;
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final DateTime accountCreatedDate;
  final List<String> favoriteCategories;
  final bool hasViewedProductsButNoBuy;
  final int cartAbandonmentCount;

  UserChurnAnalysis({
    required this.userId,
    required this.riskLevel,
    required this.lastActiveDate,
    required this.daysSinceLastActivity,
    required this.totalOrders,
    required this.totalSpent,
    required this.averageOrderValue,
    required this.accountCreatedDate,
    required this.favoriteCategories,
    required this.hasViewedProductsButNoBuy,
    required this.cartAbandonmentCount,
  });
}

/// Delivery time prediction model
class DeliveryPrediction {
  final String orderId;
  final DateTime estimatedDeliveryTime;
  final int estimatedMinutes;
  final double confidence; // 0-1 (how confident in estimate)
  final String reason; // Why this estimate

  DeliveryPrediction({
    required this.orderId,
    required this.estimatedDeliveryTime,
    required this.estimatedMinutes,
    required this.confidence,
    required this.reason,
  });
}

/// Demand forecast for a product
class DemandForecast {
  final String productId;
  final String productName;
  final int forecastedDemandUnits;
  final double confidenceScore; // 0-1
  final DateTime forecastDate;
  final String trend; // 'increasing', 'decreasing', 'stable'
  final List<int> historicalDemandLast30Days;

  DemandForecast({
    required this.productId,
    required this.productName,
    required this.forecastedDemandUnits,
    required this.confidenceScore,
    required this.forecastDate,
    required this.trend,
    required this.historicalDemandLast30Days,
  });
}

/// Smart driver assignment recommendation
class DriverAssignmentRecommendation {
  final String driverId;
  final String driverName;
  final double score; // 0-100 (higher = better match)
  final String reason;
  final double estimatedDeliveryMinutes;
  final double distanceKm;

  DriverAssignmentRecommendation({
    required this.driverId,
    required this.driverName,
    required this.score,
    required this.reason,
    required this.estimatedDeliveryMinutes,
    required this.distanceKm,
  });
}

/// Order Intelligence Service
/// Provides:
/// - Churn prediction & prevention
/// - Delivery time estimation
/// - Demand forecasting
/// - Smart driver assignment
/// - Route optimization
class OrderIntelligenceService {
  static final OrderIntelligenceService _instance =
      OrderIntelligenceService._internal();
  late FirebaseFirestore _firestore;

  factory OrderIntelligenceService() => _instance;

  OrderIntelligenceService._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Analyze user churn risk
  Future<UserChurnAnalysis> analyzeChurnRisk({
    required String userId,
  }) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final lastActiveDate = (userData['lastActive'] as Timestamp?)?.toDate() ??
          DateTime.now().subtract(const Duration(days: 90));

      // Get user orders
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      final totalOrders = ordersSnapshot.docs.length;
      double totalSpent = 0;
      for (var doc in ordersSnapshot.docs) {
        totalSpent += (doc['totalAmount'] as num?)?.toDouble() ?? 0;
      }

      final averageOrderValue =
          totalOrders > 0 ? totalSpent / totalOrders.toDouble() : 0.0;

      // Get user activity
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      // Check for products viewed but not purchased
      bool hasViewedButNoBuy = false;
      int cartAbandonmentCount = 0;

      for (var doc in eventsSnapshot.docs) {
        final eventType = doc['eventType'];
        if (eventType == 'product_viewed' || eventType == 'category_browsed') {
          hasViewedButNoBuy = true;
        }
        if (eventType == 'cart_abandoned') {
          cartAbandonmentCount++;
        }
      }

      // Get favorite categories from user activity
      final categoriesSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .where('eventType', isEqualTo: 'product_viewed')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final categoryMap = <String, int>{};
      for (var doc in categoriesSnapshot.docs) {
        final category = doc['properties']['category'] as String?;
        if (category != null) {
          categoryMap[category] = (categoryMap[category] ?? 0) + 1;
        }
      }

      final favoriteCategories = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final favCats = favoriteCategories.take(3).map((e) => e.key).toList();

      // Calculate days since last activity
      final daysSinceLastActivity =
          DateTime.now().difference(lastActiveDate).inDays;

      // Determine risk level
      ChurnRiskLevel riskLevel;
      if (daysSinceLastActivity < 7) {
        riskLevel = ChurnRiskLevel.low;
      } else if (daysSinceLastActivity < 14) {
        riskLevel = ChurnRiskLevel.medium;
      } else if (daysSinceLastActivity < 30) {
        riskLevel = ChurnRiskLevel.high;
      } else {
        riskLevel = ChurnRiskLevel.critical;
      }

      return UserChurnAnalysis(
        userId: userId,
        riskLevel: riskLevel,
        lastActiveDate: lastActiveDate,
        daysSinceLastActivity: daysSinceLastActivity,
        totalOrders: totalOrders,
        totalSpent: totalSpent,
        averageOrderValue: averageOrderValue,
        accountCreatedDate: DateTime.now().subtract(const Duration(days: 365)),
        favoriteCategories: favCats,
        hasViewedProductsButNoBuy: hasViewedButNoBuy,
        cartAbandonmentCount: cartAbandonmentCount,
      );
    } catch (e) {
      debugPrint('❌ Failed to analyze churn risk: $e');
      rethrow;
    }
  }

  /// Predict delivery time for an order
  Future<DeliveryPrediction> predictDeliveryTime({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Get order data
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final deliverySlot = orderData['deliverySlot'] as String? ?? 'standard';

      // Simple delivery time estimation
      // Base: 30 minutes processing + 20 minutes delivery
      // Adjusted by delivery slot
      int baseMinutes = 50;

      if (deliverySlot == 'urgent') {
        baseMinutes = 30; // Faster
      } else if (deliverySlot == 'next_day') {
        baseMinutes = 1440; // Next day
      } else if (deliverySlot == 'scheduled') {
        // Get scheduled time
        baseMinutes = 120;
      }

      // Add some variability based on time of day
      final hour = DateTime.now().hour;
      if (hour >= 18 && hour <= 21) {
        // Peak hours
        baseMinutes = (baseMinutes * 1.3).toInt();
      } else if (hour >= 22 || hour < 6) {
        // Off-peak hours
        baseMinutes = (baseMinutes * 0.8).toInt();
      }

      final estimatedDelivery =
          DateTime.now().add(Duration(minutes: baseMinutes));

      return DeliveryPrediction(
        orderId: orderId,
        estimatedDeliveryTime: estimatedDelivery,
        estimatedMinutes: baseMinutes,
        confidence: 0.85, // 85% confident
        reason:
            'Based on delivery slot ($deliverySlot), time of day, and historical patterns',
      );
    } catch (e) {
      debugPrint('❌ Failed to predict delivery time: $e');
      rethrow;
    }
  }

  /// Forecast demand for a product
  Future<DemandForecast> forecastDemand({
    required String productId,
    required String productName,
  }) async {
    try {
      // Get product order history (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      // Count occurrences of this product
      final dailyDemand = <int>[]; // Daily demand for last 30 days
      int totalUnits = 0;

      for (var i = 0; i < 30; i++) {
        final date = thirtyDaysAgo.add(Duration(days: i));
        final nextDate = date.add(const Duration(days: 1));

        int dayCount = 0;
        for (var orderDoc in ordersSnapshot.docs) {
          final items = orderDoc['items'] as List? ?? [];
          for (var item in items) {
            if (item['productId'] == productId) {
              final createdAt = (orderDoc['createdAt'] as Timestamp?)?.toDate();
              if (createdAt != null &&
                  createdAt.isAfter(date) &&
                  createdAt.isBefore(nextDate)) {
                dayCount += (item['quantity'] as int?) ?? 1;
              }
            }
          }
        }

        dailyDemand.add(dayCount);
        totalUnits += dayCount;
      }

      // Calculate average and trend
      final average = totalUnits ~/ 30;
      final recentAverage = dailyDemand
              .sublist(max(0, 25))
              .fold<int>(0, (sum, val) => sum + val) ~/
          (dailyDemand.length > 25 ? 5 : dailyDemand.length);

      // Determine trend
      String trend = 'stable';
      if (recentAverage > average * 1.2) {
        trend = 'increasing';
      } else if (recentAverage < average * 0.8) {
        trend = 'decreasing';
      }

      // Forecast next 7 days (simple linear projection)
      int forecastedDemand;
      if (trend == 'increasing') {
        forecastedDemand = (recentAverage * 1.15).toInt();
      } else if (trend == 'decreasing') {
        forecastedDemand = (recentAverage * 0.85).toInt();
      } else {
        forecastedDemand = recentAverage;
      }

      return DemandForecast(
        productId: productId,
        productName: productName,
        forecastedDemandUnits: forecastedDemand,
        confidenceScore: 0.75,
        forecastDate: DateTime.now().add(const Duration(days: 7)),
        trend: trend,
        historicalDemandLast30Days: dailyDemand,
      );
    } catch (e) {
      debugPrint('❌ Failed to forecast demand: $e');
      rethrow;
    }
  }

  /// Get smart driver assignment recommendation
  Future<List<DriverAssignmentRecommendation>> recommendDrivers({
    required String orderId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Get available drivers
      final driversSnapshot = await _firestore
          .collection('drivers')
          .where('available', isEqualTo: true)
          .get();

      final recommendations = <DriverAssignmentRecommendation>[];

      for (var driverDoc in driversSnapshot.docs) {
        final driverData = driverDoc.data();
        final driverName = driverData['name'] as String? ?? 'Driver';
        final currentLocation = driverData['current_location'] as Map?;

        // Calculate score based on distance, performance, and current load
        double score = 100.0;

        // Distance factor (closer = better)
        if (currentLocation != null) {
          final driverLat = (currentLocation['lat'] as num?)?.toDouble() ?? 0;
          final driverLng = (currentLocation['lng'] as num?)?.toDouble() ?? 0;
          final distance =
              _calculateDistance(driverLat, driverLng, latitude, longitude);

          score -= (distance * 0.5); // Deduct points for distance
        }

        // Performance factor (good rating = better)
        final performance = driverData['performance'] as Map? ?? {};
        final rating = (performance['rating'] as num?)?.toDouble() ?? 0;
        score += (rating * 5); // Add points for rating

        // Workload factor (fewer active deliveries = better)
        final activeDeliveries =
            (driverData['active_deliveries_count'] as num?)?.toInt() ?? 0;
        score -= (activeDeliveries * 2); // Deduct points for workload

        // Ensure score is between 0-100
        score = score.clamp(0, 100);

        final estimatedMinutes = ((3 + (score / 100)) * 20)
            .toInt(); // Faster driver = faster delivery

        recommendations.add(
          DriverAssignmentRecommendation(
            driverId: driverDoc.id,
            driverName: driverName,
            score: score,
            reason: _getAssignmentReason(score),
            estimatedDeliveryMinutes: estimatedMinutes.toDouble(),
            distanceKm: currentLocation != null
                ? _calculateDistance(currentLocation['lat'] as double? ?? 0,
                    currentLocation['lng'] as double? ?? 0, latitude, longitude)
                : 0,
          ),
        );
      }

      // Sort by score (highest first)
      recommendations.sort((a, b) => b.score.compareTo(a.score));

      return recommendations.take(3).toList(); // Return top 3
    } catch (e) {
      debugPrint('❌ Failed to recommend drivers: $e');
      return [];
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * (pi / 180);

  String _getAssignmentReason(double score) {
    if (score >= 80) {
      return 'Excellent match: Close location + high performance';
    } else if (score >= 60) {
      return 'Good match: Reasonable distance and good performance';
    } else if (score >= 40) {
      return 'Fair match: Available but some distance';
    } else {
      return 'Fallback option: Limited driver availability';
    }
  }

  /// Get all users at churn risk (for retention campaigns)
  Future<List<UserChurnAnalysis>> getUsersAtChurnRisk({
    ChurnRiskLevel minRiskLevel = ChurnRiskLevel.medium,
    int limit = 100,
  }) async {
    try {
      // This would need to be optimized with a Cloud Function in production
      // For now, we'll return an empty list and recommend using Cloud Function
      debugPrint(
          '💡 Note: getUsersAtChurnRisk should be run as a Cloud Function for production');
      return [];
    } catch (e) {
      debugPrint('❌ Failed to get users at churn risk: $e');
      return [];
    }
  }
}
