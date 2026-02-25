import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/models/product_review_models.dart';

/// Service for managing product reviews
/// Handles creation, retrieval, rating updates, and helpfulness tracking
class ProductReviewService {
  static final ProductReviewService _instance = ProductReviewService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory ProductReviewService() => _instance;

  ProductReviewService._internal();

  /// Submit a new review for a product
  Future<String> submitReview({
    required String productId,
    required String userId,
    required String userName,
    required int rating,
    required String title,
    required String comment,
    bool verified = false,
  }) async {
    try {
      final review = ProductReview(
        id: '', // Firestore will generate
        productId: productId,
        userId: userId,
        userName: userName,
        rating: rating,
        title: title,
        comment: comment,
        verified: verified,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .add(review.toFirestore());

      // Update product rating summary
      await _updateProductRatingSummary(productId);

      return docRef.id;
    } catch (e) {
      print('Failed to submit review: $e');
      rethrow;
    }
  }

  /// Get all reviews for a product
  Future<List<ProductReview>> getProductReviews({
    required String productId,
    int limit = 10,
    String orderBy = 'recent', // 'recent', 'helpful', 'rating-high', 'rating-low'
  }) async {
    try {
      Query query = _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews');

      // Apply sorting
      switch (orderBy) {
        case 'helpful':
          query = query.orderBy('helpfulCount', descending: true);
          break;
        case 'rating-high':
          query = query.orderBy('rating', descending: true);
          break;
        case 'rating-low':
          query = query.orderBy('rating', descending: false);
          break;
        case 'recent':
        default:
          query = query.orderBy('createdAt', descending: true);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => ProductReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Failed to get reviews: $e');
      // Fallback to mock data
      return mockProductReviews.where((r) => r.productId == productId).toList();
    }
  }

  /// Get rating summary for a product
  Future<ProductRatingSummary> getProductRatingSummary(String productId) async {
    try {
      final doc = await _firestore
          .collection('products')
          .doc(productId)
          .collection('rating_summary')
          .doc('summary')
          .get();

      if (doc.exists) {
        return ProductRatingSummary.fromFirestore(doc);
      }

      // If not exists, calculate from reviews
      return await _calculateRatingSummary(productId);
    } catch (e) {
      print('Failed to get rating summary: $e');
      // Return mock data
      return mockRatingSummaries[productId] ??
          ProductRatingSummary(
            productId: productId,
            averageRating: 0.0,
            totalReviews: 0,
            ratingDistribution: {},
          );
    }
  }

  /// Mark review as helpful
  Future<void> markReviewHelpful({
    required String productId,
    required String reviewId,
    required String userId,
  }) async {
    try {
      // Record the helpfulness
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(reviewId)
          .collection('helpfulness')
          .doc(userId)
          .set({
            'helpful': true,
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Increment helpful count
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(reviewId)
          .update({
            'helpfulCount': FieldValue.increment(1),
          });
    } catch (e) {
      print('Failed to mark review helpful: $e');
      rethrow;
    }
  }

  /// Mark review as not helpful
  Future<void> markReviewNotHelpful({
    required String productId,
    required String reviewId,
    required String userId,
  }) async {
    try {
      // Record the helpfulness
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(reviewId)
          .collection('helpfulness')
          .doc(userId)
          .set({
            'helpful': false,
            'userId': userId,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Failed to mark review not helpful: $e');
      rethrow;
    }
  }

  /// Get reviews by user
  Future<List<ProductReview>> getUserReviews({
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Failed to get user reviews: $e');
      return [];
    }
  }

  /// Check if user has already reviewed a product
  Future<bool> hasUserReviewedProduct({
    required String productId,
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Failed to check review status: $e');
      return false;
    }
  }

  /// Delete a review (admin or review owner only)
  Future<void> deleteReview({
    required String productId,
    required String reviewId,
  }) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      // Recalculate rating summary
      await _updateProductRatingSummary(productId);
    } catch (e) {
      print('Failed to delete review: $e');
      rethrow;
    }
  }

  /// Get top rated products (for admin dashboard)
  Future<List<Map<String, dynamic>>> getTopRatedProducts({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('rating_summary')
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                'productId': doc.reference.parent.parent?.id ?? '',
                'averageRating': (doc['averageRating'] as num?)?.toDouble() ?? 0.0,
                'totalReviews': doc['totalReviews'] ?? 0,
              })
          .toList();
    } catch (e) {
      print('Failed to get top rated products: $e');
      return [];
    }
  }

  /// Calculate rating summary from reviews
  Future<ProductRatingSummary> _calculateRatingSummary(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .get();

      if (snapshot.docs.isEmpty) {
        return ProductRatingSummary(
          productId: productId,
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
        );
      }

      // Calculate averages
      double totalRating = 0;
      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in snapshot.docs) {
        final review = ProductReview.fromFirestore(doc);
        totalRating += review.rating;
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
      }

      final averageRating = totalRating / snapshot.docs.length;

      return ProductRatingSummary(
        productId: productId,
        averageRating: averageRating,
        totalReviews: snapshot.docs.length,
        ratingDistribution: distribution,
      );
    } catch (e) {
      print('Failed to calculate rating summary: $e');
      return ProductRatingSummary(
        productId: productId,
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
      );
    }
  }

  /// Update product rating summary
  Future<void> _updateProductRatingSummary(String productId) async {
    try {
      final summary = await _calculateRatingSummary(productId);

      await _firestore
          .collection('products')
          .doc(productId)
          .collection('rating_summary')
          .doc('summary')
          .set(summary.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Failed to update rating summary: $e');
    }
  }

  /// Get mock reviews (for testing/offline)
  Future<List<ProductReview>> getMockReviews(String productId) async {
    return mockProductReviews.where((r) => r.productId == productId).toList();
  }
}

/// Riverpod providers
final productReviewServiceProvider = Provider((ref) => ProductReviewService());

/// Get all reviews for a product
final productReviewsProvider = FutureProvider.family<List<ProductReview>, String>((ref, productId) async {
  final service = ref.watch(productReviewServiceProvider);
  return service.getProductReviews(productId: productId);
});

/// Get rating summary for a product
final productRatingSummaryProvider = FutureProvider.family<ProductRatingSummary, String>((ref, productId) async {
  final service = ref.watch(productReviewServiceProvider);
  return service.getProductRatingSummary(productId);
});

/// Get user's reviews
final userReviewsProvider = FutureProvider.family<List<ProductReview>, String>((ref, userId) async {
  final service = ref.watch(productReviewServiceProvider);
  return service.getUserReviews(userId: userId);
});
