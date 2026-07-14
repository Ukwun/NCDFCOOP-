import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Models (adapt based on your app's structure)
// import '../models/product_model.dart';

/// Product model (simplified)
class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.description,
  });
}

/// Lazy loading state
class PaginationState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  PaginationState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  PaginationState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PaginationState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing pagination
class PaginationNotifier extends Notifier<PaginationState> {
  // Configuration
  static const pageSize = 20;
  static const maxPages = 5; // Load max 100 products

  @override
  PaginationState build() {
    return PaginationState();
  }

  /// Load initial page of products
  Future<void> loadFirstPage() async {
    if (state.currentPage != 0) {
      // Reset to first page
      state = PaginationState();
    }

    await loadNextPage();
  }

  /// Load next page of products
  Future<void> loadNextPage() async {
    // Don't load if already loading
    if (state.isLoading) return;

    // Don't load if no more products
    if (!state.hasMore) return;

    // Don't exceed max pages
    if (state.currentPage >= maxPages) {
      state = state.copyWith(hasMore: false);
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Fetch products from API
      final newProducts = await _fetchProductsPage(
        pageNumber: state.currentPage,
        pageSize: pageSize,
      );

      // Check if this is the last page
      final isLastPage = newProducts.length < pageSize;

      // Update state
      state = state.copyWith(
        products: [...state.products, ...newProducts],
        isLoading: false,
        hasMore: !isLastPage,
        currentPage: state.currentPage + 1,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  /// Refresh - clear and reload first page
  Future<void> refresh() async {
    state = PaginationState();
    await loadFirstPage();
  }

  /// Reset pagination state
  void reset() {
    state = PaginationState();
  }

  Future<List<Product>> _fetchProductsPage({
    required int pageNumber,
    required int pageSize,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('is_active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .limit((pageNumber + 1) * pageSize)
        .get();
    return snapshot.docs.skip(pageNumber * pageSize).map((doc) {
      final data = doc.data();
      final images = data['images'] is List ? data['images'] as List : const [];
      return Product(
        id: doc.id,
        name: (data['name'] ?? data['productName'] ?? 'Product').toString(),
        image: (data['imageUrl'] ?? (images.isNotEmpty ? images.first : ''))
            .toString(),
        price: ((data['retailPrice'] ?? data['price'] ?? 0) as num).toDouble(),
        description: (data['description'] ?? '').toString(),
      );
    }).toList();
  }

  /// Filter products by category
  Future<void> filterByCategory(String category) async {
    state = PaginationState();
    // TODO: Implement category filter
    await loadFirstPage();
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await refresh();
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Fetch search results
      final results = await _searchProducts(query);

      state = state.copyWith(
        products: results,
        isLoading: false,
        hasMore: false, // Search results don't have pagination
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<List<Product>> _searchProducts(String query) async {
    final normalized = query.trim().toLowerCase();
    final products = await _fetchProductsPage(pageNumber: 0, pageSize: 100);
    return products
        .where((product) =>
            product.name.toLowerCase().contains(normalized) ||
            product.description.toLowerCase().contains(normalized))
        .toList();
  }
}

// ==================== RIVERPOD PROVIDERS ====================

/// Provider for product pagination
final productPaginationProvider =
    NotifierProvider<PaginationNotifier, PaginationState>(() {
  return PaginationNotifier();
});

/// Provider for just the product list
final productListProvider = Provider<List<Product>>((ref) {
  final state = ref.watch(productPaginationProvider);
  return state.products;
});

/// Provider for pagination status
final paginationLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(productPaginationProvider);
  return state.isLoading;
});

/// Provider for pagination error
final paginationErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(productPaginationProvider);
  return state.error;
});

/// Provider for "has more" status
final paginationHasMoreProvider = Provider<bool>((ref) {
  final state = ref.watch(productPaginationProvider);
  return state.hasMore;
});

/// Provider for items remaining
final itemsRemainingProvider = Provider<int>((ref) {
  final state = ref.watch(productPaginationProvider);
  return state.hasMore ? -1 : state.products.length; // -1 means unknown
});
