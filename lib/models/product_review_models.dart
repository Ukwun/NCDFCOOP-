import 'package:cloud_firestore/cloud_firestore.dart';

/// Product review data model
class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final int rating; // 1-5 stars
  final String title;
  final String comment;
  final int helpfulCount; // How many found this helpful
  final DateTime createdAt;
  final bool verified; // true if purchaser

  ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.title,
    required this.comment,
    this.helpfulCount = 0,
    required this.createdAt,
    this.verified = false,
  });

  /// Create from Firestore document
  factory ProductReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductReview(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      rating: data['rating'] ?? 5,
      title: data['title'] ?? '',
      comment: data['comment'] ?? '',
      helpfulCount: data['helpfulCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verified: data['verified'] ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'title': title,
      'comment': comment,
      'helpfulCount': helpfulCount,
      'createdAt': FieldValue.serverTimestamp(),
      'verified': verified,
    };
  }
}

/// Product rating summary
class ProductRatingSummary {
  final String productId;
  final double averageRating; // 0.0 - 5.0
  final int totalReviews;
  final Map<int, int> ratingDistribution; // {1: count, 2: count, etc}

  ProductRatingSummary({
    required this.productId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  /// Create from Firestore document
  factory ProductRatingSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final distMap = (data['ratingDistribution'] as Map<String, dynamic>?)?.cast<int, int>() ?? {};
    return ProductRatingSummary(
      productId: doc.id,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] ?? 0,
      ratingDistribution: distMap,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
    };
  }

  /// Get percentage of reviews at specific rating
  double getPercentageAtRating(int rating) {
    if (totalReviews == 0) return 0.0;
    final count = ratingDistribution[rating] ?? 0;
    return (count / totalReviews) * 100;
  }

  /// Get star count display (e.g., "4.5 out of 5")
  String getStarDisplay() {
    return '${averageRating.toStringAsFixed(1)} out of 5';
  }
}

/// Help/feedback submission for review
class ReviewHelpfulness {
  final String reviewId;
  final String userId;
  final bool helpful; // true = helpful, false = not helpful
  final DateTime createdAt;

  ReviewHelpfulness({
    required this.reviewId,
    required this.userId,
    required this.helpful,
    required this.createdAt,
  });

  factory ReviewHelpfulness.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewHelpfulness(
      reviewId: data['reviewId'] ?? '',
      userId: data['userId'] ?? '',
      helpful: data['helpful'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reviewId': reviewId,
      'userId': userId,
      'helpful': helpful,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Mock data for reviews (for testing and offline use)
final mockProductReviews = [
  ProductReview(
    id: 'review_001',
    productId: 'prod_001',
    userId: 'user_001',
    userName: 'Chioma A.',
    rating: 5,
    title: 'Excellent quality rice!',
    comment: 'Best parboiled rice I\'ve bought online. Grains are uniform and very clean. Delivery was fast.',
    helpfulCount: 24,
    createdAt: DateTime.now().subtract(Duration(days: 5)),
    verified: true,
  ),
  ProductReview(
    id: 'review_002',
    productId: 'prod_001',
    userId: 'user_002',
    userName: 'Adeola M.',
    rating: 4,
    title: 'Good quality, minor issue with packaging',
    comment: 'The rice taste is good but the packaging could be better. Some grains leaked into the box.',
    helpfulCount: 12,
    createdAt: DateTime.now().subtract(Duration(days: 10)),
    verified: true,
  ),
  ProductReview(
    id: 'review_003',
    productId: 'prod_002',
    userId: 'user_003',
    userName: 'Oluwaseun B.',
    rating: 5,
    title: 'Perfect beans!',
    comment: 'No stones, properly sorted, cooks evenly. This is my go-to brand now.',
    helpfulCount: 34,
    createdAt: DateTime.now().subtract(Duration(days: 3)),
    verified: true,
  ),
  ProductReview(
    id: 'review_004',
    productId: 'prod_002',
    userId: 'user_004',
    userName: 'Blessing O.',
    rating: 3,
    title: 'Average quality',
    comment: 'Beans are okay but I found a few stones. Price is a bit high compared to market.',
    helpfulCount: 8,
    createdAt: DateTime.now().subtract(Duration(days: 7)),
    verified: true,
  ),
];

final mockRatingSummaries = {
  'prod_001': ProductRatingSummary(
    productId: 'prod_001',
    averageRating: 4.6,
    totalReviews: 156,
    ratingDistribution: {
      5: 112,
      4: 28,
      3: 12,
      2: 3,
      1: 1,
    },
  ),
  'prod_002': ProductRatingSummary(
    productId: 'prod_002',
    averageRating: 4.4,
    totalReviews: 89,
    ratingDistribution: {
      5: 61,
      4: 18,
      3: 7,
      2: 2,
      1: 1,
    },
  ),
};
