import 'package:cloud_firestore/cloud_firestore.dart';

/// Media attachment for reviews (photo or video)
class ReviewMedia {
  final String id;
  final String type; // 'photo' or 'video'
  final String url; // Firebase Storage URL
  final String fileName;
  final int fileSizeBytes;
  final DateTime uploadedAt;
  final Map<String, dynamic>?
      metadata; // Additional metadata (dimensions, duration, etc)

  ReviewMedia({
    required this.id,
    required this.type,
    required this.url,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    this.metadata,
  });

  factory ReviewMedia.fromMap(Map<String, dynamic> data) {
    return ReviewMedia(
      id: data['id'] ?? '',
      type: data['type'] ?? 'photo',
      url: data['url'] ?? '',
      fileName: data['fileName'] ?? '',
      fileSizeBytes: data['fileSizeBytes'] ?? 0,
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': FieldValue.serverTimestamp(),
      'metadata': metadata,
    };
  }

  bool get isPhoto => type == 'photo';
  bool get isVideo => type == 'video';
}

/// Enhanced product review with media support
class EnhancedProductReview {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final int rating; // 1-5 stars
  final String title;
  final String comment;
  final List<ReviewMedia> mediaAttachments;
  final int helpfulCount;
  final int notHelpfulCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool verified; // true if verified purchaser
  final String? orderId; // Link to order for verification
  final bool isModerated;
  final String? moderationNotes;
  final List<String> tags; // e.g., ['verified-purchase', 'with-photos']

  EnhancedProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.rating,
    required this.title,
    required this.comment,
    this.mediaAttachments = const [],
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.verified = false,
    this.orderId,
    this.isModerated = false,
    this.moderationNotes,
    this.tags = const [],
  });

  /// Create from Firestore document
  factory EnhancedProductReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final mediaList = (data['media_attachments'] as List?)
            ?.map((m) => ReviewMedia.fromMap(m as Map<String, dynamic>))
            .toList() ??
        [];

    return EnhancedProductReview(
      id: doc.id,
      productId: data['product_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'Anonymous',
      userPhotoUrl: data['user_photo_url'] ?? '',
      rating: data['rating'] ?? 5,
      title: data['title'] ?? '',
      comment: data['comment'] ?? '',
      mediaAttachments: mediaList,
      helpfulCount: data['helpful_count'] ?? 0,
      notHelpfulCount: data['not_helpful_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
      verified: data['verified'] ?? false,
      orderId: data['order_id'],
      isModerated: data['is_moderated'] ?? false,
      moderationNotes: data['moderation_notes'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'rating': rating,
      'title': title,
      'comment': comment,
      'media_attachments': mediaAttachments.map((m) => m.toMap()).toList(),
      'helpful_count': helpfulCount,
      'not_helpful_count': notHelpfulCount,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'verified': verified,
      'order_id': orderId,
      'is_moderated': isModerated,
      'moderation_notes': moderationNotes,
      'tags': tags,
    };
  }

  /// Calculate helpfulness score
  double getHelpfulnessScore() {
    final total = helpfulCount + notHelpfulCount;
    if (total == 0) return 0.0;
    return (helpfulCount / total) * 100;
  }

  /// Check if review has media
  bool get hasMedia => mediaAttachments.isNotEmpty;

  /// Get number of photos
  int get photoCount => mediaAttachments.where((m) => m.isPhoto).length;

  /// Get number of videos
  int get videoCount => mediaAttachments.where((m) => m.isVideo).length;

  /// Check if by verified purchaser
  bool get isVerifiedPurchase => verified && orderId != null;
}

/// Review moderation record
class ReviewModerationRecord {
  final String id;
  final String reviewId;
  final String moderatorId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? reason; // Why rejected
  final List<String>
      flags; // Issues flagged: 'spam', 'inappropriate', 'irrelevant', etc
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? moderatorNotes;

  ReviewModerationRecord({
    required this.id,
    required this.reviewId,
    required this.moderatorId,
    required this.status,
    this.reason,
    this.flags = const [],
    required this.createdAt,
    this.resolvedAt,
    this.moderatorNotes,
  });

  factory ReviewModerationRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModerationRecord(
      id: doc.id,
      reviewId: data['review_id'] ?? '',
      moderatorId: data['moderator_id'] ?? '',
      status: data['status'] ?? 'pending',
      reason: data['reason'],
      flags: List<String>.from(data['flags'] ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolved_at'] as Timestamp?)?.toDate(),
      moderatorNotes: data['moderator_notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'review_id': reviewId,
      'moderator_id': moderatorId,
      'status': status,
      'reason': reason,
      'flags': flags,
      'created_at': FieldValue.serverTimestamp(),
      'resolved_at':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'moderator_notes': moderatorNotes,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

/// Summary of review statistics
class ReviewStatistics {
  final String productId;
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingDistribution; // {1: count, 2: count, etc}
  final int reviewsWithMedia;
  final int verifiedPurchaseReviews;
  final double averageHelpfulnessScore;
  final DateTime lastReviewDate;
  final Map<String, int>
      tagDistribution; // e.g., {'verified-purchase': 45, 'with-photos': 23}

  ReviewStatistics({
    required this.productId,
    required this.totalReviews,
    required this.averageRating,
    required this.ratingDistribution,
    this.reviewsWithMedia = 0,
    this.verifiedPurchaseReviews = 0,
    this.averageHelpfulnessScore = 0.0,
    required this.lastReviewDate,
    this.tagDistribution = const {},
  });

  factory ReviewStatistics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final distMap = (data['rating_distribution'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
        {};

    return ReviewStatistics(
      productId: doc.id,
      totalReviews: data['total_reviews'] ?? 0,
      averageRating: (data['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingDistribution: distMap,
      reviewsWithMedia: data['reviews_with_media'] ?? 0,
      verifiedPurchaseReviews: data['verified_purchase_reviews'] ?? 0,
      averageHelpfulnessScore:
          (data['average_helpfulness_score'] as num?)?.toDouble() ?? 0.0,
      lastReviewDate:
          (data['last_review_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tagDistribution: Map<String, int>.from(data['tag_distribution'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'total_reviews': totalReviews,
      'average_rating': averageRating,
      'rating_distribution':
          ratingDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'reviews_with_media': reviewsWithMedia,
      'verified_purchase_reviews': verifiedPurchaseReviews,
      'average_helpfulness_score': averageHelpfulnessScore,
      'last_review_date': FieldValue.serverTimestamp(),
      'tag_distribution': tagDistribution,
    };
  }

  double getPercentageAtRating(int rating) {
    if (totalReviews == 0) return 0.0;
    final count = ratingDistribution[rating] ?? 0;
    return (count / totalReviews) * 100;
  }

  String getStarDisplay() {
    return '${averageRating.toStringAsFixed(1)} ($totalReviews reviews)';
  }
}
