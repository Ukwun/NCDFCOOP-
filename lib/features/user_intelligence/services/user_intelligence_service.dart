import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_interaction.dart';
import 'models/user_relationship.dart';
import 'models/seller_reputation.dart';

/// User Intelligence Service
/// Handles tracking of user interactions, relationships, and scoring
class UserIntelligenceService {
  final FirebaseFirestore _firestore;

  UserIntelligenceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ========================================================================
  // USER INTERACTION TRACKING
  // ========================================================================

  /// Log a user interaction
  Future<void> logInteraction({
    required String fromUserId,
    required String toUserId,
    required String fromUserRole,
    required String toUserRole,
    required String type,
    String? referenceId,
    Map<String, dynamic>? metadata,
    bool isPositive = true,
  }) async {
    try {
      final interaction = UserInteraction(
        id: _firestore.collection('user_interactions').doc().id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        fromUserRole: fromUserRole,
        toUserRole: toUserRole,
        type: type,
        referenceId: referenceId,
        metadata: metadata,
        timestamp: DateTime.now(),
        isPositive: isPositive,
      );

      await _firestore
          .collection('user_interactions')
          .doc(interaction.id)
          .set(interaction.toFirestore());

      // Update relationship interaction count
      await _updateRelationshipInteractionCount(fromUserId, toUserId);

      // Update user scores based on interaction
      await _updateUserScoresFromInteraction(interaction);
    } catch (e) {
      print('Error logging interaction: $e');
      rethrow;
    }
  }

  /// Get interactions for a user
  Future<List<UserInteraction>> getUserInteractions(
    String userId, {
    String? type,
    bool? isPositive,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('user_interactions')
          .where('fromUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      if (isPositive != null) {
        query = query.where('isPositive', isEqualTo: isPositive);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserInteraction.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting user interactions: $e');
      return [];
    }
  }

  /// Get interaction history between two users
  Future<List<UserInteraction>> getInteractionHistory(
    String userId1,
    String userId2, {
    int limit = 50,
  }) async {
    try {
      final query1 = _firestore
          .collection('user_interactions')
          .where('fromUserId', isEqualTo: userId1)
          .where('toUserId', isEqualTo: userId2)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final query2 = _firestore
          .collection('user_interactions')
          .where('fromUserId', isEqualTo: userId2)
          .where('toUserId', isEqualTo: userId1)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final [snapshot1, snapshot2] = await Future.wait([
        query1.get(),
        query2.get(),
      ]);

      final interactions = [
        ...snapshot1.docs,
        ...snapshot2.docs,
      ];

      // Sort by timestamp
      interactions.sort((a, b) {
        final aTime =
            (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime =
            (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return interactions
          .map((doc) => UserInteraction.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting interaction history: $e');
      return [];
    }
  }

  // ========================================================================
  // USER RELATIONSHIP MANAGEMENT
  // ========================================================================

  /// Create or update a relationship between users
  Future<void> setRelationship({
    required String userId,
    required String relatedUserId,
    required String relationshipType,
    String? notes,
  }) async {
    try {
      final relationshipId = '${userId}_${relatedUserId}_$relationshipType';
      final relationship = UserRelationship(
        id: relationshipId,
        userId: userId,
        relatedUserId: relatedUserId,
        relationshipType: relationshipType,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        interactionCount: 0,
      );

      await _firestore
          .collection('user_relationships')
          .doc(relationshipId)
          .set(relationship.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error setting relationship: $e');
      rethrow;
    }
  }

  /// Get relationships for a user
  Future<List<UserRelationship>> getUserRelationships(
    String userId, {
    String? relationshipType,
  }) async {
    try {
      Query query = _firestore
          .collection('user_relationships')
          .where('userId', isEqualTo: userId);

      if (relationshipType != null) {
        query = query.where('relationshipType', isEqualTo: relationshipType);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserRelationship.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting user relationships: $e');
      return [];
    }
  }

  /// Remove a relationship
  Future<void> removeRelationship(
    String userId,
    String relatedUserId,
    String relationshipType,
  ) async {
    try {
      final relationshipId = '${userId}_${relatedUserId}_$relationshipType';
      await _firestore
          .collection('user_relationships')
          .doc(relationshipId)
          .delete();
    } catch (e) {
      print('Error removing relationship: $e');
      rethrow;
    }
  }

  // ========================================================================
  // SELLER REPUTATION
  // ========================================================================

  /// Update seller reputation
  Future<void> updateSellerReputation(
    String sellerId, {
    double? averageRating,
    int? totalReviews,
    int? newSale,
    int? returnedOrder,
    int? cancelledOrder,
    double? newResponseTime,
    bool? isVerified,
    String? tier,
  }) async {
    try {
      // Get current reputation
      final currentRep = await getSellerReputation(sellerId);

      // Calculate updated values
      final updatedAverageRating =
          averageRating ?? currentRep?.averageRating ?? 0.0;
      final updatedTotalReviews = totalReviews ?? currentRep?.totalReviews ?? 0;
      final updatedTotalSales = (currentRep?.totalSales ?? 0) + (newSale ?? 0);
      final updatedReturnedOrders =
          (currentRep?.returnedOrders ?? 0) + (returnedOrder ?? 0);
      final updatedCancelledOrders =
          (currentRep?.cancelledOrders ?? 0) + (cancelledOrder ?? 0);

      // Calculate trust score
      final trustScore = _calculateTrustScore(
        averageRating: updatedAverageRating,
        totalReviews: updatedTotalReviews,
        totalSales: updatedTotalSales,
        returnedOrders: updatedReturnedOrders,
        cancelledOrders: updatedCancelledOrders,
      );

      // Determine tier
      final newTier =
          tier ?? _determineTier(updatedTotalSales, updatedAverageRating);

      final reputation = SellerReputation(
        id: sellerId,
        averageRating: updatedAverageRating,
        totalReviews: updatedTotalReviews,
        totalSales: updatedTotalSales,
        returnedOrders: updatedReturnedOrders,
        cancelledOrders: updatedCancelledOrders,
        responseTime: newResponseTime ?? currentRep?.responseTime ?? 0,
        isVerified: isVerified ?? currentRep?.isVerified ?? false,
        isActive: currentRep?.isActive ?? true,
        tier: newTier,
        trustScore: trustScore,
        createdAt: currentRep?.createdAt ?? DateTime.now(),
        lastUpdated: DateTime.now(),
        badges: currentRep?.badges ?? {},
      );

      await _firestore
          .collection('seller_reputations')
          .doc(sellerId)
          .set(reputation.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error updating seller reputation: $e');
      rethrow;
    }
  }

  /// Get seller reputation
  Future<SellerReputation?> getSellerReputation(String sellerId) async {
    try {
      final doc =
          await _firestore.collection('seller_reputations').doc(sellerId).get();
      if (!doc.exists) return null;
      return SellerReputation.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e) {
      print('Error getting seller reputation: $e');
      return null;
    }
  }

  /// Get top sellers by reputation
  Future<List<SellerReputation>> getTopSellers({
    int limit = 10,
    String? tier,
  }) async {
    try {
      Query query = _firestore
          .collection('seller_reputations')
          .where('isActive', isEqualTo: true)
          .orderBy('trustScore', descending: true)
          .limit(limit);

      if (tier != null) {
        query = query.where('tier', isEqualTo: tier);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => SellerReputation.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting top sellers: $e');
      return [];
    }
  }

  // ========================================================================
  // USER INTELLIGENCE & SCORING
  // ========================================================================

  /// Get user activity summary
  Future<Map<String, dynamic>> getUserActivitySummary(String userId) async {
    try {
      final interactions = await getUserInteractions(userId);
      final relationships = await getUserRelationships(userId);

      // Count interaction types
      final typeMap = <String, int>{};
      for (final interaction in interactions) {
        typeMap[interaction.type] = (typeMap[interaction.type] ?? 0) + 1;
      }

      // Count positive vs negative
      int positiveCount = 0;
      int negativeCount = 0;
      for (final interaction in interactions) {
        if (interaction.isPositive) {
          positiveCount++;
        } else {
          negativeCount++;
        }
      }

      return {
        'totalInteractions': interactions.length,
        'interactionTypes': typeMap,
        'positiveInteractions': positiveCount,
        'negativeInteractions': negativeCount,
        'totalRelationships': relationships.length,
        'lastActivityDate':
            interactions.isNotEmpty ? interactions.first.timestamp : null,
      };
    } catch (e) {
      print('Error getting user activity summary: $e');
      return {};
    }
  }

  /// Get user influence score (0-100)
  /// Based on interactions, relationships, and activities
  Future<double> calculateUserInfluenceScore(String userId) async {
    try {
      final summary = await getUserActivitySummary(userId);
      final relationships = await getUserRelationships(userId);

      double score = 0.0;

      // Interaction count (max 30 points)
      final interactionCount = (summary['totalInteractions'] as int?) ?? 0;
      score += (interactionCount / 100 * 30).clamp(0, 30);

      // Positive interaction ratio (max 40 points)
      if (interactionCount > 0) {
        final positiveCount = (summary['positiveInteractions'] as int?) ?? 0;
        final positiveRatio = positiveCount / interactionCount;
        score += positiveRatio * 40;
      }

      // Relationship count (max 20 points)
      score += (relationships.length / 50 * 20).clamp(0, 20);

      // Activity recency (max 10 points)
      final lastActive = summary['lastActivityDate'] as DateTime?;
      if (lastActive != null) {
        final daysSinceActive = DateTime.now().difference(lastActive).inDays;
        if (daysSinceActive == 0) {
          score += 10; // Very recent
        } else if (daysSinceActive <= 7) {
          score += 7; // Within a week
        } else if (daysSinceActive <= 30) {
          score += 3; // Within a month
        }
      }

      return score.clamp(0, 100);
    } catch (e) {
      print('Error calculating influence score: $e');
      return 0.0;
    }
  }

  // ========================================================================
  // PRIVATE HELPER METHODS
  // ========================================================================

  /// Update interaction count between two users
  Future<void> _updateRelationshipInteractionCount(
    String userId1,
    String userId2,
  ) async {
    try {
      // Create a collection reference for counted interactions
      // This would be used to track frequency of interactions
      await Future.delayed(const Duration(milliseconds: 100)); // Placeholder
    } catch (e) {
      print('Error updating interaction count: $e');
    }
  }

  /// Update user scores based on an interaction
  Future<void> _updateUserScoresFromInteraction(
      UserInteraction interaction) async {
    try {
      // If it's a seller rating or review interaction
      if (interaction.type == 'review' || interaction.type == 'rating') {
        final rating = interaction.metadata?['rating'] as double? ?? 0.0;
        await updateSellerReputation(
          interaction.toUserId,
          totalReviews: 1,
          averageRating: rating,
        );
      }
    } catch (e) {
      print('Error updating scores from interaction: $e');
    }
  }

  /// Calculate trust score for a seller
  double _calculateTrustScore({
    required double averageRating,
    required int totalReviews,
    required int totalSales,
    required int returnedOrders,
    required int cancelledOrders,
  }) {
    double score = 50; // Base score

    // Rating component (0-30 points)
    score += (averageRating / 5) * 30;

    // Review count bonus (0-15 points)
    score += (totalReviews / 100 * 15).clamp(0, 15);

    // Sales component (0-15 points)
    score += (totalSales / 1000 * 15).clamp(0, 15);

    // Return/cancel penalty (-20 to 0)
    final returnRate = totalSales > 0 ? returnedOrders / totalSales : 0;
    final cancelRate = totalSales > 0 ? cancelledOrders / totalSales : 0;
    score -= (returnRate + cancelRate) * 20;

    return score.clamp(0, 100);
  }

  /// Determine seller tier based on sales and rating
  String _determineTier(int totalSales, double averageRating) {
    if (totalSales >= 500 && averageRating >= 4.5) {
      return 'platinum';
    } else if (totalSales >= 200 && averageRating >= 4.3) {
      return 'gold';
    } else if (totalSales >= 50 && averageRating >= 4.0) {
      return 'silver';
    } else {
      return 'bronze';
    }
  }
}
