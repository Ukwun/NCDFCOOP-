import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// FCM SERVICE - Firebase Cloud Messaging for Push Notifications
// ============================================================================

class FCMService {
  static final FCMService _instance = FCMService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  late String _fcmToken;
  bool _isInitialized = false;

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  // ========================================================================
  // INITIALIZATION
  // ========================================================================

  /// Initialize FCM service - call once in main.dart
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions (iOS 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken() ?? '';
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }

      // Save token to Firestore
      await _saveTokenToFirestore(_fcmToken);

      // Set up handlers for different message scenarios
      _setupMessageHandlers();

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
    }
  }

  // ========================================================================
  // PERMISSION HANDLING
  // ========================================================================

  /// Request notification permissions
  Future<NotificationSettings> requestPermissions() async {
    return await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// Check current notification permission status
  Future<NotificationSettings> checkPermissions() async {
    return await _messaging.getNotificationSettings();
  }

  // ========================================================================
  // TOKEN MANAGEMENT
  // ========================================================================

  /// Get current FCM token
  Future<String> getToken() async {
    if (_fcmToken.isNotEmpty) {
      return _fcmToken;
    }
    _fcmToken = await _messaging.getToken() ?? '';
    return _fcmToken;
  }

  /// Refresh FCM token (call periodically)
  Future<void> refreshToken() async {
    try {
      final newToken = await _messaging.getToken() ?? '';
      if (newToken != _fcmToken) {
        _fcmToken = newToken;
        await _saveTokenToFirestore(newToken);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing token: $e');
      }
    }
  }

  /// Listen for token refresh events
  void onTokenRefresh(Function(String) onRefresh) {
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      onRefresh(newToken);
      _saveTokenToFirestore(newToken);
    });
  }

  // ========================================================================
  // FIRESTORE TOKEN PERSISTENCE
  // ========================================================================

  /// Save token to Firestore for later use (messaging from backend)
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      // Get current user ID from wherever you store it
      // This is a placeholder - adjust based on your auth setup
      final userId = 'current_user_id'; // TODO: Get from AuthProvider

      await FirebaseFirestore.instance
          .collection('members')
          .doc(userId)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': Timestamp.now(),
      }).catchError((e) {
        if (kDebugMode) {
          print('Error saving token to Firestore: $e');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  // ========================================================================
  // MESSAGE HANDLERS
  // ========================================================================

  /// Set up all message handlers (foreground, background, terminated)
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message: ${message.messageId}');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
      }

      _handleForegroundMessage(message);
    });

    // Handle background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
            'Message opened from background/terminated: ${message.messageId}');
      }

      _handleMessageTap(message);
    });

    // Handle messages received while app is in background
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  /// Handle message received while app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification
    await _showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      data: message.data,
    );

    // Also save to Firestore for Notifications Center
    await _saveNotificationToFirestore(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'system',
      data: message.data,
    );
  }

  /// Handle message opened from background/terminated state
  void _handleMessageTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.messageId}');
    }

    // Handle navigation based on message data
    final actionUrl = message.data['actionUrl'];
    if (actionUrl != null) {
      // Navigate to the specified route
      // This would use your GoRouter navigation
      // Example: context.go(actionUrl);
    }

    // Mark as read in Firestore if notification ID provided
    final notificationId = message.data['notificationId'];
    if (notificationId != null) {
      _markNotificationAsRead(notificationId);
    }
  }

  /// Static handler for background messages (top-level function)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Handling background message: ${message.messageId}');
    }

    // Save to Firestore (notification is still processed even when app is closed)
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': message.notification?.title ?? '',
      'message': message.notification?.body ?? '',
      'type': message.data['type'] ?? 'system',
      'isRead': false,
      'createdAt': Timestamp.now(),
      'data': message.data,
    });
  }

  // ========================================================================
  // LOCAL NOTIFICATIONS
  // ========================================================================

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          print('Local notification tapped: ${details.id}');
        }
      },
    );
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'default',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: data.toString(),
    );
  }

  // ========================================================================
  // TOPIC SUBSCRIPTION
  // ========================================================================

  /// Subscribe to notification topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic $topic: $e');
      }
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic $topic: $e');
      }
    }
  }

  /// Subscribe to multiple topics
  Future<void> subscribeToTopics(List<String> topics) async {
    for (final topic in topics) {
      await subscribeToTopic(topic);
    }
  }

  /// Setup topic subscriptions based on member tier
  Future<void> setupMemberTopics(String memberTier) async {
    // All members get these
    await subscribeToTopics([
      'all_members',
      'order_updates',
      'promotions',
      'system_notifications',
    ]);

    // Tier-specific topics
    switch (memberTier.toUpperCase()) {
      case 'SILVER':
        await subscribeToTopics([
          'silver_members',
          'silver_exclusive',
        ]);
        break;
      case 'GOLD':
        await subscribeToTopics([
          'gold_members',
          'gold_exclusive',
          'vip_deals',
        ]);
        break;
      case 'PLATINUM':
        await subscribeToTopics([
          'platinum_members',
          'platinum_exclusive',
          'vip_deals',
          'early_access',
        ]);
        break;
      default:
        // BASIC tier
        break;
    }
  }

  // ========================================================================
  // FIRESTORE NOTIFICATION PERSISTENCE
  // ========================================================================

  /// Save notification to Firestore for Notifications Center
  Future<void> _saveNotificationToFirestore({
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get current user ID
      final userId = 'current_user_id'; // TODO: Get from AuthProvider

      await FirebaseFirestore.instance.collection('notifications').add({
        'memberId': userId,
        'title': title,
        'message': body,
        'type': type,
        'actionUrl': data['actionUrl'],
        'data': data,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification to Firestore: $e');
      }
    }
  }

  /// Mark notification as read in Firestore
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  // ========================================================================
  // UTILITIES
  // ========================================================================

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    // This actually requires user to change settings manually on the device
    // But we can track this preference in our database
    try {
      final userId = 'current_user_id'; // TODO: Get from AuthProvider
      await FirebaseFirestore.instance
          .collection('members')
          .doc(userId)
          .update({
        'notificationsEnabled': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error disabling notifications: $e');
      }
    }
  }

  /// Enable notifications
  Future<void> enableNotifications() async {
    try {
      final userId = 'current_user_id'; // TODO: Get from AuthProvider
      await FirebaseFirestore.instance
          .collection('members')
          .doc(userId)
          .update({
        'notificationsEnabled': true,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error enabling notifications: $e');
      }
    }
  }

  /// Clean up - call when user logs out
  Future<void> cleanup() async {
    try {
      // Unsubscribe from all topics
      await unsubscribeFromTopic('all_members');
      await unsubscribeFromTopic('order_updates');
      await unsubscribeFromTopic('promotions');
      await unsubscribeFromTopic('system_notifications');

      _isInitialized = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error during FCM cleanup: $e');
      }
    }
  }
}
