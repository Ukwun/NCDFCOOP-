import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/widgets/product_image.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  late TextEditingController searchController;
  String selectedCategory = 'All';
  String sortBy = 'Relevance';

  final List<String> categories = [
    'All',
    'Grains & Rice',
    'Spices',
    'Oils & Fats',
    'Sugar & Sweeteners',
    'Condiments',
  ];

  final List<String> sortOptions = [
    'Relevance',
    'Price: Low to High',
    'Price: High to Low',
    'Newest',
    'Top Rated',
  ];

  // Mock products - TODO: Replace with Firestore data
  final List<Map<String, dynamic>> allProducts = [
    {
      'id': '1',
      'name': 'Premium Basmati Rice',
      'company': 'Golden Rice Co.',
      'image':
          'https://images.unsplash.com/photo-1638551112442-20fcf9f96f64?w=200&h=200&fit=crop',
      'regularPrice': 8500,
      'memberPrice': 6800,
      'rating': 5,
      'reviews': 342,
      'inStock': true,
      'category': 'Grains & Rice',
    },
    {
      'id': '2',
      'name': 'Organic Sugar',
      'company': 'Sweet Life Ltd',
      'image':
          'https://images.unsplash.com/photo-1599599810694-b6be7d4a7c67?w=200&h=200&fit=crop',
      'regularPrice': 3500,
      'memberPrice': 2500,
      'rating': 4,
      'reviews': 128,
      'inStock': true,
      'category': 'Sugar & Sweeteners',
    },
    {
      'id': '3',
      'name': 'Ground Pepper',
      'company': 'Spice Master',
      'image':
          'https://images.unsplash.com/photo-1599599810694-b6be7d4a7c67?w=200&h=200&fit=crop',
      'regularPrice': 9500,
      'memberPrice': 8200,
      'rating': 4,
      'reviews': 85,
      'inStock': true,
      'category': 'Spices',
    },
    {
      'id': '4',
      'name': 'Cooking Oil (1L)',
      'company': 'Oil Refinery Co.',
      'image':
          'https://images.unsplash.com/photo-1599599810694-b6be7d4a7c67?w=200&h=200&fit=crop',
      'regularPrice': 4500,
      'memberPrice': 3800,
      'rating': 5,
      'reviews': 512,
      'inStock': true,
      'category': 'Oils & Fats',
    },
    {
      'id': '5',
      'name': 'Tomato Paste (2kg)',
      'company': 'Fresh Foods Ltd',
      'image':
          'https://images.unsplash.com/photo-1599599810694-b6be7d4a7c67?w=200&h=200&fit=crop',
      'regularPrice': 7200,
      'memberPrice': 6250,
      'rating': 4,
      'reviews': 203,
      'inStock': false,
      'category': 'Condiments',
    },
    {
      'id': '6',
      'name': 'Soya Beans',
      'company': 'Legume Farm',
      'image':
          'https://images.unsplash.com/photo-1599599810694-b6be7d4a7c67?w=200&h=200&fit=crop',
      'regularPrice': 6000,
      'memberPrice': 4800,
      'rating': 5,
      'reviews': 156,
      'inStock': true,
      'category': 'Grains & Rice',
    },
  ];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredProducts {
    return allProducts.where((product) {
      // Category filter
      if (selectedCategory != 'All' &&
          product['category'] != selectedCategory) {
        return false;
      }

      // Search filter
      if (searchController.text.isNotEmpty) {
        final query = searchController.text.toLowerCase();
        return product['name'].toString().toLowerCase().contains(query) ||
            product['company'].toString().toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  void _addToCart(Map<String, dynamic> product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Added ${product['name']} to cart'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Add to cart provider
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '🛒 Products',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❤️ Wishlist')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedCategory = category);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Sort dropdown and product count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredProducts.length} products',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                PopupMenuButton(
                  initialValue: sortBy,
                  onSelected: (String value) {
                    setState(() => sortBy = value);
                  },
                  itemBuilder: (BuildContext context) =>
                      sortOptions.map((String option) {
                    return PopupMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  child: Row(
                    children: [
                      Text(
                        'Sort: $sortBy',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Products grid
          Expanded(
            child: filteredProducts.isEmpty
                ? _buildNoResults()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) =>
                        _buildProductCard(filteredProducts[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isMember = true; // TODO: Get from user provider
    final memberPrice = product['memberPrice'];
    final regularPrice = product['regularPrice'];
    final savings = regularPrice - memberPrice;
    final savingsPercent = ((savings / regularPrice) * 100).toInt();

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to product detail
        // context.push('/products/${product['id']}');
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              child: Stack(
                children: [
                  // Product image
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: ProductImage(
                      imageUrl: product['image'],
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Savings badge
                  if (savings > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Save $savingsPercent%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                  // Out of stock overlay
                  if (!product['inStock'])
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Wishlist button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❤️ Added to wishlist'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product info section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rating
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: i < product['rating']
                              ? AppColors.accent
                              : Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product['reviews']})',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Product name
                  Text(
                    product['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Row(
                    children: [
                      Text(
                        '₦${memberPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₦${regularPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          product['inStock'] ? () => _addToCart(product) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        '🛒 Add',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: product['inStock']
                              ? Colors.white
                              : Colors.grey[700],
                        ),
                      ),
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
}
