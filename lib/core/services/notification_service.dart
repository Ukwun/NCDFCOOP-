import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../models/notification_models.dart';

/// Service for managing notifications: FCM push, in-app, and order tracking
///
/// Responsibilities:
/// - Initialize Firebase Cloud Messaging (FCM)
/// - Handle push notifications
/// - Send and manage in-app notifications
/// - Track order status with real-time updates
/// - Manage notification preferences
/// - Handle notification dismissal and archival
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize Firebase Cloud Messaging
  /// Call this on app startup (in main.dart or boot sequence)
  ///
  /// Workflow:
  /// 1. Request notification permissions (iOS)
  /// 2. Get FCM token for this device
  /// 3. Set up foreground notification handler
  /// 4. Set up background notification handler
  /// 5. Set up notification tap handler
  Future<void> initializeFirebaseMessaging(String userId) async {
    try {
      // Request permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
          'DEBUG: Notification permission status: ${settings.authorizationStatus}');

      // Get FCM token and save to Firestore
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(userId, token);
        print(
            'DEBUG: FCM token obtained and saved: ${token.substring(0, 20)}...');
      }

      // Handle notification when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('DEBUG: Foreground notification received');
        _handleForegroundNotification(message, userId);
      });

      // Handle notification tap when app was in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('DEBUG: User tapped notification from background/terminated');
        _handleNotificationTap(message, userId);
      });

      // Handle background message
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      print('DEBUG: Firebase Messaging initialized for user $userId');
    } catch (e) {
      print('ERROR: Failed to initialize Firebase Messaging: $e');
      rethrow;
    }
  }

  /// Static handler for background messages
  /// Must be a top-level function
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      print('DEBUG: Background notification handler triggered');
      print('DEBUG: Notification title: ${message.notification?.title}');
      // Here you could update local notification or perform background task
    } catch (e) {
      print('ERROR: Failed to handle background message: $e');
    }
  }

  /// Handle foreground notification (app in focus)
  void _handleForegroundNotification(RemoteMessage message, String userId) {
    try {
      final data = message.data;
      final notificationType = data['type'] as String? ?? 'system';

      // For demonstration: create in-app notification
      // In production, you might show a snackbar, toast, or in-app banner
      print('DEBUG: Foreground notification - Type: $notificationType');
      print('DEBUG: Title: ${message.notification?.title}');
      print('DEBUG: Body: ${message.notification?.body}');

      // You could trigger a Riverpod provider to update the UI here
      // Example: ref.read(inAppNotificationProvider).showNotification(...)
    } catch (e) {
      print('ERROR: Failed to handle foreground notification: $e');
    }
  }

  /// Handle notification tap from background/terminated state
  void _handleNotificationTap(RemoteMessage message, String userId) {
    try {
      final data = message.data;
      final actionType = data['actionType'] as String?;
      final targetId = data['targetId'] as String?;

      print(
          'DEBUG: Handling notification tap - Action: $actionType, Target: $targetId');

      // Route to appropriate screen based on notification type
      // This would typically be handled by your router (go_router)
      // Example: router.go('/order/$targetId') for order notifications
    } catch (e) {
      print('ERROR: Failed to handle notification tap: $e');
    }
  }

  /// Save FCM token to Firestore for push notifications
  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFCMTokenUpdate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('ERROR: Failed to save FCM token: $e');
      // Don't rethrow - FCM token loss isn't critical
    }
  }

  /// Send push notification via FCM (from backend/cloud function typically)
  /// This is a helper method; in production, FCM is usually triggered server-side
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // In production, you'd send this to Cloud Functions or backend
      // For now, we'll save to Firestore and let Cloud Function handle FCM

      final notificationId = 'notif-${DateTime.now().millisecondsSinceEpoch}';

      await _firestore
          .collection('pending_notifications')
          .doc(notificationId)
          .set({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': DateTime.now().toIso8601String(),
        'sent': false,
      });

      // Push notification queued for user
    } catch (e) {
      // Log error without using print in production
      rethrow;
    }
  }

  /// Create and save a new in-app notification
  /// These appear in the notification center and optionally as in-app banners
  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      final notification = AppNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
        data: data,
        imageUrl: imageUrl,
        isFcmEnabled: false, // Mark as in-app only
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      print('DEBUG: In-app notification created: ${notification.id}');
      return notification.id;
    } catch (e) {
      print('ERROR: Failed to create in-app notification: $e');
      rethrow;
    }
  }

  /// Create order notification (with tracking data)
  Future<String> createOrderNotification({
    required String userId,
    required String orderId,
    required String orderStatus,
    required String title,
    required String message,
    DateTime? estimatedDeliveryDate,
    String? trackingNumber,
    double? totalAmount,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final notification = OrderNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        message: message,
        orderId: orderId,
        orderStatus: orderStatus,
        estimatedDeliveryDate: estimatedDeliveryDate,
        trackingNumber: trackingNumber,
        totalAmount: totalAmount,
        priority: priority,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      print('DEBUG: Order notification created for order $orderId');
      return notification.id;
    } catch (e) {
      print('ERROR: Failed to create order notification: $e');
      rethrow;
    }
  }

  /// Create B2B notification (PO, contract, invoice)
  Future<String> createB2BNotification({
    required String userId,
    required String title,
    required String message,
    required String actionType,
    String? purchaseOrderId,
    String? contractId,
    String? invoiceId,
    String? requiredAction,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    try {
      final notification = B2BNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        message: message,
        actionType: actionType,
        purchaseOrderId: purchaseOrderId,
        contractId: contractId,
        invoiceId: invoiceId,
        requiredAction: requiredAction,
        priority: priority,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      print('DEBUG: B2B notification created - Action: $actionType');
      return notification.id;
    } catch (e) {
      print('ERROR: Failed to create B2B notification: $e');
      rethrow;
    }
  }

  /// Create franchise notification (store, sales, compliance)
  Future<String> createFranchiseNotification({
    required String userId,
    required String storeId,
    required String title,
    required String message,
    required String alertType,
    Map<String, dynamic>? metrics,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final notification = FranchiseNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        message: message,
        storeId: storeId,
        alertType: alertType,
        metrics: metrics,
        priority: priority,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      print('DEBUG: Franchise notification created - Store: $storeId');
      return notification.id;
    } catch (e) {
      print('ERROR: Failed to create franchise notification: $e');
      rethrow;
    }
  }

  /// Create driver notification (route, delivery, earnings)
  Future<String> createDriverNotification({
    required String userId,
    required String driverId,
    required String title,
    required String message,
    required String notificationType,
    String? routeId,
    String? deliveryId,
    double? earnedAmount,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    try {
      final notification = DriverNotification(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        message: message,
        driverId: driverId,
        notificationType: notificationType,
        routeId: routeId,
        deliveryId: deliveryId,
        earnedAmount: earnedAmount,
        priority: priority,
      );

      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());

      print('DEBUG: Driver notification created - Type: $notificationType');
      return notification.id;
    } catch (e) {
      print('ERROR: Failed to create driver notification: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': 'read',
        'readAt': DateTime.now().toIso8601String(),
      });

      print('DEBUG: Notification marked as read: $notificationId');
    } catch (e) {
      print('ERROR: Failed to mark notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unread')
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'read',
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      print('DEBUG: All notifications marked as read for user $userId');
    } catch (e) {
      print('ERROR: Failed to mark all notifications as read: $e');
      rethrow;
    }
  }

  /// Archive notification (soft delete)
  Future<void> archiveNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': 'archived',
      });

      print('DEBUG: Notification archived: $notificationId');
    } catch (e) {
      print('ERROR: Failed to archive notification: $e');
      rethrow;
    }
  }

  /// Delete notification (soft delete)
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'status': 'deleted',
      });

      print('DEBUG: Notification deleted: $notificationId');
    } catch (e) {
      print('ERROR: Failed to delete notification: $e');
      rethrow;
    }
  }

  /// Get unread notifications for user
  Stream<List<AppNotification>> getUserUnreadNotifications(String userId) {
    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unread')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('ERROR: Failed to get unread notifications: $e');
      return Stream.value([]);
    }
  }

  /// Get all notifications for user (unread, read, with pagination)
  Stream<List<AppNotification>> getUserNotifications(
    String userId, {
    int limit = 50,
  }) {
    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status',
              whereIn: ['unread', 'read']) // Exclude archived/deleted
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      print('ERROR: Failed to get user notifications: $e');
      return Stream.value([]);
    }
  }

  /// Get notifications of specific type
  Stream<List<AppNotification>> getUserNotificationsByType(
    String userId,
    NotificationType type, {
    int limit = 50,
  }) {
    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('status',
              whereIn: ['unread', 'read']) // Exclude archived/deleted
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      print('ERROR: Failed to get notifications by type: $e');
      return Stream.value([]);
    }
  }

  /// Get notification statistics for user
  Future<NotificationStats> getNotificationStats(String userId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      final allNotifs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['unread', 'read']).get();

      final unreadNotifs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unread')
          .get();

      final todayNotifs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();

      final weekNotifs = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();

      // Count by type
      final countByType = <NotificationType, int>{};
      for (var doc in allNotifs.docs) {
        final notif = AppNotification.fromFirestore(doc);
        countByType[notif.type] = (countByType[notif.type] ?? 0) + 1;
      }

      return NotificationStats(
        unreadCount: unreadNotifs.docs.length,
        todayCount: todayNotifs.docs.length,
        weekCount: weekNotifs.docs.length,
        countByType: countByType,
        lastReadAt: DateTime.now(),
      );
    } catch (e) {
      print('ERROR: Failed to get notification stats: $e');
      return NotificationStats(
        unreadCount: 0,
        todayCount: 0,
        weekCount: 0,
        countByType: {},
        lastReadAt: DateTime.now(),
      );
    }
  }

  /// Track order status with real-time updates
  /// Returns stream of order tracking events
  Stream<List<OrderTrackingEvent>> trackOrder(String orderId) {
    try {
      return _firestore
          .collection('order_tracking')
          .doc(orderId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return OrderTrackingEvent.fromMap(data);
        }).toList();
      });
    } catch (e) {
      print('ERROR: Failed to track order: $e');
      return Stream.value([]);
    }
  }

  /// Add tracking event to order
  /// Called when order status changes
  Future<void> addOrderTrackingEvent({
    required String orderId,
    required String eventType,
    required String description,
    LatLng? location,
    String? estimatedNextUpdate,
  }) async {
    try {
      final event = OrderTrackingEvent(
        orderId: orderId,
        eventType: eventType,
        description: description,
        timestamp: DateTime.now(),
        location: location,
        estimatedNextUpdate: estimatedNextUpdate,
      );

      await _firestore
          .collection('order_tracking')
          .doc(orderId)
          .collection('events')
          .add(event.toMap());

      print(
          'DEBUG: Tracking event added for order $orderId - Event: $eventType');
    } catch (e) {
      print('ERROR: Failed to add tracking event: $e');
      rethrow;
    }
  }

  /// Get notification preferences for user
  Future<NotificationPreferences?> getNotificationPreferences(
      String userId) async {
    try {
      final doc = await _firestore
          .collection('notification_preferences')
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Return default preferences
        return NotificationPreferences(userId: userId);
      }

      return NotificationPreferences.fromFirestore(doc);
    } catch (e) {
      print('ERROR: Failed to get notification preferences: $e');
      return null;
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    required String userId,
    bool? pushEnabled,
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    Set<NotificationType>? enabledTypes,
    bool? showPreviewContent,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (pushEnabled != null) {
        updates['pushNotificationsEnabled'] = pushEnabled;
      }
      if (inAppEnabled != null) {
        updates['inAppNotificationsEnabled'] = inAppEnabled;
      }
      if (emailEnabled != null) {
        updates['emailNotificationsEnabled'] = emailEnabled;
      }
      if (smsEnabled != null) updates['smsNotificationsEnabled'] = smsEnabled;
      if (enabledTypes != null) {
        updates['enabledTypes'] =
            enabledTypes.map((t) => t.toString().split('.').last).toList();
      }
      if (showPreviewContent != null) {
        updates['showPreviewContent'] = showPreviewContent;
      }

      await _firestore
          .collection('notification_preferences')
          .doc(userId)
          .set(updates, SetOptions(merge: true));

      print('DEBUG: Notification preferences updated for user $userId');
    } catch (e) {
      print('ERROR: Failed to update notification preferences: $e');
      rethrow;
    }
  }

  // ============================================================================
  // REAL-TIME WATCH STREAMS
  // ============================================================================

  /// Watch unread notifications for a user in real-time
  Stream<List<AppNotification>> watchUnreadNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'unread')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Watch all notifications for a user in real-time
  Stream<List<AppNotification>> watchAllNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Watch notifications by type in real-time
  Stream<List<AppNotification>> watchNotificationsByType(
      String userId, String type) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Watch order tracking events in real-time
  Stream<List<OrderTrackingEvent>> watchOrderTracking(String orderId) {
    return _firestore
        .collection('order_tracking')
        .doc(orderId)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderTrackingEvent.fromMap(doc.data()))
            .toList());
  }

  // ============================================================================
  // NOTIFICATION ACTIONS
  // ============================================================================

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unread')
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }

      await batch.commit();
      print('DEBUG: All notifications marked as read for user $userId');
    } catch (e) {
      print('ERROR: Failed to mark all as read: $e');
      rethrow;
    }
  }

  /// Mark a specific notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'status': 'read'});
      print('DEBUG: Notification $notificationId marked as read');
    } catch (e) {
      print('ERROR: Failed to mark notification as read: $e');
      rethrow;
    }
  }

  /// Get all notifications for a user
  Future<List<AppNotification>> getAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Error getting all notifications
      return [];
    }
  }

  /// Toggle notification type enabled/disabled
  Future<void> toggleNotificationType(
      String userId, NotificationType type, bool enabled) async {
    try {
      final prefs = await getNotificationPreferences(userId);
      final enabledTypes = prefs?.enabledTypes ?? {};

      if (enabled) {
        enabledTypes.add(type);
      } else {
        enabledTypes.remove(type);
      }

      await _firestore.collection('notification_preferences').doc(userId).set({
        'enabledTypes':
            enabledTypes.map((t) => t.toString().split('.').last).toList(),
      }, SetOptions(merge: true));

      print('DEBUG: Notification type $type toggled to $enabled for $userId');
    } catch (e) {
      print('ERROR: Failed to toggle notification type: $e');
      rethrow;
    }
  }

  /// Toggle push notifications
  Future<void> togglePushNotifications(String userId, bool enabled) async {
    try {
      await _firestore
          .collection('notification_preferences')
          .doc(userId)
          .set({'pushNotificationsEnabled': enabled}, SetOptions(merge: true));
      print('DEBUG: Push notifications toggled to $enabled for $userId');
    } catch (e) {
      print('ERROR: Failed to toggle push notifications: $e');
      rethrow;
    }
  }

  /// Toggle in-app notifications
  Future<void> toggleInAppNotifications(String userId, bool enabled) async {
    try {
      await _firestore
          .collection('notification_preferences')
          .doc(userId)
          .set({'inAppNotificationsEnabled': enabled}, SetOptions(merge: true));
      print('DEBUG: In-app notifications toggled to $enabled for $userId');
    } catch (e) {
      print('ERROR: Failed to toggle in-app notifications: $e');
      rethrow;
    }
  }

  /// Toggle email notifications
  Future<void> toggleEmailNotifications(String userId, bool enabled) async {
    try {
      await _firestore
          .collection('notification_preferences')
          .doc(userId)
          .set({'emailNotificationsEnabled': enabled}, SetOptions(merge: true));
      print('DEBUG: Email notifications toggled to $enabled for $userId');
    } catch (e) {
      print('ERROR: Failed to toggle email notifications: $e');
      rethrow;
    }
  }
}
