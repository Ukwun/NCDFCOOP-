import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';

/// Service for managing member premium upgrades
class PremiumMembershipService {
  static final PremiumMembershipService _instance =
      PremiumMembershipService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory PremiumMembershipService() {
    return _instance;
  }

  PremiumMembershipService._internal();

  /// Premium tier pricing
  static const Map<String, double> premiumTierPricing = {
    'gold': 5000.0, // ₦5,000/year
    'platinum': 15000.0, // ₦15,000/year
  };

  /// Premium tier benefits
  static const Map<String, List<String>> premiumTierBenefits = {
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

  /// Upgrade member to premium
  /// Returns the updated user with premiumMember role
  Future<User> upgradeToPremium({
    required User user,
    required String tier, // 'gold' or 'platinum'
  }) async {
    try {
      if (!user.hasRole(UserRole.coopMember)) {
        throw Exception('User must be a co-op member to upgrade');
      }

      if (!premiumTierPricing.containsKey(tier)) {
        throw Exception('Invalid tier: $tier');
      }

      // Add premium member role if not already present
      final updatedRoles = user.roles.toList();
      if (!updatedRoles.contains(UserRole.premiumMember)) {
        updatedRoles.add(UserRole.premiumMember);
      }

      // Calculate expiry date (1 year from now)
      final expiryDate = DateTime.now().add(const Duration(days: 365));

      // Update user in Firestore
      await _firestore.collection('users').doc(user.id).update({
        'roles': updatedRoles.map((r) => r.name).toList(),
        'membershipTier': tier,
        'membershipExpiryDate': expiryDate.toIso8601String(),
        'premiumUpgradeDate': DateTime.now().toIso8601String(),
      });

      // Create upgrade record in audit
      await _createUpgradeRecord(
        userId: user.id,
        fromRole: UserRole.coopMember,
        toRole: UserRole.premiumMember,
        tier: tier,
        amount: premiumTierPricing[tier]!,
      );

      // Return updated user
      return user.copyWith(
        roles: updatedRoles,
        membershipTier: tier,
        membershipExpiryDate: expiryDate,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check if member is eligible for premium upgrade
  bool canUpgradeToPremium(User user) {
    return user.hasRole(UserRole.coopMember) &&
        !user.hasRole(UserRole.premiumMember);
  }

  /// Check if premium membership is still active
  bool isPremiumActive(User user) {
    if (!user.hasRole(UserRole.premiumMember)) return false;
    if (user.membershipExpiryDate == null) return false;
    return user.membershipExpiryDate!.isAfter(DateTime.now());
  }

  /// Renew premium membership
  Future<User> renewPremium({
    required User user,
    required String tier,
  }) async {
    try {
      if (!user.hasRole(UserRole.premiumMember)) {
        throw Exception('User is not a premium member');
      }

      if (!premiumTierPricing.containsKey(tier)) {
        throw Exception('Invalid tier: $tier');
      }

      // Calculate new expiry date (1 year from now or from current expiry if in future)
      final currentExpiry = user.membershipExpiryDate ?? DateTime.now();
      final newExpiry = currentExpiry.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(days: 365))
          : currentExpiry.add(const Duration(days: 365));

      // Update in Firestore
      await _firestore.collection('users').doc(user.id).update({
        'membershipTier': tier,
        'membershipExpiryDate': newExpiry.toIso8601String(),
        'premiumRenewalDate': DateTime.now().toIso8601String(),
      });

      // Create renewal record
      await _createRenewalRecord(
        userId: user.id,
        tier: tier,
        amount: premiumTierPricing[tier]!,
        newExpiryDate: newExpiry,
      );

      return user.copyWith(
        membershipTier: tier,
        membershipExpiryDate: newExpiry,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's premium details
  Future<Map<String, dynamic>?> getPremiumDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {
        'tier': data['membershipTier'],
        'expiryDate': data['membershipExpiryDate'],
        'upgradeDate': data['premiumUpgradeDate'],
        'renewalDate': data['premiumRenewalDate'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Create an upgrade record for audit trail
  Future<void> _createUpgradeRecord({
    required String userId,
    required UserRole fromRole,
    required UserRole toRole,
    required String tier,
    required double amount,
  }) async {
    try {
      await _firestore.collection('premium_upgrades').add({
        'userId': userId,
        'fromRole': fromRole.name,
        'toRole': toRole.name,
        'tier': tier,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    } catch (e) {
      // Log error but don't fail the upgrade
      debugPrint('Error creating upgrade record: $e');
    }
  }

  /// Create a renewal record for audit trail
  Future<void> _createRenewalRecord({
    required String userId,
    required String tier,
    required double amount,
    required DateTime newExpiryDate,
  }) async {
    try {
      await _firestore.collection('premium_renewals').add({
        'userId': userId,
        'tier': tier,
        'amount': amount,
        'newExpiryDate': newExpiryDate.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    } catch (e) {
      // Log error but don't fail the renewal
      debugPrint('Error creating renewal record: $e');
    }
  }
}
