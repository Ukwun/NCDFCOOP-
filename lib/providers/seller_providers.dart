import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/seller_models.dart';
import '../../core/services/seller_service.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/core/auth/role.dart';

// Services
final sellerServiceProvider = Provider((ref) {
  return SellerService();
});

// Profile Providers
final sellerProfileByUserIdProvider =
    FutureProvider.family<SellerProfile?, String>((ref, userId) async {
  final service = ref.watch(sellerServiceProvider);
  final profile = await service.getSellerProfileByUserId(userId);
  if (profile != null) return profile;

  // Website sellers may predate the mobile-only `sellers` profile collection.
  // Their trusted Firebase role and UID remain authoritative, so build a
  // non-persisted compatibility profile instead of hiding owned inventory.
  final user = ref.read(currentUserProvider);
  if (user == null || user.id != userId || !user.hasRole(UserRole.seller)) {
    return null;
  }
  return SellerProfile(
    id: userId,
    userId: userId,
    businessName: user.name.isEmpty ? 'My CoopX Store' : user.name,
    sellerType: 'website',
    sellingPath: 'marketplace',
    country: 'Nigeria',
    category: '',
    targetCustomer: TargetCustomer.individual,
    isVerified: false,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
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

final sellerProductsForSellerProvider = FutureProvider.family<
    List<SellerProduct>,
    ({String userId, String? sellerProfileId})>((ref, params) async {
  final service = ref.watch(sellerServiceProvider);
  return service.getSellerProductsForSeller(
    userId: params.userId,
    sellerProfileId: params.sellerProfileId,
  );
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
