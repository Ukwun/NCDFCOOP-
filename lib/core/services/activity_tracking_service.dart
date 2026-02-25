import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Activity event types
enum ActivityType {
  productView,
  cartAdd,
  cartRemove,
  wishlistAdd,
  wishlistRemove,
  purchase,
  review,
  search,
}

extension ActivityTypeExt on ActivityType {
  String get value {
    switch (this) {
      case ActivityType.productView:
        return 'product_view';
      case ActivityType.cartAdd:
        return 'cart_add';
      case ActivityType.cartRemove:
        return 'cart_remove';
      case ActivityType.wishlistAdd:
        return 'wishlist_add';
      case ActivityType.wishlistRemove:
        return 'wishlist_remove';
      case ActivityType.purchase:
        return 'purchase';
      case ActivityType.review:
        return 'review';
      case ActivityType.search:
        return 'search';
    }
  }
}

/// User activity event model
class UserActivityEvent {
  final String id;
  final String userId;
  final ActivityType type;
  final DateTime timestamp;
  final String? productId;
  final String? productName;
  final Map<String, dynamic>? metadata;
  final String? deviceId;
  final String? sessionId;

  UserActivityEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    this.productId,
    this.productName,
    this.metadata,
    this.deviceId,
    this.sessionId,
  });

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.value,
    'timestamp': timestamp,
    'productId': productId,
    'productName': productName,
    'metadata': metadata,
    'deviceId': deviceId,
    'sessionId': sessionId,
  };

  /// Create from JSON
  factory UserActivityEvent.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'] as String?;
    ActivityType type = ActivityType.productView;
    
    switch (typeValue) {
      case 'product_view':
        type = ActivityType.productView;
        break;
      case 'cart_add':
        type = ActivityType.cartAdd;
        break;
      case 'cart_remove':
        type = ActivityType.cartRemove;
        break;
      case 'wishlist_add':
        type = ActivityType.wishlistAdd;
        break;
      case 'wishlist_remove':
        type = ActivityType.wishlistRemove;
        break;
      case 'purchase':
        type = ActivityType.purchase;
        break;
      case 'review':
        type = ActivityType.review;
        break;
      case 'search':
        type = ActivityType.search;
        break;
    }

    return UserActivityEvent(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: type,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      deviceId: json['deviceId'] as String?,
      sessionId: json['sessionId'] as String?,
    );
  }

  /// Create a copy with modified fields
  UserActivityEvent copyWith({
    String? id,
    String? userId,
    ActivityType? type,
    DateTime? timestamp,
    String? productId,
    String? productName,
    Map<String, dynamic>? metadata,
    String? deviceId,
    String? sessionId,
  }) {
    return UserActivityEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      metadata: metadata ?? this.metadata,
      deviceId: deviceId ?? this.deviceId,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

/// Service for tracking and persisting user activities to Firestore
class ActivityTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _usersCollection = 'users';
  static const String _activitiesSubcollection = 'activities';
  static const String _activitiesAnalyticsCollection = 'user_activities_analytics';

  /// Log a user activity event to Firestore
  Future<void> logActivity({
    required ActivityType type,
    String? productId,
    String? productName,
    Map<String, dynamic>? metadata,
    String? deviceId,
    String? sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️  Cannot log activity - user not authenticated');
        return;
      }

      final now = DateTime.now();
      final event = UserActivityEvent(
        id: _firestore.collection('dummy').doc().id,
        userId: user.uid,
        type: type,
        timestamp: now,
        productId: productId,
        productName: productName,
        metadata: metadata,
        deviceId: deviceId,
        sessionId: sessionId,
      );

      // Store in activities subcollection
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_activitiesSubcollection)
          .doc(event.id)
          .set(event.toJson());

      // Also store in analytics collection for easy querying
      await _firestore
          .collection(_activitiesAnalyticsCollection)
          .doc(event.id)
          .set(event.toJson());

      debugPrint('✅ Activity logged: ${event.type.value}');
    } catch (e) {
      debugPrint('❌ Error logging activity: $e');
    }
  }

  /// Log product view
  Future<void> logProductView({
    required String productId,
    required String productName,
    String? deviceId,
    String? sessionId,
  }) => logActivity(
    type: ActivityType.productView,
    productId: productId,
    productName: productName,
    deviceId: deviceId,
    sessionId: sessionId,
  );

  /// Log cart add
  Future<void> logCartAdd({
    required String productId,
    required String productName,
    required int quantity,
    required double price,
    String? deviceId,
    String? sessionId,
  }) => logActivity(
    type: ActivityType.cartAdd,
    productId: productId,
    productName: productName,
    metadata: {
      'quantity': quantity,
      'price': price,
    },
    deviceId: deviceId,
    sessionId: sessionId,
  );

  /// Log cart remove
  Future<void> logCartRemove({
    required String productId,
    required String productName,
    String? deviceId,
    String? sessionId,
  }) => logActivity(
    type: ActivityType.cartRemove,
    productId: productId,
    productName: productName,
    deviceId: deviceId,
    sessionId: sessionId,
  );

  /// Log wishlist add
  Future<void> logWishlistAdd({
    required String productId,
    required String productName,
    String? deviceId,
    String? sessionId,
  }) => logActivity(
    type: ActivityType.wishlistAdd,
    productId: productId,
    productName: productName,
    deviceId: deviceId,
    sessionId: sessionId,
  );

  /// Log wishlist remove
  Future<void> logWishlistRemove({
    required String productId,
    required String productName,
    String? deviceId,
    String? sessionId,
  }) => logActivity(
    type: ActivityType.wishlistRemove,
    productId: productId,
    productName: productName,
    deviceId: deviceId,
    sessionId: sessionId,
  );

  /// Log purchase
  Future<void> logPurchase({
    required String orderId,
    required List<String> productIds,
    required double totalAmount,
    String? deviceId,
    String? sessionId,
  }) => logActivity(
    type: ActivityType.purchase,
    metadata: {
      'orderId': orderId,
      'productIds': productIds,
      'totalAmount': totalAmount,
      'itemCount': productIds.length,
    },
    deviceId: deviceId,
    sessionId: sessionId,
  );

  /// Log product review
  Future<void> logReview({
    required String productId,
    required String productName,
    required int rating,
    String? deviceId,
    String? sessionId,
  }) => logActivity(
    type: ActivityType.review,
    productId: productId,
    productName: productName,
    metadata: {
      'rating': rating,
    },
    deviceId: deviceId,
    sessionId: sessionId,
  );

  /// Log search
  Future<void> logSearch({
    required String searchQuery,
    required int resultsCount,
    String? deviceId,
    String? sessionId,
  }) => logActivity(
    type: ActivityType.search,
    metadata: {
      'query': searchQuery,
      'resultsCount': resultsCount,
    },
    deviceId: deviceId,
    sessionId: sessionId,
  );

  /// Get user activity history
  Future<List<UserActivityEvent>> getUserActivityHistory({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    ActivityType? filterType,
    int limit = 100,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('⚠️  Cannot get activity history - user not authenticated');
        return [];
      }

      var query = _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_activitiesSubcollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // Apply filters
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      if (filterType != null) {
        query = query.where('type', isEqualTo: filterType.value);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserActivityEvent.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting activity history: $e');
      return [];
    }
  }

  /// Stream user activity history
  Stream<List<UserActivityEvent>> streamUserActivityHistory({
    String? userId,
    ActivityType? filterType,
    int limit = 50,
  }) {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return Stream.value([]);
      }

      var query = _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_activitiesSubcollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (filterType != null) {
        query = query.where('type', isEqualTo: filterType.value);
      }

      return query.snapshots().map((snapshot) =>
          snapshot.docs
              .map((doc) => UserActivityEvent.fromJson(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('❌ Error streaming activity: $e');
      return Stream.value([]);
    }
  }

  /// Get activity analytics for a user
  Future<Map<String, dynamic>> getUserActivityAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return {};
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_activitiesSubcollection) as Query<Map<String, dynamic>>;

      // Apply date filters
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final events = snapshot.docs.map((doc) => UserActivityEvent.fromJson(doc.data())).toList();

      // Calculate analytics
      final Map<String, int> typeCount = {};
      int totalProductViews = 0;
      int totalPurchases = 0;
      double totalSpent = 0.0;
      final Set<String> viewedProducts = {};

      for (final event in events) {
        // Count by type
        typeCount[event.type.value] = (typeCount[event.type.value] ?? 0) + 1;

        // Product views
        if (event.type == ActivityType.productView && event.productId != null) {
          totalProductViews++;
          viewedProducts.add(event.productId!);
        }

        // Purchases
        if (event.type == ActivityType.purchase) {
          totalPurchases++;
          totalSpent += (event.metadata?['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return {
        'totalEvents': events.length,
        'byType': typeCount,
        'totalProductViews': totalProductViews,
        'uniqueProductsViewed': viewedProducts.length,
        'totalPurchases': totalPurchases,
        'totalSpent': totalSpent,
        'averageSpentPerPurchase': totalPurchases > 0 ? totalSpent / totalPurchases : 0.0,
      };
    } catch (e) {
      debugPrint('❌ Error getting analytics: $e');
      return {};
    }
  }

  /// Get trending products across all users
  Future<List<Map<String, dynamic>>> getTrendingProducts({
    Duration period = const Duration(days: 30),
    int limit = 10,
  }) async {
    try {
      final startDate = DateTime.now().subtract(period);

      final snapshot = await _firestore
          .collection(_activitiesAnalyticsCollection)
          .where('type', isEqualTo: 'product_view')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .get();

      // Count product views
      final productCounts = <String, int>{};
      final productNames = <String, String>{};

      for (final doc in snapshot.docs) {
        final event = UserActivityEvent.fromJson(doc.data());
        if (event.productId != null) {
          productCounts[event.productId!] = (productCounts[event.productId!] ?? 0) + 1;
          if (event.productName != null) {
            productNames[event.productId!] = event.productName!;
          }
        }
      }

      // Sort by count and return top N
      final sortedEntries = productCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      
      final sorted = sortedEntries
          .take(limit)
          .map((e) => {
            'productId': e.key,
            'productName': productNames[e.key] ?? '',
            'viewCount': e.value,
          })
          .toList();

      return sorted;
    } catch (e) {
      debugPrint('❌ Error getting trending products: $e');
      return [];
    }
  }

  /// Get recommended products based on user's viewing history
  Future<List<String>> getRecommendations({
    String? userId,
    int limit = 5,
  }) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return [];
      }

      // Get user's recently viewed products
      final viewedProducts = await getUserActivityHistory(
        userId: uid,
        filterType: ActivityType.productView,
        limit: 20,
      );

      // For now, return viewed products (can be enhanced with ML recommendations)
      return viewedProducts
          .where((event) => event.productId != null)
          .map((event) => event.productId!)
          .toList()
          .take(limit)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting recommendations: $e');
      return [];
    }
  }

  /// Clear user's activity data (for privacy/GDPR)
  Future<void> clearUserActivityData({String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return;
      }

      final batch = _firestore.batch();

      // Delete activities subcollection
      final activities = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_activitiesSubcollection)
          .get();

      for (final doc in activities.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Activity data cleared for user: $uid');
    } catch (e) {
      debugPrint('❌ Error clearing activity data: $e');
    }
  }
}

extension ListExt<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compareFn) {
    final list = List<T>.from(this);
    list.sort(compareFn);
    return list;
  }
}
