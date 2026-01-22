import 'api_client.dart';

/// Category model for API
class Category {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      productCount: json['productCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'productCount': productCount,
  };
}

/// Category service for API calls
class CategoryService {
  final ApiClient _apiClient;

  CategoryService(this._apiClient);

  /// Fetch all categories
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _apiClient.client.get('/categories');
      final categories = (response.data['categories'] as List)
          .map((c) => Category.fromJson(c))
          .toList();
      return categories;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch category by ID
  Future<Category> getCategoryById(String categoryId) async {
    try {
      final response = await _apiClient.client.get('/categories/$categoryId');
      return Category.fromJson(response.data['category']);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch featured categories
  Future<List<Category>> getFeaturedCategories({int limit = 5}) async {
    try {
      final response = await _apiClient.client.get(
        '/categories/featured',
        queryParameters: {'limit': limit},
      );
      final categories = (response.data['categories'] as List)
          .map((c) => Category.fromJson(c))
          .toList();
      return categories;
    } catch (e) {
      rethrow;
    }
  }
}
