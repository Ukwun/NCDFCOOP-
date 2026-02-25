import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../core/providers/home_providers.dart';
import '../../core/providers/order_providers.dart';
import '../../core/services/order_fulfillment_service.dart';

class ConsumerHomeScreen extends ConsumerWidget {
  const ConsumerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wire real providers: user, featured products, and recent orders
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    final featuredAsync = ref.watch(featuredProductsProvider);
    final recentOrdersAsync = userId.isNotEmpty
        ? ref.watch(userOrdersProvider(userId))
        : const AsyncValue.data(<OrderData>[]);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with greeting
              _buildHeader(user),

              // 2. Search bar
              _buildSearchBar(context),

              // 3. Featured carousel
              _buildFeaturedCarousel(context, featuredAsync),

              // 4. Quick categories
              _buildCategoryGrid(context),

              // 5. Recent orders
              _buildRecentOrders(context, recentOrdersAsync),

              // 6. Recommended products
              _buildRecommended(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user?.firstName ?? "Guest"}!',
            style: AppTextStyles.h1.copyWith(color: AppColors.primary),
          ),
          Text(
            'What would you like to buy today?',
            style: AppTextStyles.body.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GestureDetector(
        onTap: () => context.pushNamed('search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textLight),
              const SizedBox(width: 12),
              Text(
                'Search products...',
                style: AppTextStyles.body.copyWith(color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCarousel(
    BuildContext context,
    AsyncValue<List<Product>> featured,
  ) {
    return featured.when(
      data: (products) {
        if (products.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('No featured products available'),
            ),
          );
        }
        return SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () => context.goNamed(
                  'product-detail',
                  pathParameters: {'productId': product.id},
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: product.imageUrl != null && product.imageUrl!.startsWith('assets/')
                          ? AssetImage(product.imageUrl!)
                          : NetworkImage(product.imageUrl ?? '') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: AppTextStyles.h3.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Text('Error loading featured: $e'),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      ('Groceries', Icons.shopping_basket),
      ('Electronics', Icons.devices),
      ('Clothing', Icons.shopping_bag),
      ('Home', Icons.home),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1,
        children: categories.map((cat) {
          return GestureDetector(
            onTap: () => context.pushNamed(
              'products',
              extra: cat.$1,
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    cat.$2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.$1,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentOrders(
    BuildContext context,
    AsyncValue<List<OrderData>> recentOrders,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Orders',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 12),
          recentOrders.when(
            data: (orders) {
              if (orders.isEmpty) {
                return Text(
                  'No recent orders',
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.textLight),
                );
              }
              return Column(
                children: orders.take(3).map((order) {
                  return _buildOrderCard(context, order);
                }).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderData order) {
    return GestureDetector(
      onTap: () => context.pushNamed('order-detail', extra: order.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    order.status ?? 'Unknown',
                    style: AppTextStyles.caption.copyWith(
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${order.total.toStringAsFixed(2)}',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommended(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended For You',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 12),
          Text(
            'Check back soon for personalized recommendations',
            style: AppTextStyles.body.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textLight;
    }
  }
}
