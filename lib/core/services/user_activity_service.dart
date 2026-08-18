import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_functions/cloud_functions.dart';

/// User activity model - synced to Firestore
class UserActivity {
  final String id;
  final String userId;
  final String
      activityType; // 'view', 'search', 'add_to_cart', 'purchase', 'review', 'wishlist'
  final String? productId;
  final String? productName;
  final String? category;
  final double? price;
  final int? quantity;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? sessionId;

  UserActivity({
    required this.id,
    required this.userId,
    required this.activityType,
    this.productId,
    this.productName,
    this.category,
    this.price,
    this.quantity,
    this.metadata,
    required this.timestamp,
    this.sessionId,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'activityType': activityType,
        'productId': productId,
        'productName': productName,
        'category': category,
        'price': price,
        'quantity': quantity,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(timestamp),
        'sessionId': sessionId,
      };

  factory UserActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final eventData = data['eventData'] is Map
        ? Map<String, dynamic>.from(data['eventData'] as Map)
        : data['activityData'] is Map
            ? Map<String, dynamic>.from(data['activityData'] as Map)
            : data['details'] is Map
                ? Map<String, dynamic>.from(data['details'] as Map)
                : <String, dynamic>{};
    final metadata = data['metadata'] is Map
        ? Map<String, dynamic>.from(data['metadata'] as Map)
        : <String, dynamic>{};
    metadata.addAll(eventData);
    final rawType = data['activityType'] ??
        data['eventType'] ??
        data['action'] ??
        (data['quoteId'] != null || data['targetUnitPrice'] != null
            ? 'quote_request'
            : null);
    final normalizedType = switch (rawType?.toString()) {
      'product_view' || 'viewed_product' => 'view',
      'product_search' => 'search',
      'cart_add' => 'add_to_cart',
      'purchase_complete' || 'purchase_completed' => 'purchase',
      'review_submitted' => 'review',
      'wishlist_add' => 'wishlist',
      final value when value != null && value.isNotEmpty => value,
      _ => 'unknown',
    };
    DateTime readTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse(value?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return UserActivity(
      id: doc.id,
      userId: data['userId'] ?? data['buyerId'] ?? data['memberId'] ?? '',
      activityType: normalizedType,
      productId: data['productId'] ?? eventData['productId'],
      productName: data['productName'] ?? eventData['productName'],
      category: data['category'] ?? eventData['productCategory'],
      price: (data['price'] as num?)?.toDouble() ??
          (eventData['productPrice'] as num?)?.toDouble(),
      quantity: data['quantity'] ?? eventData['quantity'],
      metadata: metadata.isEmpty ? null : metadata,
      timestamp: readTimestamp(data['timestamp'] ?? data['createdAt']),
      sessionId: data['sessionId'],
    );
  }
}

/// User behavior aggregation (daily summary)
class UserBehaviorSummary {
  final String userId;
  final DateTime date;
  final int viewCount;
  final int searchCount;
  final int cartAddCount;
  final int purchaseCount;
  final double totalSpent;
  final List<String> categoriesViewed; // Unique categories
  final List<String> topProducts; // Most viewed
  final double timeSpentMinutes;

  UserBehaviorSummary({
    required this.userId,
    required this.date,
    required this.viewCount,
    required this.searchCount,
    required this.cartAddCount,
    required this.purchaseCount,
    required this.totalSpent,
    required this.categoriesViewed,
    required this.topProducts,
    required this.timeSpentMinutes,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'viewCount': viewCount,
        'searchCount': searchCount,
        'cartAddCount': cartAddCount,
        'purchaseCount': purchaseCount,
        'totalSpent': totalSpent,
        'categoriesViewed': categoriesViewed,
        'topProducts': topProducts,
        'timeSpentMinutes': timeSpentMinutes,
      };

  factory UserBehaviorSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBehaviorSummary(
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: data['viewCount'] ?? 0,
      searchCount: data['searchCount'] ?? 0,
      cartAddCount: data['cartAddCount'] ?? 0,
      purchaseCount: data['purchaseCount'] ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      categoriesViewed: List<String>.from(data['categoriesViewed'] ?? []),
      topProducts: List<String>.from(data['topProducts'] ?? []),
      timeSpentMinutes: (data['timeSpentMinutes'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Handles all user activity tracking and persistence to Firestore
class UserActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static const String _activitiesCollection = 'user_activities';
  static const String _personalizationCollection =
      'user_personalization_profiles';

  String? _sessionId;

  UserActivityService() {
    _sessionId = _generateSessionId();
  }

  /// Generate unique session ID for this app session
  String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecond % 1000)}';
  }

  /// Get current user ID
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Map<String, dynamic>? _sanitizeMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final sanitized = <String, dynamic>{};
    metadata.forEach((key, value) {
      if (value != null) {
        sanitized[key] = value;
      }
    });
    return sanitized.isEmpty ? null : sanitized;
  }

  UserActivity _buildActivity({
    required String userId,
    required String activityType,
    String? productId,
    String? productName,
    String? category,
    double? price,
    int? quantity,
    Map<String, dynamic>? metadata,
  }) {
    return UserActivity(
      id: '',
      userId: userId,
      activityType: activityType,
      productId: productId,
      productName: productName,
      category: category,
      price: price,
      quantity: quantity,
      metadata: _sanitizeMetadata(metadata),
      timestamp: DateTime.now(),
      sessionId: _sessionId,
    );
  }

  Future<void> _writeActivity(UserActivity activity) async {
    await _firestore
        .collection(_activitiesCollection)
        .add(activity.toFirestore());
  }

  /// Log product view
  Future<void> logProductView({
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return; // Skip if not authenticated

    try {
      // Log locally to Firestore
      await _firestore.collection('user_activities').add(UserActivity(
            id: '', // Will be generated by Firestore
            userId: userId,
            activityType: 'view',
            productId: productId,
            productName: productName,
            category: category,
            price: price,
            timestamp: DateTime.now(),
            sessionId: _sessionId,
          ).toFirestore());

      // Also update behavior summary
      await _updateBehaviorSummary(userId, 'view', category: category);
      await _updatePersonalizationProfile(
        userId: userId,
        category: category,
      );

      // Call Cloud Function to update trending and prepare for recommendations
      try {
        await FirebaseFunctions.instance.httpsCallable('logProductView').call({
          'productId': productId,
          'productName': productName,
          'category': category,
          'price': price,
        });
        debugPrint('✅ Product view logged to backend: $productName');
      } catch (cloudFunctionError) {
        debugPrint(
            '⚠️ Cloud Function call failed (non-critical): $cloudFunctionError');
        // Don't throw - local logging already succeeded
      }
    } catch (e) {
      debugPrint('❌ Error logging product view: $e');
    }
  }

  /// Log search query
  Future<void> logSearch({
    required String query,
    required int resultsCount,
    required String? category,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _firestore.collection('user_activities').add(UserActivity(
            id: '',
            userId: userId,
            activityType: 'search',
            category: category,
            metadata: {
              'query': query,
              'resultsCount': resultsCount,
            },
            timestamp: DateTime.now(),
            sessionId: _sessionId,
          ).toFirestore());

      await _updateBehaviorSummary(userId, 'search', category: category);
      await _updatePersonalizationProfile(
        userId: userId,
        category: category,
      );
    } catch (e) {
      debugPrint('❌ Error logging search: $e');
    }
  }

  /// Log add to cart
  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required int quantity,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _firestore.collection('user_activities').add(UserActivity(
            id: '',
            userId: userId,
            activityType: 'add_to_cart',
            productId: productId,
            productName: productName,
            category: category,
            price: price,
            quantity: quantity,
            timestamp: DateTime.now(),
            sessionId: _sessionId,
          ).toFirestore());

      await _updateBehaviorSummary(userId, 'cart_add', category: category);
      await _updatePersonalizationProfile(
        userId: userId,
        category: category,
      );
    } catch (e) {
      debugPrint('❌ Error logging add to cart: $e');
    }
  }

  /// Log purchase
  Future<void> logPurchase({
    required String orderId,
    required List<String> productIds,
    required List<String> productNames,
    required double totalAmount,
    required List<String> categories,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      // Log purchase activity
      await _firestore.collection('user_activities').add(UserActivity(
            id: '',
            userId: userId,
            activityType: 'purchase',
            metadata: {
              'orderId': orderId,
              'productCount': productIds.length,
              'totalAmount': totalAmount,
              'productIds': productIds,
              'productNames': productNames,
            },
            timestamp: DateTime.now(),
            sessionId: _sessionId,
          ).toFirestore());

      // Update user purchase history
      await _updateUserPurchaseHistory(
          userId, orderId, productIds, totalAmount);

      // Update behavior summary
      await _updateBehaviorSummary(userId, 'purchase',
          amount: totalAmount, categories: categories);

      for (final category in categories) {
        await _updatePersonalizationProfile(
          userId: userId,
          category: category,
          isPurchase: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Error logging purchase: $e');
    }
  }

  /// Log checkout journey start
  Future<void> logCheckoutStarted({
    required double cartTotal,
    required int itemCount,
    String? paymentMethod,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _firestore.collection(_activitiesCollection).add(UserActivity(
            id: '',
            userId: userId,
            activityType: 'checkout_started',
            metadata: {
              'cartTotal': cartTotal,
              'itemCount': itemCount,
              'paymentMethod': paymentMethod,
            },
            timestamp: DateTime.now(),
            sessionId: _sessionId,
          ).toFirestore());
    } catch (e) {
      debugPrint('❌ Error logging checkout start: $e');
    }
  }

  /// Log payment result for observability
  Future<void> logPaymentResult({
    required String orderId,
    required bool success,
    required double amount,
    required String paymentMethod,
    String? errorMessage,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _firestore.collection(_activitiesCollection).add(UserActivity(
            id: '',
            userId: userId,
            activityType: success ? 'payment_success' : 'payment_failed',
            metadata: {
              'orderId': orderId,
              'amount': amount,
              'paymentMethod': paymentMethod,
              'errorMessage': errorMessage,
            },
            timestamp: DateTime.now(),
            sessionId: _sessionId,
          ).toFirestore());
    } catch (e) {
      debugPrint('❌ Error logging payment result: $e');
    }
  }

  /// Log follow seller activity and enrich seller affinity profile
  Future<void> logFollowSeller({
    required String sellerId,
    String? sellerName,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _firestore.collection(_activitiesCollection).add(UserActivity(
            id: '',
            userId: userId,
            activityType: 'follow_seller',
            metadata: {
              'sellerId': sellerId,
              'sellerName': sellerName,
            },
            timestamp: DateTime.now(),
            sessionId: _sessionId,
          ).toFirestore());

      await _updatePersonalizationProfile(
        userId: userId,
        sellerId: sellerId,
      );
    } catch (e) {
      debugPrint('❌ Error logging seller follow: $e');
    }
  }

  /// Log add to wishlist
  Future<void> logAddToWishlist({
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _firestore.collection('user_activities').add(UserActivity(
            id: '',
            userId: userId,
            activityType: 'wishlist',
            productId: productId,
            productName: productName,
            category: category,
            price: price,
            timestamp: DateTime.now(),
            sessionId: _sessionId,
          ).toFirestore());

      await _updateBehaviorSummary(userId, 'wishlist', category: category);
      await _updatePersonalizationProfile(
        userId: userId,
        category: category,
      );
    } catch (e) {
      debugPrint('❌ Error logging wishlist: $e');
    }
  }

  /// Log product review
  Future<void> logProductReview({
    required String productId,
    required String productName,
    required String category,
    required double rating,
    required String reviewText,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _firestore.collection('user_activities').add(UserActivity(
            id: '',
            userId: userId,
            activityType: 'review',
            productId: productId,
            productName: productName,
            category: category,
            metadata: {
              'rating': rating,
              'reviewText': reviewText,
            },
            timestamp: DateTime.now(),
            sessionId: _sessionId,
          ).toFirestore());

      await _updateBehaviorSummary(userId, 'review');
      await _updatePersonalizationProfile(
        userId: userId,
        category: category,
      );
    } catch (e) {
      debugPrint('❌ Error logging review: $e');
    }
  }

  /// Log membership purchase/upgrade event.
  Future<void> logMembershipPurchase({
    required String membershipType,
    required double amount,
    String? duration,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _writeActivity(_buildActivity(
        userId: userId,
        activityType: 'membership_purchase',
        metadata: {
          'membershipType': membershipType,
          'amount': amount,
          'duration': duration,
        },
      ));

      await _updateBehaviorSummary(userId, 'membership_purchase',
          amount: amount);
      await _updatePersonalizationProfile(userId: userId, isPurchase: true);
    } catch (e) {
      debugPrint('❌ Error logging membership purchase: $e');
    }
  }

  /// Log authentication sign-in.
  Future<void> logLogin({
    String? method,
    bool isNewUser = false,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      _sessionId = _generateSessionId();
      await _writeActivity(_buildActivity(
        userId: userId,
        activityType: 'login',
        metadata: {
          'method': method,
          'isNewUser': isNewUser,
        },
      ));
    } catch (e) {
      debugPrint('❌ Error logging login: $e');
    }
  }

  /// Log authentication sign-out.
  Future<void> logLogout({
    String? reason,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _writeActivity(_buildActivity(
        userId: userId,
        activityType: 'logout',
        metadata: {
          'reason': reason,
        },
      ));
    } catch (e) {
      debugPrint('❌ Error logging logout: $e');
    }
  }

  /// Log route/screen visibility.
  Future<void> logScreenView({
    required String screenName,
    String? route,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _writeActivity(_buildActivity(
        userId: userId,
        activityType: 'screen_view',
        metadata: {
          'screenName': screenName,
          'route': route,
        },
      ));
    } catch (e) {
      debugPrint('❌ Error logging screen view: $e');
    }
  }

  /// Log explicit button/icon interaction.
  Future<void> logButtonTap({
    required String buttonName,
    String? screenName,
    String? context,
    bool? success,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _writeActivity(_buildActivity(
        userId: userId,
        activityType: 'button_tap',
        metadata: {
          'buttonName': buttonName,
          'screenName': screenName,
          'context': context,
          'success': success,
        },
      ));
    } catch (e) {
      debugPrint('❌ Error logging button tap: $e');
    }
  }

  /// Get user's activity history (for recommendations)
  Future<List<UserActivity>> getUserActivityHistory({
    required String userId,
    int limit = 100,
    String? activityType,
  }) async {
    try {
      Query query = _firestore
          .collection(_activitiesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (activityType != null) {
        query = query.where('activityType', isEqualTo: activityType);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserActivity.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      // Common production case: rules or offline mode; caller will fallback.
      if (e.code == 'permission-denied' || e.code == 'unavailable') {
        return [];
      }
      debugPrint('⚠️ Activity history fetch issue: ${e.code}');
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Stream user activity timeline in real-time
  Stream<List<UserActivity>> watchUserActivity({
    required String userId,
    int limit = 100,
  }) {
    try {
      final controller = StreamController<List<UserActivity>>();
      final bySource = <String, List<UserActivity>>{};
      final subscriptions = <StreamSubscription<QuerySnapshot>>[];
      void emit() {
        final merged = <String, UserActivity>{};
        for (final entry in bySource.entries) {
          for (final activity in entry.value) {
            final canonicalSource = entry.key.split(':').first;
            merged['$canonicalSource:${activity.id}'] = activity;
          }
        }
        final result = merged.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        if (!controller.isClosed) {
          controller.add(result.take(limit).toList());
        }
      }

      void listenToSource(
        String sourceKey,
        Query<Map<String, dynamic>> query,
      ) {
        subscriptions.add(query.limit(limit).snapshots().listen((snapshot) {
          bySource[sourceKey] = snapshot.docs
              .map(UserActivity.fromFirestore)
              .where((activity) =>
                  activity.userId.isEmpty || activity.userId == userId)
              .toList();
          emit();
        }, onError: (Object error) {
          debugPrint('Activity source $sourceKey unavailable: $error');
          bySource[sourceKey] = const [];
          emit();
        }));
      }

      for (final collectionName in [_activitiesCollection, 'activityLogs']) {
        final base = _firestore
            .collection(collectionName)
            .where('userId', isEqualTo: userId);
        listenToSource('$collectionName:timestamp',
            base.orderBy('timestamp', descending: true));
        listenToSource('$collectionName:createdAt',
            base.orderBy('createdAt', descending: true));
      }
      listenToSource(
        'user_activities_nested',
        _firestore
            .collection(_activitiesCollection)
            .doc(userId)
            .collection('activities')
            .orderBy('timestamp', descending: true),
      );
      listenToSource(
        'quote_requests:buyerId',
        _firestore
            .collection('quote_requests')
            .where('buyerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true),
      );
      listenToSource(
        'quote_requests:userId',
        _firestore
            .collection('quote_requests')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true),
      );
      controller.onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
      return controller.stream;
    } catch (e) {
      debugPrint('⚠️ Activity stream fallback for user $userId: $e');
      return Stream.value(const <UserActivity>[]);
    }
  }

  /// Stream global activities for admin observability
  Stream<List<UserActivity>> watchGlobalActivity({
    int limit = 1000,
  }) async* {
    try {
      await for (final snapshot in _firestore
          .collection(_activitiesCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()) {
        yield snapshot.docs.map(UserActivity.fromFirestore).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Global activity stream fallback: $e');
      yield const [];
    }
  }

  /// Aggregate role-specific behavior for dashboards.
  Future<Map<String, dynamic>> getRoleBehaviorSummary({
    required String role,
    int days = 7,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection(_activitiesCollection)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .orderBy('timestamp', descending: true)
          .limit(2000)
          .get();

      int total = 0;
      final byType = <String, int>{};
      final uniqueUsers = <String>{};

      for (final doc in snapshot.docs) {
        final activity = UserActivity.fromFirestore(doc);
        final activityRole = activity.metadata?['role']?.toString();
        if (activityRole != null && activityRole != role) continue;

        total += 1;
        uniqueUsers.add(activity.userId);
        byType[activity.activityType] =
            (byType[activity.activityType] ?? 0) + 1;
      }

      return {
        'role': role,
        'days': days,
        'totalEvents': total,
        'activeUsers': uniqueUsers.length,
        'eventsByType': byType,
      };
    } catch (e) {
      debugPrint('⚠️ Failed to get role behavior summary: $e');
      return {
        'role': role,
        'days': days,
        'totalEvents': 0,
        'activeUsers': 0,
        'eventsByType': <String, int>{},
      };
    }
  }

  Future<String> _resolvePrimaryRole(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      if (data == null) return 'unknown';

      final roles = data['roles'];
      if (roles is List && roles.isNotEmpty) {
        return roles.first.toString();
      }

      final role = data['role'];
      if (role is String && role.isNotEmpty) {
        return role;
      }
    } catch (e) {
      debugPrint('⚠️ Unable to resolve user role: $e');
    }
    return 'unknown';
  }

  Map<String, int> _stringIntMap(dynamic source) {
    final result = <String, int>{};
    if (source is Map) {
      for (final entry in source.entries) {
        result[entry.key.toString()] = (entry.value as num?)?.toInt() ?? 0;
      }
    }
    return result;
  }

  List<String> _topKeys(Map<String, int> source, {int limit = 5}) {
    final sorted = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  Future<void> _updatePersonalizationProfile({
    required String userId,
    String? category,
    String? sellerId,
    bool isPurchase = false,
  }) async {
    try {
      final now = Timestamp.now();
      final docRef =
          _firestore.collection(_personalizationCollection).doc(userId);
      final existing = await docRef.get();
      final existingData = existing.data() ?? <String, dynamic>{};

      final categoryScores = _stringIntMap(existingData['categoryScores']);
      if (category != null && category.isNotEmpty) {
        categoryScores[category] = (categoryScores[category] ?? 0) + 1;
      }

      final sellerAffinity = _stringIntMap(existingData['sellerAffinity']);
      if (sellerId != null && sellerId.isNotEmpty) {
        sellerAffinity[sellerId] = (sellerAffinity[sellerId] ?? 0) + 1;
      }

      final currentPurchaseFrequency =
          (existingData['purchaseFrequency'] as num?)?.toInt() ?? 0;

      final role = await _resolvePrimaryRole(userId);

      await docRef.set({
        'userId': userId,
        'role': role,
        'purchaseFrequency': isPurchase
            ? currentPurchaseFrequency + 1
            : currentPurchaseFrequency,
        'preferredCategories': _topKeys(categoryScores, limit: 5),
        'categoryScores': categoryScores,
        'sellerAffinity': sellerAffinity,
        'topSellerAffinity': _topKeys(sellerAffinity, limit: 5),
        'lastActivityAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ Failed to update personalization profile: $e');
    }
  }

  /// Get user behavior summary for today
  Future<UserBehaviorSummary?> getTodayBehaviorSummary(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('user_behavior_summaries')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserBehaviorSummary.fromFirestore(snapshot.docs.first);
      }
      return null;
    } on FirebaseException catch (e) {
      // Quiet fallback for auth/rules/connectivity instability.
      if (e.code == 'permission-denied' || e.code == 'unavailable') {
        return null;
      }
      debugPrint('⚠️ Behavior summary fetch issue: ${e.code}');
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update behavior summary document
  Future<void> _updateBehaviorSummary(
    String userId,
    String activity, {
    String? category,
    double? amount,
    List<String>? categories,
  }) async {
    try {
      final today = DateTime.now();
      final docId = '${userId}_${today.year}${today.month}${today.day}';

      final docRef =
          _firestore.collection('user_behavior_summaries').doc(docId);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Create new summary
        await docRef.set(UserBehaviorSummary(
          userId: userId,
          date: DateTime(today.year, today.month, today.day),
          viewCount: activity == 'view' ? 1 : 0,
          searchCount: activity == 'search' ? 1 : 0,
          cartAddCount: activity == 'cart_add' ? 1 : 0,
          purchaseCount: activity == 'purchase' ? 1 : 0,
          totalSpent: amount ?? 0,
          categoriesViewed: category != null ? [category] : [],
          topProducts: [],
          timeSpentMinutes: 0,
        ).toFirestore());
      } else {
        // Update existing summary
        final summary = UserBehaviorSummary.fromFirestore(doc);

        int newViewCount = summary.viewCount + (activity == 'view' ? 1 : 0);
        int newSearchCount =
            summary.searchCount + (activity == 'search' ? 1 : 0);
        int newCartCount =
            summary.cartAddCount + (activity == 'cart_add' ? 1 : 0);
        int newPurchaseCount =
            summary.purchaseCount + (activity == 'purchase' ? 1 : 0);
        double newTotal = summary.totalSpent + (amount ?? 0);

        List<String> newCategories = [...summary.categoriesViewed];
        if (category != null && !newCategories.contains(category)) {
          newCategories.add(category);
        }
        if (categories != null) {
          for (final cat in categories) {
            if (!newCategories.contains(cat)) {
              newCategories.add(cat);
            }
          }
        }

        await docRef.update({
          'viewCount': newViewCount,
          'searchCount': newSearchCount,
          'cartAddCount': newCartCount,
          'purchaseCount': newPurchaseCount,
          'totalSpent': newTotal,
          'categoriesViewed': newCategories,
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating behavior summary: $e');
    }
  }

  /// Update user purchase history for quick access
  Future<void> _updateUserPurchaseHistory(
    String userId,
    String orderId,
    List<String> productIds,
    double totalAmount,
  ) async {
    try {
      await _firestore.collection('user_purchase_history').doc(userId).update({
        'totalPurchases': FieldValue.increment(1),
        'totalSpent': FieldValue.increment(totalAmount),
        'lastPurchaseDate': Timestamp.now(),
        'recentOrders': FieldValue.arrayUnion([orderId]),
        'purchasedProductIds': FieldValue.arrayUnion(productIds),
      }).catchError((_) async {
        // Create new document if it doesn't exist
        await _firestore.collection('user_purchase_history').doc(userId).set({
          'userId': userId,
          'totalPurchases': 1,
          'totalSpent': totalAmount,
          'firstPurchaseDate': Timestamp.now(),
          'lastPurchaseDate': Timestamp.now(),
          'recentOrders': [orderId],
          'purchasedProductIds': productIds,
        });
      });
    } catch (e) {
      debugPrint('❌ Error updating purchase history: $e');
    }
  }

  /// Get recommended products based on user activity
  Future<List<String>> getRecommendedProducts({
    required String userId,
    int limit = 10,
  }) async {
    try {
      // Get user's most viewed categories
      final summary = await getTodayBehaviorSummary(userId);
      if (summary == null || summary.categoriesViewed.isEmpty) {
        return [];
      }

      // Get products from those categories that user hasn't viewed
      final activities =
          await getUserActivityHistory(userId: userId, limit: 500);
      final viewedProductIds = activities
          .where((a) => a.activityType == 'view')
          .map((a) => a.productId)
          .whereType<String>()
          .toSet();

      // Query recommended products
      final snapshot = await _firestore
          .collection('products')
          .where('category', whereIn: summary.categoriesViewed)
          .limit(limit * 2)
          .get();

      return snapshot.docs
          .map((doc) => doc.id)
          .where((id) => !viewedProductIds.contains(id))
          .take(limit)
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unavailable') {
        return [];
      }
      debugPrint('⚠️ Recommendation fetch issue: ${e.code}');
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get user's frequently purchased categories
  Future<List<String>> getFavoriteCategories(String userId) async {
    try {
      final purchases = await getUserActivityHistory(
        userId: userId,
        limit: 100,
        activityType: 'purchase',
      );

      final categories = <String, int>{};
      for (final activity in purchases) {
        if (activity.category != null) {
          categories[activity.category!] =
              (categories[activity.category] ?? 0) + 1;
        }
      }

      // Sort by frequency
      final sorted = categories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.map((e) => e.key).take(5).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unavailable') {
        return [];
      }
      debugPrint('⚠️ Favorite category fetch issue: ${e.code}');
      return [];
    } catch (e) {
      return [];
    }
  }
}
