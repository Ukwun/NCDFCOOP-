import 'package:firebase_messaging/firebase_messaging.dart';

typedef NotificationCallback = Future<void> Function(RemoteMessage message);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  NotificationCallback? _onMessageCallback;
  NotificationCallback? _onMessageOpenedAppCallback;

  bool _isInitialized = false;

  Future<void> initialize({
    NotificationCallback? onMessage,
    NotificationCallback? onMessageOpenedApp,
  }) async {
    if (_isInitialized) return;

    _onMessageCallback = onMessage;
    _onMessageOpenedAppCallback = onMessageOpenedApp;

    // Request notification permissions (iOS/Web)
    await _requestNotificationPermissions();

    // Get FCM token
    final token = await getFCMToken();
    print('🔔 FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated message
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle initial message (app opened from notification)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _isInitialized = true;
  }

  Future<void> _requestNotificationPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print(
        'User notification permission status: ${settings.authorizationStatus}');
  }

  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  void setOnForegroundMessageHandler(NotificationCallback callback) {
    _onMessageCallback = callback;
  }

  void setOnMessageOpenedAppHandler(NotificationCallback callback) {
    _onMessageOpenedAppCallback = callback;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling a foreground message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');

    if (_onMessageCallback != null) {
      await _onMessageCallback!(message);
    } else {
      // Default handling
      _showNotification(message);
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');

    if (_onMessageOpenedAppCallback != null) {
      await _onMessageOpenedAppCallback!(message);
    }

    // Handle navigation logic based on message data
    _handleNotificationNavigation(message);
  }

  void _showNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      print('Showing notification: ${notification.title}');
      // TODO: Integrate with local notifications to show banner
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'order_update':
        final orderId = data['orderId'];
        print('Navigate to order: $orderId');
        // NavigationService.navigateToOrderDetails(orderId);
        break;
      case 'promotion':
        final promotionId = data['promotionId'];
        print('Navigate to promotion: $promotionId');
        // NavigationService.navigateToPromotion(promotionId);
        break;
      case 'wallet':
        print('Navigate to wallet');
        // NavigationService.navigateToWallet();
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('❌ Unsubscribed from topic: $topic');
  }

  // Common topic subscriptions
  Future<void> subscribeToOrderUpdates(String userId) async {
    await subscribeToTopic('orders_$userId');
    await subscribeToTopic('all_users_orders');
  }

  Future<void> subscribeToPromotions() async {
    await subscribeToTopic('promotions');
  }

  Future<void> subscribeToWalletUpdates(String userId) async {
    await subscribeToTopic('wallet_$userId');
  }

  Future<void> subscribeToDeliveryUpdates(String userId) async {
    await subscribeToTopic('delivery_$userId');
  }

  // Unsubscribe from all notifications
  Future<void> unsubscribeFromAllNotifications(String userId) async {
    await unsubscribeFromTopic('orders_$userId');
    await unsubscribeFromTopic('all_users_orders');
    await unsubscribeFromTopic('promotions');
    await unsubscribeFromTopic('wallet_$userId');
    await unsubscribeFromTopic('delivery_$userId');
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Open app notification settings
  Future<void> openNotificationSettings() async {
    try {
      // This method varies by platform
      // For now, we'll just print a message
      print('🔔 Open notification settings in device settings');
    } catch (e) {
      print('Error opening notification settings: $e');
    }
  }
}
