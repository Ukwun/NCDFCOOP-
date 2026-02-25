import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/models/notification_models.dart';
import 'package:coop_commerce/core/services/notification_service.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';

// ============================================================================
// NOTIFICATION SERVICE PROVIDER
// ============================================================================

/// Provides singleton NotificationService instance
final notificationServiceProvider = Provider((ref) {
  return NotificationService();
});

// ============================================================================
// NOTIFICATION STREAM PROVIDERS
// ============================================================================

/// Watch unread notifications for current user in real-time
final unreadNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }

  return service.watchUnreadNotifications(user.id);
});

/// Watch all notifications for current user
final allNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }

  return service.watchAllNotifications(user.id);
});

/// Filter notifications by type
final notificationsByTypeProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, type) {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }

  return service.watchNotificationsByType(user.id, type);
});

// ============================================================================
// NOTIFICATION PREFERENCE PROVIDERS
// ============================================================================

/// Get notification preferences for current user
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user == null) {
    return NotificationPreferences(userId: '');
  }

  final prefs = await service.getNotificationPreferences(user.id);
  return prefs ?? NotificationPreferences(userId: user.id);
});

// ============================================================================
// IN-APP NOTIFICATION STATE
// ============================================================================

/// Current in-app notification to display (not persisted)
final inAppNotificationProvider = Provider<AppNotification?>((ref) {
  return null;
});

// ============================================================================
// NOTIFICATION ACTIONS
// ============================================================================

/// Mark all notifications as read
final markAllAsReadProvider = FutureProvider<void>((ref) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user != null) {
    await service.markAllAsRead(user.id);
    // Refresh unread notifications - ignore unused result, refreshing for UI update
    // ignore: unused_result
    ref.refresh(unreadNotificationsProvider);
  }
});

/// Mark specific notification as read
final markNotificationAsReadProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user != null) {
    await service.markAsRead(notificationId);
    // Refresh notifications - ignore unused result, refreshing for UI update
    // ignore: unused_result
    ref.refresh(unreadNotificationsProvider);
    // ignore: unused_result
    ref.refresh(allNotificationsProvider);
  }
});

/// Delete notification
final deleteNotificationProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user != null) {
    await service.deleteNotification(notificationId);
    // Refresh notifications - ignore unused result, refreshing for UI update
    // ignore: unused_result
    ref.refresh(allNotificationsProvider);
    // ignore: unused_result
    ref.refresh(unreadNotificationsProvider);
  }
});

/// Toggle notification type
final toggleNotificationTypeProvider =
    FutureProvider.family<void, (NotificationType, bool)>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user != null) {
    await service.toggleNotificationType(user.id, params.$1, params.$2);
    // Refresh preferences - ignore unused result, refreshing for UI update
    // ignore: unused_result
    ref.refresh(notificationPreferencesProvider);
  }
});

/// Toggle push notifications
final togglePushNotificationsProvider =
    FutureProvider.family<void, bool>((ref, enabled) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user != null) {
    await service.togglePushNotifications(user.id, enabled);
    // Refresh preferences - ignore unused result, refreshing for UI update
    // ignore: unused_result
    ref.refresh(notificationPreferencesProvider);
  }
});

/// Toggle in-app notifications
final toggleInAppNotificationsProvider =
    FutureProvider.family<void, bool>((ref, enabled) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user != null) {
    await service.toggleInAppNotifications(user.id, enabled);
    // Refresh preferences - ignore unused result, refreshing for UI update
    // ignore: unused_result
    ref.refresh(notificationPreferencesProvider);
  }
});

/// Toggle email notifications
final toggleEmailNotificationsProvider =
    FutureProvider.family<void, bool>((ref, enabled) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user != null) {
    await service.toggleEmailNotifications(user.id, enabled);
    // Refresh preferences - ignore unused result, refreshing for UI update
    // ignore: unused_result
    ref.refresh(notificationPreferencesProvider);
  }
});

// ============================================================================
// NOTIFICATION STATISTICS
// ============================================================================

/// Get notification statistics (counts by type)
final notificationStatsProvider =
    FutureProvider<NotificationStats>((ref) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user == null) {
    return NotificationStats(
      unreadCount: 0,
      todayCount: 0,
      weekCount: 0,
      countByType: {},
      lastReadAt: DateTime.now(),
    );
  }

  final allNotifs = await service.getAllNotifications(user.id);

  int unreadCount = 0;

  for (final notif in allNotifs) {
    if (notif.status == NotificationStatus.unread) {
      unreadCount++;
    }
  }

  return NotificationStats(
    unreadCount: unreadCount,
    todayCount: allNotifs.where((n) => _isToday(n.createdAt)).length,
    weekCount: allNotifs.where((n) => _isThisWeek(n.createdAt)).length,
    countByType: _groupByType(allNotifs),
    lastReadAt: DateTime.now(),
  );
});

/// Watch order notifications
final orderNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }

  return service.watchNotificationsByType(user.id, 'order');
});

/// Watch B2B notifications
final b2bNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);

  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }

  return service.watchNotificationsByType(user.id, 'b2b');
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

bool _isThisWeek(DateTime date) {
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  return date.isAfter(weekAgo) && date.isBefore(now);
}

Map<NotificationType, int> _groupByType(List<AppNotification> notifications) {
  final counts = <NotificationType, int>{};
  for (final notif in notifications) {
    counts[notif.type] = (counts[notif.type] ?? 0) + 1;
  }
  return counts;
}

// ============================================================================
// ORDER TRACKING PROVIDER
// ============================================================================

/// Watch order tracking events
final orderTrackingProvider =
    StreamProvider.family<List<OrderTrackingEvent>, String>((ref, orderId) {
  final service = ref.watch(notificationServiceProvider);
  return service.watchOrderTracking(orderId);
});
