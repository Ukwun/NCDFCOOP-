import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_intelligence_service.dart';
import '../models/user_interaction.dart';
import '../models/user_relationship.dart';
import '../models/seller_reputation.dart';

/// User Intelligence Service Provider
final userIntelligenceServiceProvider =
    Provider<UserIntelligenceService>((ref) {
  return UserIntelligenceService();
});

/// User interactions provider
/// Gets all interactions for a specific user
final userInteractionsProvider =
    FutureProvider.family<List<UserInteraction>, String>(
  (ref, userId) async {
    final service = ref.watch(userIntelligenceServiceProvider);
    return service.getUserInteractions(userId);
  },
);

/// User relationships provider
/// Gets all relationships for a specific user
final userRelationshipsProvider =
    FutureProvider.family<List<UserRelationship>, String>(
  (ref, userId) async {
    final service = ref.watch(userIntelligenceServiceProvider);
    return service.getUserRelationships(userId);
  },
);

/// Interaction history between two users
final interactionHistoryProvider = FutureProvider.family<List<UserInteraction>,
    ({String userId1, String userId2})>(
  (ref, params) async {
    final service = ref.watch(userIntelligenceServiceProvider);
    return service.getInteractionHistory(params.userId1, params.userId2);
  },
);

/// Seller reputation provider
final sellerReputationProvider =
    FutureProvider.family<SellerReputation?, String>(
  (ref, sellerId) async {
    final service = ref.watch(userIntelligenceServiceProvider);
    return service.getSellerReputation(sellerId);
  },
);

/// Top sellers provider
final topSellersProvider = FutureProvider<List<SellerReputation>>(
  (ref) async {
    final service = ref.watch(userIntelligenceServiceProvider);
    return service.getTopSellers();
  },
);

/// User activity summary provider
final userActivitySummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    final service = ref.watch(userIntelligenceServiceProvider);
    return service.getUserActivitySummary(userId);
  },
);

/// User influence score provider
final userInfluenceScoreProvider = FutureProvider.family<double, String>(
  (ref, userId) async {
    final service = ref.watch(userIntelligenceServiceProvider);
    return service.calculateUserInfluenceScore(userId);
  },
);

/// Interaction logging notifier
/// Used to execute interactions and invalidate related providers
final interactionLoggingProvider =
    StateNotifierProvider<InteractionLoggingNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(userIntelligenceServiceProvider);
  return InteractionLoggingNotifier(service, ref);
});

/// Notifier for logging interactions
class InteractionLoggingNotifier extends StateNotifier<AsyncValue<void>> {
  final UserIntelligenceService _service;
  final Ref _ref;

  InteractionLoggingNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

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
    state = const AsyncValue.loading();
    try {
      await _service.logInteraction(
        fromUserId: fromUserId,
        toUserId: toUserId,
        fromUserRole: fromUserRole,
        toUserRole: toUserRole,
        type: type,
        referenceId: referenceId,
        metadata: metadata,
        isPositive: isPositive,
      );

      // Invalidate related providers
      _ref.invalidate(userInteractionsProvider(fromUserId));
      _ref.invalidate(userInteractionsProvider(toUserId));
      _ref.invalidate(userActivitySummaryProvider(fromUserId));
      _ref.invalidate(userActivitySummaryProvider(toUserId));
      _ref.invalidate(userInfluenceScoreProvider(fromUserId));
      _ref.invalidate(userInfluenceScoreProvider(toUserId));
      _ref.invalidate(
        interactionHistoryProvider((userId1: fromUserId, userId2: toUserId)),
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Relationship management notifier
final relationshipManagementProvider =
    StateNotifierProvider<RelationshipManagementNotifier, AsyncValue<void>>(
        (ref) {
  final service = ref.watch(userIntelligenceServiceProvider);
  return RelationshipManagementNotifier(service, ref);
});

/// Notifier for managing relationships
class RelationshipManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final UserIntelligenceService _service;
  final Ref _ref;

  RelationshipManagementNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> setRelationship({
    required String userId,
    required String relatedUserId,
    required String relationshipType,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.setRelationship(
        userId: userId,
        relatedUserId: relatedUserId,
        relationshipType: relationshipType,
        notes: notes,
      );

      // Invalidate related providers
      _ref.invalidate(userRelationshipsProvider(userId));
      _ref.invalidate(userRelationshipsProvider(relatedUserId));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> removeRelationship({
    required String userId,
    required String relatedUserId,
    required String relationshipType,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.removeRelationship(
          userId, relatedUserId, relationshipType);

      // Invalidate related providers
      _ref.invalidate(userRelationshipsProvider(userId));
      _ref.invalidate(userRelationshipsProvider(relatedUserId));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Seller reputation notifier
final sellerReputationUpdateProvider =
    StateNotifierProvider<SellerReputationNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(userIntelligenceServiceProvider);
  return SellerReputationNotifier(service, ref);
});

/// Notifier for updating seller reputation
class SellerReputationNotifier extends StateNotifier<AsyncValue<void>> {
  final UserIntelligenceService _service;
  final Ref _ref;

  SellerReputationNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> updateReputation({
    required String sellerId,
    double? averageRating,
    int? totalReviews,
    int? newSale,
    int? returnedOrder,
    int? cancelledOrder,
    double? newResponseTime,
    bool? isVerified,
    String? tier,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateSellerReputation(
        sellerId,
        averageRating: averageRating,
        totalReviews: totalReviews,
        newSale: newSale,
        returnedOrder: returnedOrder,
        cancelledOrder: cancelledOrder,
        newResponseTime: newResponseTime,
        isVerified: isVerified,
        tier: tier,
      );

      // Invalidate related providers
      _ref.invalidate(sellerReputationProvider(sellerId));
      _ref.invalidate(topSellersProvider);
      _ref.invalidate(userActivitySummaryProvider(sellerId));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
