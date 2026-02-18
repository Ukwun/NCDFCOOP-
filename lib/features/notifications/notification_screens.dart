import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/notification_providers.dart' as providers;
import '../../models/notification_models.dart';

// ============================================================================
// NOTIFICATION CENTER SCREEN
// ============================================================================

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(allNotificationsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          elevation: 0,
          backgroundColor: const Color(0xFF1E7F4E),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Unread'),
              Tab(text: 'Orders'),
              Tab(text: 'B2B'),
            ],
          ),
          actions: [
            // Mark all as read button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    ref.read(markAllAsReadProvider.future).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All marked as read')),
                      );
                    });
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // All notifications tab
            _NotificationListView(
              notificationsAsync: notifications,
              onNotificationTap: (notif) =>
                  _handleNotificationTap(context, notif),
            ),

            // Unread notifications tab
            Consumer(
              builder: (context, ref, _) {
                final unread = ref.watch(unreadNotificationsProvider);
                return _NotificationListView(
                  notificationsAsync: unread,
                  onNotificationTap: (notif) =>
                      _handleNotificationTap(context, notif),
                );
              },
            ),

            // Order notifications tab
            Consumer(
              builder: (context, ref, _) {
                final orders = ref.watch(orderNotificationsProvider);
                return _NotificationListView(
                  notificationsAsync: orders,
                  onNotificationTap: (notif) =>
                      _handleNotificationTap(context, notif),
                );
              },
            ),

            // B2B notifications tab
            Consumer(
              builder: (context, ref, _) {
                final b2b = ref.watch(b2bNotificationsProvider);
                return _NotificationListView(
                  notificationsAsync: b2b,
                  onNotificationTap: (notif) =>
                      _handleNotificationTap(context, notif),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notif) {
    // Mark as read
    final ref = ProviderScope.containerOf(context);
    ref.read(markNotificationAsReadProvider(notif.id));

    // Navigate based on type
    switch (notif.type) {
      case NotificationType.order:
        if (notif is OrderNotification) {
          // Navigate to order details
          // Navigator.pushNamed(context, '/order/${notif.orderId}');
        }
        break;
      case NotificationType.b2b:
        if (notif is B2BNotification && notif.purchaseOrderId != null) {
          // Navigate to PO details
          // Navigator.pushNamed(context, '/institutional/po/${notif.purchaseOrderId}');
        }
        break;
      case NotificationType.franchise:
        if (notif is FranchiseNotification) {
          // Navigate to franchise store
          // Navigator.pushNamed(context, '/franchise/store/${notif.storeId}');
        }
        break;
      default:
        break;
    }
  }
}

// ============================================================================
// NOTIFICATION LIST VIEW WIDGET
// ============================================================================

class _NotificationListView extends ConsumerWidget {
  final AsyncValue<List<AppNotification>> notificationsAsync;
  final Function(AppNotification) onNotificationTap;

  const _NotificationListView({
    required this.notificationsAsync,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
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
                  'No notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return _NotificationTile(
              notification: notif,
              onTap: () => onNotificationTap(notif),
              onDelete: () => ref.read(deleteNotificationProvider(notif.id)),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text('Error loading notifications'),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NOTIFICATION TILE WIDGET
// ============================================================================

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = notification.status == NotificationStatus.unread;

    return Container(
      color: isUnread ? const Color(0xFF1E7F4E).withValues(alpha: 0.05) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _getNotificationIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E7F4E),
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
        onLongPress: () {
          _showNotificationOptions(context);
        },
      ),
    );
  }

  Widget _getNotificationIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.order:
        icon = Icons.shopping_bag_outlined;
        color = Colors.blue;
        break;
      case NotificationType.payment:
        icon = Icons.payment_outlined;
        color = Colors.green;
        break;
      case NotificationType.b2b:
        icon = Icons.business_outlined;
        color = Colors.purple;
        break;
      case NotificationType.franchise:
        icon = Icons.store_outlined;
        color = Colors.orange;
        break;
      case NotificationType.driver:
        icon = Icons.directions_car_outlined;
        color = Colors.cyan;
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer_outlined;
        color = Colors.red;
        break;
      case NotificationType.inventory:
        icon = Icons.inventory_2_outlined;
        color = Colors.amber;
        break;
      case NotificationType.account:
        icon = Icons.person_outline;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  void _showNotificationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  onDelete();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

// ============================================================================
// ORDER TRACKING SCREEN
// ============================================================================

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingEvents = ref.watch(orderTrackingProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${orderId.substring(0, 8)}'),
        backgroundColor: const Color(0xFF1E7F4E),
      ),
      body: trackingEvents.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Text('No tracking information available'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Timeline
                _OrderTimeline(events: events),

                const SizedBox(height: 24),

                // Latest event details
                if (events.isNotEmpty) _LatestEventDetails(event: events.first),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading tracking: $error'),
        ),
      ),
    );
  }
}

// ============================================================================
// ORDER TIMELINE WIDGET
// ============================================================================

class _OrderTimeline extends StatelessWidget {
  final List<OrderTrackingEvent> events;

  const _OrderTimeline({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        final isActive = index == 0;

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline circle
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1E7F4E)
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: isActive
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Event content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.getEventLabel(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(event.timestamp),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final time =
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    final date = '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    return '$date at $time';
  }
}

// ============================================================================
// LATEST EVENT DETAILS WIDGET
// ============================================================================

class _LatestEventDetails extends StatelessWidget {
  final OrderTrackingEvent event;

  const _LatestEventDetails({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1E7F4E)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Update',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            event.getEventLabel(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E7F4E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          if (event.estimatedNextUpdate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Estimated next update: ${event.estimatedNextUpdate}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// NOTIFICATION PREFERENCES SCREEN
// ============================================================================

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: const Color(0xFF1E7F4E),
      ),
      body: preferencesAsync.when(
        data: (prefs) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification channels
                Text(
                  'Notification Channels',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Push notifications toggle
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive notifications on your device'),
                  value: prefs.pushNotificationsEnabled,
                  onChanged: (value) {
                    ref
                        .read(togglePushNotificationsProvider(value).future)
                        .then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Push notifications ${value ? 'enabled' : 'disabled'}'),
                        ),
                      );
                    });
                  },
                ),

                // In-app notifications toggle
                SwitchListTile(
                  title: const Text('In-App Notifications'),
                  subtitle: const Text('Show alerts while using the app'),
                  value: prefs.inAppNotificationsEnabled,
                  onChanged: (value) {
                    ref
                        .read(toggleInAppNotificationsProvider(value).future)
                        .then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'In-app notifications ${value ? 'enabled' : 'disabled'}'),
                        ),
                      );
                    });
                  },
                ),

                // Email notifications toggle
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive updates via email'),
                  value: prefs.emailNotificationsEnabled,
                  onChanged: (value) {
                    ref
                        .read(toggleEmailNotificationsProvider(value).future)
                        .then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Email notifications ${value ? 'enabled' : 'disabled'}'),
                        ),
                      );
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Notification types
                Text(
                  'Notification Types',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Order notifications
                _NotificationTypeToggle(
                  type: NotificationType.order,
                  label: 'Order Updates',
                  description: 'Order confirmations, shipping, delivery',
                  enabled: prefs.isTypeEnabled(NotificationType.order),
                  onChanged: (enabled) {
                    ref.read(providers.toggleNotificationTypeProvider(
                        (NotificationType.order, enabled)).future);
                  },
                ),

                // Payment notifications
                _NotificationTypeToggle(
                  type: NotificationType.payment,
                  label: 'Payment Alerts',
                  description: 'Payment status, failed transactions',
                  enabled: prefs.isTypeEnabled(NotificationType.payment),
                  onChanged: (enabled) {
                    ref.read(providers.toggleNotificationTypeProvider(
                        (NotificationType.payment, enabled)).future);
                  },
                ),

                // B2B notifications
                _NotificationTypeToggle(
                  type: NotificationType.b2b,
                  label: 'B2B Alerts',
                  description: 'PO approvals, invoices, contracts',
                  enabled: prefs.isTypeEnabled(NotificationType.b2b),
                  onChanged: (enabled) {
                    ref.read(providers.toggleNotificationTypeProvider(
                        (NotificationType.b2b, enabled)).future);
                  },
                ),

                // Franchise notifications
                _NotificationTypeToggle(
                  type: NotificationType.franchise,
                  label: 'Franchise Updates',
                  description: 'Sales reports, compliance alerts',
                  enabled: prefs.isTypeEnabled(NotificationType.franchise),
                  onChanged: (enabled) {
                    ref.read(providers.toggleNotificationTypeProvider(
                        (NotificationType.franchise, enabled)).future);
                  },
                ),

                // Promotion notifications
                _NotificationTypeToggle(
                  type: NotificationType.promotion,
                  label: 'Promotions',
                  description: 'Special offers, discounts',
                  enabled: prefs.isTypeEnabled(NotificationType.promotion),
                  onChanged: (enabled) {
                    ref.read(providers.toggleNotificationTypeProvider(
                        (NotificationType.promotion, enabled)).future);
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading preferences: $error'),
        ),
      ),
    );
  }
}

// ============================================================================
// NOTIFICATION TYPE TOGGLE WIDGET
// ============================================================================

class _NotificationTypeToggle extends StatelessWidget {
  final NotificationType type;
  final String label;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationTypeToggle({
    required this.type,
    required this.label,
    required this.description,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      subtitle: Text(description),
      value: enabled,
      onChanged: onChanged,
    );
  }
}

// ============================================================================
// IN-APP NOTIFICATION BANNER (to display floating notifications)
// ============================================================================

class InAppNotificationBanner extends ConsumerWidget {
  final Widget child;

  const InAppNotificationBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notification = ref.watch(inAppNotificationProvider);

    return Stack(
      children: [
        child,
        if (notification != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _InAppNotificationCard(notification: notification),
          ),
      ],
    );
  }
}

class _InAppNotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _InAppNotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;

    switch (notification.priority) {
      case NotificationPriority.urgent:
      case NotificationPriority.high:
        backgroundColor = Colors.red[600] ?? Colors.red;
        break;
      case NotificationPriority.normal:
        backgroundColor = const Color(0xFF1E7F4E);
        break;
      case NotificationPriority.low:
        backgroundColor = Colors.grey[600] ?? Colors.grey;
        break;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
