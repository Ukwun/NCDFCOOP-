import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: user == null
          ? const _NotificationMessage(
              icon: Icons.lock_outline,
              title: 'Sign in to view notifications',
              message: 'Your account activity and updates will appear here.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(user.uid)
                  .collection('items')
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _NotificationMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Notifications are unavailable',
                    message: 'Check your connection and try again.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!.docs;
                if (items.isEmpty) {
                  return const _NotificationMessage(
                    icon: Icons.notifications_none,
                    title: 'No notifications yet',
                    message:
                        'Order, product, offer, and account updates will appear here.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(user.uid)
                        .collection('items')
                        .limit(1)
                        .get(const GetOptions(source: Source.server));
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = items[index];
                      return _NotificationCard(
                        id: doc.id,
                        userId: user.uid,
                        data: doc.data(),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.id,
    required this.userId,
    required this.data,
  });

  final String id;
  final String userId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final type = data['type']?.toString() ?? 'info';
    final isRead = data['isRead'] == true;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final color = type.contains('product') || type.contains('offer')
        ? AppColors.accent
        : AppColors.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface : color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isRead ? AppColors.border : color.withValues(alpha: .5),
        ),
        boxShadow: AppShadows.smList,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: isRead
            ? null
            : () => FirebaseFirestore.instance
                .collection('notifications')
                .doc(userId)
                .collection('items')
                .doc(id)
                .update(
                    {'isRead': true, 'readAt': FieldValue.serverTimestamp()}),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(_iconFor(type), color: color),
        ),
        title: Text(
          data['title']?.toString() ?? 'Account update',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['message']?.toString() ?? '',
                style: TextStyle(color: AppColors.muted),
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 6),
                Text(_relativeTime(createdAt),
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ],
          ),
        ),
        trailing: isRead
            ? null
            : Semantics(
                label: 'Unread',
                child: Container(
                  width: 9,
                  height: 9,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    if (type.contains('product')) return Icons.inventory_2_outlined;
    if (type.contains('order')) return Icons.local_shipping_outlined;
    if (type.contains('offer')) return Icons.local_offer_outlined;
    if (type.contains('message')) return Icons.chat_bubble_outline;
    return Icons.notifications_outlined;
  }

  static String _relativeTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 58, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(title, style: AppTextStyles.h4, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: TextStyle(color: AppColors.muted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
