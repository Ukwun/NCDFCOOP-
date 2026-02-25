import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coop_commerce/core/services/cart_activity_logger.dart';
import 'package:coop_commerce/core/services/review_activity_logger.dart';
import 'package:coop_commerce/core/services/activity_tracking_service.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Providers for analytics data
final cartLoggerProvider = Provider((ref) {
  final activityTracker = ref.watch(activityTrackerProvider);
  return CartActivityLogger(activityTracker);
});

final reviewLoggerProvider = Provider((ref) {
  final activityTracker = ref.watch(activityTrackerProvider);
  return ReviewActivityLogger(activityTracker);
});

final activityTrackerProvider = Provider((ref) => ActivityTrackingService());

final cartMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  final logger = ref.watch(cartLoggerProvider);
  return logger.getCartMetrics(user.uid);
});

final reviewMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  final logger = ref.watch(reviewLoggerProvider);
  return logger.getReviewMetrics(user.uid);
});

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final cartMetrics = ref.watch(cartMetricsProvider);
    final reviewMetrics = ref.watch(reviewMetricsProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(
          child: Text('Please login to view analytics'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Analytics'),
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Shopping Activity',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your purchases, reviews, and shopping habits',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cart Metrics Section
            Text(
              'Shopping Cart Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            cartMetrics.when(
              data: (metrics) => _buildCartMetricsCards(context, metrics),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: Text('Error loading cart metrics: $err'),
              ),
            ),
            const SizedBox(height: 24),

            // Review Metrics Section
            Text(
              'Review Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            reviewMetrics.when(
              data: (metrics) => _buildReviewMetricsCards(context, metrics),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(
                child: Text('Error loading review metrics: $err'),
              ),
            ),
            const SizedBox(height: 24),

            // Additional Stats
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildQuickStatsCards(context, cartMetrics, reviewMetrics),
          ],
        ),
      ),
    );
  }

  Widget _buildCartMetricsCards(BuildContext context, Map<String, dynamic> metrics) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMetricCard(
          context,
          title: 'Items Added',
          value: '${metrics['totalAdds'] ?? 0}',
          icon: Icons.shopping_cart_outlined,
          color: Colors.blue,
        ),
        _buildMetricCard(
          context,
          title: 'Items Removed',
          value: '${metrics['totalRemoves'] ?? 0}',
          icon: Icons.delete_outline,
          color: Colors.red,
        ),
        _buildMetricCard(
          context,
          title: 'Qty Updated',
          value: '${metrics['totalUpdates'] ?? 0}',
          icon: Icons.edit_outlined,
          color: Colors.orange,
        ),
        _buildMetricCard(
          context,
          title: 'Total Value',
          value: '₦${(metrics['totalValueAdded'] ?? 0).toStringAsFixed(0)}',
          icon: Icons.trending_up,
          color: Colors.green,
          isLarge: true,
        ),
        _buildMetricCard(
          context,
          title: 'Avg Add Value',
          value: '₦${(metrics['averageAddValue'] ?? 0).toStringAsFixed(0)}',
          icon: Icons.analytics_outlined,
          color: Colors.purple,
        ),
        _buildMetricCard(
          context,
          title: 'Total Qty',
          value: '${metrics['totalQuantityAdded'] ?? 0}',
          icon: Icons.inventory_2_outlined,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildReviewMetricsCards(BuildContext context, Map<String, dynamic> metrics) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMetricCard(
          context,
          title: 'Reviews Given',
          value: '${metrics['totalReviewsSubmitted'] ?? 0}',
          icon: Icons.rate_review_outlined,
          color: Colors.amber,
        ),
        _buildMetricCard(
          context,
          title: 'Helpful Votes',
          value: '${metrics['totalHelpfulVotes'] ?? 0}',
          icon: Icons.thumb_up_outlined,
          color: Colors.green,
        ),
        _buildMetricCard(
          context,
          title: 'Not Helpful',
          value: '${metrics['totalUnhelpfulVotes'] ?? 0}',
          icon: Icons.thumb_down_outlined,
          color: Colors.red,
        ),
        _buildMetricCard(
          context,
          title: 'Helpfulness',
          value: '${metrics['helpfulnessRatio'] ?? 'N/A'}%',
          icon: Icons.assessment_outlined,
          color: Colors.blue,
        ),
        _buildMetricCard(
          context,
          title: 'Avg Rating',
          value: '${metrics['averageReviewRating'] ?? 0}/5 ⭐',
          icon: Icons.star_outlined,
          color: Colors.orange,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLarge = false,
  }) {
    return Container(
      width: isLarge ? double.infinity : ((MediaQuery.of(context).size.width - 60) / 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> cartMetrics,
    AsyncValue<Map<String, dynamic>> reviewMetrics,
  ) {
    return Column(
      spacing: 12,
      children: [
        // Shopping Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🛍️ Shopping Summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              cartMetrics.when(
                data: (metrics) => Column(
                  spacing: 8,
                  children: [
                    _buildStatLine(
                      context,
                      'Total items browsed & added: ${metrics['totalAdds'] ?? 0} items',
                    ),
                    _buildStatLine(
                      context,
                      'Total cart value: ₦${(metrics['totalValueAdded'] ?? 0).toStringAsFixed(0)}',
                    ),
                    _buildStatLine(
                      context,
                      'Average item value: ₦${(metrics['averageAddValue'] ?? 0).toStringAsFixed(0)}',
                    ),
                  ],
                ),
                loading: () => const Text('Loading...'),
                error: (err, st) => const Text('Error loading data'),
              ),
            ],
          ),
        ),

        // Review Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⭐ Review Summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              reviewMetrics.when(
                data: (metrics) => Column(
                  spacing: 8,
                  children: [
                    _buildStatLine(
                      context,
                      'Reviews submitted: ${metrics['totalReviewsSubmitted'] ?? 0}',
                    ),
                    _buildStatLine(
                      context,
                      'Your average rating: ${metrics['averageReviewRating'] ?? 0}/5 ⭐',
                    ),
                    _buildStatLine(
                      context,
                      'Community found ${metrics['totalHelpfulVotes'] ?? 0} of your reviews helpful',
                    ),
                  ],
                ),
                loading: () => const Text('Loading...'),
                error: (err, st) => const Text('Error loading data'),
              ),
            ],
          ),
        ),

        // Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ℹ️ Analytics Information',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your shopping metrics are updated in real-time as you browse, add to cart, and submit reviews. This dashboard helps you understand your shopping patterns and contribution to the community.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatLine(BuildContext context, String text) {
    return Row(
      children: [
        Icon(Icons.check_circle, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ),
      ],
    );
  }
}
