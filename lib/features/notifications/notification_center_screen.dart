import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:coop_commerce/core/providers/notification_providers.dart';
import 'package:coop_commerce/models/notification_models.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Notification Center Screen - Displays all notifications for the current user
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allNotificationsAsync = ref.watch(allNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(ref),
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: allNotificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const _EmptyNotificationState();
          }

          // Separate unread and read
          final unread = notifications
              .where((n) => n.status == NotificationStatus.unread)
              .toList();
          final read = notifications
              .where((n) => n.status == NotificationStatus.read)
              .toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unread notifications section
                if (unread.isNotEmpty) ...[
                  const _SectionHeader('New'),
                  ...unread.map((notif) {
                    return _NotificationTile(
                      notification: notif,
                      onTap: () => _handleNotificationTap(context, ref, notif),
                      isUnread: true,
                    );
                  }),
                ],

                // Read notifications section
                if (read.isNotEmpty) ...[
                  const _SectionHeader('Earlier'),
                  ...read.map((notif) {
                    return _NotificationTile(
                      notification: notif,
                      onTap: () => _handleNotificationTap(context, ref, notif),
                      isUnread: false,
                    );
                  }),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading notifications'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(allNotificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle notification tap - route to appropriate screen based on type
  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    // Mark as read
    final service = ref.read(notificationServiceProvider);
    await service.markAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.order:
        final orderId = notification.data?['orderId'];
        if (orderId != null) {
          context.push('/orders/$orderId');
        }
        break;

      case NotificationType.payment:
        context.pushNamed('wallet');
        break;

      case NotificationType.inventory:
        context.push('/inventory');
        break;

      case NotificationType.promotion:
        context.pushNamed('products');
        break;

      case NotificationType.b2b:
        final poId = notification.data?['poId'];
        if (poId != null) {
          context.push('/institutional/po/$poId');
        } else {
          context.pushNamed('approvals');
        }
        break;

      case NotificationType.franchise:
        context.push('/franchise/dashboard');
        break;

      case NotificationType.driver:
        context.push('/driver/deliveries');
        break;

      case NotificationType.account:
        context.pushNamed('profile');
        break;

      case NotificationType.system:
        // Just mark as read, no navigation needed
        break;
    }
  }

  /// Mark all notifications as read
  void _markAllAsRead(WidgetRef ref) {
    final service = ref.read(notificationServiceProvider);
    service.markAllAsRead();
    ref.refresh(allNotificationsProvider);
  }
}

/// Empty state widget
class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see updates about your orders,\npayments, and account here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification tile widget
class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final bool isUnread;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: isUnread ? Colors.blue[50] : Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon based on type
                _getNotificationIcon(),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            _formatTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Unread indicator
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get icon widget based on notification type
  Widget _getNotificationIcon() {
    IconData iconData = Icons.notifications_outlined;
    Color iconColor = Colors.grey[600]!;

    switch (notification.type) {
      case NotificationType.order:
        iconData = Icons.local_shipping_outlined;
        iconColor = Colors.blue;
        break;
      case NotificationType.payment:
        iconData = Icons.payment_outlined;
        iconColor = Colors.green;
        break;
      case NotificationType.inventory:
        iconData = Icons.inventory_2_outlined;
        iconColor = Colors.orange;
        break;
      case NotificationType.promotion:
        iconData = Icons.local_offer_outlined;
        iconColor = Colors.red;
        break;
      case NotificationType.b2b:
        iconData = Icons.business_outlined;
        iconColor = Colors.purple;
        break;
      case NotificationType.franchise:
        iconData = Icons.store_outlined;
        iconColor = Colors.amber;
        break;
      case NotificationType.driver:
        iconData = Icons.directions_car_outlined;
        iconColor = Colors.cyan;
        break;
      case NotificationType.account:
        iconData = Icons.person_outlined;
        iconColor = Colors.indigo;
        break;
      case NotificationType.system:
        iconData = Icons.info_outlined;
        iconColor = Colors.grey[600]!;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withOpacity(0.1),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  /// Format timestamp for display
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}
