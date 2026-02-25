import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing order notifications
class OrderNotificationService {
  static final OrderNotificationService _instance =
      OrderNotificationService._internal();

  factory OrderNotificationService() {
    return _instance;
  }

  OrderNotificationService._internal();

  /// Send payment confirmation notification
  Future<void> sendPaymentConfirmedNotification({
    required String userId,
    required String orderId,
    required double amount,
  }) async {
    try {
      // Store notification in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'payment_confirmed',
        'title': 'Payment Confirmed',
        'body':
            'Your payment of ₦${amount.toStringAsFixed(0)} has been confirmed for order #$orderId',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send FCM notification if user has FCM token
      // This would be sent from your backend in production
    } catch (e) {
      print('Error sending payment notification: $e');
    }
  }

  /// Send order shipped notification
  Future<void> sendOrderShippedNotification({
    required String userId,
    required String orderId,
    required String trackingNumber,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'order_shipped',
        'title': 'Order Shipped!',
        'body':
            'Your order #$orderId has been shipped. Tracking: $trackingNumber',
        'orderId': orderId,
        'trackingNumber': trackingNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending shipped notification: $e');
    }
  }

  /// Send order delivered notification
  Future<void> sendOrderDeliveredNotification({
    required String userId,
    required String orderId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'order_delivered',
        'title': 'Delivery Confirmed',
        'body': 'Order #$orderId has been delivered successfully!',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending delivered notification: $e');
    }
  }

  /// Send order pending notification
  Future<void> sendOrderPendingNotification({
    required String userId,
    required String orderId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'order_pending',
        'title': 'Order Confirmed',
        'body': 'Order #$orderId is being prepared for shipment',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending pending notification: $e');
    }
  }

  /// Send payment failed notification
  Future<void> sendPaymentFailedNotification({
    required String userId,
    required String orderId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'payment_failed',
        'title': 'Payment Failed',
        'body': 'Payment for order #$orderId failed. Please try again.',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending failed notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}

/// Riverpod provider for notification service
final orderNotificationServiceProvider =
    Provider<OrderNotificationService>((ref) {
  return OrderNotificationService();
});

/// Watch unread notifications count
final unreadNotificationCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  if (userId.isEmpty) return 0;

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .count()
      .get()
      .then((snapshot) => snapshot.count ?? 0);
});

/// Watch user's notifications in real-time
final userNotificationsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) {
    if (userId.isEmpty) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  },
);

/// Watch notifications for a specific order
final orderNotificationsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, Map<String, String>>(
  (ref, params) {
    final userId = params['userId'] ?? '';
    final orderId = params['orderId'] ?? '';

    if (userId.isEmpty || orderId.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  },
);
