import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member_models.dart';
import '../core/providers/order_providers.dart' as commerce_orders;
import '../core/services/order_fulfillment_service.dart';
import 'auth_provider.dart';

// ============================================================================
// MEMBER PROVIDERS - State management for all member-specific features
// ============================================================================

// MEMBER DATA PROVIDERS

/// Current member (logged in user) as Member object
final currentMemberProvider = FutureProvider<Member?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final firestore = FirebaseFirestore.instance;
  final snapshots = await Future.wait([
    firestore.collection('members').doc(user.id).get(),
    firestore.collection('users').doc(user.id).get(),
  ]);
  final memberData = snapshots[0].data() ?? const <String, dynamic>{};
  final userData = snapshots[1].data() ?? const <String, dynamic>{};
  if (memberData.isEmpty && userData.isEmpty) return null;
  final data = <String, dynamic>{...userData, ...memberData};
  final storedName = (data['name'] as String?)?.trim();
  final nameParts = (storedName?.isNotEmpty == true ? storedName! : user.name)
      .split(RegExp(r'\s+'));
  final firstName = nameParts.isNotEmpty ? nameParts.first : '';
  final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
  final now = DateTime.now();
  DateTime dateFrom(dynamic value) => value is Timestamp ? value.toDate() : now;

  return Member(
    id: user.id,
    firstName: firstName.isEmpty ? 'User' : firstName,
    lastName: lastName.isEmpty ? 'Member' : lastName,
    email: (data['email'] as String?) ?? user.email,
    phone: (data['phone'] ?? data['phoneNumber'] ?? user.phoneNumber) as String,
    memberTier: ((data['memberTier'] ?? data['tier'] ?? 'bronze') as String)
        .toUpperCase(),
    loyaltyPoints: (data['loyaltyPoints'] as num?)?.toInt() ?? 0,
    totalPointsEarned: (data['totalPointsEarned'] as num?)?.toInt() ?? 0,
    memberSince: dateFrom(data['memberSince'] ?? data['joiningDate']),
    lastPurchaseDate: data['lastPurchaseDate'] is Timestamp
        ? (data['lastPurchaseDate'] as Timestamp).toDate()
        : null,
    totalOrders:
        (data['totalOrders'] as num? ?? data['ordersCount'] as num? ?? 0)
            .toInt(),
    totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
    isActive: data['isActive'] as bool? ??
        (data['membershipStatus'] == null ||
            data['membershipStatus'] == 'active'),
    createdAt: dateFrom(data['createdAt'] ?? data['joiningDate']),
    updatedAt: dateFrom(data['updatedAt']),
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

/// Active, administrator-configured rewards. Empty means no offer is live.
final availableMemberRewardsProvider =
    FutureProvider<List<Reward>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('rewards')
      .where('active', isEqualTo: true)
      .get();
  final now = DateTime.now();
  final rewards = snapshot.docs
      .where((document) {
        final data = document.data();
        final startsAt = data['startsAt'] as Timestamp?;
        final endsAt = data['endsAt'] as Timestamp?;
        final stock = (data['stock'] as num?)?.toInt();
        return (startsAt == null || !startsAt.toDate().isAfter(now)) &&
            (endsAt == null || !endsAt.toDate().isBefore(now)) &&
            (stock == null || stock > 0);
      })
      .map((document) {
        return Reward.fromMap({...document.data(), 'id': document.id});
      })
      .where((reward) => reward.pointsRequired > 0)
      .toList();
  rewards.sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired));
  return rewards;
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

  return FirebaseFirestore.instance
      .collection('notifications')
      .doc(user.id)
      .collection('items')
      .snapshots()
      .map((snapshot) {
    final notifications =
        snapshot.docs.map(AppNotification.fromFirestore).toList();
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  });
});

/// Real-time unread notification count
final memberUnreadCountProvider = Provider<AsyncValue<int>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data(0);

  return ref.watch(memberNotificationsStreamProvider).whenData(
        (notifications) =>
            notifications.where((notification) => !notification.isRead).length,
      );
});

/// Real-time member loyalty points updates
final memberLoyaltyStreamProvider = StreamProvider<MemberLoyalty?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('memberLoyalty')
      .doc(user.id)
      .snapshots()
      .map((document) =>
          document.exists ? MemberLoyalty.fromFirestore(document) : null);
});

/// Real-time member order updates
final memberOrdersStreamProvider = Provider<AsyncValue<List<OrderData>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const AsyncValue.data([]);

  return ref.watch(commerce_orders.userOrdersProvider(user.id));
});

// ============================================================================
// ACTION PROVIDERS - For mutations/updates
// ============================================================================

/// Mark notification as read
final markNotificationAsReadProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('Authentication required');
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(user.id)
      .collection('items')
      .doc(notificationId)
      .update({'isRead': true, 'readAt': Timestamp.now()});
});

/// Mark all notifications as read
final markAllNotificationsAsReadProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  final unread = await FirebaseFirestore.instance
      .collection('notifications')
      .doc(user.id)
      .collection('items')
      .where('isRead', isEqualTo: false)
      .get();
  for (var offset = 0; offset < unread.docs.length; offset += 450) {
    final batch = FirebaseFirestore.instance.batch();
    for (final document in unread.docs.skip(offset).take(450)) {
      batch.update(document.reference,
          {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }
});

/// Delete notification
final deleteNotificationProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('Authentication required');
  await FirebaseFirestore.instance
      .collection('notifications')
      .doc(user.id)
      .collection('items')
      .doc(notificationId)
      .delete();
});

/// Update member profile
final updateMemberProfileProvider =
    FutureProvider.family<void, Member>((ref, updatedMember) async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  final memberData = updatedMember.toFirestore();
  batch.set(firestore.collection('members').doc(updatedMember.id), memberData,
      SetOptions(merge: true));
  batch.set(
      firestore.collection('users').doc(updatedMember.id),
      {
        'name': updatedMember.fullName.trim(),
        'firstName': updatedMember.firstName,
        'lastName': updatedMember.lastName,
        'phone': updatedMember.phone,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true));
  await batch.commit();
  ref.invalidate(currentMemberProvider);
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
  final (memberId, reward) = params;
  final callable =
      FirebaseFunctions.instance.httpsCallable('claimMemberReward');
  await callable.call(<String, dynamic>{
    'memberId': memberId,
    'rewardId': reward.id,
  });
  ref.invalidate(currentMemberProvider);
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
