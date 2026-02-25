import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/core/providers/order_providers.dart'
    show OrderStatusNotification;

/// Firebase Cloud Messaging service for push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();

  late final FirebaseMessaging _firebaseMessaging;

  // Callbacks for notification handling
  Function(RemoteMessage)? onMessageCallback;
  Function(RemoteMessage)? onMessageOpenedCallback;
  Function(RemoteMessage)? onBackgroundMessageCallback;

  factory FCMService() {
    return _instance;
  }

  FCMService._internal() {
    _firebaseMessaging = FirebaseMessaging.instance;
  }

  /// Initialize FCM and request notification permissions
  Future<void> initialize() async {
    try {
      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('FCM Notification Permission: ${settings.authorizationStatus}');
      }

      // Get FCM token for sending messages
      final token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('FCM Token Refreshed: $newToken');
        }
        _uploadTokenToFirebase(newToken);
      });

      if (kDebugMode) {
        print('FCM Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Handling foreground message: ${message.messageId}');
    }

    if (onMessageCallback != null) {
      onMessageCallback!(message);
    }
  }

  /// Handle message opened from notification tap
  void _handleMessageOpened(RemoteMessage message) {
    if (kDebugMode) {
      print('Message opened: ${message.messageId}');
    }

    if (onMessageOpenedCallback != null) {
      onMessageOpenedCallback!(message);
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Upload token to Firestore for targeted notifications
  Future<void> _uploadTokenToFirebase(String token) async {
    try {
      // This would be implemented based on your auth service
      // Example: firestore.collection('users').doc(userId).update({'fcmToken': token})
      if (kDebugMode) {
        print('Token uploaded to Firebase: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading token: $e');
      }
    }
  }

  /// Parse order status notification from FCM payload
  static OrderStatusNotification? parseOrderNotification(
      RemoteMessage message) {
    try {
      final data = message.data;

      if (!data.containsKey('orderStatus') || !data.containsKey('orderId')) {
        return null;
      }

      return OrderStatusNotification(
        orderId: data['orderId'] as String,
        previousStatus: data['previousStatus'] as String? ?? '',
        currentStatus: data['orderStatus'] as String,
        title: data['title'] as String? ?? 'Order Update',
        message: data['message'] as String? ?? 'Your order has been updated',
        timestamp: DateTime.parse(
            data['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing order notification: $e');
      }
      return null;
    }
  }

  /// Check if message is from order system
  static bool isOrderNotification(RemoteMessage message) {
    return message.data.containsKey('orderStatus') &&
        message.data.containsKey('orderId');
  }

  /// Get notification title for order status
  static String getNotificationTitle(String status) {
    return switch (status) {
      'confirmed' => 'Order Confirmed ✓',
      'processing' => 'Processing Order',
      'dispatched' => 'Order Dispatched 🚚',
      'outForDelivery' => 'Out for Delivery',
      'delivered' => 'Order Delivered! 🎉',
      'cancelled' => 'Order Cancelled',
      'failed' => 'Order Failed ⚠️',
      _ => 'Order Update',
    };
  }

  /// Get notification message for order status
  static String getNotificationMessage(String status) {
    return switch (status) {
      'confirmed' => 'Your order has been confirmed and is being prepared',
      'processing' => 'Your items are being prepared for shipment',
      'dispatched' => 'Your order has been dispatched and is on the way',
      'outForDelivery' => 'Your delivery is out for delivery today',
      'delivered' => 'Your order has been delivered successfully',
      'cancelled' => 'Your order has been cancelled',
      'failed' => 'Your order processing failed. Please contact support',
      _ => 'Your order status has been updated',
    };
  }
}

/// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }

  // Handle the message
  if (FCMService.isOrderNotification(message)) {
    final notification = FCMService.parseOrderNotification(message);
    if (kDebugMode && notification != null) {
      print('Background order notification: ${notification.currentStatus}');
    }
  }
}

/// Extension on OrderStatusNotification for FCM compatibility
extension OrderStatusNotificationFCM on OrderStatusNotification {
  /// Convert to FCM notification payload
  Map<String, dynamic> toFCMPayload() {
    return {
      'orderId': orderId,
      'orderStatus': currentStatus,
      'previousStatus': previousStatus,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
