import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth/user_persistence.dart';

/// User's membership tier (if any)
final userMembershipTierProvider = FutureProvider<String?>((ref) async {
  try {
    final membership = await UserPersistence.getMembership();
    return membership?['tier'] as String?;
  } catch (e) {
    return null;
  }
});

/// User's membership expiry date (if any)
final userMembershipExpiryProvider = FutureProvider<DateTime?>((ref) async {
  try {
    final membership = await UserPersistence.getMembership();
    if (membership == null) return null;
    return DateTime.parse(membership['expiryDate'] as String);
  } catch (e) {
    return null;
  }
});

/// Check if user has active membership
final hasActiveMembershipProvider = FutureProvider<bool>((ref) async {
  try {
    final membership = await UserPersistence.getMembership();
    if (membership == null) return false;
    
    final expiryDate = DateTime.parse(membership['expiryDate'] as String);
    return expiryDate.isAfter(DateTime.now());
  } catch (e) {
    return false;
  }
});

/// Get user's membership benefits based on tier
final membershipBenefitsProvider =
    FutureProvider.family<List<String>, String?>((ref, tier) async {
  if (tier == null) return [];

  final benefits = {
    'basic': [
      'Member pricing (10% off)',
      'Access to app features',
      'Basic customer support',
      'Monthly newsletter',
    ],
    'gold': [
      'Everything in Basic',
      '15% off member pricing',
      'Priority customer support',
      '2% cash back on purchases',
      'Exclusive member events',
      'Free shipping over ₦10,000',
    ],
    'platinum': [
      'Everything in Gold',
      '20% off member pricing',
      'VIP customer support',
      '3% cash back on purchases',
      'Early access to sales',
      'Free shipping on all orders',
      'Birthday bonus rewards',
      'Personal shopping assistant',
    ],
  };

  return benefits[tier] ?? [];
});
