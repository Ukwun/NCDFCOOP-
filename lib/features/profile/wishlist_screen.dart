import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_activity_providers.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (wishlistState.items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text('My Wishlist'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: AppColors.muted,
              ),
              const SizedBox(height: 24),
              Text(
                'Your wishlist is empty',
                style: AppTextStyles.h3.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: 12),
              Text(
                'Add items to your wishlist to save them for later',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'Continue Shopping',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'My Wishlist (${wishlistState.items.length})',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: wishlistState.items.length,
        itemBuilder: (context, index) {
          final item = wishlistState.items[index];
          final discountPercent =
              ((item.originalPrice - item.price) / item.originalPrice * 100)
                  .round();

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    image: item.imageUrl != null
                        ? DecorationImage(
                            image: item.imageUrl!.startsWith('assets/')
                                ? AssetImage(item.imageUrl!)
                                : NetworkImage(item.imageUrl!) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: AppColors.background,
                  ),
                  child: item.imageUrl == null
                      ? Icon(
                          Icons.image_not_supported,
                          color: AppColors.muted,
                        )
                      : null,
                ),

                // Product Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '₦${item.price.toStringAsFixed(0)}',
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₦${item.originalPrice.toStringAsFixed(0)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.muted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-$discountPercent%',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Move to Cart Button
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      color: AppColors.primary,
                      onPressed: () async {
                        // Add to cart
                        cartNotifier.addItem(
                          CartItem(
                            id: item.id,
                            productId: item.productId,
                            productName: item.productName,
                            memberPrice: item.price,
                            marketPrice: item.originalPrice,
                            imageUrl: item.imageUrl,
                          ),
                        );

                        // Log cart activity
                        try {
                          final activityLogger =
                              ref.read(activityLoggerProvider.notifier);
                          await activityLogger.logAddToCart(
                            productId: item.productId,
                            productName: item.productName,
                            category: 'Uncategorized',
                            price: item.price,
                            quantity: 1,
                          );
                          debugPrint('✅ Wishlist to cart logged');
                        } catch (e) {
                          debugPrint('⚠️ Failed to log wishlist to cart: $e');
                        }

                        // Remove from wishlist
                        ref
                            .read(wishlistProvider.notifier)
                            .removeItem(item.productId);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Added to cart'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                cartNotifier.removeItem(item.productId);
                                ref
                                    .read(wishlistProvider.notifier)
                                    .addItem(item);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    // Remove from Wishlist Button
                    IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        ref
                            .read(wishlistProvider.notifier)
                            .removeItem(item.productId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Removed from wishlist'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
