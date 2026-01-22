import 'api_client.dart';

/// Product model for API
class Product {
  final String id;
  final String name;
  final String description;
  final double memberPrice;
  final double marketPrice;
  final String categoryId;
  final String? imageUrl;
  final int stock;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.memberPrice,
    required this.marketPrice,
    required this.categoryId,
    this.imageUrl,
    required this.stock,
    this.rating = 0.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      memberPrice: (json['memberPrice'] ?? 0).toDouble(),
      marketPrice: (json['marketPrice'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? '',
      imageUrl: json['imageUrl'],
      stock: json['stock'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'memberPrice': memberPrice,
    'marketPrice': marketPrice,
    'categoryId': categoryId,
    'imageUrl': imageUrl,
    'stock': stock,
    'rating': rating,
  };
}

/// Product service for API calls
class ProductService {
  final ApiClient _apiClient;

  ProductService(this._apiClient);

  /// Fetch all products
  Future<List<Product>> getAllProducts({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.client.get(
        '/products',
        queryParameters: {'page': page, 'limit': limit},
      );
      final products = (response.data['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList();
      return products;
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
  Future<List<Product>> getProductsByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.client.get(
        '/categories/$categoryId/products',
        queryParameters: {'page': page, 'limit': limit},
      );
      final products = (response.data['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList();
      return products;
    } catch (e) {
      rethrow;
    }
  }

  /// Search products
  Future<List<Product>> searchProducts(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.client.get(
        '/products/search',
        queryParameters: {'q': query, 'page': page, 'limit': limit},
      );
      final products = (response.data['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList();
      return products;
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
}
