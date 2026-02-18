import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/product_providers.dart';

/// Product Detail Screen - Shows full product information with real data
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    // Log product view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Could log view analytics here
    });
  }

  @override
  Widget build(BuildContext context) {
    final productDetail = ref.watch(productDetailProvider(widget.productId));
    final relatedProducts = ref.watch(relatedProductsProvider((
      productId: widget.productId,
      category: productDetail.maybeWhen(
        data: (product) => product.categoryId,
        orElse: () => '',
      ),
    )));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            color: AppColors.textLight,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to wishlist'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: productDetail.when(
        data: (product) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Section
                Container(
                  width: double.infinity,
                  height: 350,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.shopping_basket,
                                    size: 80,
                                    color: AppColors.muted,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.shopping_basket,
                                size: 80,
                                color: AppColors.muted,
                              ),
                            ),
                      // Savings Badge (if there's a discount)
                      if (product.wholesalePrice < product.retailPrice)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'SAVE ${_calculateSavingsPercent(product.retailPrice, product.wholesalePrice)}%',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Product Info Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        product.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Price Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: AppSpacing.md,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Retail Price',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '₦${product.retailPrice.toStringAsFixed(0)}',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (product.wholesalePrice < product.retailPrice)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wholesale Price',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '₦${product.wholesalePrice.toStringAsFixed(0)}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Star Rating
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.star,
                                size: 16,
                                color: index < product.rating.toInt()
                                    ? Colors.amber
                                    : AppColors.border,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            '${product.rating.toStringAsFixed(1)} rating',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Product Details
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Details',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDetailRow('Product ID', product.id),
                      _buildDetailRow('Category', product.categoryId),
                      _buildDetailRow(
                        'Stock',
                        '${product.stock} units available',
                      ),
                      _buildDetailRow(
                        'MOQ',
                        '${product.minimumOrderQuantity} units',
                      ),
                    ],
                  ),
                ),

                // Description
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Description',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        product.description.isEmpty
                            ? 'High-quality product sourced directly from trusted suppliers. All products go through strict quality control to ensure you get the best value for your money.'
                            : product.description,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Benefits Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why Buy From Us?',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildBenefitRow(
                        Icons.verified,
                        'Quality Guaranteed',
                        'All products verified for quality',
                      ),
                      _buildBenefitRow(
                        Icons.local_shipping,
                        'Fast Delivery',
                        'Same-day delivery in select cities',
                      ),
                      _buildBenefitRow(
                        Icons.undo,
                        '30-Day Returns',
                        'Easy returns and exchanges',
                      ),
                      _buildBenefitRow(
                        Icons.card_giftcard,
                        'Member Rewards',
                        'Earn points on every purchase',
                      ),
                    ],
                  ),
                ),

                // Related Products
                if (relatedProducts.maybeWhen(
                  data: (products) => products.isNotEmpty,
                  orElse: () => false,
                ))
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    margin: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Related Products',
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        relatedProducts.when(
                          data: (products) => SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final related = products[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppSpacing.lg),
                                  child: _buildRelatedProductCard(related),
                                );
                              },
                            ),
                          ),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Error loading product',
                style: AppTextStyles.h4.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                error.toString(),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: productDetail.maybeWhen(
        data: (product) => Container(
          color: Colors.white,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.lg,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (quantity > 1) quantity--;
                        });
                      },
                    ),
                    Text(
                      quantity.toString(),
                      style: AppTextStyles.h4,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() => quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Add to Cart Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        product.stock > 0 ? AppColors.primary : AppColors.muted,
                  ),
                  onPressed: product.stock > 0
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$quantity x ${product.name} added to cart',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        orElse: () => SizedBox.fromSize(),
      ),
    );
  }

  int _calculateSavingsPercent(double retail, double wholesale) {
    if (retail == 0) return 0;
    return (((retail - wholesale) / retail) * 100).toInt();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.muted,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProductCard(dynamic product) {
    return GestureDetector(
      onTap: () {
        context.pushNamed('product-detail', extra: product.id);
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [AppShadows.sm],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                color: AppColors.background,
                image: product.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl == null
                  ? Icon(Icons.shopping_basket,
                      color: AppColors.muted, size: 30)
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '₦${product.retailPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
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
}
