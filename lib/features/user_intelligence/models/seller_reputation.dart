import 'package:cloud_firestore/cloud_firestore.dart';

/// Seller reputation model
/// Tracks seller reputation, ratings, and performance metrics
class SellerReputation {
  final String id; // Seller user ID
  final double averageRating; // 0-5 star rating
  final int totalReviews; // Total number of reviews
  final int totalSales; // Total number of completed sales
  final int returnedOrders; // Number of returned orders
  final int cancelledOrders; // Number of cancelled orders
  final double responseTime; // Average response time in hours
  final bool isVerified; // Whether seller is verified
  final bool isActive; // Whether seller is actively selling
  final String tier; // Seller tier: bronze, silver, gold, platinum
  final double trustScore; // Computed trust score 0-100
  final DateTime createdAt;
  final DateTime lastUpdated;
  final Map<String, dynamic>? badges; // Special badges (eco, fast, etc.)

  const SellerReputation({
    required this.id,
    required this.averageRating,
    required this.totalReviews,
    required this.totalSales,
    required this.returnedOrders,
    required this.cancelledOrders,
    required this.responseTime,
    required this.isVerified,
    required this.isActive,
    required this.tier,
    required this.trustScore,
    required this.createdAt,
    required this.lastUpdated,
    this.badges,
  });

  /// Create from Firestore document
  factory SellerReputation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document does not exist');
    }

    return SellerReputation(
      id: doc.id,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      totalSales: data['totalSales'] as int? ?? 0,
      returnedOrders: data['returnedOrders'] as int? ?? 0,
      cancelledOrders: data['cancelledOrders'] as int? ?? 0,
      responseTime: (data['responseTime'] as num?)?.toDouble() ?? 0.0,
      isVerified: data['isVerified'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      tier: data['tier'] as String? ?? 'bronze',
      trustScore: (data['trustScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      badges: data['badges'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalSales': totalSales,
      'returnedOrders': returnedOrders,
      'cancelledOrders': cancelledOrders,
      'responseTime': responseTime,
      'isVerified': isVerified,
      'isActive': isActive,
      'tier': tier,
      'trustScore': trustScore,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
      'badges': badges,
    };
  }

  /// Get reputation status based on metrics
  String getReputationStatus() {
    if (averageRating >= 4.7 && totalReviews >= 50) {
      return 'Excellent';
    } else if (averageRating >= 4.3 && totalReviews >= 20) {
      return 'Very Good';
    } else if (averageRating >= 3.8 && totalReviews >= 10) {
      return 'Good';
    } else if (averageRating >= 3.0) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  /// Check if seller is trustworthy
  bool isTrustworthy() {
    return trustScore >= 70 && isVerified && totalReviews >= 10;
  }

  /// Copy with new values
  SellerReputation copyWith({
    String? id,
    double? averageRating,
    int? totalReviews,
    int? totalSales,
    int? returnedOrders,
    int? cancelledOrders,
    double? responseTime,
    bool? isVerified,
    bool? isActive,
    String? tier,
    double? trustScore,
    DateTime? createdAt,
    DateTime? lastUpdated,
    Map<String, dynamic>? badges,
  }) {
    return SellerReputation(
      id: id ?? this.id,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalSales: totalSales ?? this.totalSales,
      returnedOrders: returnedOrders ?? this.returnedOrders,
      cancelledOrders: cancelledOrders ?? this.cancelledOrders,
      responseTime: responseTime ?? this.responseTime,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      tier: tier ?? this.tier,
      trustScore: trustScore ?? this.trustScore,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      badges: badges ?? this.badges,
    );
  }
}
