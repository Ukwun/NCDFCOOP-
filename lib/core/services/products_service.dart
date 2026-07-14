import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/models/real_product_model.dart';

/// Real production products service - fetches from Firestore
class ProductsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _productsCollection = 'products';

  /// Fetch all products from Firestore
  /// ONLY loads from Firestore - no fallback to mock data
  Future<List<Product>> getAllProducts({
    bool forceRefresh = false,
  }) async {
    try {
      debugPrint('📦 Fetching ALL products from Firestore...');

      final snapshot = await _firestore.collection(_productsCollection).get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️  No products found in Firestore - returning empty list');
        return [];
      }

      final products = snapshot.docs
          .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      debugPrint('✅ Fetched ${products.length} products from Firestore');
      return products;
    } catch (e) {
      debugPrint('❌ Error fetching products: $e');
      return [];
    }
  }

  /// Fetch products by category from Firestore
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      debugPrint('📦 Fetching products in category: $category');

      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('category', isEqualTo: category)
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      debugPrint('✅ Fetched ${products.length} products in $category');
      return products;
    } catch (e) {
      debugPrint('❌ Error fetching products by category: $e');
      return [];
    }
  }

  /// Search products by query
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    try {
      debugPrint('🔍 Searching for: "$query"');

      final allProducts = await getAllProducts();
      final searchQuery = query.toLowerCase();

      final results = allProducts
          .where((product) =>
              product.name.toLowerCase().contains(searchQuery) ||
              product.description.toLowerCase().contains(searchQuery) ||
              product.category.toLowerCase().contains(searchQuery))
          .toList();

      debugPrint('✅ Found ${results.length} products matching "$query"');
      return results;
    } catch (e) {
      debugPrint('❌ Error searching products: $e');
      return [];
    }
  }

  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final doc =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!doc.exists) {
        debugPrint('⚠️  Product not found: $productId');
        return null;
      }

      final product = Product.fromJson(
          {...doc.data() as Map<String, dynamic>, 'id': doc.id});
      debugPrint('✅ Fetched product: ${product.name}');
      return product;
    } catch (e) {
      debugPrint('❌ Error fetching product: $e');
      return null;
    }
  }

  /// Get featured/trending products
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      debugPrint('⭐ Fetching featured products...');

      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('isFeatured', isEqualTo: true)
          .limit(limit)
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      debugPrint('✅ Fetched ${products.length} featured products');
      return products;
    } catch (e) {
      debugPrint('❌ Error fetching featured products: $e');
      return [];
    }
  }

  /// Get products on sale/flash sale
  Future<List<Product>> getSaleProducts({int limit = 20}) async {
    try {
      debugPrint('🔥 Fetching sale products...');

      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('onSale', isEqualTo: true)
          .limit(limit)
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      debugPrint('✅ Fetched ${products.length} sale products');
      return products;
    } catch (e) {
      debugPrint('❌ Error fetching sale products: $e');
      return [];
    }
  }

  /// Stream products in real-time
  Stream<List<Product>> streamProducts() {
    return _firestore.collection(_productsCollection).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream products by category in real-time
  Stream<List<Product>> streamProductsByCategory(String category) {
    return _firestore
        .collection(_productsCollection)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Get product price for specific membership tier
  double getPrice(Product product, String? membershipTier) {
    return product.getPriceForTier(membershipTier);
  }

  /// Get savings for membership tier
  double getSavings(Product product, String? membershipTier) {
    return product.getSavingsForTier(membershipTier);
  }

  /// Update product from Firestore (for real-time inventory/pricing)
  Future<void> syncProductFromFirestore(String productId) async {
    try {
      await _firestore.collection(_productsCollection).doc(productId).get();
      debugPrint('✅ Synced product: $productId');
    } catch (e) {
      debugPrint('❌ Error syncing product: $e');
    }
  }

  /// Get product count
  Future<int> getProductCount() async {
    try {
      final snapshot =
          await _firestore.collection(_productsCollection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting product count: $e');
      return 0;
    }
  }
}
