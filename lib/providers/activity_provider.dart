import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/user_persistence.dart';
import 'user_activity_providers.dart' show activityLoggerProvider;

/// Provider for user activity log
final userActivityLogProvider = FutureProvider<List<ActivityLog>>((ref) async {
  return await UserPersistence.getActivityLog();
});

/// Provider for recent user activities (last 10)
final recentActivitiesProvider = FutureProvider<List<ActivityLog>>((ref) async {
  return await UserPersistence.getRecentActivities(limit: 10);
});

// activityLoggerProvider is now imported from user_activity_providers.dart

/// Helper class for logging activities (kept for reference)
class ActivityLogger {
  /// Log product view
  Future<void> logProductView(String productId, String productName) async {
    await UserPersistence.logActivity(
      type: 'view',
      productId: productId,
      productName: productName,
      metadata: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Log product added to cart
  Future<void> logAddToCart(
      String productId, String productName, double price) async {
    await UserPersistence.logActivity(
      type: 'cart_add',
      productId: productId,
      productName: productName,
      metadata: {'price': price, 'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Log product added to wishlist
  Future<void> logAddToWishlist(String productId, String productName) async {
    await UserPersistence.logActivity(
      type: 'wishlist',
      productId: productId,
      productName: productName,
      metadata: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Log purchase
  Future<void> logPurchase(
      String orderId, List<String> productIds, double totalAmount) async {
    await UserPersistence.logActivity(
      type: 'purchase',
      metadata: {
        'orderId': orderId,
        'productCount': productIds.length,
        'totalAmount': totalAmount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log login
  Future<void> logLogin(String email) async {
    await UserPersistence.logActivity(
      type: 'login',
      metadata: {'email': email, 'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Log logout
  Future<void> logLogout() async {
    await UserPersistence.logActivity(
      type: 'logout',
      metadata: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Log search
  Future<void> logSearch(String query, int resultsCount) async {
    await UserPersistence.logActivity(
      type: 'search',
      metadata: {
        'query': query,
        'resultsCount': resultsCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log membership purchase
  Future<void> logMembershipPurchase(String tier, double amount) async {
    await UserPersistence.logActivity(
      type: 'membership_purchase',
      metadata: {
        'tier': tier,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
