import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// User segment based on purchasing behavior
enum UserSegment {
  highValue, // Spent > ₦100,000
  mediumValue, // Spent ₦20k-100k
  lowValue, // Spent < ₦20k
  atRisk, // Haven't purchased in 30+ days
  new_, // Registered < 7 days ago
  frequentBuyer, // 3+ purchases
}

extension UserSegmentExt on UserSegment {
  String get displayName {
    switch (this) {
      case UserSegment.highValue:
        return 'High Value Customer';
      case UserSegment.mediumValue:
        return 'Medium Value Customer';
      case UserSegment.lowValue:
        return 'Low Value Customer';
      case UserSegment.atRisk:
        return 'At-Risk Customer';
      case UserSegment.new_:
        return 'New Customer';
      case UserSegment.frequentBuyer:
        return 'Frequent Buyer';
    }
  }

  double get baseDiscountPercent {
    switch (this) {
      case UserSegment.highValue:
        return 5.0; // 5% for loyal customers
      case UserSegment.mediumValue:
        return 2.0;
      case UserSegment.lowValue:
        return 0.0;
      case UserSegment.atRisk:
        return 10.0; // 10% recovery discount
      case UserSegment.new_:
        return 5.0; // 5% first-time discount
      case UserSegment.frequentBuyer:
        return 7.0; // 7% for repeat purchases
    }
  }
}

/// Inventory level for demand-based pricing
enum InventoryLevel {
  critical, // < 5 units (scarcity premium)
  low, // 5-30 units (normal price)
  normal, // 30-100 units (standard)
  abundant, // > 100 units (clear inventory)
}

extension InventoryLevelExt on InventoryLevel {
  String get displayName {
    switch (this) {
      case InventoryLevel.critical:
        return 'Critical Stock';
      case InventoryLevel.low:
        return 'Low Stock';
      case InventoryLevel.normal:
        return 'Normal Stock';
      case InventoryLevel.abundant:
        return 'Abundant Stock';
    }
  }

  double get demandPricingMultiplier {
    switch (this) {
      case InventoryLevel.critical:
        return 1.20; // +20% scarcity premium
      case InventoryLevel.low:
        return 1.0; // No adjustment
      case InventoryLevel.normal:
        return 1.0; // No adjustment
      case InventoryLevel.abundant:
        return 0.90; // -10% clearance discount
    }
  }
}

/// Dynamic pricing result
class DynamicPrice {
  final double basePrice;
  final double finalPrice;
  final double totalDiscountPercent;
  final List<PricingComponent> components;
  final String reason;

  DynamicPrice({
    required this.basePrice,
    required this.finalPrice,
    required this.totalDiscountPercent,
    required this.components,
    required this.reason,
  });
}

/// Pricing component (for transparency)
class PricingComponent {
  final String name;
  final double percentageChange; // Positive = increase, negative = decrease
  final String reason;

  PricingComponent({
    required this.name,
    required this.percentageChange,
    required this.reason,
  });
}

/// Intelligent Dynamic Pricing Engine
/// Implements:
/// - Segment-based pricing (high-value customers get better deals)
/// - Inventory-based pricing (scarce items cost more, excess items cost less)
/// - Time-based pricing (peak hours cost more)
/// - Recovery pricing (at-risk customers get discounts to return)
/// - Psychological pricing strategies
class DynamicPricingEngine {
  static final DynamicPricingEngine _instance =
      DynamicPricingEngine._internal();
  late FirebaseFirestore _firestore;

  factory DynamicPricingEngine() => _instance;

  DynamicPricingEngine._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  /// Calculate dynamic price for a product
  Future<DynamicPrice> calculateDynamicPrice({
    required String productId,
    required double basePrice,
    required int currentStock,
    String? userId,
  }) async {
    try {
      final components = <PricingComponent>[];
      double pricingMultiplier = 1.0;

      // Step 1: Segment-based pricing
      UserSegment? userSegment;
      if (userId != null && userId.isNotEmpty) {
        userSegment = await _getUserSegment(userId);
      }

      if (userSegment != null) {
        final segmentDiscount = userSegment.baseDiscountPercent;
        if (segmentDiscount > 0) {
          pricingMultiplier *= (1 - (segmentDiscount / 100));
          components.add(
            PricingComponent(
              name: 'Segment Discount',
              percentageChange: -segmentDiscount,
              reason:
                  'Special pricing for ${userSegment.displayName}: ${segmentDiscount.toStringAsFixed(1)}% off',
            ),
          );
        }
      }

      // Step 2: Inventory-based pricing
      final inventoryLevel = _getInventoryLevel(currentStock);
      final demandMultiplier = inventoryLevel.demandPricingMultiplier;

      if (demandMultiplier != 1.0) {
        final percentChange = ((demandMultiplier - 1) * 100);
        pricingMultiplier *= demandMultiplier;
        components.add(
          PricingComponent(
            name: 'Demand-Based Pricing',
            percentageChange: percentChange,
            reason:
                '${inventoryLevel.displayName}: ${demandMultiplier > 1 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
          ),
        );
      }

      // Step 3: Time-based pricing
      final (timePriceAdjustment, timeReason) = _getTimePriceAdjustment();
      if (timePriceAdjustment != 0) {
        pricingMultiplier *= (1 + (timePriceAdjustment / 100));
        components.add(
          PricingComponent(
            name: 'Time-Based Adjustment',
            percentageChange: timePriceAdjustment,
            reason: timeReason,
          ),
        );
      }

      // Step 4: Bulk order reward (if applicable, user gets better price on larger quantities)
      // This would be applied at checkout time with actual quantity

      // Calculate final price
      final finalPrice = basePrice * pricingMultiplier;
      final totalDiscount = ((1 - pricingMultiplier) * 100);

      final reason = _generatePricingReason(
        userSegment,
        inventoryLevel,
        components,
      );

      return DynamicPrice(
        basePrice: basePrice,
        finalPrice: finalPrice,
        totalDiscountPercent: totalDiscount,
        components: components,
        reason: reason,
      );
    } catch (e) {
      debugPrint('❌ Failed to calculate dynamic price: $e');
      // Fallback to base price
      return DynamicPrice(
        basePrice: basePrice,
        finalPrice: basePrice,
        totalDiscountPercent: 0,
        components: [],
        reason: 'Standard pricing',
      );
    }
  }

  /// Get user segment based on purchase history
  Future<UserSegment> _getUserSegment(String userId) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return UserSegment.lowValue;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final createdAt = (userData['createdAt'] as Timestamp?)?.toDate();
      final lastActive = (userData['lastActive'] as Timestamp?)?.toDate();

      // Check if new user (< 7 days)
      if (createdAt != null &&
          DateTime.now().difference(createdAt).inDays < 7) {
        return UserSegment.new_;
      }

      // Get order history
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      final orderCount = ordersSnapshot.docs.length;
      double totalSpent = 0;

      for (var doc in ordersSnapshot.docs) {
        totalSpent += (doc['totalAmount'] as num?)?.toDouble() ?? 0;
      }

      // Check if at risk (no activity in 30+ days)
      if (lastActive != null &&
          DateTime.now().difference(lastActive).inDays >= 30) {
        return UserSegment.atRisk;
      }

      // Check if frequent buyer (3+ purchases)
      if (orderCount >= 3) {
        return UserSegment.frequentBuyer;
      }

      // Classify by spending
      if (totalSpent > 100000) {
        return UserSegment.highValue;
      } else if (totalSpent > 20000) {
        return UserSegment.mediumValue;
      } else {
        return UserSegment.lowValue;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to determine user segment: $e');
      return UserSegment.lowValue;
    }
  }

  /// Get inventory level based on stock count
  InventoryLevel _getInventoryLevel(int stock) {
    if (stock < 5) {
      return InventoryLevel.critical;
    } else if (stock < 30) {
      return InventoryLevel.low;
    } else if (stock < 100) {
      return InventoryLevel.normal;
    } else {
      return InventoryLevel.abundant;
    }
  }

  /// Get time-based price adjustment
  /// Returns (adjustment percentage, reason)
  (double, String) _getTimePriceAdjustment() {
    final hour = DateTime.now().hour;
    final isWeekend = [5, 6].contains(DateTime.now().weekday);

    // Peak hours: 6pm-9pm (expensive delivery)
    if (hour >= 18 && hour <= 21) {
      return (10.0, 'Peak ordering hours (6pm-9pm): +10%');
    }

    // Off-peak hours: midnight-6am (encourage off-peak orders)
    if (hour >= 0 && hour < 6) {
      return (-5.0, 'Off-peak hours midnight-6am: -5%');
    }

    // Weekend premium
    if (isWeekend && hour >= 12 && hour < 18) {
      return (5.0, 'Weekend afternoon demand: +5%');
    }

    // Normal hours: standard pricing
    return (0.0, 'Standard hours');
  }

  /// Generate readable pricing reason
  String _generatePricingReason(
    UserSegment? segment,
    InventoryLevel inventory,
    List<PricingComponent> components,
  ) {
    final reasons = <String>[];

    if (segment != null) {
      reasons.add('Your segment: ${segment.displayName}');
    }

    reasons.add('Stock level: ${inventory.displayName}');

    if (components.isNotEmpty) {
      final totalAdjustment =
          components.fold<double>(0, (s, c) => s + c.percentageChange);
      if (totalAdjustment > 0) {
        reasons.add('Total markup: +${totalAdjustment.toStringAsFixed(1)}%');
      } else if (totalAdjustment < 0) {
        reasons.add('Total discount: ${totalAdjustment.toStringAsFixed(1)}%');
      }
    }

    return reasons.join(' • ');
  }

  /// Analyze pricing effectiveness (for analytics)
  Future<Map<String, dynamic>> analyzePricingMetrics({
    required String productId,
    int daysBack = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: daysBack));

      // Get orders for this product
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
          .get();

      int salesCount = 0;
      double totalRevenue = 0;
      final pricePoints = <double>[];

      for (var orderDoc in ordersSnapshot.docs) {
        final items = orderDoc['items'] as List? ?? [];
        for (var item in items) {
          if (item['productId'] == productId) {
            salesCount++;
            final price = (item['price'] as num?)?.toDouble() ?? 0;
            final quantity = (item['quantity'] as int?) ?? 1;
            totalRevenue += price * quantity;
            pricePoints.add(price);
          }
        }
      }

      // Calculate statistics
      final avgPrice =
          salesCount > 0 ? totalRevenue / salesCount.toDouble() : 0.0;
      final priceVariation = salesCount > 1
          ? _calculateStandardDeviation(pricePoints) / avgPrice * 100
          : 0.0;

      return {
        'productId': productId,
        'salesCount': salesCount,
        'totalRevenue': totalRevenue,
        'averagePrice': avgPrice,
        'priceVariation': priceVariation,
        'daysAnalyzed': daysBack,
        'recommendation': _getPricingRecommendation(
          salesCount,
          totalRevenue,
          priceVariation,
        ),
      };
    } catch (e) {
      debugPrint('❌ Failed to analyze pricing metrics: $e');
      return {};
    }
  }

  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.fold(0.0, (a, b) => a + b) / values.length;
    final variance = values
            .map((x) => pow(x - mean, 2).toDouble())
            .fold(0.0, (a, b) => a + b) /
        values.length;
    return sqrt(variance).toDouble();
  }

  String _getPricingRecommendation(
    int salesCount,
    double totalRevenue,
    double priceVariation,
  ) {
    if (salesCount < 5) {
      return 'Not enough data for recommendation (< 5 sales)';
    }

    if (priceVariation > 20) {
      return 'High price variation suggests volatile demand - consider stabilizing prices';
    }

    if (salesCount > 50 && totalRevenue > 50000) {
      return 'Strong sales - consider increasing prices to maximize profit';
    }

    if (salesCount < 10) {
      return 'Low sales volume - consider discount promotions to boost demand';
    }

    return 'Current pricing appears optimal - maintain status quo';
  }

  /// Get suggested promotional pricing
  Future<Map<String, dynamic>> getSuggestedPromotion({
    required String productId,
    required double basePrice,
    required int currentStock,
  }) async {
    try {
      // Get inventory level
      final inventoryLevel = _getInventoryLevel(currentStock);

      // Get sales trend
      final analyzeResult = await analyzePricingMetrics(productId: productId);
      final salesCount = ((analyzeResult['salesCount'] as num?)?.toInt() ?? 0);

      // Suggest promotion based on situation
      if (inventoryLevel == InventoryLevel.abundant && salesCount < 20) {
        return {
          'promotionType': 'clearance',
          'suggestedDiscount': 20.0,
          'reason': 'High stock + low sales - aggressive clearance needed',
          'suggestedPrice': basePrice * 0.8,
        };
      } else if (inventoryLevel == InventoryLevel.critical) {
        return {
          'promotionType': 'scarcity',
          'suggestedDiscount': -15.0, // Price increase
          'reason': 'Critical stock levels - increase price to manage demand',
          'suggestedPrice': basePrice * 1.15,
        };
      } else if (salesCount > 50) {
        return {
          'promotionType': 'loyalty',
          'suggestedDiscount': 5.0,
          'reason': 'High sales volume - loyalty discount to retain customers',
          'suggestedPrice': basePrice * 0.95,
        };
      } else {
        return {
          'promotionType': 'none',
          'suggestedDiscount': 0.0,
          'reason': 'Current pricing appears optimal',
          'suggestedPrice': basePrice,
        };
      }
    } catch (e) {
      debugPrint('❌ Failed to get suggested promotion: $e');
      return {
        'promotionType': 'none',
        'suggestedDiscount': 0.0,
        'reason': 'Unable to analyze',
        'suggestedPrice': basePrice,
      };
    }
  }
}
