import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/models/product_model.dart';

/// Recommendation type and score
class PersonalizedRecommendation {
  final Product product;
  final double score; // 0-100
  final String
      type; // 'category_preference', 'trending', 'deal', 'churn_recovery', 'similar'
  final String reason;
  final bool isMustSee; // High priority recommendation

  PersonalizedRecommendation({
    required this.product,
    required this.score,
    required this.type,
    required this.reason,
    required this.isMustSee,
  });
}

/// Personalization & Churn Prevention Engine
/// Provides:
/// - Personalized recommendations based on user behavior
/// - Churn recovery recommendations
/// - "You might like" suggestions
/// - Trending products tailored to user segment
/// - Deal notifications for at-risk users
class PersonalizationEngine {
  static final PersonalizationEngine _instance =
      PersonalizationEngine._internal();
  late FirebaseFirestore _firestore;
  late firebase_auth.FirebaseAuth _auth;

  factory PersonalizationEngine() => _instance;

  PersonalizationEngine._internal() {
    _firestore = FirebaseFirestore.instance;
    _auth = firebase_auth.FirebaseAuth.instance;
  }

  /// Get personalized recommendations for logged-in user
  Future<List<PersonalizedRecommendation>> getPersonalizedRecommendations({
    int limit = 10,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in');
        return [];
      }

      final recommendations = <PersonalizedRecommendation>[];

      // Strategy 1: Category-based recommendations (highest priority)
      final categoryRecs = await _getCategoryBasedRecommendations(user.uid);
      recommendations.addAll(categoryRecs);

      // Strategy 2: Trending products (for discovery)
      final trendingRecs = await _getTrendingRecommendations();
      recommendations.addAll(trendingRecs);

      // Strategy 3: Deal recommendations (prices user likes)
      final dealRecs = await _getDealRecommendations(user.uid);
      recommendations.addAll(dealRecs);

      // Strategy 4: Churn recovery (if user at risk)
      final churnRecs = await _getChurnRecoveryRecommendations(user.uid);
      recommendations.addAll(churnRecs);

      // Sort by score and must-see flag
      recommendations.sort((a, b) {
        if (a.isMustSee && !b.isMustSee) return -1;
        if (!a.isMustSee && b.isMustSee) return 1;
        return b.score.compareTo(a.score);
      });

      // Remove duplicates and limit
      final seen = <String>{};
      final unique = <PersonalizedRecommendation>[];
      for (var rec in recommendations) {
        if (!seen.contains(rec.product.id)) {
          seen.add(rec.product.id);
          unique.add(rec);
          if (unique.length >= limit) break;
        }
      }

      return unique;
    } catch (e) {
      debugPrint('❌ Failed to get personalized recommendations: $e');
      return [];
    }
  }

  /// Get category-based recommendations
  Future<List<PersonalizedRecommendation>> _getCategoryBasedRecommendations(
    String userId,
  ) async {
    try {
      // Get user's viewed/purchased categories
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .where('eventType', whereIn: ['product_viewed', 'order_placed'])
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final categoryFrequency = <String, int>{};
      for (var doc in eventsSnapshot.docs) {
        final props = doc['properties'] as Map? ?? {};
        final category = props['category'] as String?;
        if (category != null) {
          categoryFrequency[category] = (categoryFrequency[category] ?? 0) + 1;
        }
      }

      // Get top 3 categories
      final topCategories = categoryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final favoriteCategories =
          topCategories.take(3).map((e) => e.key).toList();

      if (favoriteCategories.isEmpty) {
        return [];
      }

      // Get products from these categories
      final productsSnapshot = await _firestore
          .collection('products')
          .where('category', whereIn: favoriteCategories)
          .limit(10)
          .get();

      final recommendations = <PersonalizedRecommendation>[];

      for (var doc in productsSnapshot.docs) {
        if (doc.exists) {
          try {
            final product = Product.fromFirestore(doc);
            final categoryName = doc['category'] as String? ?? '';

            // Higher score if category matches user's most viewed
            double score = 75.0;
            if (categoryName == favoriteCategories.first) {
              score = 85.0;
            }

            recommendations.add(
              PersonalizedRecommendation(
                product: product,
                score: score,
                type: 'category_preference',
                reason: 'You have shown interest in $categoryName products',
                isMustSee: false,
              ),
            );
          } catch (e) {
            // Skip products that fail to parse
            continue;
          }
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('⚠️ Failed to get category recommendations: $e');
      return [];
    }
  }

  /// Get trending product recommendations
  Future<List<PersonalizedRecommendation>> _getTrendingRecommendations() async {
    try {
      // Get products with most views in last 7 days
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final eventsSnapshot = await _firestore
          .collection('events')
          .where('eventType', isEqualTo: 'product_viewed')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      // Count views per product
      final productViews = <String, int>{};
      for (var doc in eventsSnapshot.docs) {
        final props = doc['properties'] as Map? ?? {};
        final productId = props['productId'] as String?;
        if (productId != null) {
          productViews[productId] = (productViews[productId] ?? 0) + 1;
        }
      }

      // Get top 5 trending products
      final trendingProducts = productViews.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final recommendations = <PersonalizedRecommendation>[];

      for (var entry in trendingProducts.take(5)) {
        try {
          final productDoc =
              await _firestore.collection('products').doc(entry.key).get();

          if (productDoc.exists) {
            final product = Product.fromFirestore(productDoc);
            recommendations.add(
              PersonalizedRecommendation(
                product: product,
                score: 70.0,
                type: 'trending',
                reason:
                    'Trending now - ${entry.value} people viewed this this week',
                isMustSee: false,
              ),
            );
          }
        } catch (e) {
          continue;
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('⚠️ Failed to get trending recommendations: $e');
      return [];
    }
  }

  /// Get deal recommendations (products at discounts user might like)
  Future<List<PersonalizedRecommendation>> _getDealRecommendations(
    String userId,
  ) async {
    try {
      // Get user's price sensitivity (average order value)
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .limit(10)
          .get();

      if (ordersSnapshot.docs.isEmpty) {
        return [];
      }

      double avgOrderValue = 0;
      for (var doc in ordersSnapshot.docs) {
        avgOrderValue += (doc['totalAmount'] as num?)?.toDouble() ?? 0;
      }
      avgOrderValue /= ordersSnapshot.docs.length;

      // Find products in similar price range with discounts
      final productsSnapshot = await _firestore
          .collection('products')
          .where('hasDiscount', isEqualTo: true)
          .limit(10)
          .get();

      final recommendations = <PersonalizedRecommendation>[];

      for (var doc in productsSnapshot.docs) {
        try {
          final product = Product.fromFirestore(doc);
          final price = (doc['price'] as num?)?.toDouble() ?? 0;

          // Higher score if price matches user's budget
          double score = 70.0;
          if ((price - avgOrderValue).abs() < avgOrderValue * 0.2) {
            score = 80.0; // Better score if price matches budget
          }

          final discount = (doc['discountPercent'] as num?)?.toDouble() ?? 0;

          recommendations.add(
            PersonalizedRecommendation(
              product: product,
              score: score,
              type: 'deal',
              reason:
                  '${discount.toStringAsFixed(0)}% off - in your price range',
              isMustSee: false,
            ),
          );
        } catch (e) {
          continue;
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('⚠️ Failed to get deal recommendations: $e');
      return [];
    }
  }

  /// Get churn recovery recommendations (high-priority for at-risk users)
  Future<List<PersonalizedRecommendation>> _getChurnRecoveryRecommendations(
    String userId,
  ) async {
    try {
      // Check if user is at risk
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final lastActive = (userData['lastActive'] as Timestamp?)?.toDate();

      if (lastActive == null) {
        return [];
      }

      final daysSinceActive = DateTime.now().difference(lastActive).inDays;

      // Only show recovery recs if user inactive 10+ days
      if (daysSinceActive < 10) {
        return [];
      }

      // Get their favorite categories and show hot deals in those categories
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .where('eventType', isEqualTo: 'product_viewed')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      final categoryFrequency = <String, int>{};
      for (var doc in eventsSnapshot.docs) {
        final props = doc['properties'] as Map? ?? {};
        final category = props['category'] as String?;
        if (category != null) {
          categoryFrequency[category] = (categoryFrequency[category] ?? 0) + 1;
        }
      }

      if (categoryFrequency.isEmpty) {
        return [];
      }

      final topCategories = categoryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final favoriteCategory =
          topCategories.isNotEmpty ? topCategories.first.key : null;

      if (favoriteCategory == null) {
        return [];
      }

      // Get best deals in their favorite category
      final dealsSnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: favoriteCategory)
          .where('hasDiscount', isEqualTo: true)
          .orderBy('discountPercent', descending: true)
          .limit(5)
          .get();

      final recommendations = <PersonalizedRecommendation>[];

      for (var doc in dealsSnapshot.docs) {
        try {
          final product = Product.fromFirestore(doc);
          final discount = (doc['discountPercent'] as num?)?.toDouble() ?? 0;

          recommendations.add(
            PersonalizedRecommendation(
              product: product,
              score: 95.0 -
                  (daysSinceActive * 0.5).clamp(0, 20), // Decays over time
              type: 'churn_recovery',
              reason:
                  '🎁 Welcome back! ${discount.toStringAsFixed(0)}% off products you love',
              isMustSee: daysSinceActive > 30, // Must-see if critical risk
            ),
          );
        } catch (e) {
          continue;
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('⚠️ Failed to get churn recovery recommendations: $e');
      return [];
    }
  }

  /// Get "Similar Products" recommendations based on currently viewed product
  Future<List<PersonalizedRecommendation>> getSimilarProducts({
    required String productId,
    int limit = 5,
  }) async {
    try {
      // Get the current product
      final productDoc =
          await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        return [];
      }

      final currentProduct = Product.fromFirestore(productDoc);

      // Get products from same category
      final similarSnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: currentProduct.category)
          .limit(20)
          .get();

      final recommendations = <PersonalizedRecommendation>[];

      for (var doc in similarSnapshot.docs) {
        if (doc.id == productId) continue; // Skip current product

        try {
          final product = Product.fromFirestore(doc);

          // Score based on similarity
          double similarityScore = 70.0;

          // Same price range = higher similarity
          final priceDiff = (product.price - currentProduct.price).abs();
          if (priceDiff < (currentProduct.price * 0.2)) {
            similarityScore += 10;
          }

          // Similar rating = higher similarity
          if ((product.rating - currentProduct.rating).abs() < 0.5) {
            similarityScore += 5;
          }

          recommendations.add(
            PersonalizedRecommendation(
              product: product,
              score: similarityScore.clamp(0, 100),
              type: 'similar',
              reason: 'Similar to ${currentProduct.name}',
              isMustSee: false,
            ),
          );
        } catch (e) {
          continue;
        }
      }

      // Sort by score and limit
      recommendations.sort((a, b) => b.score.compareTo(a.score));
      return recommendations.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Failed to get similar products: $e');
      return [];
    }
  }

  /// Get products abandoned in cart (for targeted recovery)
  Future<List<Product>> getAbandonedCartProducts({
    required String userId,
  }) async {
    try {
      // Get cart abandonment events
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .where('eventType', isEqualTo: 'cart_abandoned')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final productIds = <String>{};
      for (var doc in eventsSnapshot.docs) {
        final props = doc['properties'] as Map? ?? {};
        final items = props['cartItems'] as List?;
        if (items != null) {
          for (var item in items) {
            final productId = (item as Map?)?['productId'] as String?;
            if (productId != null) {
              productIds.add(productId);
            }
          }
        }
      }

      if (productIds.isEmpty) {
        return [];
      }

      // Get product details
      final products = <Product>[];
      for (var productId in productIds.take(5)) {
        try {
          final productDoc =
              await _firestore.collection('products').doc(productId).get();

          if (productDoc.exists) {
            products.add(Product.fromFirestore(productDoc));
          }
        } catch (e) {
          continue;
        }
      }

      return products;
    } catch (e) {
      debugPrint('⚠️ Failed to get abandoned cart products: $e');
      return [];
    }
  }

  /// Get notification-worthy products (new arrivals, restocks, etc.)
  Future<List<PersonalizedRecommendation>> getNotificationWorthyProducts({
    required String userId,
  }) async {
    try {
      // Check user's favorite categories
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .where('eventType', whereIn: ['wishlist_added', 'product_viewed'])
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      final categoriesOfInterest = <String>{};
      for (var doc in eventsSnapshot.docs) {
        final props = doc['properties'] as Map? ?? {};
        final category = props['category'] as String?;
        if (category != null) {
          categoriesOfInterest.add(category);
        }
      }

      if (categoriesOfInterest.isEmpty) {
        return [];
      }

      // Get recently added products in these categories
      final recentSnapshot = await _firestore
          .collection('products')
          .where('category', whereIn: categoriesOfInterest.toList())
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final recommendations = <PersonalizedRecommendation>[];

      for (var doc in recentSnapshot.docs) {
        try {
          final product = Product.fromFirestore(doc);

          recommendations.add(
            PersonalizedRecommendation(
              product: product,
              score: 80.0,
              type: 'trending',
              reason: '🆕 New arrival in a category you love',
              isMustSee: true, // New items are high priority
            ),
          );
        } catch (e) {
          continue;
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('⚠️ Failed to get notification-worthy products: $e');
      return [];
    }
  }
}
