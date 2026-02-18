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

// ===================== STATE PROVIDERS =====================

/// Search query notifier
class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

/// Track the current search query
final productSearchQueryProvider =
    NotifierProvider<_SearchQueryNotifier, String>(() {
  return _SearchQueryNotifier();
});

/// Pagination notifier
class _PaginationNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

/// Track pagination state
final paginationNotifierProvider =
    NotifierProvider<_PaginationNotifier, int>(() {
  return _PaginationNotifier();
});

// ===================== FILTER STATE PROVIDERS =====================

/// Product filters state
class ProductFilters {
  final String? category;
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;

  ProductFilters({
    this.category,
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'popularity',
  });

  ProductFilters copyWith({
    String? category,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) {
    return ProductFilters(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// Track current product filters
final productFiltersProvider =
    NotifierProvider<ProductFiltersNotifier, ProductFilters>(() {
  return ProductFiltersNotifier();
});

class ProductFiltersNotifier extends Notifier<ProductFilters> {
  @override
  ProductFilters build() => ProductFilters();

  void setCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void setPriceRange(double? minPrice, double? maxPrice) {
    state = state.copyWith(minPrice: minPrice, maxPrice: maxPrice);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void reset() {
    state = ProductFilters();
  }
}

/// Mock products for fallback
List<Product> _getMockProducts() {
  return [
    Product(
      id: 'mock_001',
      name: 'Premium Rice 50kg',
      retailPrice: 22000.0,
      wholesalePrice: 19800.0,
      contractPrice: 18000.0,
      description: 'High quality long grain rice - perfect for bulk orders',
      imageUrl: 'assets/images/ijebugarri1.png',
      categoryId: 'grains',
      stock: 100,
    ),
    Product(
      id: 'mock_002',
      name: 'Palm Oil 25L',
      retailPrice: 45000.0,
      wholesalePrice: 40500.0,
      contractPrice: 40000.0,
      description: 'Premium edible palm oil for cooking',
      imageUrl: 'assets/images/Groundnut oil1.png',
      categoryId: 'oils',
      stock: 50,
    ),
    Product(
      id: 'mock_003',
      name: 'Black Beans 20kg',
      retailPrice: 15000.0,
      wholesalePrice: 13500.0,
      contractPrice: 12000.0,
      description: 'Quality black beans legumes - wholesale pricing',
      imageUrl: 'assets/images/Honey beans1.png',
      categoryId: 'legumes',
      stock: 75,
    ),
    Product(
      id: 'mock_004',
      name: 'White Sugar 25kg',
      retailPrice: 28000.0,
      wholesalePrice: 25200.0,
      contractPrice: 24000.0,
      description: 'Pure white granulated sugar',
      imageUrl: 'assets/images/All inclusive pack.png',
      categoryId: 'sweeteners',
      stock: 60,
    ),
    Product(
      id: 'mock_005',
      name: 'Garlic Powder 500g',
      retailPrice: 3500.0,
      wholesalePrice: 3150.0,
      contractPrice: 3000.0,
      description: 'Premium garlic powder spice - high quality seasoning',
      imageUrl: 'assets/images/6in1 spices.png',
      categoryId: 'spices',
      stock: 120,
    ),
    Product(
      id: 'mock_006',
      name: 'Tomato Paste 1kg',
      retailPrice: 5000.0,
      wholesalePrice: 4500.0,
      contractPrice: 4200.0,
      description: 'Rich tomato paste for cooking - concentrated flavor',
      imageUrl: 'assets/images/Tomatoes1.png',
      categoryId: 'condiments',
      stock: 90,
    ),
    Product(
      id: 'mock_007',
      name: 'Onion Powder 300g',
      retailPrice: 2800.0,
      wholesalePrice: 2520.0,
      contractPrice: 2400.0,
      description: 'Fine onion powder seasoning - perfect for all dishes',
      imageUrl: 'assets/images/One crate eggs1.png',
      categoryId: 'spices',
      stock: 110,
    ),
    Product(
      id: 'mock_008',
      name: 'Chicken Seasoning 250g',
      retailPrice: 3200.0,
      wholesalePrice: 2880.0,
      contractPrice: 2700.0,
      description: 'Delicious chicken seasoning mix - perfect for poultry',
      imageUrl: 'assets/images/Spices hamper1.png',
      categoryId: 'spices',
      stock: 95,
    ),
  ];
}

/// Get products filtered by active filters
final productsByFiltersProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final filters = ref.watch(productFiltersProvider);
  final productService = ref.watch(productServiceProvider);

  try {
    // Apply filters based on what's set
    if (filters.searchQuery?.isNotEmpty == true) {
      // If searching, use search endpoint
      final result = await productService.searchProducts(
        searchQuery: filters.searchQuery!,
        limit: 50,
        offset: 0,
      );
      return result.products;
    } else if (filters.category?.isNotEmpty == true) {
      // If category selected, use category endpoint
      final result = await productService.getProductsByCategory(
        category: filters.category!,
        limit: 50,
        offset: 0,
        sortBy: filters.sortBy,
      );
      return result.products;
    } else {
      // Default: get all products
      final result = await productService.getAllProducts(
        limit: 50,
        offset: 0,
        sortBy: filters.sortBy,
      );
      return result.products;
    }
  } catch (e) {
    // Return mock products as fallback when service fails
    return _getMockProducts();
  }
});

// ===================== DATA PROVIDERS =====================

/// Get all products
final allProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  try {
    final productService = ref.watch(productServiceProvider);

    final result = await productService.getAllProducts(
      limit: productsPerPage,
      offset: 0,
      sortBy: 'popularity',
    );

    return result.products;
  } catch (e) {
    return _getMockProducts();
  }
});

/// Get products by category
final productsByCategoryProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, categoryId) async {
  try {
    final productService = ref.watch(productServiceProvider);

    final result = await productService.getProductsByCategory(
      category: categoryId,
      limit: productsPerPage,
      offset: 0,
      sortBy: 'popularity',
    );

    return result.products;
  } catch (e) {
    return _getMockProducts().where((p) => p.categoryId == categoryId).toList();
  }
});

/// Search products by query
final productSearchProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, searchQuery) async {
  if (searchQuery.isEmpty) {
    return [];
  }

  try {
    final productService = ref.watch(productServiceProvider);

    final result = await productService.searchProducts(
      searchQuery: searchQuery,
      limit: productsPerPage,
      offset: 0,
    );

    return result.products;
  } catch (e) {
    // Fallback: search mock products locally
    final query = searchQuery.toLowerCase();
    return _getMockProducts()
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query))
        .toList();
  }
});

/// Get product details by ID
final productDetailProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, productId) async {
  try {
    final productService = ref.watch(productServiceProvider);
    return productService.getProductById(productId: productId);
  } catch (e) {
    // Fallback: find in mock products
    final mockProducts = _getMockProducts();
    try {
      return mockProducts.firstWhere((p) => p.id == productId);
    } catch (_) {
      return mockProducts.first; // Return first if not found
    }
  }
});

/// Get related products for a product
final relatedProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, ({String productId, String category})>(
        (ref, params) async {
  try {
    final productService = ref.watch(productServiceProvider);
    return productService.getRelatedProducts(
      productId: params.productId,
      category: params.category,
      limit: 6,
    );
  } catch (e) {
    // Fallback: get mock products from same category
    return _getMockProducts()
        .where(
            (p) => p.categoryId == params.category && p.id != params.productId)
        .take(6)
        .toList();
  }
});

/// Get featured products
final featuredProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  try {
    final productService = ref.watch(productServiceProvider);
    return productService.getFeaturedProducts(limit: 10);
  } catch (e) {
    return _getMockProducts().take(10).toList();
  }
});

/// Get member-exclusive products
final memberExclusiveProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  try {
    final productService = ref.watch(productServiceProvider);
    return productService.getMemberExclusiveProducts(limit: 10);
  } catch (e) {
    return _getMockProducts().take(10).toList();
  }
});

/// Get all categories
final categoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  try {
    final productService = ref.watch(productServiceProvider);
    return productService.getCategories();
  } catch (e) {
    // Fallback: extract categories from mock products
    return _getMockProducts().map((p) => p.categoryId).toSet().toList()..sort();
  }
});

/// Get price range for a category
final categoryPriceRangeProvider = FutureProvider.autoDispose
    .family<({double minPrice, double maxPrice}), String>(
        (ref, category) async {
  try {
    final productService = ref.watch(productServiceProvider);
    return productService.getPriceRange(category: category);
  } catch (e) {
    // Fallback: calculate from mock products
    final filtered =
        _getMockProducts().where((p) => p.categoryId == category).toList();
    if (filtered.isEmpty) {
      return (minPrice: 0.0, maxPrice: 100000.0);
    }
    double minPrice = filtered.first.retailPrice;
    double maxPrice = filtered.first.retailPrice;
    for (var product in filtered) {
      minPrice =
          minPrice > product.retailPrice ? product.retailPrice : minPrice;
      maxPrice =
          maxPrice < product.retailPrice ? product.retailPrice : maxPrice;
    }
    return (minPrice: minPrice, maxPrice: maxPrice);
  }
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
