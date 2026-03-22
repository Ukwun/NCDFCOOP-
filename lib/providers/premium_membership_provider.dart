import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/api/premium_membership_service.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';
import 'package:coop_commerce/providers/auth_provider.dart';

/// Singleton instance of premium membership service
final premiumMembershipServiceProvider =
    Provider<PremiumMembershipService>((ref) {
  return PremiumMembershipService();
});

/// Check if current user can upgrade to premium
final canUpgradeToPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final service = ref.watch(premiumMembershipServiceProvider);
  return service.canUpgradeToPremium(user);
});

/// Check if current user has active premium membership
final hasActivePremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final service = ref.watch(premiumMembershipServiceProvider);
  return service.isPremiumActive(user);
});

/// Get current user's premium membership details
final userPremiumDetailsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final service = ref.watch(premiumMembershipServiceProvider);
  return service.getPremiumDetails(user.id);
});

/// Upgrade to premium - mutation provider
final upgradeToPremiumProvider =
    FutureProvider.family<User, String>((ref, tier) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User must be logged in to upgrade');
  }

  final service = ref.watch(premiumMembershipServiceProvider);
  final upgradedUser = await service.upgradeToPremium(
    user: user,
    tier: tier,
  );

  // Update the current user in state
  ref.read(currentUserProvider.notifier).setUser(upgradedUser);

  return upgradedUser;
});

/// Renew premium membership - mutation provider
final renewPremiumProvider =
    FutureProvider.family<User, String>((ref, tier) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User must be logged in to renew');
  }

  final service = ref.watch(premiumMembershipServiceProvider);
  final renewedUser = await service.renewPremium(
    user: user,
    tier: tier,
  );

  // Update the current user in state
  ref.read(currentUserProvider.notifier).setUser(renewedUser);

  return renewedUser;
});

/// Get available member pricing discounts
final memberPricingProvider = Provider<Map<String, double>>((ref) {
  return {
    'wholesaleBuyer': 0.0, // No discount - retail price
    'coopMember': 0.05, // 5% discount
    'premiumMember': 0.10, // 10% premium discount
  };
});

/// Get account balance (add money feature for member and wholesale buyer)
final accountBalanceProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;

  // Check if user can add money
  final canAddMoney = user.hasRole(UserRole.coopMember) ||
      user.hasRole(UserRole.premiumMember) ||
      user.hasRole(UserRole.wholesaleBuyer);

  if (!canAddMoney) return 0.0;

  // TODO: Fetch from backend when wallet service is implemented
  return 0.0;
});

/// Get saved money on platform (member-only feature)
final savedMoneyProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;

  // Only members and premium members can save money
  final hasPermission =
      user.hasRole(UserRole.coopMember) || user.hasRole(UserRole.premiumMember);

  if (!hasPermission) return 0.0;

  // TODO: Fetch from backend when savings service is implemented
  return 0.0;
});
