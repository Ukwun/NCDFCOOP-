import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/enhanced_review_models.dart';
import '../utils/logger.dart';

/// Service for managing product reviews with moderation and media support
class EnhancedReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _reviewsCollection = 'product_reviews_enhanced';
  static const String _moderationCollection = 'review_moderation';
  static const String _statisticsCollection = 'review_statistics';

  /// Submit a new product review
  Future<String> submitReview({
    required String productId,
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required int rating,
    required String title,
    required String comment,
    List<ReviewMedia> mediaAttachments = const [],
    String? orderId,
  }) async {
    try {
      AppLogger.logMethodCall('submitReview', params: {
        'productId': productId,
        'rating': rating,
        'userName': userName,
      });

      final review = EnhancedProductReview(
        id: DateTime.now().toString(),
        productId: productId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        rating: rating,
        title: title,
        comment: comment,
        mediaAttachments: mediaAttachments,
        createdAt: DateTime.now(),
        verified: orderId != null,
        orderId: orderId,
        tags: [
          if (orderId != null) 'verified-purchase',
          if (mediaAttachments.isNotEmpty) 'with-photos',
          if (mediaAttachments.any((m) => m.isVideo)) 'with-videos',
        ],
      );

      final docRef = await _firestore
          .collection(_reviewsCollection)
          .add(review.toFirestore());

      debugPrint('✅ Review submitted: ${docRef.id}');

      // Trigger moderation workflow
      await _createModerationRecord(docRef.id);

      // Update product statistics
      await _updateProductStatistics(productId);

      return docRef.id;
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      rethrow;
    }
  }

  /// Get reviews for a product
  Future<List<EnhancedProductReview>> getProductReviews({
    required String productId,
    int limit = 20,
    String sortBy =
        'helpful', // 'recent', 'helpful', 'rating_high', 'rating_low'
    bool onlyApproved = true,
  }) async {
    try {
      Query query = _firestore
          .collection(_reviewsCollection)
          .where('product_id', isEqualTo: productId);

      // Only show approved reviews by default
      if (onlyApproved) {
        query = query.where('is_moderated', isEqualTo: true);
      }

      // Apply sorting
      query = _applySorting(query, sortBy);

      final snapshot = await query.limit(limit).get();

      final reviews = snapshot.docs
          .map((doc) => EnhancedProductReview.fromFirestore(doc))
          .toList();

      debugPrint(
          '✅ Retrieved ${reviews.length} reviews for product: $productId');
      return reviews;
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      return [];
    }
  }

  /// Get a single review by ID
  Future<EnhancedProductReview?> getReview(String reviewId) async {
    try {
      final doc =
          await _firestore.collection(_reviewsCollection).doc(reviewId).get();

      if (!doc.exists) return null;

      return EnhancedProductReview.fromFirestore(doc);
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      return null;
    }
  }

  /// Mark review as helpful
  Future<void> markAsHelpful(String reviewId, String userId) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return;

      // Check if user already voted (simplified - use set for production)
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'helpful_count': review.helpfulCount + 1,
      });

      debugPrint('✅ Marked review as helpful: $reviewId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Mark review as not helpful
  Future<void> markAsNotHelpful(String reviewId, String userId) async {
    try {
      final review = await getReview(reviewId);
      if (review == null) return;

      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'not_helpful_count': review.notHelpfulCount + 1,
      });

      debugPrint('✅ Marked review as not helpful: $reviewId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Flag review for moderation
  Future<void> flagReview({
    required String reviewId,
    required String reason,
    required List<String> flags,
  }) async {
    try {
      AppLogger.debug('Flagging review: $reviewId');

      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'flagged': true,
        'flag_reason': reason,
        'flag_count': FieldValue.increment(1),
      });

      // Create moderation record
      await _firestore.collection(_moderationCollection).add({
        'review_id': reviewId,
        'flags': flags,
        'reason': reason,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Review flagged: $reviewId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Approve review (admin)
  Future<void> approveReview({
    required String reviewId,
    required String moderatorId,
  }) async {
    try {
      AppLogger.logMethodCall('approveReview', params: {
        'reviewId': reviewId,
        'moderatorId': moderatorId,
      });

      // Update review status
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'is_moderated': true,
        'moderation_notes': 'Approved by moderator',
      });

      // Get the latest moderation record
      final moderationDocs = await _firestore
          .collection(_moderationCollection)
          .where('review_id', isEqualTo: reviewId)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (moderationDocs.docs.isNotEmpty) {
        await moderationDocs.docs.first.reference.update({
          'status': 'approved',
          'resolved_at': FieldValue.serverTimestamp(),
          'moderator_id': moderatorId,
        });
      }

      debugPrint('✅ Review approved: $reviewId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Reject review (admin)
  Future<void> rejectReview({
    required String reviewId,
    required String moderatorId,
    required String reason,
  }) async {
    try {
      AppLogger.logMethodCall('rejectReview', params: {
        'reviewId': reviewId,
        'reason': reason,
      });

      // Update review status
      await _firestore.collection(_reviewsCollection).doc(reviewId).update({
        'is_moderated': false,
        'moderation_notes': reason,
      });

      // Update moderation record
      final moderationDocs = await _firestore
          .collection(_moderationCollection)
          .where('review_id', isEqualTo: reviewId)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (moderationDocs.docs.isNotEmpty) {
        await moderationDocs.docs.first.reference.update({
          'status': 'rejected',
          'resolved_at': FieldValue.serverTimestamp(),
          'moderator_id': moderatorId,
          'reason': reason,
        });
      }

      debugPrint('✅ Review rejected: $reviewId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Delete review (admin)
  Future<void> deleteReview(String reviewId) async {
    try {
      AppLogger.debug('Deleting review: $reviewId');

      final review = await getReview(reviewId);

      // Delete review
      await _firestore.collection(_reviewsCollection).doc(reviewId).delete();

      // Delete associated moderation records
      final modRecords = await _firestore
          .collection(_moderationCollection)
          .where('review_id', isEqualTo: reviewId)
          .get();

      for (var doc in modRecords.docs) {
        await doc.reference.delete();
      }

      // Update product statistics
      if (review != null) {
        await _updateProductStatistics(review.productId);
      }

      debugPrint('✅ Review deleted: $reviewId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Get pending reviews for moderation
  Future<List<ReviewModerationRecord>> getPendingReviews(
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_moderationCollection)
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      final records = snapshot.docs
          .map((doc) => ReviewModerationRecord.fromFirestore(doc))
          .toList();

      debugPrint('✅ Retrieved ${records.length} pending reviews');
      return records;
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      return [];
    }
  }

  /// Get review statistics for a product
  Future<ReviewStatistics?> getProductReviewStatistics(String productId) async {
    try {
      final doc = await _firestore
          .collection(_statisticsCollection)
          .doc(productId)
          .get();

      if (!doc.exists) return null;

      return ReviewStatistics.fromFirestore(doc);
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      return null;
    }
  }

  /// Get user's reviews
  Future<List<EnhancedProductReview>> getUserReviews({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_reviewsCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      final reviews = snapshot.docs
          .map((doc) => EnhancedProductReview.fromFirestore(doc))
          .toList();

      return reviews;
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      return [];
    }
  }

  /// Apply sorting to query
  Query _applySorting(Query query, String sortBy) {
    switch (sortBy.toLowerCase()) {
      case 'recent':
        return query.orderBy('created_at', descending: true);
      case 'helpful':
        return query.orderBy('helpful_count', descending: true);
      case 'rating_high':
        return query.orderBy('rating', descending: true);
      case 'rating_low':
        return query.orderBy('rating', descending: false);
      default:
        return query;
    }
  }

  /// Create moderation record for new review
  Future<void> _createModerationRecord(String reviewId) async {
    try {
      await _firestore.collection(_moderationCollection).add({
        'review_id': reviewId,
        'status': 'pending',
        'flags': [],
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Update product review statistics
  Future<void> _updateProductStatistics(String productId) async {
    try {
      // Get all approved reviews for product
      final reviewsSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('product_id', isEqualTo: productId)
          .where('is_moderated', isEqualTo: true)
          .get();

      final reviews = reviewsSnapshot.docs
          .map((doc) => EnhancedProductReview.fromFirestore(doc))
          .toList();

      if (reviews.isEmpty) return;

      // Calculate statistics
      final totalReviews = reviews.length;
      final averageRating =
          reviews.fold<int>(0, (sum, r) => sum + r.rating) / totalReviews;

      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = reviews.where((r) => r.rating == i).length;
      }

      final reviewsWithMedia = reviews.where((r) => r.hasMedia).length;
      final verifiedReviews = reviews.where((r) => r.isVerifiedPurchase).length;

      final averageHelpfulness = reviews
              .where((r) => r.helpfulCount + r.notHelpfulCount > 0)
              .fold<double>(0, (sum, r) => sum + r.getHelpfulnessScore()) /
          reviews
              .where((r) => r.helpfulCount + r.notHelpfulCount > 0)
              .length
              .toDouble()
              .clamp(1, double.infinity);

      // Save statistics
      await _firestore.collection(_statisticsCollection).doc(productId).set({
        'total_reviews': totalReviews,
        'average_rating': averageRating,
        'rating_distribution': ratingDistribution,
        'reviews_with_media': reviewsWithMedia,
        'verified_purchase_reviews': verifiedReviews,
        'average_helpfulness_score': averageHelpfulness,
        'last_review_date': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Updated statistics for product: $productId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }
}
