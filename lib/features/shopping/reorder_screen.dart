import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Screen for reordering previous products
class ReorderScreen extends ConsumerWidget {
  const ReorderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock products for fallback display
    final mockReorderItems = [
      {
        'productId': 'prod_001',
        'name': 'Premium Rice - 50kg',
        'price': 22000.0,
        'imageUrl': 'https://via.placeholder.com/150?text=Rice',
      },
      {
        'productId': 'prod_002',
        'name': 'Palm Oil - 25L',
        'price': 45000.0,
        'imageUrl': 'https://via.placeholder.com/150?text=Oil',
      },
      {
        'productId': 'prod_003',
        'name': 'Black Beans - 20kg',
        'price': 15000.0,
        'imageUrl': 'https://via.placeholder.com/150?text=Beans',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reorder'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: mockReorderItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: AppColors.muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No previous orders found',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start shopping to reorder items',
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
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockReorderItems.length,
              itemBuilder: (context, index) {
                final item = mockReorderItems[index];
                return _buildReorderItem(context, item);
              },
            ),
    );
  }

  Widget _buildReorderItem(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => context.goNamed('product-detail',
          pathParameters: {'productId': item['productId']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.smList,
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                image: item['imageUrl'] != null
                    ? DecorationImage(
                        image: item['imageUrl'].toString().startsWith('assets/')
                            ? AssetImage(item['imageUrl'])
                            : NetworkImage(item['imageUrl']) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item['imageUrl'] == null
                  ? Icon(
                      Icons.image_outlined,
                      color: AppColors.muted,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${item['price'].toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Add to Cart Button
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['name']} added to cart'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.add_shopping_cart),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
