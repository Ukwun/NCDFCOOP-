import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics service for tracking user behavior, funnels, and custom events
/// Supports graceful degradation if Firebase is unavailable
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  late FirebaseAnalytics _analytics;

  factory AnalyticsService() => _instance;

  AnalyticsService._internal() {
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      print('Analytics initialization failed: $e');
    }
  }

  /// Track user signup completion
  /// Called after successful registration
  Future<void> trackSignup({
    required String userId,
    required String role,
    String? referralCode,
  }) async {
    try {
      await _analytics.logSignUp(signUpMethod: 'email');
      await _analytics.logEvent(
        name: 'user_signup_complete',
        parameters: {
          'user_role': role,
          'referral_code': referralCode ?? 'none',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track signup: $e');
    }
  }

  /// Track first purchase (critical funnel metric)
  /// Called after first successful order
  Future<void> trackFirstPurchase({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required List<String> productIds,
  }) async {
    try {
      await _analytics.logPurchase(
        currency: currency,
        value: amount,
        items: productIds
            .map((id) => AnalyticsEventItem(itemId: id, itemName: id))
            .toList(),
      );
      await _analytics.logEvent(
        name: 'first_purchase_complete',
        parameters: {
          'order_id': orderId,
          'amount': amount,
          'item_count': productIds.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track first purchase: $e');
    }
  }

  /// Track general purchase
  /// Called after every successful order
  Future<void> trackPurchase({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required List<String> productIds,
    required String orderType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'purchase_complete',
        parameters: {
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
          'item_count': productIds.length,
          'order_type': orderType, // 'retail', 'wholesale', 'institutional'
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track purchase: $e');
    }
  }

  /// Track product view
  /// Called when user opens product detail
  Future<void> trackProductView({
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) async {
    try {
      await _analytics.logViewItem(
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: productName,
            itemCategory: category,
            price: price,
          ),
        ],
      );
      await _analytics.logEvent(
        name: 'product_view',
        parameters: {
          'product_id': productId,
          'product_name': productName,
          'category': category,
          'price': price,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track product view: $e');
    }
  }

  /// Track cart addition
  /// Called when item added to cart
  Future<void> trackAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
  }) async {
    try {
      await _analytics.logAddToCart(
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: productName,
            price: price,
            quantity: quantity,
          ),
        ],
      );
    } catch (e) {
      print('Failed to track add to cart: $e');
    }
  }

  /// Track search queries
  /// Called after user searches
  Future<void> trackSearch({
    required String searchTerm,
    required int resultCount,
  }) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
      await _analytics.logEvent(
        name: 'product_search',
        parameters: {
          'search_term': searchTerm,
          'result_count': resultCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track search: $e');
    }
  }

  /// Track member tier progression
  /// Called when member reaches new tier
  Future<void> trackTierProgression({
    required String userId,
    required String newTier,
    required int totalPoints,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'tier_progression',
        parameters: {
          'new_tier': newTier,
          'total_points': totalPoints,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track tier progression: $e');
    }
  }

  /// Track loyalty points redemption
  /// Called when member redeems points
  Future<void> trackPointsRedeemed({
    required String userId,
    required int pointsRedeemed,
    required double discountValue,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'points_redeemed',
        parameters: {
          'points_amount': pointsRedeemed,
          'discount_value': discountValue,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track points redeemed: $e');
    }
  }

  /// Track PO creation (B2B)
  /// Called when institutional buyer creates PO
  Future<void> trackPOCreation({
    required String poId,
    required String buyerId,
    required double amount,
    required int itemCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'po_created',
        parameters: {
          'po_id': poId,
          'amount': amount,
          'item_count': itemCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track PO creation: $e');
    }
  }

  /// Track PO approval
  /// Called when approver approves PO
  Future<void> trackPOApproval({
    required String poId,
    required String approverId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'po_approved',
        parameters: {
          'po_id': poId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track PO approval: $e');
    }
  }

  /// Track app crash/error
  /// Called from error handler
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    required String screen,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage,
          'screen': screen,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Failed to track error: $e');
    }
  }

  /// Track screen view
  /// Called when navigating to new screen
  Future<void> trackScreenView({
    required String screenName,
  }) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      print('Failed to track screen view: $e');
    }
  }

  /// Get dashboard statistics for admin view
  /// Returns mock data for v1.0 (Firebase Analytics API integration in v1.1)
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // In v1.1, this will connect to Firebase Analytics API
      // For now, return mock data based on realistic projections
      return {
        'totalSignups': 1245,
        'signupsThisMonth': 387,
        'firstPurchaseConversion': 0.68, // 68%
        'averageOrderValue': 45000.0, // NGN
        'repeatCustomerRate': 0.42, // 42%
        'topSearchTerms': [
          {'term': 'rice', 'count': 1243},
          {'term': 'beans', 'count': 987},
          {'term': 'palm oil', 'count': 856},
        ],
        'topProducts': [
          {'productId': 'prod_001', 'views': 5432, 'purchases': 432},
          {'productId': 'prod_002', 'views': 4123, 'purchases': 287},
          {'productId': 'prod_003', 'views': 3891, 'purchases': 198},
        ],
        'conversionFunnel': {
          'productViews': 15432,
          'addToCart': 4521,
          'checkout': 2156,
          'purchase': 1456,
        },
        'memberTierDistribution': {
          'BASIC': 756,
          'SILVER': 243,
          'GOLD': 89,
          'PLATINUM': 12,
        },
        'poStats': {
          'totalCreated': 342,
          'totalApproved': 289,
          'averageAmount': 125000.0,
          'approvalRate': 0.845,
        },
        'memberEngagement': {
          'pointsRedeemedThisMonth': 125000,
          'usersWithActivePoints': 487,
          'averagePointsPerUser': 2143,
        },
      };
    } catch (e) {
      print('Failed to get dashboard stats: $e');
      return {};
    }
  }

  /// Export analytics data for reporting
  /// Used by admins to download analytics
  Future<String> exportAnalyticsReport({
    required String dateRange,
    required List<String> metrics,
  }) async {
    try {
      // In v1.1, this will generate real reports from Firebase Analytics
      // For now, return mock CSV data
      final buffer = StringBuffer();
      buffer.writeln('Coop Commerce Analytics Report - $dateRange');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('');
      buffer.writeln('Metric,Value,Trend');

      for (String metric in metrics) {
        switch (metric) {
          case 'signups':
            buffer.writeln('User Signups,387,+12%');
            break;
          case 'revenue':
            buffer.writeln('Total Revenue,₦15,432,000,+8%');
            break;
          case 'orders':
            buffer.writeln('Total Orders,1456,+15%');
            break;
          case 'members':
            buffer.writeln('Active Members,1100,+5%');
            break;
          case 'pos':
            buffer.writeln('PO Created,287,+22%');
            break;
        }
      }

      return buffer.toString();
    } catch (e) {
      print('Failed to export analytics: $e');
      return '';
    }
  }
}

/// Riverpod provider for analytics service
final analyticsServiceProvider = Provider((ref) => AnalyticsService());
