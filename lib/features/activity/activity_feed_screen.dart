import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/user_activity_providers.dart';
import 'package:coop_commerce/core/services/user_activity_service.dart';

/// Activity Feed Screen
/// Shows recent interactions and activities from followed sellers and users
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Activity Feed',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Please sign in to view your activity timeline.'),
        ),
      );
    }

    final timelineAsync =
        ref.watch(userActivityTimelineProvider(currentUserId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Activity Feed',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: AppColors.background,
      body: timelineAsync.when(
        data: (activities) =>
            _buildActivityFeed(context, ref, activities, currentUserId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error loading activities: $e'),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(
    BuildContext context,
    WidgetRef ref,
    List<UserActivity> activities,
    String userId,
  ) {
    final totalActivities = activities.length;
    final purchases =
        activities.where((a) => a.activityType == 'purchase').length;
    final follows =
        activities.where((a) => a.activityType == 'follow_seller').length;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$totalActivities',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$purchases',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purchases',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$follows',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Following',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Activity List
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),

            if (activities.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Text(
                  'No activity yet. Start browsing products to build your timeline.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...activities.map((activity) {
                final ui = _activityUI(activity);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      final productId = activity.productId;
                      final orderId =
                          (activity.metadata?['orderId'] as String?);
                      if (productId != null && productId.isNotEmpty) {
                        context.pushNamed('product-detail',
                            pathParameters: {'productId': productId});
                        return;
                      }
                      if (orderId != null && orderId.isNotEmpty) {
                        context.push('/order-tracking/$orderId');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ui.color.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              ui.icon,
                              color: ui.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ui.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ui.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _timeAgo(activity.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 20),

            // Load more button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.invalidate(userActivityTimelineProvider(userId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity feed refreshed.')),
                  );
                },
                child: const Text('Refresh Timeline'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({IconData icon, Color color, String title, String subtitle}) _activityUI(
      UserActivity activity) {
    switch (activity.activityType) {
      case 'purchase':
        return (
          icon: Icons.shopping_bag,
          color: Colors.green,
          title: 'Purchase completed',
          subtitle:
              'Order ${activity.metadata?['orderId'] ?? ''} was successful',
        );
      case 'review':
        return (
          icon: Icons.star,
          color: Colors.amber,
          title: 'Review submitted',
          subtitle: activity.productName ?? 'You reviewed a product',
        );
      case 'follow_seller':
        return (
          icon: Icons.person_add,
          color: Colors.blue,
          title: 'Seller followed',
          subtitle: activity.metadata?['sellerName']?.toString() ??
              'You followed a seller',
        );
      case 'checkout_started':
        return (
          icon: Icons.shopping_cart_checkout,
          color: Colors.deepPurple,
          title: 'Checkout started',
          subtitle: 'You initiated checkout',
        );
      case 'payment_failed':
        return (
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Payment failed',
          subtitle: activity.metadata?['errorMessage']?.toString() ??
              'Try another method and retry',
        );
      case 'payment_success':
        return (
          icon: Icons.verified,
          color: Colors.green,
          title: 'Payment successful',
          subtitle: 'Transaction completed securely',
        );
      case 'add_to_cart':
        return (
          icon: Icons.add_shopping_cart,
          color: Colors.teal,
          title: 'Added to cart',
          subtitle: activity.productName ?? 'Item added',
        );
      case 'view':
        return (
          icon: Icons.visibility,
          color: Colors.orange,
          title: 'Product viewed',
          subtitle: activity.productName ?? 'You viewed a product',
        );
      default:
        return (
          icon: Icons.bolt,
          color: Colors.indigo,
          title: activity.activityType.replaceAll('_', ' '),
          subtitle: activity.productName ?? 'User activity',
        );
    }
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
