import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:coop_commerce/core/providers/order_providers.dart';
import 'package:coop_commerce/core/services/fcm_service.dart' as fcm;
import 'package:coop_commerce/theme/app_theme.dart';

/// OrderNotificationListener - Monitors order status changes and displays toast notifications
class OrderNotificationListener extends ConsumerWidget {
  final Widget child;
  final String? orderId;

  const OrderNotificationListener({
    super.key,
    required this.child,
    this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for order status notifications (Firestore)
    if (orderId != null) {
      ref.listen(orderStatusNotificationProvider(orderId!), (previous, next) {
        next.whenData((notification) {
          if (notification != null) {
            _showNotificationToast(context, notification);
          }
        });
      });

      // Listen for delivery updates (Firestore)
      ref.listen(deliveryUpdatesProvider(orderId!), (previous, next) {
        next.whenData((update) {
          if (update != null && update.driverName != null) {
            _showDeliveryUpdate(context, update);
          }
        });
      });
    }

    // Listen for FCM messages (Push notifications)
    ref.listen(fcmMessageStreamProvider, (previous, next) {
      next.whenData((message) {
        _handleFCMMessage(context, message);
      });
    });

    // Listen for FCM message opened events
    ref.listen(fcmMessageOpenedStreamProvider, (previous, next) {
      next.whenData((message) {
        _handleFCMMessageOpened(context, message);
      });
    });

    return child;
  }

  void _showNotificationToast(
    BuildContext context,
    OrderStatusNotification notification,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: _getNotificationColor(notification.currentStatus),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showDeliveryUpdate(
    BuildContext context,
    DeliveryUpdate update,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Assigned',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              update.driverName ?? 'Your order is with a driver',
              style: const TextStyle(fontSize: 12),
            ),
            if (update.estimatedDeliveryAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Est. Delivery: ${_formatTime(update.estimatedDeliveryAt!)}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getNotificationColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'dispatched':
      case 'outfordelivery':
        return AppColors.accent;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.isNegative) {
      return 'Now';
    } else if (difference.inHours == 0) {
      return 'In ${difference.inMinutes} mins';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours}h';
    } else {
      return 'Tomorrow';
    }
  }

  /// Handle incoming FCM message in foreground
  void _handleFCMMessage(BuildContext context, RemoteMessage message) {
    if (fcm.FCMService.isOrderNotification(message)) {
      final notification = fcm.FCMService.parseOrderNotification(message);
      if (notification != null) {
        _showFCMNotificationToast(context, notification);
      }
    }
  }

  /// Handle FCM message when user taps notification from background
  void _handleFCMMessageOpened(BuildContext context, RemoteMessage message) {
    if (fcm.FCMService.isOrderNotification(message)) {
      final notification = fcm.FCMService.parseOrderNotification(message);
      if (notification != null) {
        // Could navigate to order tracking screen here
        debugPrint('Order notification opened: ${notification.orderId}');
      }
    }
  }

  /// Show toast for FCM notification
  void _showFCMNotificationToast(
    BuildContext context,
    OrderStatusNotification notification,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: _getNotificationColor(notification.currentStatus),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// OrderNotificationBadge - Shows unread notification count
class OrderNotificationBadge extends ConsumerWidget {
  final Widget child;

  const OrderNotificationBadge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadOrderNotificationsProvider);

    return unreadCount.when(
      data: (count) {
        if (count == 0) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => child,
      error: (error, stackTrace) => child,
    );
  }
}

/// OrderStatusStream - Real-time order status widget
class OrderStatusStream extends ConsumerWidget {
  final String orderId;
  final Function(OrderStatusNotification?) onStatusChange;
  final Widget child;

  const OrderStatusStream({
    super.key,
    required this.orderId,
    required this.onStatusChange,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusStream = ref.watch(orderStatusNotificationProvider(orderId));

    statusStream.whenData((notification) {
      if (notification != null) {
        onStatusChange(notification);
      }
    });

    return child;
  }
}
