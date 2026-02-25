import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member_models.dart';
import 'auth_provider.dart';

// ============================================================================
// MEMBER PROVIDERS - State management for all member-specific features
// ============================================================================

// MEMBER DATA PROVIDERS

/// Current member (logged in user) as Member object
final currentMemberProvider = FutureProvider<Member?>((ref) async {
  // Connect to auth provider to get current user
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  // For now, return a placeholder member object based on user
  // In production, fetch from Firestore using user ID

  final nameParts = user.name.split(' ');
  final firstName = nameParts.isNotEmpty ? nameParts.first : '';
  final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

  final now = DateTime.now();

  // Handle phone number - use the value from user
  final phone = user.phoneNumber;

  return Member(
    id: user.id,
    firstName: firstName.isEmpty ? 'User' : firstName,
    lastName: lastName.isEmpty ? 'Member' : lastName,
    email: user.email,
    phone: phone,
    memberTier: 'BASIC', // Default tier for new members
    loyaltyPoints: 0,
    totalPointsEarned: 0,
    memberSince: now,
    totalOrders: 0,
    totalSpent: 0.0,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
});

/// Member's loyalty information
final memberLoyaltyProvider = FutureProvider<MemberLoyalty?>((ref) async {
  try {
    final member = await ref.watch(currentMemberProvider.future);
    if (member == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('memberLoyalty')
        .doc(member.id)
        .get();

    if (!doc.exists) return null;
    return MemberLoyalty.fromFirestore(doc);
  } catch (e) {
    // Firebase not available or error - return null gracefully
    return null;
  }
});

/// All member benefits available in the system
final memberBenefitsProvider = FutureProvider<List<MemberBenefit>>((ref) async {
  try {
    final docs = await FirebaseFirestore.instance
        .collection('memberBenefits')
        .orderBy('createdAt', descending: true)
        .get();
    return docs.docs.map((doc) => MemberBenefit.fromFirestore(doc)).toList();
  } catch (e) {
    return [];
  }
});

/// Benefits filtered by current member's tier
final memberTierBenefitsProvider =
    FutureProvider<List<MemberBenefit>>((ref) async {
  final member = await ref.watch(currentMemberProvider.future);
  final allBenefits = await ref.watch(memberBenefitsProvider.future);

  if (member == null) return [];

  return allBenefits
      .where((benefit) => benefit.tiers.contains(member.memberTier))
      .toList();
});

/// Recommendations personalized for member
final memberRecommendationsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  try {
    final member = await ref.watch(currentMemberProvider.future);
    if (member == null) return [];

    // Fetch personalized recommendations based on purchase history
    final docs =
        await FirebaseFirestore.instance.collection('products').limit(10).get();
    return docs.docs.map((doc) => doc.data()).toList();
  } catch (e) {
    return [];
  }
});

/// Member's order statistics
final memberOrderStatsProvider = FutureProvider<OrderStats?>((ref) async {
  try {
    final member = await ref.watch(currentMemberProvider.future);
    if (member == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('orderStats')
        .doc(member.id)
        .get();

    if (!doc.exists) return null;
    return OrderStats.fromFirestore(doc);
  } catch (e) {
    return null;
  }
});

/// Member's saved payment methods
final memberPaymentMethodsProvider =
    FutureProvider<List<SavedPaymentMethod>>((ref) async {
  try {
    final member = await ref.watch(currentMemberProvider.future);
    if (member == null) return [];

    final docs = await FirebaseFirestore.instance
        .collection('members')
        .doc(member.id)
        .collection('paymentMethods')
        .get();

    return docs.docs
        .map((doc) => SavedPaymentMethod.fromFirestore(doc))
        .toList();
  } catch (e) {
    return [];
  }
});

// ============================================================================
// REAL-TIME STREAM PROVIDERS
// ============================================================================

/// Real-time member notifications stream
final memberNotificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  // For now, return empty stream - in production, listen to Firestore
  // return FirebaseFirestore.instance
  //     .collection('members')
  //     .doc(user.id)
  //     .collection('notifications')
  //     .orderBy('createdAt', descending: true)
  //     .snapshots()
  //     .map((snapshot) => snapshot.docs
  //         .map((doc) => AppNotification.fromFirestore(doc))
  //         .toList());

  return Stream.value([]);
});

/// Real-time unread notification count
final memberUnreadCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  // For now, return 0 - in production, query unread count from Firestore
  return Stream.value(0);
});

/// Real-time member loyalty points updates
final memberLoyaltyStreamProvider = StreamProvider<MemberLoyalty?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  // For now, return null - in production, listen to Firestore
  return Stream.value(null);
});

/// Real-time member order updates
final memberOrdersStreamProvider = StreamProvider<List<dynamic>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  // For now, return empty - in production, listen to Firestore
  return Stream.value([]);
});

// ============================================================================
// ACTION PROVIDERS - For mutations/updates
// ============================================================================

/// Mark notification as read
final markNotificationAsReadProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  try {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
      'readAt': Timestamp.now(),
    });
  } catch (e) {
    // Silently fail if Firebase is not available
  }
});

/// Mark all notifications as read
final markAllNotificationsAsReadProvider = FutureProvider<void>((ref) async {
  try {
    final user = ref.watch(currentUserProvider);
    if (user == null) return;

    // In production, update all user's notifications in Firestore
    // await FirebaseFirestore.instance
    //     .collection('members')
    //     .doc(user.id)
    //     .collection('notifications')
    //     .where('isRead', isEqualTo: false)
    //     .get()
    //     .then((snapshot) {
    //   for (var doc in snapshot.docs) {
    //     doc.reference.update({'isRead': true, 'readAt': Timestamp.now()});
    //   }
    // });
    return;
  } catch (e) {
    // Silently fail if Firebase is not available
  }
});

/// Delete notification
final deleteNotificationProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  try {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  } catch (e) {
    // Silently fail if Firebase is not available
  }
});

/// Update member profile
final updateMemberProfileProvider =
    FutureProvider.family<void, Member>((ref, updatedMember) async {
  try {
    await FirebaseFirestore.instance
        .collection('members')
        .doc(updatedMember.id)
        .update(updatedMember.toFirestore());
  } catch (e) {
    // Silently fail if Firebase is not available
  }
});

/// Update member payment methods
final updatePaymentMethodProvider =
    FutureProvider.family<void, SavedPaymentMethod>((ref, paymentMethod) async {
  try {
    await FirebaseFirestore.instance
        .collection('members')
        .doc(paymentMethod.memberId)
        .collection('paymentMethods')
        .doc(paymentMethod.id)
        .update(paymentMethod.toFirestore());
  } catch (e) {
    // Silently fail if Firebase is not available
  }
});

/// Delete payment method
final deletePaymentMethodProvider =
    FutureProvider.family<void, (String, String)>((ref, ids) async {
  try {
    final (memberId, paymentMethodId) = ids;
    await FirebaseFirestore.instance
        .collection('members')
        .doc(memberId)
        .collection('paymentMethods')
        .doc(paymentMethodId)
        .delete();
  } catch (e) {
    // Silently fail if Firebase is not available
  }
});

/// Claim reward from loyalty points
final claimRewardProvider =
    FutureProvider.family<void, (String, Reward)>((ref, params) async {
  try {
    final (memberId, reward) = params;

    final batch = FirebaseFirestore.instance.batch();

    // Update loyalty - deduct points and add claimed reward
    final loyaltyRef =
        FirebaseFirestore.instance.collection('memberLoyalty').doc(memberId);

    batch.update(loyaltyRef, {
      'currentPoints': FieldValue.increment(-reward.pointsRequired),
      'claimedRewards': FieldValue.arrayUnion([reward.toMap()]),
    });

    await batch.commit();
  } catch (e) {
    // Silently fail if Firebase is not available
  }
});

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

/// Get member tier color
final memberTierColorProvider = Provider<String>((ref) {
  // This would be used in the UI to get color for tier badge
  return 'primary'; // Adjust based on actual tier
});

/// Get member tier benefits count
final memberBenefitsCountProvider = FutureProvider<int>((ref) async {
  try {
    final benefits = await ref.watch(memberTierBenefitsProvider.future);
    return benefits.length;
  } catch (e) {
    return 0;
  }
});

/// Check if member has reached next tier
final canUpgradeTierProvider = FutureProvider<bool>((ref) async {
  try {
    final loyalty = await ref.watch(memberLoyaltyProvider.future);
    if (loyalty == null) return false;
    return loyalty.currentPoints >= loyalty.pointsNeededForNextTier;
  } catch (e) {
    return false;
  }
});

// NOTE: Placeholder for authStateProvider - should be defined in your auth providers
// final authStateProvider = StreamProvider<User?>(...);
