import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/product_service.dart';
import 'package:coop_commerce/core/audit/audit_service.dart';
import 'package:coop_commerce/models/product.dart';

// ===================== SERVICE PROVIDERS =====================

/// ProductService provider
final productServiceProvider = Provider((ref) {
  final auditService = AuditService();
  return ProductService(auditService);
});

const int productsPerPage = 20;

// ===================== DATA PROVIDERS =====================

/// Get all products
final allProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final productService = ref.watch(productServiceProvider);

  final result = await productService.getAllProducts(
    limit: productsPerPage,
    offset: 0,
    sortBy: 'popularity',
  );

  return result.products;
});

/// Get products by category
final productsByCategoryProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, categoryId) async {
  final productService = ref.watch(productServiceProvider);

  final result = await productService.getProductsByCategory(
    category: categoryId,
    limit: productsPerPage,
    offset: 0,
    sortBy: 'popularity',
  );

  return result.products;
});

/// Search products by query
final productSearchProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, searchQuery) async {
  if (searchQuery.isEmpty) {
    return [];
  }

  final productService = ref.watch(productServiceProvider);

  final result = await productService.searchProducts(
    searchQuery: searchQuery,
    limit: productsPerPage,
    offset: 0,
  );

  return result.products;
});

/// Get product details by ID
final productDetailProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, productId) async {
  final productService = ref.watch(productServiceProvider);
  return productService.getProductById(productId: productId);
});

/// Get related products for a product
final relatedProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, ({String productId, String category})>(
        (ref, params) async {
  final productService = ref.watch(productServiceProvider);
  return productService.getRelatedProducts(
    productId: params.productId,
    category: params.category,
    limit: 6,
  );
});

/// Get featured products
final featuredProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final productService = ref.watch(productServiceProvider);
  return productService.getFeaturedProducts(limit: 10);
});

/// Get member-exclusive products
final memberExclusiveProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final productService = ref.watch(productServiceProvider);
  return productService.getMemberExclusiveProducts(limit: 10);
});

/// Get all categories
final categoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final productService = ref.watch(productServiceProvider);
  return productService.getCategories();
});

/// Get price range for a category
final categoryPriceRangeProvider = FutureProvider.autoDispose
    .family<({double minPrice, double maxPrice}), String>(
        (ref, category) async {
  final productService = ref.watch(productServiceProvider);
  return productService.getPriceRange(category: category);
});

// ===================== WISHLIST PROVIDERS =====================

/// Wishlist items (local state - using empty list as default)
final wishlistProvider = Provider<List<String>>((ref) => []);

/// Check if product is in wishlist
final isProductWishlisted =
    FutureProvider.family<bool, String>((ref, productId) async {
  final wishlist = ref.watch(wishlistProvider);
  return wishlist.contains(productId);
});

// ===================== HELPER PROVIDERS =====================

/// Get currently displayed products - simplified to just return all products
final displayedProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final result = await ref.watch(allProductsProvider.future);
  return result;
});

/// Check if there are more products to load
final canLoadMoreProvider = FutureProvider.autoDispose<bool>((ref) async {
  return false; // Simplified - pagination handled at screen level
});
