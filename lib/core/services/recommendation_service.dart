import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/models/real_product_model.dart';
import 'package:coop_commerce/core/services/activity_tracking_service.dart';
import 'package:coop_commerce/core/services/products_service.dart';

/// User behavior model for recommendations
class UserBehaviorProfile {
  final String userId;
  final List<String> viewedProductIds;
  final List<String> purchasedProductIds;
  final List<String> favoriteCategories;
  final Map<String, int> categoryViewCount;
  final DateTime lastActive;
  final int totalProductViews;
  final int totalPurchases;

  UserBehaviorProfile({
    required this.userId,
    required this.viewedProductIds,
    required this.purchasedProductIds,
    required this.favoriteCategories,
    required this.categoryViewCount,
    required this.lastActive,
    required this.totalProductViews,
    required this.totalPurchases,
  });
}

/// Product recommendation with score
class RecommendedProduct {
  final Product product;
  final double score;
  final String reason; // Why recommended
  final String type; // 'viewed', 'category', 'trending', 'similar'

  RecommendedProduct({
    required this.product,
    required this.score,
    required this.reason,
    required this.type,
  });
}

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final ProductsService _productsService = ProductsService();
  final ActivityTrackingService _activityService = ActivityTrackingService();

  /// Get personalized recommendations for user
  Future<List<RecommendedProduct>> getPersonalizedRecommendations({
    int limit = 10,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in for recommendations');
        return [];
      }

      debugPrint('🎯 Generating personalized recommendations for ${user.uid}');

      // Get user behavior profile
      final userProfile = await _getUserBehaviorProfile(user.uid);
      if (userProfile == null) {
        debugPrint('⚠️ No user behavior data available');
        return _getTrendingRecommendations(limit);
      }

      // Get all products
      final allProducts = await _productsService.getAllProducts();

      // Generate recommendations using multiple strategies
      final recommendations = <RecommendedProduct>{};

      // Strategy 1: Category-based (user's favorite categories)
      recommendations.addAll(
        await _getCategoryBasedRecommendations(
          userProfile.favoriteCategories,
          allProducts,
          userProfile.viewedProductIds,
        ),
      );

      // Strategy 2: Similar to viewed products (often bought together)
      recommendations.addAll(
        await _getSimilarProductRecommendations(
          userProfile.viewedProductIds,
          allProducts,
          userProfile.viewedProductIds,
        ),
      );

      // Strategy 3: Trending products (what others are buying)
      recommendations.addAll(
        await _getTrendingBasedRecommendations(
          allProducts,
          userProfile.purchasedProductIds,
        ),
      );

      // Sort by score and return top N
      final sortedRecommendations = recommendations.toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      debugPrint(
        '✅ Generated ${sortedRecommendations.length} recommendations',
      );
      return sortedRecommendations.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error generating recommendations: $e');
      return [];
    }
  }

  /// Get trending products (most viewed/purchased recently)
  Future<List<RecommendedProduct>> _getTrendingBasedRecommendations(
    List<Product> allProducts,
    List<String> userPurchasedIds,
  ) async {
    try {
      debugPrint('📊 Fetching trending recommendations...');

      // Query trending products from analytics
      final snapshot = await _firestore
          .collection('user_activities_analytics')
          .where('activityType', isEqualTo: 'productView')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      // Count views by product
      final viewCounts = <String, int>{};
      for (var doc in snapshot.docs) {
        final productId = doc.get('productId') as String?;
        if (productId != null) {
          viewCounts[productId] = (viewCounts[productId] ?? 0) + 1;
        }
      }

      // Map to products
      final recommendations = <RecommendedProduct>[];
      for (final entry in viewCounts.entries) {
        // Skip products user already purchased
        if (userPurchasedIds.contains(entry.key)) continue;

        final product = allProducts.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => Product(
            id: '',
            name: 'Unknown Product',
            description: '',
            category: 'Other',
            regularPrice: 0,
          ),
        );

        if (product.id.isNotEmpty) {
          // Score: based on view count
          final score = (entry.value * 10).toDouble();
          recommendations.add(
            RecommendedProduct(
              product: product,
              score: score,
              reason: '${entry.value} users viewed this',
              type: 'trending',
            ),
          );
        }
      }

      debugPrint('✅ Found ${recommendations.length} trending products');
      return recommendations;
    } catch (e) {
      debugPrint('❌ Error getting trending: $e');
      return [];
    }
  }

  /// Get category-based recommendations
  Future<List<RecommendedProduct>> _getCategoryBasedRecommendations(
    List<String> userCategories,
    List<Product> allProducts,
    List<String> viewedIds,
  ) async {
    try {
      debugPrint('🏷️ Fetching category-based recommendations...');

      final recommendations = <RecommendedProduct>[];

      for (final category in userCategories) {
        final categoryProducts = allProducts
            .where((p) => p.category == category && !viewedIds.contains(p.id))
            .toList();

        for (final product in categoryProducts.take(3)) {
          recommendations.add(
            RecommendedProduct(
              product: product,
              score: 50.0,
              reason: 'You like $category products',
              type: 'category',
            ),
          );
        }
      }

      debugPrint('✅ Found ${recommendations.length} category recommendations');
      return recommendations;
    } catch (e) {
      debugPrint('❌ Error getting category recommendations: $e');
      return [];
    }
  }

  /// Get similar products to ones user viewed
  Future<List<RecommendedProduct>> _getSimilarProductRecommendations(
    List<String> viewedIds,
    List<Product> allProducts,
    List<String> excludeIds,
  ) async {
    try {
      debugPrint('🔗 Fetching similar product recommendations...');

      final recommendations = <RecommendedProduct>[];
      final processedProductIds = <String>{};

      // For each viewed product, find similar ones
      for (final viewedId in viewedIds.take(5)) {
        final viewedProduct = allProducts.firstWhere(
          (p) => p.id == viewedId,
          orElse: () => Product(
            id: '',
            name: 'Unknown Product',
            description: '',
            category: 'Other',
            regularPrice: 0,
          ),
        );

        if (viewedProduct.id.isNotEmpty) {
          // Find products in same category
          final similar = allProducts
              .where((p) =>
                  p.category == viewedProduct.category &&
                  !excludeIds.contains(p.id) &&
                  !processedProductIds.contains(p.id))
              .take(2);

          for (final product in similar) {
            processedProductIds.add(product.id);
            recommendations.add(
              RecommendedProduct(
                product: product,
                score: 30.0,
                reason: 'Similar to ${viewedProduct.name}',
                type: 'similar',
              ),
            );
          }
        }
      }

      debugPrint('✅ Found ${recommendations.length} similar products');
      return recommendations;
    } catch (e) {
      debugPrint('❌ Error getting similar recommendations: $e');
      return [];
    }
  }

  /// Get trending products (fallback when no user data)
  Future<List<RecommendedProduct>> _getTrendingRecommendations(
      int limit) async {
    try {
      debugPrint('⭐ Fetching trending products as fallback...');

      final products = await _productsService.getAllProducts();
      final recommendations = products
          .take(limit)
          .map((product) => RecommendedProduct(
                product: product,
                score: 50.0,
                reason: 'Popular right now',
                type: 'trending',
              ))
          .toList();

      return recommendations;
    } catch (e) {
      debugPrint('❌ Error getting trending: $e');
      return [];
    }
  }

  /// Build user behavior profile from activity history
  Future<UserBehaviorProfile?> _getUserBehaviorProfile(String userId) async {
    try {
      final activities = await _activityService.getUserActivityHistory(
        userId: userId,
        limit: 500,
      );

      if (activities.isEmpty) {
        return null;
      }

      final viewedProducts = <String>{};
      final purchasedProducts = <String>{};
      final categoryViews = <String, int>{};

      for (final activity in activities) {
        // Use activity.type instead of activityType
        if (activity.productId != null) {
          if (activity.type == ActivityType.productView) {
            viewedProducts.add(activity.productId!);
          } else if (activity.type == ActivityType.purchase) {
            purchasedProducts.add(activity.productId!);
          }

          // Extract category from metadata if available
          final category = activity.metadata?['category'] as String?;
          if (category != null) {
            categoryViews[category] = (categoryViews[category] ?? 0) + 1;
          }
        }
      }

      // Get top 5 favorite categories
      final sortedCategories = categoryViews.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final favoriteCategories =
          sortedCategories.take(5).map((e) => e.key).toList();

      return UserBehaviorProfile(
        userId: userId,
        viewedProductIds: viewedProducts.toList(),
        purchasedProductIds: purchasedProducts.toList(),
        favoriteCategories: favoriteCategories,
        categoryViewCount: categoryViews,
        lastActive: DateTime.now(),
        totalProductViews: viewedProducts.length,
        totalPurchases: purchasedProducts.length,
      );
    } catch (e) {
      debugPrint('❌ Error building user profile: $e');
      return null;
    }
  }

  /// Save recommendation click for analytics
  Future<void> recordRecommendationClick({
    required String productId,
    required String recommendationType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('recommendation_analytics').add({
        'userId': user.uid,
        'productId': productId,
        'type': recommendationType,
        'timestamp': Timestamp.now(),
      });

      debugPrint('✅ Recommendation click recorded');
    } catch (e) {
      debugPrint('❌ Error recording recommendation click: $e');
    }
  }

  /// Get personalized recommendations from Cloud Function
  /// This uses the backend intelligence engine with multi-factor analysis
  Future<List<RecommendedProduct>> getCloudFunctionRecommendations({
    int limit = 10,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in for recommendations');
        return [];
      }

      debugPrint('🚀 Fetching cloud-based recommendations for ${user.uid}');

      // Call Cloud Function for intelligent recommendations
      final response = await FirebaseFunctions.instance
          .httpsCallable('getRecommendedProducts')
          .call({
        'limit': limit,
      });

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        debugPrint('⚠️ No recommendations returned from Cloud Function');
        return _getTrendingRecommendations(limit);
      }

      final recommendationsList = (data['recommendations'] as List?) ?? [];
      if (recommendationsList.isEmpty) {
        debugPrint('⚠️ Empty recommendations list from Cloud Function');
        return _getTrendingRecommendations(limit);
      }

      // Convert to RecommendedProduct objects
      final allProducts = await _productsService.getAllProducts();
      final recommendations = <RecommendedProduct>[];

      for (var item in recommendationsList) {
        try {
          final productId = item['id'] as String?;
          final reason = item['reason'] as String? ?? 'Recommended for you';
          final score = (item['score'] as num?)?.toDouble() ?? 0.8;

          if (productId == null) continue;

          final product = allProducts.firstWhere(
            (p) => p.id == productId,
            orElse: () => Product(
              id: productId,
              name: item['name'] ?? 'Unknown',
              category: 'Recommended',
              description: reason,
              regularPrice: (item['price'] as num?)?.toDouble() ?? 0.0,
              imageUrl: null,
            ),
          );

          recommendations.add(RecommendedProduct(
            product: product,
            score: score,
            reason: reason,
            type: 'cloud_recommendation',
          ));
        } catch (e) {
          debugPrint('⚠️ Error parsing recommendation: $e');
          continue;
        }
      }

      debugPrint(
          '✅ Got ${recommendations.length} recommendations from Cloud Function');
      return recommendations;
    } catch (e) {
      debugPrint('⚠️ Cloud Function call failed (falling back to local): $e');
      // Fallback to local recommendations
      return getPersonalizedRecommendations(limit: limit);
    }
  }
}
