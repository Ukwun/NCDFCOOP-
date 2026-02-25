import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../utils/app_constants.dart';
import '../utils/logger.dart';
import 'base_firebase_service.dart';

class ProductService extends BaseFirebaseService {
  static final ProductService _instance = ProductService._internal();

  factory ProductService() {
    return _instance;
  }

  ProductService._internal();

  Future<Product?> getProduct(String productId) async {
    try {
      AppLogger.logMethodCall('getProduct', params: {'productId': productId});
      final product = await getDocument(
        AppConstants.productsCollection,
        productId,
        (doc) => Product.fromFirestore(doc),
      );
      AppLogger.logMethodReturn('getProduct', result: product);
      return product;
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to get product');
      return null;
    }
  }

  Future<List<Product>> getProducts({
    int limit = AppConstants.defaultPageSize,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? searchTerm,
  }) async {
    try {
      AppLogger.logMethodCall('getProducts', params: {
        'limit': limit,
        'category': category,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'searchTerm': searchTerm,
      });

      final products = await getCollection(
        AppConstants.productsCollection,
        (doc) => Product.fromFirestore(doc),
        queryBuilder: (query) {
          if (category != null) {
            query = query.where('category', isEqualTo: category);
          }
          if (minPrice != null) {
            query = query.where('price', isGreaterThanOrEqualTo: minPrice);
          }
          if (maxPrice != null) {
            query = query.where('price', isLessThanOrEqualTo: maxPrice);
          }
          return query.limit(limit);
        },
      );

      // Filter by search term if provided
      if (searchTerm != null && searchTerm.isNotEmpty) {
        return products
            .where((p) =>
                p.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                p.description.toLowerCase().contains(searchTerm.toLowerCase()))
            .toList();
      }

      AppLogger.logMethodReturn('getProducts',
          result: 'Found ${products.length} products');
      return products;
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to get products');
      return [];
    }
  }

  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      AppLogger.logMethodCall('getFeaturedProducts', params: {'limit': limit});
      final products = await getCollection(
        AppConstants.productsCollection,
        (doc) => Product.fromFirestore(doc),
        queryBuilder: (query) =>
            query.where('isFeatured', isEqualTo: true).limit(limit),
      );
      AppLogger.logMethodReturn('getFeaturedProducts',
          result: 'Found ${products.length} products');
      return products;
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to get featured products');
      return [];
    }
  }

  Future<List<Product>> getProductsByCategory(String category,
      {int limit = 20}) async {
    try {
      AppLogger.logMethodCall('getProductsByCategory', params: {
        'category': category,
        'limit': limit,
      });
      final products = await getCollection(
        AppConstants.productsCollection,
        (doc) => Product.fromFirestore(doc),
        queryBuilder: (query) =>
            query.where('category', isEqualTo: category).limit(limit),
      );
      AppLogger.logMethodReturn('getProductsByCategory',
          result: 'Found ${products.length} products');
      return products;
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace,
          message: 'Failed to get products by category');
      return [];
    }
  }

  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    try {
      AppLogger.logMethodCall('searchProducts', params: {
        'query': query,
        'limit': limit,
      });
      final products = await getCollection(
        AppConstants.productsCollection,
        (doc) => Product.fromFirestore(doc),
        queryBuilder: (q) => q.limit(limit),
      );

      final filtered = products
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.description.toLowerCase().contains(query.toLowerCase()) ||
              p.category.toLowerCase().contains(query.toLowerCase()))
          .toList();

      AppLogger.logMethodReturn('searchProducts',
          result: 'Found ${filtered.length} results');
      return filtered;
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to search products');
      return [];
    }
  }

  Stream<List<Product>> watchProducts(
      {int limit = AppConstants.defaultPageSize}) {
    try {
      AppLogger.debug('Watching products');
      return watchCollection(
        AppConstants.productsCollection,
        (doc) => Product.fromFirestore(doc),
        queryBuilder: (query) => query.limit(limit),
      );
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to watch products');
      rethrow;
    }
  }

  Stream<Product?> watchProduct(String productId) {
    try {
      AppLogger.debug('Watching product: $productId');
      return watchDocument(
        AppConstants.productsCollection,
        productId,
        (doc) => Product.fromFirestore(doc),
      );
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to watch product');
      rethrow;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      AppLogger.logMethodCall('addProduct', params: {'productId': product.id});
      final data = {
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'costPrice': product.costPrice,
        'category': product.category,
        'images': product.images,
        'imageUrl': product.imageUrl,
        'stock': product.stock,
        'rating': product.rating,
        'reviews': product.reviews,
        'isFeatured': product.isFeatured,
        'createdAt': Timestamp.fromDate(product.createdAt),
        'updatedAt': Timestamp.fromDate(product.updatedAt),
      };
      await addDocument(AppConstants.productsCollection, data,
          documentId: product.id);
      AppLogger.logMethodReturn('addProduct');
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to add product');
      rethrow;
    }
  }

  Future<void> updateProduct(
      String productId, Map<String, dynamic> data) async {
    try {
      AppLogger.logMethodCall('updateProduct',
          params: {'productId': productId, 'data': data});
      await updateDocument(AppConstants.productsCollection, productId, data);
      AppLogger.logMethodReturn('updateProduct');
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to update product');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      AppLogger.logMethodCall('deleteProduct',
          params: {'productId': productId});
      await deleteDocument(AppConstants.productsCollection, productId);
      AppLogger.logMethodReturn('deleteProduct');
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to delete product');
      rethrow;
    }
  }

  Future<int> getProductCount({String? category}) async {
    try {
      AppLogger.logMethodCall('getProductCount',
          params: {'category': category});
      final count = await getCollectionCount(
        AppConstants.productsCollection,
        queryBuilder: category != null
            ? (query) => query.where('category', isEqualTo: category)
            : null,
      );
      AppLogger.logMethodReturn('getProductCount', result: count);
      return count;
    } catch (e, stackTrace) {
      AppLogger.logException(e,
          stackTrace: stackTrace, message: 'Failed to get product count');
      return 0;
    }
  }
}
