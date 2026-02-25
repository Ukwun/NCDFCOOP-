import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/real_product_model.dart';
import './membership_provider.dart';

/// Get all products with user's membership applied
final productsWithMemberPricingProvider =
    FutureProvider<List<Product>>((ref) async {
  final membershipTier =
      await ref.watch(userMembershipTierProvider.future);
  
  // Non-members see all regular products
  // Members see all products (including exclusive ones)
  if (membershipTier == null) {
    return realProducts.where((p) => !p.isMemberExclusive).toList();
  }

  // Members see everything
  return realProducts;
});

/// Get member-exclusive products only
final memberExclusiveProductsProvider =
    FutureProvider<List<Product>>((ref) async {
  final membershipTier =
      await ref.watch(userMembershipTierProvider.future);

  if (membershipTier == null) return [];

  return realProducts
      .where((p) => p.isMemberExclusive)
      .toList();
});

/// Get total savings for user based on membership
final totalPotentialSavingsProvider =
    FutureProvider<double>((ref) async {
  final membershipTier =
      await ref.watch(userMembershipTierProvider.future);

  if (membershipTier == null) return 0;

  double totalSavings = 0;
  for (final product in realProducts) {
    totalSavings += product.getSavingsForTier(membershipTier);
  }
  return totalSavings;
});

/// Get products by category with membership pricing
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) async {
  final membershipTier =
      await ref.watch(userMembershipTierProvider.future);

  final filtered = realProducts.where((p) => p.category == category);

  if (membershipTier == null) {
    return filtered.where((p) => !p.isMemberExclusive).toList();
  }

  return filtered.toList();
});

/// Search products with membership pricing applied
final searchProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  final membershipTier =
      await ref.watch(userMembershipTierProvider.future);

  final searchQuery = query.toLowerCase();
  final filtered = realProducts.where((p) =>
      p.name.toLowerCase().contains(searchQuery) ||
      p.description.toLowerCase().contains(searchQuery) ||
      p.category.toLowerCase().contains(searchQuery));

  if (membershipTier == null) {
    return filtered.where((p) => !p.isMemberExclusive).toList();
  }

  return filtered.toList();
});

/// Get specific product with user's pricing
final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  final membershipTier =
      await ref.watch(userMembershipTierProvider.future);

  Product? product;
  try {
    product = realProducts.firstWhere((p) => p.id == productId);
  } catch (e) {
    product = null;
  }

  if (product == null) return null;
  if (product.isMemberExclusive && membershipTier == null) return null;

  return product;
});
