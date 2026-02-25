import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

/// Real user data model with actual Firestore integration
class RealUserData {
  final String userId;
  final String email;
  final String name;
  final String? photoUrl;
  final String tier; // 'regular', 'gold', 'platinum'
  final int rewardsPoints;
  final int lifetimePoints;
  final DateTime memberSince;
  final bool isActive;
  final double totalSpent;
  final int ordersCount;
  final DateTime lastPurchaseDate;
  final List<String> favoriteCategories;
  final double discountPercentage;

  RealUserData({
    required this.userId,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.tier,
    required this.rewardsPoints,
    required this.lifetimePoints,
    required this.memberSince,
    required this.isActive,
    required this.totalSpent,
    required this.ordersCount,
    required this.lastPurchaseDate,
    required this.favoriteCategories,
    required this.discountPercentage,
  });

  factory RealUserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RealUserData(
      userId: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Member',
      photoUrl: data['photoUrl'],
      tier: data['tier'] ?? 'regular',
      rewardsPoints: data['rewardsPoints'] ?? 0,
      lifetimePoints: data['lifetimePoints'] ?? 0,
      memberSince: (data['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      ordersCount: data['ordersCount'] ?? 0,
      lastPurchaseDate: (data['lastPurchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      favoriteCategories: List<String>.from(data['favoriteCategories'] ?? []),
      discountPercentage: (data['discountPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
    'tier': tier,
    'rewardsPoints': rewardsPoints,
    'lifetimePoints': lifetimePoints,
    'memberSince': memberSince,
    'isActive': isActive,
    'totalSpent': totalSpent,
    'ordersCount': ordersCount,
    'lastPurchaseDate': lastPurchaseDate,
    'favoriteCategories': favoriteCategories,
    'discountPercentage': discountPercentage,
  };
}

/// User data service - fetches REAL user data from Firestore
class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  static const String _usersCollection = 'users';
  static const String _activitiesCollection = 'user_activities';
  static const String _ordersCollection = 'orders';

  /// Get current user's real data from Firestore
  Future<RealUserData?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️  No authenticated user');
        return null;
      }

      debugPrint('👤 Fetching current user data from Firestore: ${user.uid}');
      return getUserById(user.uid);
    } catch (e) {
      debugPrint('❌ Error getting current user data: $e');
      return null;
    }
  }

  /// Get user data by ID from Firestore
  Future<RealUserData?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️  User not found in Firestore: $userId');
        return _createDefaultUserData(userId);
      }

      final userData = RealUserData.fromFirestore(doc);
      debugPrint('✅ Fetched user data: ${userData.name} (tier: ${userData.tier})');
      return userData;
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
      return null;
    }
  }

  /// Update user rewards points (add or subtract)
  Future<void> updateRewardsPoints(String userId, int pointsChange) async {
    try {
      debugPrint('💰 Updating rewards for user: $userId (+$pointsChange points)');
      
      await _firestore.collection(_usersCollection).doc(userId).update({
        'rewardsPoints': FieldValue.increment(pointsChange),
        'lifetimePoints': FieldValue.increment(pointsChange),
      });
      debugPrint('✅ Rewards updated');
    } catch (e) {
      debugPrint('❌ Error updating rewards: $e');
    }
  }

  /// Update user membership tier based on spending
  Future<void> updateMembershipTier(String userId) async {
    try {
      final userData = await getUserById(userId);
      if (userData == null) return;

      String newTier = 'regular';
      double discountPercentage = 0;

      // Tier logic based on lifetime spending
      if (userData.totalSpent >= 500000) {
        newTier = 'platinum';
        discountPercentage = 20;
      } else if (userData.totalSpent >= 100000) {
        newTier = 'gold';
        discountPercentage = 15;
      } else if (userData.totalSpent >= 50000) {
        newTier = 'silver';
        discountPercentage = 10;
      }

      if (userData.tier != newTier) {
        debugPrint('⬆️  Upgrading user tier: ${userData.tier} → $newTier');
        
        await _firestore.collection(_usersCollection).doc(userId).update({
          'tier': newTier,
          'discountPercentage': discountPercentage,
        });

        debugPrint('✅ Tier updated to: $newTier');
      }
    } catch (e) {
      debugPrint('❌ Error updating tier: $e');
    }
  }

  /// Record a purchase for user
  Future<void> recordPurchase(
    String userId, {
    required double amount,
    required List<String> productIds,
  }) async {
    try {
      debugPrint('🛒 Recording purchase for user: $userId (₦$amount)');
      
      final rewardsPoints = (amount * 0.01).toInt(); // 1 point per ₦1

      // Update user purchase history
      await _firestore.collection(_usersCollection).doc(userId).update({
        'totalSpent': FieldValue.increment(amount),
        'ordersCount': FieldValue.increment(1),
        'lastPurchaseDate': FieldValue.serverTimestamp(),
        'rewardsPoints': FieldValue.increment(rewardsPoints),
        'lifetimePoints': FieldValue.increment(rewardsPoints),
      });

      debugPrint('✅ Purchase recorded: ₦$amount (earned $rewardsPoints points)');

      // Check if tier should be updated
      await updateMembershipTier(userId);
    } catch (e) {
      debugPrint('❌ Error recording purchase: $e');
    }
  }

  /// Track user activity (view, search, cart, purchase)
  Future<void> trackActivity({
    required String userId,
    required String activityType, // 'view', 'search', 'cart', 'purchase', 'review'
    String? productId,
    String? productName,
    String? category,
    double? price,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activityData = {
        'userId': userId,
        'activityType': activityType,
        'productId': productId,
        'productName': productName,
        'category': category,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      };

      await _firestore.collection(_activitiesCollection).add(activityData);
      debugPrint('✅ Activity tracked: $activityType for user $userId');

      // Update favorite categories
      if (category != null && category.isNotEmpty) {
        await _updateFavoriteCategories(userId, category);
      }
    } catch (e) {
      debugPrint('❌ Error tracking activity: $e');
    }
  }

  /// Get user's favorite categories based on activity
  Future<List<String>> getFavoriteCategories(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return [];

      final favorites = List<String>.from(doc.get('favoriteCategories') ?? []);
      return favorites;
    } catch (e) {
      debugPrint('❌ Error getting favorite categories: $e');
      return [];
    }
  }

  /// Get user's purchase history
  Future<List<Map<String, dynamic>>> getPurchaseHistory(
    String userId, {
    int limit = 10,
  }) async {
    try {
      debugPrint('📜 Fetching purchase history for user: $userId');
      
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final orders = snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();

      debugPrint('✅ Fetched ${orders.length} orders');
      return orders;
    } catch (e) {
      debugPrint('❌ Error fetching purchase history: $e');
      return [];
    }
  }

  /// Get user's recent activity
  Future<List<Map<String, dynamic>>> getRecentActivity(
    String userId, {
    int limit = 20,
  }) async {
    try {
      debugPrint('👀 Fetching recent activities for user: $userId');
      
      final snapshot = await _firestore
          .collection(_activitiesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final activities = snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();

      debugPrint('✅ Fetched ${activities.length} activities');
      return activities;
    } catch (e) {
      debugPrint('❌ Error fetching activities: $e');
      return [];
    }
  }

  /// Stream user data in real-time
  Stream<RealUserData?> streamUserData(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? RealUserData.fromFirestore(doc) : null);
  }

  /// Create initial user document in Firestore after signup
  Future<void> createUserDocument({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      debugPrint('📝 Creating user document in Firestore: $userId');
      
      final userData = RealUserData(
        userId: userId,
        email: email,
        name: name,
        tier: 'regular',
        rewardsPoints: 0,
        lifetimePoints: 0,
        memberSince: DateTime.now(),
        isActive: true,
        totalSpent: 0,
        ordersCount: 0,
        lastPurchaseDate: DateTime.now(),
        favoriteCategories: [],
        discountPercentage: 0,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(userData.toFirestore());

      debugPrint('✅ User document created: $name');
    } catch (e) {
      debugPrint('❌ Error creating user document: $e');
    }
  }

  // Private helpers
  Future<void> _updateFavoriteCategories(String userId, String category) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return;

      final favorites = List<String>.from(doc.get('favoriteCategories') ?? []);
      if (!favorites.contains(category)) {
        favorites.add(category);
        if (favorites.length > 5) {
          favorites.removeAt(0); // Keep only last 5 favorite categories
        }

        await _firestore.collection(_usersCollection).doc(userId).update({
          'favoriteCategories': favorites,
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating favorite categories: $e');
    }
  }

  RealUserData _createDefaultUserData(String userId) {
    return RealUserData(
      userId: userId,
      email: '',
      name: 'New Member',
      tier: 'regular',
      rewardsPoints: 0,
      lifetimePoints: 0,
      memberSince: DateTime.now(),
      isActive: true,
      totalSpent: 0,
      ordersCount: 0,
      lastPurchaseDate: DateTime.now(),
      favoriteCategories: [],
      discountPercentage: 0,
    );
  }
}
