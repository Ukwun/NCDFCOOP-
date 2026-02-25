import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/core/providers/recommendation_providers.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Widget to display personalized recommendations
class PersonalizedRecommendationsSection extends ConsumerWidget {
  const PersonalizedRecommendationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(personalizedRecommendationsProvider);

    return recommendations.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recommended For You', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Based on your shopping activity',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Horizontal scrolling list of recommendations
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final recommendation = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: RecommendationCard(
                      recommendation: recommendation,
                      onTap: () {
                        // Track the recommendation click
                        ref.read(recommendationServiceProvider).then((service) {
                          service.recordRecommendationClick(
                            productId: recommendation.product.id,
                            recommendationType: recommendation.type,
                          );
                        });

                        // Navigate to product detail
                        context.push(
                          '/product/${recommendation.product.id}',
                          extra: recommendation.product,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended For You', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended For You', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 280,
              child: Center(child: Text('Could not load recommendations: $err')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual recommendation card
class RecommendationCard extends StatelessWidget {
  final dynamic recommendation; // RecommendedProduct
  final VoidCallback onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.smList,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  topRight: Radius.circular(AppRadius.md),
                ),
                image: recommendation.product.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(recommendation.product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: recommendation.product.imageUrl == null
                  ? Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
                    )
                  : null,
            ),

            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      recommendation.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Category
                    Text(
                      recommendation.product.category,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),

                    const Spacer(),

                    // Price and recommendation badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Text(
                          '\$${recommendation.product.regularPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),

                        // Recommendation reason badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getRecommendationColor(recommendation.type),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getRecommendationLabel(recommendation.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRecommendationColor(String type) {
    switch (type) {
      case 'trending':
        return Colors.red;
      case 'category':
        return Colors.blue;
      case 'similar':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRecommendationLabel(String type) {
    switch (type) {
      case 'trending':
        return 'Trending';
      case 'category':
        return 'Your Category';
      case 'similar':
        return 'Similar';
      default:
        return 'For You';
    }
  }
}

/// Widget to display trending products (alternative view)
class TrendingProductsRecommendations extends ConsumerWidget {
  const TrendingProductsRecommendations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingProducts = ref.watch(trendingProductsProvider);

    return trendingProducts.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trending Today', style: AppTextStyles.h3),
                  Text(
                    'What everyone is buying',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final recommendation = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: RecommendationCard(
                      recommendation: recommendation,
                      onTap: () {
                        // Track the trending click
                        ref.read(recommendationServiceProvider).then((service) {
                          service.recordRecommendationClick(
                            productId: recommendation.product.id,
                            recommendationType: recommendation.type,
                          );
                        });

                        context.push(
                          '/product/${recommendation.product.id}',
                          extra: recommendation.product,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trending Today', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
