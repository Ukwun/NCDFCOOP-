import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/products_service.dart';
import 'package:coop_commerce/core/services/user_data_service.dart';
import 'package:coop_commerce/models/real_product_model.dart';
import 'package:coop_commerce/providers/auth_provider.dart';

// ============================================================================
// SERVICE PROVIDERS
// ============================================================================

/// Products service provider (singleton)
final productsServiceProvider = Provider<ProductsService>((ref) {
  return ProductsService();
});

/// User data service provider (singleton)
final userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService();
});

// ============================================================================
// PRODUCTS PROVIDERS
// ============================================================================

/// Get all products from Firestore
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.watch(productsServiceProvider);
  return service.getAllProducts();
});

/// Get products by category from Firestore
final productsByCategoryProvider = FutureProvider.family<List<Product>, String>(
  (ref, category) async {
    final service = ref.watch(productsServiceProvider);
    return service.getProductsByCategory(category);
  },
);

/// Search products from Firestore
final searchProductsProvider = FutureProvider.family<List<Product>, String>(
  (ref, query) async {
    final service = ref.watch(productsServiceProvider);
    return service.searchProducts(query);
  },
);

/// Get specific product by ID
final productDetailProvider = FutureProvider.family<Product?, String>(
  (ref, productId) async {
    final service = ref.watch(productsServiceProvider);
    return service.getProductById(productId);
  },
);

/// Get featured products
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.watch(productsServiceProvider);
  return service.getFeaturedProducts();
});

/// Get sale/flash sale products
final saleProductsProvider = FutureProvider<List<Product>>((ref) async {
  final service = ref.watch(productsServiceProvider);
  return service.getSaleProducts();
});

/// Stream all products in real-time
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final service = ref.watch(productsServiceProvider);
  return service.streamProducts();
});

/// Stream products by category in real-time
final productsCategoryStreamProvider =
    StreamProvider.family<List<Product>, String>(
  (ref, category) {
    final service = ref.watch(productsServiceProvider);
    return service.streamProductsByCategory(category);
  },
);

// ============================================================================
// USER DATA PROVIDERS
// ============================================================================

/// Get current user's real data from Firestore
final currentUserDataProvider = FutureProvider<RealUserData?>((ref) async {
  final service = ref.watch(userDataServiceProvider);
  return service.getCurrentUserData();
});

/// Get specific user's data by ID
final userDataByIdProvider = FutureProvider.family<RealUserData?, String>(
  (ref, userId) async {
    final service = ref.watch(userDataServiceProvider);
    return service.getUserById(userId);
  },
);

/// Stream current user's data in real-time
final currentUserDataStreamProvider = StreamProvider<RealUserData?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(null);

  final service = ref.watch(userDataServiceProvider);
  return service.streamUserData(currentUser.id);
});

/// Get user's favorite categories
final userFavoriteCategoriesProvider =
    FutureProvider.family<List<String>, String>(
  (ref, userId) async {
    final service = ref.watch(userDataServiceProvider);
    return service.getFavoriteCategories(userId);
  },
);

/// Get user's purchase history
final userPurchaseHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final service = ref.watch(userDataServiceProvider);
    return service.getPurchaseHistory(userId);
  },
);

/// Get user's recent activity
final userRecentActivityProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final service = ref.watch(userDataServiceProvider);
    return service.getRecentActivity(userId);
  },
);

// ============================================================================
// USER ACTIVITY ACTIONS
// ============================================================================

/// Notifier for user data operations
class UserDataNotifier extends Notifier<void> {
  late UserDataService _service;

  @override
  void build() {
    _service = ref.watch(userDataServiceProvider);
  }

  Future<void> trackProductView({
    required String userId,
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) =>
      _service.trackActivity(
        userId: userId,
        activityType: 'view',
        productId: productId,
        productName: productName,
        category: category,
        price: price,
      );

  Future<void> trackSearch({
    required String userId,
    required String query,
    required int resultsCount,
  }) =>
      _service.trackActivity(
        userId: userId,
        activityType: 'search',
        metadata: {'query': query, 'resultsCount': resultsCount},
      );

  Future<void> trackAddToCart({
    required String userId,
    required String productId,
    required String productName,
    required String category,
    required double price,
    required int quantity,
  }) =>
      _service.trackActivity(
        userId: userId,
        activityType: 'cart',
        productId: productId,
        productName: productName,
        category: category,
        price: price,
        metadata: {'quantity': quantity},
      );

  Future<void> recordPurchase({
    required String userId,
    required double amount,
    required List<String> productIds,
  }) =>
      _service.recordPurchase(
        userId,
        amount: amount,
        productIds: productIds,
      );
}

/// Notifier for user data operations
final userDataNotifierProvider = NotifierProvider<UserDataNotifier, void>(
  () => UserDataNotifier(),
);
