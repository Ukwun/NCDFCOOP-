import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/models/product.dart';
import 'package:coop_commerce/core/audit/audit_service.dart';
import 'package:coop_commerce/core/auth/role.dart' as auth_role;

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
  final AuditService _auditLogService;

  static const String _productsCollection = 'products';
  static const String _reviewsCollection = 'reviews';

  ProductService(this._auditLogService);

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

      // Get paginated results
      final snapshot = await query.limit(limit).offset(offset).get();

      final products =
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      return ProductSearchResult(
        products: products,
        totalCount: totalCount,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      // Error getting products
      rethrow;
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
      // Log search action if user provided
      if (userId != null && userRole != null) {
        await _auditLogService.logAction(
          userId,
          userRole,
          AuditAction.dataAccessed,
          'product',
          details: {'search_query': searchQuery},
        );
      }

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

      // Get paginated results
      final snapshot = await query.limit(limit).offset(offset).get();

      final products =
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      return ProductSearchResult(
        products: products,
        totalCount: totalCount,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      // Error searching products
      rethrow;
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

      // Get paginated results
      final snapshot = await query.limit(limit).offset(offset).get();

      final products =
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      return ProductSearchResult(
        products: products,
        totalCount: totalCount,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      // Error getting products by category
      rethrow;
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

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      // Error getting featured products
      rethrow;
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

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      // Error getting member-exclusive products
      rethrow;
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

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      // Error getting related products
      rethrow;
    }
  }

  /// Get product by ID
  Future<Product> getProductById({
    required String productId,
    String? userId,
    String? userRole,
  }) async {
    try {
      // Log product view if user provided
      if (userId != null && userRole != null) {
        await _auditLogService.logAction(
          userId,
          userRole,
          AuditAction.dataAccessed,
          'product',
          resourceId: productId,
          details: {'action': 'viewed_detail'},
        );
      }

      final doc =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!doc.exists) {
        throw Exception('Product not found');
      }

      return Product.fromFirestore(doc);
    } catch (e) {
      // Error getting product by ID
      rethrow;
    }
  }

  /// Get product categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('is_active', isEqualTo: true)
          .select('category')
          .get();

      final categories = <String>{};
      for (var doc in snapshot.docs) {
        final category = doc['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      // Error getting categories
      rethrow;
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
          .select('price')
          .get();

      if (snapshot.docs.isEmpty) {
        return (minPrice: 0, maxPrice: 100000);
      }

      double minPrice = double.infinity;
      double maxPrice = 0;

      for (var doc in snapshot.docs) {
        final price = (doc['price'] as num?)?.toDouble() ?? 0;
        minPrice = minPrice > price ? price : minPrice;
        maxPrice = maxPrice < price ? price : maxPrice;
      }

      return (minPrice: minPrice, maxPrice: maxPrice);
    } catch (e) {
      // Error getting price range
      rethrow;
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
          .offset(offset)
          .get();

      return snapshot.docs
          .map((doc) => ProductReview.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Error getting reviews
      rethrow;
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
      // Error adding review
      rethrow;
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
      // Error updating product rating
      rethrow;
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
