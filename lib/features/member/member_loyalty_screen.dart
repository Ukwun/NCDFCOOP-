import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/models/member_models.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/member_providers.dart';

/// Member loyalty points backed by the authenticated member's Firestore record.
class MemberLoyaltyScreen extends ConsumerWidget {
  const MemberLoyaltyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final memberId = currentUser?.id;

    final memberAsync = ref.watch(currentMemberProvider);
    final rewardsAsync = ref.watch(availableMemberRewardsProvider);
    final member = memberAsync.value;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Loyalty')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/signin'),
            child: const Text('Sign in to continue'),
          ),
        ),
      );
    }
    if (memberAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (memberAsync.hasError || member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Loyalty')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.loyalty_outlined, size: 52),
                const SizedBox(height: 16),
                const Text(
                  'Your verified member loyalty record is unavailable.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(currentMemberProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final memberName = member?.fullName.trim().isNotEmpty == true
        ? member!.fullName
        : currentUser?.name ?? 'Member';
    final currentPoints = member?.loyaltyPoints ?? 0;
    final pointsThisMonth = member?.totalPointsEarned ?? 0;
    final currentTier = member?.memberTier.toUpperCase() ?? 'BRONZE';
    final nextTierPoints = switch (currentTier) {
      'BRONZE' => 1000,
      'SILVER' => 5000,
      'GOLD' => 15000,
      _ => currentPoints > 0 ? currentPoints : 1,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Loyalty'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Member Header Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Loyalty Points',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currentPoints',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Member',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              memberName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'This Month',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '+$pointsThisMonth',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tier Progress Section
              const Text(
                'Member Tier',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTierProgressCard(
                currentPoints,
                nextTierPoints,
                currentTier,
              ),
              const SizedBox(height: 24),

              // Redeem Section
              const Text(
                'Redeem Your Points',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              rewardsAsync.when(
                data: (rewards) => rewards.isEmpty
                    ? const Text('No rewards are available right now.')
                    : Column(
                        children: rewards
                            .map((reward) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildRedemptionOption(
                                    context: context,
                                    ref: ref,
                                    memberId: memberId,
                                    currentPoints: currentPoints,
                                    reward: reward,
                                  ),
                                ))
                            .toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text(
                  'Rewards are temporarily unavailable. Please try again later.',
                ),
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierProgressCard(int current, int next, String tierName) {
    final progress = current / next;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildTierBadge(tierName),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tierName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current Tier',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(Colors.green[700]),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Next tier (PLATINUM) at 5,000 points - ${(next - current).floor()} points to go',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(String tierName) {
    final colors = {
      'BRONZE': Colors.brown[300],
      'SILVER': Colors.grey[400],
      'GOLD': Colors.amber[600],
      'PLATINUM': Colors.cyan[400],
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors[tierName] ?? Colors.green[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tierName[0],
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildRedemptionOption({
    required BuildContext context,
    required WidgetRef ref,
    required String? memberId,
    required int currentPoints,
    required Reward reward,
  }) {
    final title = reward.name;
    final description = reward.description;
    final points = reward.pointsRequired;
    final icon = switch (reward.rewardType) {
      'shipping' || 'freeship' => Icons.local_shipping,
      'gift_card' => Icons.card_giftcard,
      _ => Icons.local_offer,
    };
    return GestureDetector(
      onTap: () async {
        if (memberId == null || memberId.isEmpty) {
          context.go('/signin');
          return;
        }
        if (currentPoints < points) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Not enough points for $title'),
            ),
          );
          return;
        }

        try {
          await ref.read(claimRewardProvider((memberId, reward)).future);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reward claimed: $title'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reward could not be claimed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.green[700], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$points pts',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningRule({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[700], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
