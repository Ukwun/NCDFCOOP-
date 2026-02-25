import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/product_providers.dart';
import 'package:coop_commerce/core/providers/real_time_providers.dart';
import 'package:coop_commerce/widgets/product_image.dart';
import 'package:coop_commerce/providers/cart_provider.dart';
import 'package:coop_commerce/providers/cart_provider.dart';
import 'package:coop_commerce/providers/wishlist_provider.dart' as wl;
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/user_activity_providers.dart';

/// Product Detail Screen - Shows full product information with real data
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  final Map<String, dynamic>?
      productData; // Actual product passed from category

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.productData,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;

  Widget _buildSimpleProductDetail(Map<String, dynamic> product) {
    final savings = (product['original'] as num) - (product['price'] as num);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product['name']} added to wishlist'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing ${product['name']}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              child: _buildProductImage(product['image']),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Company
                  Text(
                    'By ${product['company']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Size
                  Text(
                    'Size: ${product['size']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pricing
                  Row(
                    children: [
                      Text(
                        '₦${(product['price'] as num).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₦${(product['original'] as num).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save ₦${savings.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quantity Selector
                  Row(
                    children: [
                      const Text('Quantity:'),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (quantity > 1) quantity--;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                child: const Text('-'),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: Text(quantity.toString()),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  quantity++;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                child: const Text('+'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Log add to cart activity
                        try {
                          final activityLogger =
                              ref.read(activityLoggerProvider.notifier);
                          await activityLogger.logAddToCart(
                            productId: widget.productId,
                            productName: product['name'] ?? 'Unknown',
                            category: product['category'] ?? 'Uncategorized',
                            price: (product['price'] as num?)?.toDouble() ?? 0,
                            quantity: quantity,
                          );
                          debugPrint('✅ Add to cart logged');
                        } catch (e) {
                          debugPrint('⚠️ Failed to log add to cart: $e');
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${product['name']} (x$quantity) added to cart'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'High-quality ${product['name'].toString().toLowerCase()} from ${product['company']}. Size: ${product['size']}. Perfect for your household needs. Member exclusive pricing available at ₦${(product['price'] as num).toStringAsFixed(0)}.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imagePath) {
    return Image(
      image: imagePath != null && imagePath.startsWith('assets/')
          ? AssetImage(imagePath)
          : imagePath != null
              ? NetworkImage(imagePath)
              : AssetImage('assets/images/Groceries1.png') as ImageProvider,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_not_supported,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Image not available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Log product view to Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logProductView();
    });
  }

  /// Log product view to Firestore
  Future<void> _logProductView() async {
    try {
      final activityLogger = ref.read(activityLoggerProvider.notifier);

      // Get product name and category from the passed data
      String productName = 'Unknown Product';
      String category = 'Uncategorized';
      double price = 0;

      if (widget.productData != null) {
        productName = widget.productData!['name'] ?? productName;
        category = widget.productData!['category'] ?? category;
        price = (widget.productData!['price'] as num?)?.toDouble() ?? 0;
      }

      await activityLogger.logProductView(
        productId: widget.productId,
        productName: productName,
        category: category,
        price: price,
      );

      debugPrint('✅ Product view logged: $productName');
    } catch (e) {
      debugPrint('⚠️ Failed to log product view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If product data was passed from category screen, use it directly
    if (widget.productData != null) {
      return _buildSimpleProductDetail(widget.productData!);
    }

    // Otherwise use the complex provider-based approach
    final productDetail = ref.watch(productDetailProvider(widget.productId));
    final relatedProducts = ref.watch(relatedProductsProvider((
      productId: widget.productId,
      category: productDetail.maybeWhen(
        data: (product) => product.categoryId,
        orElse: () => '',
      ),
    )));

    // Watch for real-time pricing updates for this product
    final pricingUpdate = ref.watch(
      cartPricingUpdatesProvider([widget.productId]),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('home');
            }
          },
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isWishlisted =
                  ref.watch(wl.isProductInWishlistProvider(widget.productId));
              return IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? Colors.red : AppColors.textLight,
                ),
                onPressed: () async {
                  final productName = productDetail.maybeWhen(
                    data: (p) => p.name,
                    orElse: () => 'Product',
                  );
                  final category = productDetail.maybeWhen(
                    data: (p) => p.categoryId,
                    orElse: () => 'Other',
                  );
                  final price = productDetail.maybeWhen(
                    data: (p) => p.retailPrice,
                    orElse: () => 0.0,
                  );

                  // Toggle wishlist
                  ref.read(wl.wishlistProvider.notifier).toggleWishlist(
                        productId: widget.productId,
                        productName: productName,
                        price: price,
                        originalPrice: price,
                        imageUrl: productDetail.maybeWhen(
                          data: (p) => p.imageUrl,
                          orElse: () => null,
                        ),
                      );

                  // Log activity only when adding
                  if (!isWishlisted) {
                    try {
                      final activityLogger =
                          ref.read(activityLoggerProvider.notifier);
                      await activityLogger.logAddToWishlist(
                        productId: widget.productId,
                        productName: productName,
                        category: category,
                        price: price,
                      );
                      debugPrint('✅ Wishlist add activity logged');
                    } catch (e) {
                      debugPrint('⚠️ Failed to log wishlist activity: $e');
                    }
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isWishlisted
                            ? 'Removed from wishlist'
                            : 'Added to wishlist',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
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
                // Real-time Pricing Update Banner
                pricingUpdate.when(
                  data: (update) {
                    if (update.promotionActive &&
                        update.newPrice != null &&
                        update.oldPrice != null &&
                        update.affectedProducts.contains(widget.productId)) {
                      final discountPercent =
                          (((update.oldPrice! - update.newPrice!) /
                                      update.oldPrice!) *
                                  100)
                              .toStringAsFixed(0);
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          border: Border.all(
                            color: Colors.amber[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_offer,
                              color: Colors.amber[700],
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price Updated!',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppSpacing.xs,
                                  ),
                                  Text(
                                    '₦${update.oldPrice!.toStringAsFixed(0)} → ₦${update.newPrice!.toStringAsFixed(0)} (Save $discountPercent%)',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.amber[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),

                // Product Image Section
                Container(
                  width: double.infinity,
                  height: 350,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      product.imageUrl != null
                          ? ProductImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
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

                      // Price Section - Role-Aware Pricing
                      Consumer(
                        builder: (context, ref, _) {
                          final user = ref.watch(currentUserProvider);
                          final userRole = user?.roles?.isNotEmpty == true
                              ? user!.roles!.first.toString().split('.').last
                              : 'consumer';

                          final currentPrice =
                              product.getPriceForRole(userRole);
                          final savings = userRole.contains('member')
                              ? product.getMemberSavingsPercent()
                              : 0.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Price for current role
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                spacing: AppSpacing.md,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getPriceLabel(userRole),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '₦${currentPrice.toStringAsFixed(0)}',
                                        style: AppTextStyles.h3.copyWith(
                                          color: _getPriceColor(userRole),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Show savings for members
                                  if (userRole.contains('member') &&
                                      product.retailPrice > currentPrice)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'SAVE',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${savings.toStringAsFixed(0)}%',
                                            style: AppTextStyles.h4.copyWith(
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              // Show retail price for comparison (not for institutional)
                              if (!userRole.contains('institutional'))
                                const SizedBox(height: AppSpacing.md),
                              if (!userRole.contains('institutional'))
                                Text(
                                  'Retail: ₦${product.retailPrice.toStringAsFixed(0)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.muted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          );
                        },
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

                // Reviews Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer Reviews',
                                style: AppTextStyles.h4,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                spacing: 8,
                                children: [
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                        5,
                                        (i) => Icon(
                                              Icons.star,
                                              size: 16,
                                              color: i < product.rating.toInt()
                                                  ? Colors.amber
                                                  : AppColors.border,
                                            )),
                                  ),
                                  Text(
                                    '(Based on verified purchases)',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                context.goNamed(
                                  'product-reviews',
                                  pathParameters: {'productId': product.id},
                                  queryParameters: {
                                    'productName': product.name
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: const Text(
                                'See All',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
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
              Consumer(
                builder: (context, ref, child) {
                  final cartNotifier = ref.read(cartProvider.notifier);
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: product.stock > 0
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                      onPressed: product.stock > 0
                          ? () {
                              // Add to cart
                              for (int i = 0; i < quantity; i++) {
                                cartNotifier.addItem(
                                  CartItem(
                                    id: DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString() +
                                        i.toString(),
                                    productId: product.id,
                                    productName: product.name,
                                    memberPrice: product.retailPrice,
                                    marketPrice: product.retailPrice,
                                    imageUrl: product.imageUrl,
                                  ),
                                );
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$quantity x ${product.name} added to cart',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'View Cart',
                                    onPressed: () {
                                      context.pushNamed('cart');
                                    },
                                  ),
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
                  );
                },
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

  String _getPriceLabel(String userRole) {
    if (userRole.contains('member') || userRole.contains('cooperative')) {
      return 'Member Price';
    } else if (userRole.contains('institutional')) {
      return 'Contract Price';
    }
    return 'Retail Price';
  }

  Color _getPriceColor(String userRole) {
    if (userRole.contains('member') || userRole.contains('cooperative')) {
      return Colors.green;
    } else if (userRole.contains('institutional')) {
      return Colors.blue;
    }
    return AppColors.primary;
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
        context.goNamed('product-detail',
            pathParameters: {'productId': product.id});
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
                        image: product.imageUrl!.startsWith('assets/')
                            ? AssetImage(product.imageUrl!)
                            : NetworkImage(product.imageUrl!) as ImageProvider,
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
