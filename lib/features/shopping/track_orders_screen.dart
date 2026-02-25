import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/order_providers.dart';
import 'package:coop_commerce/providers/auth_provider.dart';

/// Screen for tracking orders
class TrackOrdersScreen extends ConsumerWidget {
  const TrackOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final ordersAsync = ref.watch(userOrdersProvider(user?.id ?? ''));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Track Orders'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: AppColors.muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders to track',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You haven\'t placed any orders yet',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(200, 48),
                    ),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderTrackingCard(context, order);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load orders',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.refresh(userOrdersProvider(user?.id ?? ''));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTrackingCard(BuildContext context, dynamic order) {
    final statusColor = _getStatusColor(order.status ?? 'pending');
    final statusIcon = _getStatusIcon(order.status ?? 'pending');

    return GestureDetector(
      onTap: () => context
          .pushNamed('order-tracking', pathParameters: {'orderId': order.id}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.smList,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    spacing: 6,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      Text(
                        (order.status ?? 'pending').toLowerCase() ==
                                'processing'
                            ? 'Processing'
                            : (order.status ?? 'pending').toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Amount
            Text(
              '₦${(order.total ?? 0).toStringAsFixed(0)}',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // Status Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: _getProgressValue(order.status ?? 'pending'),
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            // View Details Link
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'View Details →',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'delivered' => AppColors.primary,
      'processing' || 'pending' => Colors.orange,
      'dispatched' || 'in transit' => Colors.blue,
      'cancelled' || 'failed' => Colors.red,
      _ => AppColors.muted,
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status.toLowerCase()) {
      'delivered' => Icons.check_circle,
      'dispatched' || 'in transit' => Icons.local_shipping,
      'cancelled' || 'failed' => Icons.cancel,
      _ => Icons.hourglass_empty,
    };
  }

  double _getProgressValue(String status) {
    return switch (status.toLowerCase()) {
      'pending' || 'confirmed' => 0.25,
      'processing' => 0.5,
      'dispatched' || 'in transit' => 0.75,
      'delivered' => 1.0,
      _ => 0.0,
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.day}/${date.month}/${date.year}';
  }
}
