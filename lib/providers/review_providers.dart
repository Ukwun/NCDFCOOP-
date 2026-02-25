import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/enhanced_review_service.dart';
import '../models/enhanced_review_models.dart';

/// Enhanced review service provider
final enhancedReviewServiceProvider = Provider((ref) {
  return EnhancedReviewService();
});

/// ============================================================================
/// PRODUCT REVIEWS PROVIDERS
/// ============================================================================

/// Get reviews for a specific product
final productReviewsProvider = FutureProvider.family<
    List<EnhancedProductReview>,
    ({
      String productId,
      String sortBy,
      int limit,
    })>((ref, params) async {
  final reviewService = ref.watch(enhancedReviewServiceProvider);
  return await reviewService.getProductReviews(
    productId: params.productId,
    sortBy: params.sortBy,
    limit: params.limit,
    onlyApproved: true,
  );
});

/// Get a single review
final singleReviewProvider =
    FutureProvider.family<EnhancedProductReview?, String>((ref, reviewId) async {
  final reviewService = ref.watch(enhancedReviewServiceProvider);
  return await reviewService.getReview(reviewId);
});

/// Get review statistics for a product
final reviewStatisticsProvider =
    FutureProvider.family<ReviewStatistics?, String>((ref, productId) async {
  final reviewService = ref.watch(enhancedReviewServiceProvider);
  return await reviewService.getProductReviewStatistics(productId);
});

/// Get current user's reviews
final userReviewsProvider = FutureProvider<List<EnhancedProductReview>>((ref) async {
  // TODO: Get userId from auth provider
  const userId = 'current_user'; // Placeholder
  final reviewService = ref.watch(enhancedReviewServiceProvider);
  return await reviewService.getUserReviews(userId: userId);
});

/// ============================================================================
/// MODERATION PROVIDERS
/// ============================================================================

/// Get pending reviews for moderation
final pendingReviewsProvider =
    FutureProvider<List<ReviewModerationRecord>>((ref) async {
  final reviewService = ref.watch(enhancedReviewServiceProvider);
  return await reviewService.getPendingReviews(limit: 50);
});

/// ============================================================================
/// REVIEW ACTIONS PROVIDERS
/// ============================================================================

/// Provider for review-related actions
final reviewActionsProvider = Provider((ref) {
  final reviewService = ref.read(enhancedReviewServiceProvider);
  return ReviewActions(reviewService: reviewService);
});

/// Helper class for review-related actions
class ReviewActions {
  final EnhancedReviewService reviewService;

  ReviewActions({required this.reviewService});

  /// Submit a new review
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
    return await reviewService.submitReview(
      productId: productId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      rating: rating,
      title: title,
      comment: comment,
      mediaAttachments: mediaAttachments,
      orderId: orderId,
    );
  }

  /// Mark review as helpful
  Future<void> markAsHelpful(String reviewId) async {
    // TODO: Get actual userId from auth
    const userId = 'current_user';
    await reviewService.markAsHelpful(reviewId, userId);
  }

  /// Mark review as not helpful
  Future<void> markAsNotHelpful(String reviewId) async {
    // TODO: Get actual userId from auth
    const userId = 'current_user';
    await reviewService.markAsNotHelpful(reviewId, userId);
  }

  /// Flag review for moderation
  Future<void> flagReview({
    required String reviewId,
    required String reason,
    required List<String> flags,
  }) async {
    await reviewService.flagReview(
      reviewId: reviewId,
      reason: reason,
      flags: flags,
    );
  }

  /// Approve review (admin)
  Future<void> approveReview({
    required String reviewId,
    required String moderatorId,
  }) async {
    await reviewService.approveReview(
      reviewId: reviewId,
      moderatorId: moderatorId,
    );
  }

  /// Reject review (admin)
  Future<void> rejectReview({
    required String reviewId,
    required String moderatorId,
    required String reason,
  }) async {
    await reviewService.rejectReview(
      reviewId: reviewId,
      moderatorId: moderatorId,
      reason: reason,
    );
  }

  /// Delete review (admin)
  Future<void> deleteReview(String reviewId) async {
    await reviewService.deleteReview(reviewId);
  }
}

/// ============================================================================
/// FORM STATE PROVIDERS
/// ============================================================================

/// State for review form
class ReviewFormState {
  final int rating;
  final String title;
  final String comment;
  final List<ReviewMedia> mediaAttachments;
  final bool isSubmitting;
  final String? error;

  ReviewFormState({
    this.rating = 5,
    this.title = '',
    this.comment = '',
    this.mediaAttachments = const [],
    this.isSubmitting = false,
    this.error,
  });

  ReviewFormState copyWith({
    int? rating,
    String? title,
    String? comment,
    List<ReviewMedia>? mediaAttachments,
    bool? isSubmitting,
    String? error,
  }) {
    return ReviewFormState(
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      mediaAttachments: mediaAttachments ?? this.mediaAttachments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
    );
  }
}

/// Track review form state
class ReviewFormNotifier extends Notifier<ReviewFormState> {
  @override
  ReviewFormState build() {
    return ReviewFormState();
  }

  void setRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  void addMediaAttachment(ReviewMedia media) {
    final updated = [...state.mediaAttachments, media];
    state = state.copyWith(mediaAttachments: updated);
  }

  void removeMediaAttachment(int index) {
    final updated = [...state.mediaAttachments];
    updated.removeAt(index);
    state = state.copyWith(mediaAttachments: updated);
  }

  void setSubmitting(bool submitting) {
    state = state.copyWith(isSubmitting: submitting);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = ReviewFormState();
  }

  bool get isValid =>
      state.rating >= 1 &&
      state.rating <= 5 &&
      state.title.isNotEmpty &&
      state.comment.isNotEmpty;
}

final reviewFormProvider =
    NotifierProvider<ReviewFormNotifier, ReviewFormState>(() {
  return ReviewFormNotifier();
});

/// ============================================================================
/// MODERATION FORM STATE PROVIDERS
/// ============================================================================

/// State for review moderation form
class ReviewModerationFormState {
  final String reviewId;
  final String? reason;
  final List<String> flags;
  final bool isSubmitting;
  final String? error;

  ReviewModerationFormState({
    required this.reviewId,
    this.reason,
    this.flags = const [],
    this.isSubmitting = false,
    this.error,
  });

  ReviewModerationFormState copyWith({
    String? reviewId,
    String? reason,
    List<String>? flags,
    bool? isSubmitting,
    String? error,
  }) {
    return ReviewModerationFormState(
      reviewId: reviewId ?? this.reviewId,
      reason: reason ?? this.reason,
      flags: flags ?? this.flags,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
    );
  }
}

final reviewModerationFormProvider = NotifierProvider.family<
    ReviewModerationFormNotifier,
    ReviewModerationFormState,
    String>((reviewId) {
  return ReviewModerationFormNotifier(reviewId);
});

/// Track review moderation form state
class ReviewModerationFormNotifier 
    extends Notifier<ReviewModerationFormState> {
  final String _reviewId;
  
  ReviewModerationFormNotifier(this._reviewId);
  
  @override
  ReviewModerationFormState build() {
    return ReviewModerationFormState(reviewId: _reviewId);
  }

  void setReason(String reason) {
    state = state.copyWith(reason: reason);
  }

  void addFlag(String flag) {
    if (!state.flags.contains(flag)) {
      state = state.copyWith(flags: [...state.flags, flag]);
    }
  }

  void removeFlag(String flag) {
    state = state.copyWith(
      flags: state.flags.where((f) => f != flag).toList(),
    );
  }

  void setSubmitting(bool submitting) {
    state = state.copyWith(isSubmitting: submitting);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}
