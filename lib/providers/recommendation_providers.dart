import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/recommendation_service.dart';

/// Recommendation service provider (singleton)
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService();
});

/// Get personalized recommendations for current user
final personalizedRecommendationsProvider =
    FutureProvider<List<RecommendedProduct>>((ref) async {
  final service = ref.watch(recommendationServiceProvider);
  // Use Cloud Function for intelligent recommendations with fallback
  return await service.getCloudFunctionRecommendations(limit: 10);
});

/// Watch recommendations with auto-refresh
final recommendationsStreamProvider =
    StreamProvider<List<RecommendedProduct>>((ref) async* {
  final service = ref.watch(recommendationServiceProvider);

  // Get initial recommendations
  final initial = await service.getPersonalizedRecommendations(limit: 10);
  yield initial;

  // Refresh every 5 minutes
  while (true) {
    await Future.delayed(const Duration(minutes: 5));
    final updated = await service.getPersonalizedRecommendations(limit: 10);
    yield updated;
  }
});

/// Get trending products specifically
final trendingProductsProvider =
    FutureProvider<List<RecommendedProduct>>((ref) async {
  final service = ref.watch(recommendationServiceProvider);

  // Get all products first
  final allRecommendations =
      await service.getPersonalizedRecommendations(limit: 20);

  // Filter for trending type
  return allRecommendations.where((r) => r.type == 'trending').toList();
});

/// Track when user clicks a recommendation
Future<void> trackRecommendationClick(
  WidgetRef ref,
  String productId,
  String recommendationType,
) async {
  final service = ref.read(recommendationServiceProvider);
  await service.recordRecommendationClick(
    productId: productId,
    recommendationType: recommendationType,
  );
}
