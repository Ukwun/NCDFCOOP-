import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/core/services/activity_tracking_service.dart';

/// Review activity logging service
/// Logs product reviews, review helpfulness votes, etc.
class ReviewActivityLogger {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityTrackingService _activityTracker;

  ReviewActivityLogger(this._activityTracker);

  /// Log review submitted
  Future<void> logReviewSubmitted({
    required String productId,
    required String productName,
    required String category,
    required int rating,
    required String title,
    required String comment,
    String? deviceId,
    String? sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot log review: User not authenticated');
        return;
      }

      // Log to activity tracker
      await _activityTracker.logActivity(
        type: ActivityType.review,
        productId: productId,
        productName: productName,
        metadata: {
          'action': 'submit_review',
          'category': category,
          'rating': rating,
          'titleLength': title.length,
          'commentLength': comment.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
        deviceId: deviceId,
        sessionId: sessionId,
      );

      // Save to dedicated review_activities collection
      await _firestore
          .collection('user_review_activities')
          .doc(user.uid)
          .collection('activities')
          .add({
        'userId': user.uid,
        'productId': productId,
        'productName': productName,
        'category': category,
        'action': 'submit_review',
        'rating': rating,
        'titleLength': title.length,
        'commentLength': comment.length,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Review logged: $productName (⭐ $rating/5)');
    } catch (e) {
      debugPrint('❌ Error logging review: $e');
      // Silent fail - don't block UI
    }
  }

  /// Log review marked as helpful
  Future<void> logReviewHelpful({
    required String productId,
    required String productName,
    required String reviewId,
    required bool isHelpful,
    String? deviceId,
    String? sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot log review helpful: User not authenticated');
        return;
      }

      // Save to helpful votes collection
      await _firestore
          .collection('user_review_activities')
          .doc(user.uid)
          .collection('activities')
          .add({
        'userId': user.uid,
        'productId': productId,
        'productName': productName,
        'action': 'review_helpful_vote',
        'reviewId': reviewId,
        'helpful': isHelpful,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      final action = isHelpful ? 'helpful' : 'not_helpful';
      debugPrint('✅ Review marked as $action: Review #$reviewId for $productName');
    } catch (e) {
      debugPrint('❌ Error logging review helpful: $e');
      // Silent fail - don't block UI
    }
  }

  /// Log review deleted
  Future<void> logReviewDeleted({
    required String productId,
    required String productName,
    required String reviewId,
    String? deviceId,
    String? sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot log review deletion: User not authenticated');
        return;
      }

      // Save to review_activities collection
      await _firestore
          .collection('user_review_activities')
          .doc(user.uid)
          .collection('activities')
          .add({
        'userId': user.uid,
        'productId': productId,
        'productName': productName,
        'action': 'delete_review',
        'reviewId': reviewId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Review deletion logged: $productName');
    } catch (e) {
      debugPrint('❌ Error logging review deletion: $e');
      // Silent fail - don't block UI
    }
  }

  /// Get user's review activities
  Future<List<Map<String, dynamic>>> getUserReviewActivities({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('user_review_activities')
          .doc(userId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error fetching review activities: $e');
      return [];
    }
  }

  /// Get review metrics for user
  Future<Map<String, dynamic>> getReviewMetrics(String userId) async {
    try {
      final activities = await getUserReviewActivities(userId: userId, limit: 100);

      int reviewsSubmitted = 0;
      int helpfulVotes = 0;
      int unhelpfulVotes = 0;
      int reviewsDeleted = 0;
      double averageRating = 0;
      List<int> ratings = [];

      for (final activity in activities) {
        final action = activity['action'] as String?;

        if (action == 'submit_review') {
          reviewsSubmitted++;
          final rating = activity['rating'] as int?;
          if (rating != null) {
            ratings.add(rating);
            averageRating += rating;
          }
        } else if (action == 'review_helpful_vote') {
          final isHelpful = activity['helpful'] as bool?;
          if (isHelpful == true) {
            helpfulVotes++;
          } else {
            unhelpfulVotes++;
          }
        } else if (action == 'delete_review') {
          reviewsDeleted++;
        }
      }

      if (reviewsSubmitted > 0) {
        averageRating = averageRating / reviewsSubmitted;
      }

      return {
        'totalReviewsSubmitted': reviewsSubmitted,
        'totalHelpfulVotes': helpfulVotes,
        'totalUnhelpfulVotes': unhelpfulVotes,
        'totalReviewsDeleted': reviewsDeleted,
        'averageReviewRating': double.parse(averageRating.toStringAsFixed(1)),
        'helpfulnessRatio': helpfulVotes + unhelpfulVotes > 0
            ? (helpfulVotes / (helpfulVotes + unhelpfulVotes) * 100).toStringAsFixed(1)
            : 'N/A',
        'lastReviewTime': activities
            .where((a) => (a['action'] as String?) == 'submit_review')
            .isNotEmpty
            ? activities.firstWhere((a) => (a['action'] as String?) == 'submit_review')['timestamp']
            : null,
      };
    } catch (e) {
      debugPrint('❌ Error calculating review metrics: $e');
      return {
        'totalReviewsSubmitted': 0,
        'totalHelpfulVotes': 0,
        'totalUnhelpfulVotes': 0,
        'totalReviewsDeleted': 0,
        'averageReviewRating': 0,
        'helpfulnessRatio': 'N/A',
      };
    }
  }

  /// Get user's most reviewed categories
  Future<Map<String, int>> getMostReviewedCategories(String userId,
      {int limit = 5}) async {
    try {
      final activities = await getUserReviewActivities(userId: userId, limit: 100);

      final Map<String, int> categoryCount = {};

      for (final activity in activities) {
        final action = activity['action'] as String?;
        if (action == 'submit_review') {
          final category = activity['category'] as String? ?? 'Unknown';
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }

      // Sort by count descending and take top
      final sorted = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {for (var e in sorted.take(limit)) e.key: e.value};
    } catch (e) {
      debugPrint('❌ Error getting reviewed categories: $e');
      return {};
    }
  }
}
