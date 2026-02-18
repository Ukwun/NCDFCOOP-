import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/models/product.dart';
import 'package:coop_commerce/core/audit/audit_service.dart';

/// Mock products for development and fallback
List<Product> _getMockProducts() {
  return [
    Product(
      id: 'mock_001',
      name: 'Premium Rice 50kg',
      retailPrice: 22000.0,
      wholesalePrice: 19800.0,
      contractPrice: 18000.0,
      description:
          'High quality long grain rice - perfect for bulk orders. Premium quality sourced from trusted suppliers.',
      imageUrl: 'assets/images/ijebugarri1.png',
      categoryId: 'grains',
      stock: 100,
      minimumOrderQuantity: 1,
      rating: 4.5,
    ),
    Product(
      id: 'mock_002',
      name: 'Palm Oil 25L',
      retailPrice: 45000.0,
      wholesalePrice: 40500.0,
      contractPrice: 40000.0,
      description:
          'Premium edible palm oil for cooking. Pure, unrefined, and high quality.',
      imageUrl: 'assets/images/Groundnut oil1.png',
      categoryId: 'oils',
      stock: 50,
      minimumOrderQuantity: 1,
      rating: 4.3,
    ),
    Product(
      id: 'mock_003',
      name: 'Black Beans 20kg',
      retailPrice: 15000.0,
      wholesalePrice: 13500.0,
      contractPrice: 12000.0,
      description:
          'Quality black beans legumes - wholesale pricing available. Bulk orders welcome.',
      imageUrl: 'assets/images/Honey beans1.png',
      categoryId: 'legumes',
      stock: 75,
      minimumOrderQuantity: 1,
      rating: 4.6,
    ),
    Product(
      id: 'mock_004',
      name: 'White Sugar 25kg',
      retailPrice: 28000.0,
      wholesalePrice: 25200.0,
      contractPrice: 24000.0,
      description:
          'Pure white granulated sugar. High quality, verified purity.',
      imageUrl: 'assets/images/All inclusive pack.png',
      categoryId: 'sweeteners',
      stock: 60,
      minimumOrderQuantity: 1,
      rating: 4.4,
    ),
    Product(
      id: 'mock_005',
      name: 'Garlic Powder 500g',
      retailPrice: 3500.0,
      wholesalePrice: 3150.0,
      contractPrice: 3000.0,
      description:
          'Premium garlic powder. Perfect for seasoning. Bulk discounts available.',
      imageUrl: 'assets/images/6in1 spices.png',
      categoryId: 'spices',
      stock: 200,
      minimumOrderQuantity: 1,
      rating: 4.2,
    ),
    Product(
      id: 'mock_006',
      name: 'Tomato Paste 1kg',
      retailPrice: 5000.0,
      wholesalePrice: 4500.0,
      contractPrice: 4200.0,
      description: 'Fresh tomato paste. High quality, concentrated flavor.',
      imageUrl: 'assets/images/Tomatoes1.png',
      categoryId: 'condiments',
      stock: 120,
      minimumOrderQuantity: 1,
      rating: 4.1,
    ),
    Product(
      id: 'mock_007',
      name: 'Fresh Eggs - One Crate',
      retailPrice: 8000.0,
      wholesalePrice: 7200.0,
      contractPrice: 6800.0,
      description: 'Fresh farm eggs. One full crate of quality eggs.',
      imageUrl: 'assets/images/One crate eggs1.png',
      categoryId: 'proteins',
      stock: 150,
      minimumOrderQuantity: 1,
      rating: 4.0,
    ),
    Product(
      id: 'mock_008',
      name: 'Bulk Spices Hamper',
      retailPrice: 15000.0,
      wholesalePrice: 13500.0,
      contractPrice: 12000.0,
      description:
          'All-purpose spice collection. Perfect assortment for cooking and seasoning.',
      imageUrl: 'assets/images/Spices hamper1.png',
      categoryId: 'spices',
      stock: 180,
      minimumOrderQuantity: 1,
      rating: 4.3,
    ),
  ];
}

/// Product search and filtering options
class ProductSearchOptions {
  final String? searchQuery;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final bool? onlyAvailable;
  final bool? memberOnly;
  final int? limit;
  final int? offset;
  final String? sortBy; // 'name', 'price', 'popularity', 'rating', 'newest'

  ProductSearchOptions({
    this.searchQuery,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.onlyAvailable = true,
    this.memberOnly,
    this.limit = 20,
    this.offset = 0,
    this.sortBy = 'popularity',
  });
}

/// Product search result with pagination
class ProductSearchResult {
  final List<Product> products;
  final int totalCount;
  final int limit;
  final int offset;
  final bool hasMore;

  ProductSearchResult({
    required this.products,
    required this.totalCount,
    required this.limit,
    required this.offset,
  }) : hasMore = (offset + limit) < totalCount;

  /// Check if there are more results
  bool get canLoadMore => hasMore;

  /// Get next offset for pagination
  int get nextOffset => offset + limit;
}

/// Product Service for browsing, searching, and filtering products
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _productsCollection = 'products';
  static const String _reviewsCollection = 'reviews';

  ProductService(AuditService? _auditLogService) {
    // NOTE: auditLogService parameter reserved for future feature enhancements
  }

  /// Get all products with pagination
  Future<ProductSearchResult> getAllProducts({
    int limit = 20,
    int offset = 0,
    String sortBy = 'popularity',
  }) async {
    try {
      Query query = _firestore.collection(_productsCollection);

      // Apply filters
      query = query.where('is_active', isEqualTo: true);

      // Apply sorting
      if (sortBy == 'name') {
        query = query.orderBy('name');
      } else if (sortBy == 'price') {
        query = query.orderBy('price');
      } else if (sortBy == 'rating') {
        query = query.orderBy('rating', descending: true);
      } else if (sortBy == 'newest') {
        query = query.orderBy('created_at', descending: true);
      } else {
        // Default: popularity (by popularity_score or review_count)
        query = query.orderBy('popularity_score', descending: true);
      }

      // Get total count
      final countSnapshot = await query.count().get();
      final totalCount = countSnapshot.count ?? 0;

      // Get results (pagination via offset not supported in Firestore)
      // For pagination, use startAfter with a document cursor or implement server-side pagination
      final snapshot = await query.limit(limit).get();

      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(
              (doc.data() as Map<String, dynamic>?) ?? {}))
          .toList();

      return ProductSearchResult(
        products: products,
        totalCount: totalCount,
        limit: limit,
        offset: 0, // Offset not supported in Firestore queries
      );
    } catch (e) {
      // Fallback to mock products when Firestore is unavailable
      final mockProducts = _getMockProducts();
      return ProductSearchResult(
        products: mockProducts.skip(offset).take(limit).toList(),
        totalCount: mockProducts.length,
        limit: limit,
        offset: offset,
      );
    }
  }

  /// Search products by query
  Future<ProductSearchResult> searchProducts({
    required String searchQuery,
    int limit = 20,
    int offset = 0,
    String? userId,
    String? userRole,
  }) async {
    try {
      // Audit logging temporarily disabled - uses incorrect service
      // TODO: Implement proper audit logging with correct AuditLog service

      // Search across product name, description, and SKU
      final searchLower = searchQuery.toLowerCase();

      Query query = _firestore.collection(_productsCollection);
      query = query.where('is_active', isEqualTo: true);

      // Firestore doesn't support full-text search natively
      // This requires a client-side filter or Algolia/Meilisearch integration
      // For now, filter by name prefix
      query = query
          .where('name_lower', isGreaterThanOrEqualTo: searchLower)
          .where('name_lower', isLessThan: '${searchLower}z')
          .orderBy('name_lower');

      // Get total count
      final countSnapshot = await query.count().get();
      final totalCount = countSnapshot.count ?? 0;

      // Get paginated results (skip offset as Firestore doesn't support it)
      final snapshot = await query.limit(limit).get();

      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(
              (doc.data() as Map<String, dynamic>?) ?? {}))
          .toList();

      return ProductSearchResult(
        products: products,
        totalCount: totalCount,
        limit: limit,
        offset: 0,
      );
    } catch (e) {
      // Fallback to mock products with client-side search filtering
      final mockProducts = _getMockProducts();
      final searchLower = searchQuery.toLowerCase();

      final filteredProducts = mockProducts
          .where((p) =>
              p.name.toLowerCase().contains(searchLower) ||
              p.description.toLowerCase().contains(searchLower))
          .skip(offset)
          .take(limit)
          .toList();

      return ProductSearchResult(
        products: filteredProducts,
        totalCount: mockProducts
            .where((p) =>
                p.name.toLowerCase().contains(searchLower) ||
                p.description.toLowerCase().contains(searchLower))
            .length,
        limit: limit,
        offset: offset,
      );
    }
  }

  /// Get products by category
  Future<ProductSearchResult> getProductsByCategory({
    required String category,
    int limit = 20,
    int offset = 0,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'popularity',
  }) async {
    try {
      Query query = _firestore.collection(_productsCollection);

      // Filter by category and active status
      query = query
          .where('is_active', isEqualTo: true)
          .where('category', isEqualTo: category);

      // Filter by price if specified
      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      // Apply sorting
      if (sortBy == 'name') {
        query = query.orderBy('name');
      } else if (sortBy == 'price') {
        query = query.orderBy('price');
      } else if (sortBy == 'rating') {
        query = query.orderBy('rating', descending: true);
      } else if (sortBy == 'newest') {
        query = query.orderBy('created_at', descending: true);
      } else {
        query = query.orderBy('popularity_score', descending: true);
      }

      // Get total count
      final countSnapshot = await query.count().get();
      final totalCount = countSnapshot.count ?? 0;

      // Get paginated results (skip offset as Firestore doesn't support it)
      final snapshot = await query.limit(limit).get();

      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(
              (doc.data() as Map<String, dynamic>?) ?? {}))
          .toList();

      return ProductSearchResult(
        products: products,
        totalCount: totalCount,
        limit: limit,
        offset: 0,
      );
    } catch (e) {
      // Fallback to mock products filtered by category
      final mockProducts = _getMockProducts();
      final filteredProducts = mockProducts
          .where((p) => p.categoryId == category)
          .skip(offset)
          .take(limit)
          .toList();

      return ProductSearchResult(
        products: filteredProducts,
        totalCount: mockProducts.where((p) => p.categoryId == category).length,
        limit: limit,
        offset: offset,
      );
    }
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('is_active', isEqualTo: true)
          .where('featured', isEqualTo: true)
          .orderBy('featured_order')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      // Fallback to mock products
      return _getMockProducts().take(limit).toList();
    }
  }

  /// Get member-exclusive products
  Future<List<Product>> getMemberExclusiveProducts({
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('is_active', isEqualTo: true)
          .where('member_exclusive', isEqualTo: true)
          .orderBy('popularity_score', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      // Error getting member-exclusive products - fallback to empty list
      // In a real app, this would show a default set of exclusive products
      return [];
    }
  }

  /// Get related/recommended products
  Future<List<Product>> getRelatedProducts({
    required String productId,
    required String category,
    int limit = 6,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('is_active', isEqualTo: true)
          .where('category', isEqualTo: category)
          .where('id', isNotEqualTo: productId)
          .orderBy('id')
          .orderBy('popularity_score', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      // Fallback to mock products from same category
      final mockProducts = _getMockProducts();
      return mockProducts
          .where((p) => p.categoryId == category && p.id != productId)
          .take(limit)
          .toList();
    }
  }

  /// Get product by ID
  Future<Product> getProductById({
    required String productId,
    String? userId,
    String? userRole,
  }) async {
    try {
      // Audit logging temporarily disabled - uses incorrect service
      // TODO: Implement proper audit logging with correct AuditLog service

      final doc =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!doc.exists) {
        throw Exception('Product not found');
      }

      return Product.fromFirestore(doc.data() ?? {});
    } catch (e) {
      // Fallback to mock products
      final mockProducts = _getMockProducts();
      final product = mockProducts.firstWhere(
        (p) => p.id == productId,
        orElse: () => mockProducts.first,
      );
      return product;
    }
  }

  /// Get product categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('is_active', isEqualTo: true)
          .get();

      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }
      return categories.toList()..sort();
    } catch (e) {
      // Fallback to mock products categories
      final mockProducts = _getMockProducts();
      final categories = mockProducts.map((p) => p.categoryId).toSet();
      return categories.toList()..sort();
    }
  }

  /// Get price range for category
  Future<({double minPrice, double maxPrice})> getPriceRange({
    required String category,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('is_active', isEqualTo: true)
          .where('category', isEqualTo: category)
          .get();

      if (snapshot.docs.isEmpty) {
        return (minPrice: 0.0, maxPrice: 100000.0);
      }

      double minPrice = double.infinity;
      double maxPrice = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final price = (data['retailPrice'] as num?)?.toDouble() ??
            (data['price'] as num?)?.toDouble() ??
            0;
        minPrice = minPrice > price ? price : minPrice;
        maxPrice = maxPrice < price ? price : maxPrice;
      }

      return (minPrice: minPrice, maxPrice: maxPrice);
    } catch (e) {
      // Fallback to mock products price range for category
      final mockProducts = _getMockProducts();
      final filtered =
          mockProducts.where((p) => p.categoryId == category).toList();

      if (filtered.isEmpty) {
        return (minPrice: 0.0, maxPrice: 100000.0);
      }

      double minPrice = filtered.first.retailPrice.toDouble();
      double maxPrice = filtered.first.retailPrice.toDouble();

      for (var product in filtered) {
        minPrice = minPrice > product.retailPrice.toDouble()
            ? product.retailPrice.toDouble()
            : minPrice;
        maxPrice = maxPrice < product.retailPrice.toDouble()
            ? product.retailPrice.toDouble()
            : maxPrice;
      }

      return (minPrice: minPrice, maxPrice: maxPrice);
    }
  }

  /// Get product reviews
  Future<List<ProductReview>> getProductReviews({
    required String productId,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .collection(_reviewsCollection)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductReview.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Fallback: return empty list (reviews not available offline)
      return [];
    }
  }

  /// Add product review
  Future<void> addProductReview({
    required String productId,
    required String userId,
    required int rating,
    required String title,
    required String comment,
  }) async {
    try {
      final review = ProductReview(
        id: _firestore.collection(_productsCollection).doc().id,
        productId: productId,
        userId: userId,
        rating: rating,
        title: title,
        comment: comment,
        helpfulCount: 0,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .collection(_reviewsCollection)
          .doc(review.id)
          .set(review.toMap());

      // Update product rating
      await _updateProductRating(productId);
    } catch (e) {
      // Silently fail if offline - review couldn't be saved
      // In a real app, this would be queued for later sync
      return;
    }
  }

  /// Update product rating based on reviews
  Future<void> _updateProductRating(String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .collection(_reviewsCollection)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      double totalRating = 0;
      for (var doc in snapshot.docs) {
        final rating = doc['rating'] as int?;
        if (rating != null) {
          totalRating += rating;
        }
      }

      final averageRating = totalRating / snapshot.docs.length;
      final reviewCount = snapshot.docs.length;

      await _firestore.collection(_productsCollection).doc(productId).update({
        'rating': averageRating,
        'review_count': reviewCount,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail if offline - rating couldn't be updated
      // In a real app, this would be queued for later sync
      return;
    }
  }

  /// Check product availability
  Future<bool> isProductAvailable(String productId) async {
    try {
      final doc =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!doc.exists) {
        return false;
      }

      final isActive = doc['is_active'] as bool? ?? false;
      final stock = doc['stock'] as int? ?? 0;

      return isActive && stock > 0;
    } catch (e) {
      // Error checking availability
      return false;
    }
  }

  /// Get stock for product
  Future<int> getProductStock(String productId) async {
    try {
      final doc =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!doc.exists) {
        return 0;
      }

      return doc['stock'] as int? ?? 0;
    } catch (e) {
      // Error getting stock
      return 0;
    }
  }
}

/// Product review model
class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final int rating; // 1-5
  final String title;
  final String comment;
  final int helpfulCount;
  final DateTime createdAt;

  ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    required this.title,
    required this.comment,
    required this.helpfulCount,
    required this.createdAt,
  });

  factory ProductReview.fromMap(Map<String, dynamic> map) {
    return ProductReview(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? '',
      userId: map['user_id'] ?? '',
      rating: map['rating'] ?? 0,
      title: map['title'] ?? '',
      comment: map['comment'] ?? '',
      helpfulCount: map['helpful_count'] ?? 0,
      createdAt: DateTime.parse(
          map['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'user_id': userId,
        'rating': rating,
        'title': title,
        'comment': comment,
        'helpful_count': helpfulCount,
        'created_at': createdAt.toIso8601String(),
      };
}
