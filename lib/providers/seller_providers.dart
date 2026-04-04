import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/seller_models.dart';
import '../../core/services/seller_service.dart';

// Services
final sellerServiceProvider = Provider((ref) {
  return SellerService();
});

// Profile Providers
final sellerProfileByUserIdProvider =
    FutureProvider.family<SellerProfile?, String>((ref, userId) async {
  final service = ref.watch(sellerServiceProvider);
  return service.getSellerProfileByUserId(userId);
});

final sellerProfileByIdProvider =
    FutureProvider.family<SellerProfile?, String>((ref, sellerId) async {
  final service = ref.watch(sellerServiceProvider);
  return service.getSellerProfileById(sellerId);
});

// Product Providers
final sellerProductsProvider =
    FutureProvider.family<List<SellerProduct>, String>((ref, sellerId) async {
  final service = ref.watch(sellerServiceProvider);
  return service.getSellerProducts(sellerId);
});

final sellerProductByIdProvider =
    FutureProvider.family<SellerProduct?, String>((ref, productId) async {
  final service = ref.watch(sellerServiceProvider);
  return service.getProductById(productId);
});

// Pending approvals (admin)
final pendingModerationsProvider =
    FutureProvider<List<ProductModerationRequest>>((ref) async {
  final service = ref.watch(sellerServiceProvider);
  return service.getPendingModerations();
});

// Mutations
final createSellerProfileProvider =
    FutureProvider.family<SellerProfile, SellerProfile>((ref, profile) async {
  final service = ref.watch(sellerServiceProvider);
  return service.createSellerProfile(profile);
});

final addSellerProductProvider =
    FutureProvider.family<SellerProduct, SellerProduct>((ref, product) async {
  final service = ref.watch(sellerServiceProvider);
  return service.addProduct(product);
});

final approveSellerProductProvider =
    FutureProvider.family<void, String>((ref, productId) async {
  final service = ref.watch(sellerServiceProvider);
  return service.approveProduct(productId);
});

final rejectSellerProductProvider =
    FutureProvider.family<void, (String, String)>((ref, params) async {
  final service = ref.watch(sellerServiceProvider);
  return service.rejectProduct(params.$1, params.$2);
});
