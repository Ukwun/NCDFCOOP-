import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/core/services/activity_tracking_service.dart';

/// Cart activity logging service
/// Logs add to cart, remove from cart, quantity updates
class CartActivityLogger {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityTrackingService _activityTracker;

  CartActivityLogger(this._activityTracker);

  /// Log item added to cart
  Future<void> logCartItemAdded({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required int quantity,
    String? deviceId,
    String? sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot log cart add: User not authenticated');
        return;
      }

      // Log to activity tracker
      await _activityTracker.logActivity(
        type: ActivityType.cartAdd,
        productId: productId,
        productName: productName,
        metadata: {
          'action': 'add_to_cart',
          'category': category,
          'price': price,
          'quantity': quantity,
          'timestamp': DateTime.now().toIso8601String(),
        },
        deviceId: deviceId,
        sessionId: sessionId,
      );

      // Also save to dedicated cart_activities collection for easy querying
      await _firestore
          .collection('user_cart_activities')
          .doc(user.uid)
          .collection('activities')
          .add({
        'userId': user.uid,
        'productId': productId,
        'productName': productName,
        'category': category,
        'action': 'add',
        'price': price,
        'quantity': quantity,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Cart add logged: $productName (qty: $quantity)');
    } catch (e) {
      debugPrint('❌ Error logging cart add: $e');
      // Silent fail - don't block UI
    }
  }

  /// Log item removed from cart
  Future<void> logCartItemRemoved({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required int quantity,
    String? deviceId,
    String? sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot log cart remove: User not authenticated');
        return;
      }

      // Log to activity tracker
      await _activityTracker.logActivity(
        type: ActivityType.cartRemove,
        productId: productId,
        productName: productName,
        metadata: {
          'action': 'remove_from_cart',
          'category': category,
          'price': price,
          'quantity': quantity,
          'timestamp': DateTime.now().toIso8601String(),
        },
        deviceId: deviceId,
        sessionId: sessionId,
      );

      // Also save to dedicated cart_activities collection
      await _firestore
          .collection('user_cart_activities')
          .doc(user.uid)
          .collection('activities')
          .add({
        'userId': user.uid,
        'productId': productId,
        'productName': productName,
        'category': category,
        'action': 'remove',
        'price': price,
        'quantity': quantity,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Cart remove logged: $productName');
    } catch (e) {
      debugPrint('❌ Error logging cart remove: $e');
      // Silent fail - don't block UI
    }
  }

  /// Log cart quantity updated
  Future<void> logCartQuantityUpdated({
    required String productId,
    required String productName,
    required String category,
    required double price,
    required int oldQuantity,
    required int newQuantity,
    String? deviceId,
    String? sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot log quantity update: User not authenticated');
        return;
      }

      // Only log if quantity actually changed
      if (oldQuantity == newQuantity) {
        return;
      }

      final action = newQuantity > oldQuantity ? 'quantity_increase' : 'quantity_decrease';

      // Log to activity tracker
      await _activityTracker.logActivity(
        type: ActivityType.cartAdd, // Use cartAdd as generic cart interaction
        productId: productId,
        productName: productName,
        metadata: {
          'action': action,
          'category': category,
          'price': price,
          'oldQuantity': oldQuantity,
          'newQuantity': newQuantity,
          'quantityChange': newQuantity - oldQuantity,
          'timestamp': DateTime.now().toIso8601String(),
        },
        deviceId: deviceId,
        sessionId: sessionId,
      );

      // Also save to dedicated cart_activities collection
      await _firestore
          .collection('user_cart_activities')
          .doc(user.uid)
          .collection('activities')
          .add({
        'userId': user.uid,
        'productId': productId,
        'productName': productName,
        'category': category,
        'action': 'update_quantity',
        'oldQuantity': oldQuantity,
        'newQuantity': newQuantity,
        'quantityChange': newQuantity - oldQuantity,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Cart quantity updated logged: $productName ($oldQuantity → $newQuantity)');
    } catch (e) {
      debugPrint('❌ Error logging quantity update: $e');
      // Silent fail - don't block UI
    }
  }

  /// Log cart cleared
  Future<void> logCartCleared({
    required int itemCount,
    required double totalValue,
    String? deviceId,
    String? sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Cannot log cart clear: User not authenticated');
        return;
      }

      // Save to dedicated cart_activities collection
      await _firestore
          .collection('user_cart_activities')
          .doc(user.uid)
          .collection('activities')
          .add({
        'userId': user.uid,
        'action': 'clear_cart',
        'itemCount': itemCount,
        'totalValue': totalValue,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Cart cleared logged: $itemCount items (₦${totalValue.toStringAsFixed(2)})');
    } catch (e) {
      debugPrint('❌ Error logging cart clear: $e');
      // Silent fail - don't block UI
    }
  }

  /// Get user's cart activity (for analytics)
  Future<List<Map<String, dynamic>>> getUserCartActivities({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('user_cart_activities')
          .doc(userId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error fetching cart activities: $e');
      return [];
    }
  }

  /// Get cart metrics for user (items added, removed, etc)
  Future<Map<String, dynamic>> getCartMetrics(String userId) async {
    try {
      final activities = await getUserCartActivities(userId: userId, limit: 100);

      int addCount = 0;
      int removeCount = 0;
      int updateCount = 0;
      double totalValueAdded = 0;
      int totalQuantityAdded = 0;

      for (final activity in activities) {
        final action = activity['action'] as String?;

        if (action == 'add') {
          addCount++;
          totalValueAdded += (activity['price'] ?? 0) as double;
          totalQuantityAdded += (activity['quantity'] ?? 0) as int;
        } else if (action == 'remove') {
          removeCount++;
        } else if (action == 'update_quantity') {
          updateCount++;
        }
      }

      return {
        'totalAdds': addCount,
        'totalRemoves': removeCount,
        'totalUpdates': updateCount,
        'totalValueAdded': totalValueAdded,
        'totalQuantityAdded': totalQuantityAdded,
        'averageAddValue': addCount > 0 ? totalValueAdded / addCount : 0,
        'lastActivityTime': activities.isNotEmpty ? activities.first['timestamp'] : null,
      };
    } catch (e) {
      debugPrint('❌ Error calculating cart metrics: $e');
      return {
        'totalAdds': 0,
        'totalRemoves': 0,
        'totalUpdates': 0,
        'totalValueAdded': 0,
        'totalQuantityAdded': 0,
      };
    }
  }
}
