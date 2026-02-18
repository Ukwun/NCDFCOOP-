import 'package:flutter/material.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/features/home/home_viewmodel.dart';

/// Consistent product card widget used across the app
class ProductCard extends StatelessWidget {
  final ProductData product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onTap;
  final bool showExclusiveBadge;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onTap,
    this.showExclusiveBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.smList,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image Container
            Expanded(
              flex: 3,
              child: _buildImageContainer(),
            ),
            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontSize: 13,
                      ),
                    ),
                    // Pricing Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Member Price (Bold)
                        Text(
                          '₦${product.memberPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                        // Market Price (Strikethrough)
                        Text(
                          '₦${product.marketPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.textLight,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: onAddToCart,
                        child: Text(
                          'Add to Cart',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Stack(
        children: [
          // Placeholder image
          Center(
            child: Icon(
              Icons.image_outlined,
              size: 60,
              color: AppColors.border,
            ),
          ),
          // Exclusive badge (if applicable)
          if (showExclusiveBadge)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  'EXCLUSIVE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          // Savings percentage badge
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                'Save ${product.savingsPercentage}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable product list
class ProductListHorizontal extends StatelessWidget {
  final List<ProductData> products;
  final String? title;
  final VoidCallback? onViewAll;

  const ProductListHorizontal({
    super.key,
    required this.products,
    this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title!, style: AppTextStyles.h3),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Text(
                      'View All',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (title != null) const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: products[index],
                    showExclusiveBadge: true,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Grid view for products
class ProductGridView extends StatelessWidget {
  final List<ProductData> products;
  final int crossAxisCount;
  final VoidCallback? onAddToCart;

  const ProductGridView({
    super.key,
    required this.products,
    this.crossAxisCount = 2,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.7,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          onAddToCart: onAddToCart,
        );
      },
    );
  }
}
