import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/comprehensive_event_tracker.dart';
import 'package:coop_commerce/core/services/order_intelligence_service.dart';
import 'package:coop_commerce/core/services/dynamic_pricing_engine.dart';
import 'package:coop_commerce/core/services/personalization_engine.dart';
import 'package:coop_commerce/models/product_model.dart';

/// ============================================================================
/// ACTIVITY TRACKING PROVIDERS
/// ============================================================================

/// Singleton instance of the event tracker
final eventTrackerProvider = Provider<ComprehensiveEventTracker>((ref) {
  return ComprehensiveEventTracker();
});

/// Track product view
final trackProductViewedProvider = FutureProvider.family<
    void,
    ({
      String productId,
      String productName,
      String? category,
      double? price,
    })>((ref, params) async {
  final tracker = ref.watch(eventTrackerProvider);
  await tracker.trackProductViewed(
    productId: params.productId,
    productName: params.productName,
    category: params.category,
    price: params.price,
  );
});

/// Track cart addition
final trackAddedToCartProvider = FutureProvider.family<
    void,
    ({
      String productId,
      String productName,
      int quantity,
      double price,
    })>((ref, params) async {
  final tracker = ref.watch(eventTrackerProvider);
  await tracker.trackAddedToCart(
    productId: params.productId,
    productName: params.productName,
    quantity: params.quantity,
    price: params.price,
  );
});

/// Track checkout started
final trackCheckoutStartedProvider = FutureProvider.family<
    void,
    ({
      double cartTotal,
      int itemCount,
    })>((ref, params) async {
  final tracker = ref.watch(eventTrackerProvider);
  await tracker.trackCheckoutStarted(
    cartTotal: params.cartTotal,
    itemCount: params.itemCount,
  );
});

/// Track order placed
final trackOrderPlacedProvider = FutureProvider.family<
    void,
    ({
      String orderId,
      double orderValue,
      List<String> productIds,
    })>((ref, params) async {
  final tracker = ref.watch(eventTrackerProvider);
  await tracker.trackOrderPlaced(
    orderId: params.orderId,
    orderValue: params.orderValue,
    productIds: params.productIds,
  );
});

/// Track screen viewed
final trackScreenViewedProvider =
    FutureProvider.family<void, String>((ref, screenName) async {
  final tracker = ref.watch(eventTrackerProvider);
  await tracker.trackScreenViewed(screenName: screenName);
});

/// ============================================================================
/// ORDER INTELLIGENCE PROVIDERS
/// ============================================================================

/// Singleton instance of order intelligence
final orderIntelligenceProvider = Provider<OrderIntelligenceService>((ref) {
  return OrderIntelligenceService();
});

/// Get user churn analysis
final userChurnAnalysisProvider =
    FutureProvider.family<UserChurnAnalysis, String>((ref, userId) async {
  final intelligence = ref.watch(orderIntelligenceProvider);
  return intelligence.analyzeChurnRisk(userId: userId);
});

/// Get delivery time prediction
final deliveryPredictionProvider = FutureProvider.family<
    DeliveryPrediction,
    ({
      String orderId,
      double latitude,
      double longitude,
    })>((ref, params) async {
  final intelligence = ref.watch(orderIntelligenceProvider);
  return intelligence.predictDeliveryTime(
    orderId: params.orderId,
    latitude: params.latitude,
    longitude: params.longitude,
  );
});

/// Get demand forecast
final demandForecastProvider = FutureProvider.family<
    DemandForecast,
    ({
      String productId,
      String productName,
    })>((ref, params) async {
  final intelligence = ref.watch(orderIntelligenceProvider);
  return intelligence.forecastDemand(
    productId: params.productId,
    productName: params.productName,
  );
});

/// Get driver assignment recommendations
final driverRecommendationsProvider = FutureProvider.family<
    List<DriverAssignmentRecommendation>,
    ({
      String orderId,
      double latitude,
      double longitude,
    })>((ref, params) async {
  final intelligence = ref.watch(orderIntelligenceProvider);
  return intelligence.recommendDrivers(
    orderId: params.orderId,
    latitude: params.latitude,
    longitude: params.longitude,
  );
});

/// ============================================================================
/// DYNAMIC PRICING PROVIDERS
/// ============================================================================

/// Singleton instance of dynamic pricing engine
final dynamicPricingProvider = Provider<DynamicPricingEngine>((ref) {
  return DynamicPricingEngine();
});

/// Calculate dynamic price for a product
final dynamicPriceProvider = FutureProvider.family<
    DynamicPrice,
    ({
      String productId,
      double basePrice,
      int currentStock,
      String? userId,
    })>((ref, params) async {
  final pricing = ref.watch(dynamicPricingProvider);
  return pricing.calculateDynamicPrice(
    productId: params.productId,
    basePrice: params.basePrice,
    currentStock: params.currentStock,
    userId: params.userId,
  );
});

/// Get pricing metrics analysis
final pricingMetricsProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({
      String productId,
      int daysBack,
    })>((ref, params) async {
  final pricing = ref.watch(dynamicPricingProvider);
  return pricing.analyzePricingMetrics(
    productId: params.productId,
    daysBack: params.daysBack,
  );
});

/// Get suggested promotion
final suggestedPromotionProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({
      String productId,
      double basePrice,
      int currentStock,
    })>((ref, params) async {
  final pricing = ref.watch(dynamicPricingProvider);
  return pricing.getSuggestedPromotion(
    productId: params.productId,
    basePrice: params.basePrice,
    currentStock: params.currentStock,
  );
});

/// ============================================================================
/// PERSONALIZATION & RECOMMENDATION PROVIDERS
/// ============================================================================

/// Singleton instance of personalization engine
final personalizationProvider = Provider<PersonalizationEngine>((ref) {
  return PersonalizationEngine();
});

/// Get personalized recommendations for user
final personalizedRecommendationsProvider =
    FutureProvider<List<PersonalizedRecommendation>>((ref) async {
  final personalization = ref.watch(personalizationProvider);
  return personalization.getPersonalizedRecommendations(limit: 10);
});

/// Get similar products
final similarProductsProvider =
    FutureProvider.family<List<PersonalizedRecommendation>, String>(
        (ref, productId) async {
  final personalization = ref.watch(personalizationProvider);
  return personalization.getSimilarProducts(productId: productId);
});

/// Get abandoned cart products
final abandonedCartProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, userId) async {
  final personalization = ref.watch(personalizationProvider);
  return personalization.getAbandonedCartProducts(userId: userId);
});

/// Get notification-worthy products
final notificationWorthyProductsProvider =
    FutureProvider.family<List<PersonalizedRecommendation>, String>(
        (ref, userId) async {
  final personalization = ref.watch(personalizationProvider);
  return personalization.getNotificationWorthyProducts(userId: userId);
});

/// ============================================================================
/// COMBINED INTELLIGENCE PROVIDERS (for convenience)
/// ============================================================================

/// Get complete user intelligence snapshot
final userIntelligenceSnapshotProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  try {
    // Get churn analysis
    final churnAnalysis =
        await ref.watch(userChurnAnalysisProvider(userId).future);

    return {
      'userId': userId,
      'churnAnalysis': {
        'riskLevel': churnAnalysis.riskLevel.displayName,
        'daysSinceLastActivity': churnAnalysis.daysSinceLastActivity,
        'totalOrders': churnAnalysis.totalOrders,
        'totalSpent': churnAnalysis.totalSpent,
        'averageOrderValue': churnAnalysis.averageOrderValue,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {
      'error': 'Failed to load intelligence snapshot',
      'details': e.toString(),
    };
  }
});

/// Provider for checking if personalized recommendations are loading
final isLoadingRecommendationsProvider = FutureProvider<bool>((ref) async {
  ref.watch(personalizedRecommendationsProvider);
  return false; // Returns false after recommendations load
});
