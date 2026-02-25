import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/widgets/product_image.dart';

/// Product model for display
class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double regularPrice;
  final double memberPrice;
  final String company;
  final int rating;
  final int reviewCount;
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.regularPrice,
    required this.memberPrice,
    required this.company,
    this.rating = 4,
    this.reviewCount = 0,
    this.inStock = true,
  });

  double get savings => regularPrice - memberPrice;
  double get savingsPercent => ((savings / regularPrice) * 100).roundToDouble();
}

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Product? product; // Optional: pass product data if available

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product product;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    // Use passed product or create mock product for demo
    product = widget.product ??
        Product(
          id: widget.productId,
          name: 'Premium Basmati Rice',
          description:
              'High-quality long-grain basmati rice. Perfect for biryanis and pilafs. Net weight: 5kg.',
          imageUrl:
              'https://images.unsplash.com/photo-1638551112442-20fcf9f96f64?w=500&h=500&fit=crop',
          regularPrice: 8500,
          memberPrice: 6800,
          company: 'Golden Rice Co.',
          rating: 5,
          reviewCount: 342,
          inStock: true,
        );
  }

  void _addToCart() {
    // TODO: Integrate with cart provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Added $quantity x ${product.name} to cart'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❤️ Added to wishlist')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            Container(
              color: Colors.grey[100],
              height: 350,
              width: double.infinity,
              child: Stack(
                children: [
                  // Product image
                  Center(
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Stock badge
                  if (!product.inStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Savings badge
                  if (product.savings > 0)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent, // Gold
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Save ${product.savingsPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company name
                  Text(
                    product.company,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Product name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: i < product.rating
                                ? AppColors.accent
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${product.rating}.0 (${product.reviewCount} reviews)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 16),

                  // Pricing Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Regular price (strikethrough)
                          Text(
                            '₦${product.regularPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Member price (green, bold)
                          Text(
                            '₦${product.memberPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary, // Green
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Savings amount
                      Text(
                        '💰 You save ₦${product.savings.toStringAsFixed(0)} (${product.savingsPercent.toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantity Selector
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Decrease button
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                          ),
                        ),
                        // Quantity display
                        SizedBox(
                          width: 50,
                          child: Center(
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Increase button
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() => quantity++),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Add to Cart Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: product.inStock ? _addToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              product.inStock
                  ? '🛒 Add $quantity to Cart (₦${(product.memberPrice * quantity).toStringAsFixed(0)})'
                  : 'Out of Stock',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
