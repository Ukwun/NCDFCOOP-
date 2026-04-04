import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/features/user_intelligence/providers/user_intelligence_providers.dart';

/// Activity Feed Screen
/// Shows recent interactions and activities from followed sellers and users
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real scenario, we'd get the current user ID from auth provider
    // For now, using a demo user
    const currentUserId = 'user_current_001';

    final activitiesAsync =
        ref.watch(userActivitySummaryProvider(currentUserId));

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
      body: activitiesAsync.when(
        data: (summary) => _buildActivityFeed(context, summary),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error loading activities: $e'),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(
      BuildContext context, Map<String, dynamic> summary) {
    // Demo activity data
    final activities = [
      {
        'type': 'purchase',
        'user': 'John\'s Fresh Farm',
        'userRole': 'seller',
        'action': 'You purchased Organic Tomatoes',
        'time': '2 hours ago',
        'icon': Icons.shopping_bag,
        'color': Colors.green,
      },
      {
        'type': 'review',
        'user': 'Mary\'s Dairy',
        'userRole': 'seller',
        'action': 'You left a 5-star review',
        'time': '5 hours ago',
        'icon': Icons.star,
        'color': Colors.amber,
      },
      {
        'type': 'follow',
        'user': 'Premium Supplier Co',
        'userRole': 'seller',
        'action': 'You started following',
        'time': '1 day ago',
        'icon': Icons.person_add,
        'color': Colors.blue,
      },
      {
        'type': 'buyer_activity',
        'user': 'Sarah (buyer)',
        'userRole': 'buyer',
        'action': 'Viewed your product',
        'time': '3 hours ago',
        'icon': Icons.visibility,
        'color': Colors.purple,
      },
      {
        'type': 'recommendation',
        'user': 'System',
        'userRole': 'system',
        'action': 'Your products trending in your category',
        'time': '6 hours ago',
        'icon': Icons.trending_up,
        'color': Colors.orange,
      },
    ];

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
                        '${summary['totalInteractions'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Interactions',
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
                        '${summary['totalRelationships'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connections',
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
                        '${summary['positiveInteractions'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Positive',
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

            ...activities.map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                          color: (activity['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          activity['icon'] as IconData,
                          color: activity['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['user'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity['action'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        activity['time'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Loading more activities...')),
                  );
                },
                child: const Text('Load More Activities'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
