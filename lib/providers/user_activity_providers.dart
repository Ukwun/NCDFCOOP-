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

/// Real-time user activity timeline
final userActivityTimelineProvider =
    StreamProvider.family<List<UserActivity>, String>(
  (ref, userId) {
    final service = ref.watch(userActivityServiceProvider);
    return service.watchUserActivity(userId: userId, limit: 200);
  },
);

/// Real-time global activity stream for admin observability
final globalActivityTimelineProvider = StreamProvider<List<UserActivity>>(
  (ref) {
    final service = ref.watch(userActivityServiceProvider);
    return service.watchGlobalActivity(limit: 1000);
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

/// Role-level activity summary for admin analytics surfaces.
final roleBehaviorSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, role) async {
    final service = ref.watch(userActivityServiceProvider);
    return service.getRoleBehaviorSummary(role: role, days: 7);
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

  Future<void> logCheckoutStarted({
    required double cartTotal,
    required int itemCount,
    String? paymentMethod,
  }) =>
      _service.logCheckoutStarted(
        cartTotal: cartTotal,
        itemCount: itemCount,
        paymentMethod: paymentMethod,
      );

  Future<void> logPaymentResult({
    required String orderId,
    required bool success,
    required double amount,
    required String paymentMethod,
    String? errorMessage,
  }) =>
      _service.logPaymentResult(
        orderId: orderId,
        success: success,
        amount: amount,
        paymentMethod: paymentMethod,
        errorMessage: errorMessage,
      );

  Future<void> logFollowSeller({
    required String sellerId,
    String? sellerName,
  }) =>
      _service.logFollowSeller(
        sellerId: sellerId,
        sellerName: sellerName,
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

  /// Log membership purchase activity.
  Future<void> logMembershipPurchase(String membershipType, double amount) =>
      _service.logMembershipPurchase(
        membershipType: membershipType,
        amount: amount,
      );

  /// Log authentication sign-in.
  Future<void> logLogin(String email) => _service.logLogin(method: 'email');

  /// Log authentication sign-out.
  Future<void> logLogout() => _service.logLogout(reason: 'user_initiated');

  Future<void> logScreenView({
    required String screenName,
    String? route,
  }) =>
      _service.logScreenView(screenName: screenName, route: route);

  Future<void> logButtonTap({
    required String buttonName,
    String? screenName,
    String? context,
    bool? success,
  }) =>
      _service.logButtonTap(
        buttonName: buttonName,
        screenName: screenName,
        context: context,
        success: success,
      );
}

/// Activity logger notifier provider
final activityLoggerProvider = NotifierProvider<ActivityLoggerNotifier, void>(
  ActivityLoggerNotifier.new,
);
