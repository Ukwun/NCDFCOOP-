import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/user_activity_service.dart';

/// Provider for user activity service (singleton)
final userActivityServiceProvider = Provider<UserActivityService>((ref) {
  return UserActivityService();
});

/// Watch user's activity history
final userActivityHistoryProvider =
    FutureProvider.family<List<UserActivity>, String>(
  (ref, userId) async {
    final service = ref.watch(userActivityServiceProvider);
    return service.getUserActivityHistory(userId: userId);
  },
);

/// Watch user's today's behavior summary
final todayBehaviorSummaryProvider =
    FutureProvider.family<UserBehaviorSummary?, String>(
  (ref, userId) async {
    final service = ref.watch(userActivityServiceProvider);
    return service.getTodayBehaviorSummary(userId);
  },
);

/// Get recommended products for user
final userRecommendedProductsProvider =
    FutureProvider.family<List<String>, String>(
  (ref, userId) async {
    final service = ref.watch(userActivityServiceProvider);
    return service.getRecommendedProducts(userId: userId);
  },
);

/// Get user's favorite categories
final userFavoriteCategoriesProvider =
    FutureProvider.family<List<String>, String>(
  (ref, userId) async {
    final service = ref.watch(userActivityServiceProvider);
    return service.getFavoriteCategories(userId);
  },
);

/// Activity logging operations
class ActivityLoggerNotifier extends Notifier<void> {
  late UserActivityService _service;

  @override
  void build() {
    _service = ref.watch(userActivityServiceProvider);
  }

  Future<void> logProductView({
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) =>
      _service.logProductView(
        productId: productId,
        productName: productName,
        category: category,
        price: price,
      );

  Future<void> logSearch({
    required String query,
    required int resultsCount,
    String? category,
  }) =>
      _service.logSearch(
        query: query,
        resultsCount: resultsCount,
        category: category,
      );

  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required int quantity,
  }) =>
      _service.logAddToCart(
        productId: productId,
        productName: productName,
        category: category,
        price: price,
        quantity: quantity,
      );

  Future<void> logPurchase({
    required String orderId,
    required List<String> productIds,
    required List<String> productNames,
    required double totalAmount,
    required List<String> categories,
  }) =>
      _service.logPurchase(
        orderId: orderId,
        productIds: productIds,
        productNames: productNames,
        totalAmount: totalAmount,
        categories: categories,
      );

  Future<void> logAddToWishlist({
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) =>
      _service.logAddToWishlist(
        productId: productId,
        productName: productName,
        category: category,
        price: price,
      );

  Future<void> logProductReview({
    required String productId,
    required String productName,
    required String category,
    required double rating,
    required String reviewText,
  }) =>
      _service.logProductReview(
        productId: productId,
        productName: productName,
        category: category,
        rating: rating,
        reviewText: reviewText,
      );

  /// Stub method for membership purchase logging
  Future<void> logMembershipPurchase(
      String membershipType, double amount) async {
    // TODO: Implement membership purchase logging
    debugPrint('📊 Membership purchase logged: $membershipType for ₦$amount');
  }

  /// Stub method for login logging
  Future<void> logLogin(String email) async {
    // TODO: Implement login logging
    debugPrint('📊 Login logged for: $email');
  }

  /// Stub method for logout logging
  Future<void> logLogout() async {
    // TODO: Implement logout logging
    debugPrint('📊 Logout logged');
  }
}

/// Activity logger notifier provider
final activityLoggerProvider = NotifierProvider<ActivityLoggerNotifier, void>(
  ActivityLoggerNotifier.new,
);
