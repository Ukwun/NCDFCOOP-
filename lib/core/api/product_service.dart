import 'api_client.dart';
import 'package:coop_commerce/models/product.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';

/// Product service for API calls
class ProductService {
  final ApiClient _apiClient;

  ProductService(this._apiClient);

  /// Fetch all products
  Future<ProductResult> getAllProducts({
    int page = 1,
    int limit = 20,
    int offset = 0,
    String sortBy = 'popularity',
  }) async {
    try {
      final response = await _apiClient.client.get(
        '/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          'offset': offset,
          'sortBy': sortBy,
        },
      );
      final products = (response.data['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList();
      return ProductResult(
          products: products, total: response.data['total'] ?? 0);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch product by ID
  Future<Product> getProductById(String productId) async {
    try {
      final response = await _apiClient.client.get('/products/$productId');
      return Product.fromJson(response.data['product']);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch products by category
  Future<ProductResult> getProductsByCategory({
    required String category,
    int page = 1,
    int limit = 20,
    int offset = 0,
    String sortBy = 'popularity',
  }) async {
    try {
      final response = await _apiClient.client.get(
        '/categories/$category/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          'offset': offset,
          'sortBy': sortBy,
        },
      );
      final products = (response.data['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList();
      return ProductResult(
          products: products, total: response.data['total'] ?? 0);
    } catch (e) {
      rethrow;
    }
  }

  /// Search products
  Future<ProductResult> searchProducts({
    required String searchQuery,
    int page = 1,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.client.get(
        '/products/search',
        queryParameters: {
          'q': searchQuery,
          'page': page,
          'limit': limit,
          'offset': offset,
        },
      );
      final products = (response.data['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList();
      return ProductResult(
          products: products, total: response.data['total'] ?? 0);
    } catch (e) {
      rethrow;
    }
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await _apiClient.client.get(
        '/products/featured',
        queryParameters: {'limit': limit},
      );
      final products = (response.data['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList();
      return products;
    } catch (e) {
      rethrow;
    }
  }

  /// Get products filtered by role
  Future<List<Product>> getProductsByRole({
    required User user,
    required UserRole role,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Get all products
      final allProductsResult = await getAllProducts(page: page, limit: limit);

      // Filter based on role visibility
      return allProductsResult.products.where((product) {
        return _isProductVisibleToRole(product, role);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search products with role filtering
  Future<List<Product>> searchProductsByRole({
    required User user,
    required UserRole role,
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Search all products
      final result = await searchProducts(
        searchQuery: query,
        page: page,
        limit: limit,
      );

      // Filter by role
      return result.products.where((product) {
        return _isProductVisibleToRole(product, role);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if product is visible to a role
  bool _isProductVisibleToRole(Product product, UserRole role) {
    // Admins see everything
    if (role.isAdmin) return true;

    // Check visibility flags
    if (role.isWholesale) {
      return product.visibleToWholesale;
    }

    if (role.isInstitutional) {
      return product.visibleToInstitutions;
    }

    // Consumers and members see retail
    return product.visibleToRetail;
  }
}

/// Result wrapper for product queries
class ProductResult {
  final List<Product> products;
  final int total;

  ProductResult({
    required this.products,
    required this.total,
  });
}
