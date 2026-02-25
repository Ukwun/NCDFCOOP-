import 'package:flutter/material.dart';

/// Member Tier Model - MVP
class MemberTier {
  final String name;
  final int minPoints;
  final int maxPoints;
  final Color color;
  final String icon;
  final List<String> benefits;

  MemberTier({
    required this.name,
    required this.minPoints,
    required this.maxPoints,
    required this.color,
    required this.icon,
    required this.benefits,
  });
}

/// Member Tier Progression Widget - Shows tier status and progress
class MemberTierProgressWidget extends StatelessWidget {
  final int currentPoints;
  final String currentTier;

  const MemberTierProgressWidget({
    Key? key,
    required this.currentPoints,
    required this.currentTier,
  }) : super(key: key);

  static final List<MemberTier> tiers = [
    MemberTier(
      name: 'BRONZE',
      minPoints: 0,
      maxPoints: 1000,
      color: const Color(0xFF8B6F47),
      icon: '🥉',
      benefits: [
        '1% cashback on purchases',
        'Standard shipping',
        'Access to member deals',
      ],
    ),
    MemberTier(
      name: 'SILVER',
      minPoints: 1001,
      maxPoints: 2500,
      color: Colors.grey,
      icon: '🥈',
      benefits: [
        '3% cashback on purchases',
        '50% off shipping',
        'Priority customer support',
        'Exclusive flash sales access',
      ],
    ),
    MemberTier(
      name: 'GOLD',
      minPoints: 2501,
      maxPoints: 5000,
      color: Colors.amber,
      icon: '🥇',
      benefits: [
        '5% cashback on purchases',
        'Free standard shipping',
        'VIP customer support (24/7)',
        'Early access to new products',
        '₦1000 birthday bonus',
      ],
    ),
    MemberTier(
      name: 'PLATINUM',
      minPoints: 5001,
      maxPoints: 999999,
      color: Colors.cyan,
      icon: '💎',
      benefits: [
        '8% cashback on purchases',
        'Free express shipping',
        'Dedicated VIP support line',
        'First access to limited editions',
        '₦5000 birthday bonus',
        'Exclusive member-only discounts',
        'Invitations to member events',
      ],
    ),
  ];

  MemberTier getCurrentTierData() {
    return tiers.firstWhere(
      (tier) => currentTier == tier.name,
      orElse: () => tiers[2], // Default to GOLD
    );
  }

  MemberTier getNextTierData() {
    final currentIndex = tiers.indexWhere((t) => t.name == currentTier);
    if (currentIndex >= tiers.length - 1) {
      return tiers.last; // Already at highest tier
    }
    return tiers[currentIndex + 1];
  }

  @override
  Widget build(BuildContext context) {
    final currentTierData = getCurrentTierData();
    final nextTierData = getNextTierData();
    final pointsToNext = nextTierData.minPoints - currentPoints;
    final progress = currentPoints.toDouble() / nextTierData.minPoints;

    return Column(
      children: [
        // Current Tier Card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                currentTierData.color,
                currentTierData.color.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTierData.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You are ${currentTierData.name}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        currentTierData.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Points',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        currentPoints.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Progress to Next Tier
        if (currentTier != 'PLATINUM')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to ${nextTierData.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(Colors.green[700]),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$pointsToNext points to next tier',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
            ],
          ),

        // Tier Benefits
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Benefits',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...currentTierData.benefits.map((benefit) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: currentTierData.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mini Tier Card Widget - For displaying on home screen
class MiniMemberTierCard extends StatelessWidget {
  final int currentPoints;
  final String currentTier;
  final VoidCallback? onTap;

  const MiniMemberTierCard({
    Key? key,
    required this.currentPoints,
    required this.currentTier,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tierData = MemberTierProgressWidget.tiers.firstWhere(
      (tier) => tier.name == currentTier,
      orElse: () => MemberTierProgressWidget.tiers[2],
    );

    final nextTierData =
        MemberTierProgressWidget.tiers[MemberTierProgressWidget.tiers
                .indexWhere((t) => t.name == currentTier) +
            1] ??
        MemberTierProgressWidget.tiers.last;

    final progress = currentPoints.toDouble() / nextTierData.minPoints;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tierData.color, tierData.color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tierData.icon, style: const TextStyle(fontSize: 20)),
                    Text(
                      tierData.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  currentPoints.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
