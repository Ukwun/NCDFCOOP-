import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Screen for displaying rewards and points
class MyRewardsScreen extends ConsumerWidget {
  const MyRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data for demonstration
    const totalPoints = 2450;
    const availableRewards = [
      {
        'title': '500 Bonus Points',
        'description': 'Spend ₦5,000 or more',
        'pointsNeeded': 500,
        'earned': 450,
      },
      {
        'title': '₦1,000 Voucher',
        'description': 'Redeem 1500 points',
        'pointsNeeded': 1500,
        'earned': 1200,
      },
      {
        'title': 'Free Shipping',
        'description': 'Redeem 800 points',
        'pointsNeeded': 800,
        'earned': 650,
      },
      {
        'title': '15% Discount',
        'description': 'Redeem 2000 points',
        'pointsNeeded': 2000,
        'earned': 1500,
      },
    ];

    const completedRewards = [
      {
        'title': 'Welcome Bonus',
        'points': 100,
        'date': '2024-01-15',
      },
      {
        'title': 'Birthday Gift',
        'points': 250,
        'date': '2024-01-20',
      },
      {
        'title': 'Referral Bonus',
        'points': 500,
        'date': '2024-01-25',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Rewards'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Points Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Points',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalPoints.toString(),
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Equivalent to ₦${(totalPoints ~/ 10).toString()}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Available Rewards Section
            Text(
              'Available Rewards',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...availableRewards.map((reward) {
              final progress =
                  (reward['earned'] as int) / (reward['pointsNeeded'] as int);
              final isComplete = progress >= 1.0;

              return GestureDetector(
                onTap: isComplete
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Reward "${reward['title']}" claimed!'),
                            backgroundColor: AppColors.primary,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isComplete ? AppColors.primary : AppColors.border,
                      width: isComplete ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (reward['title'] as String?) ?? 'Reward',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (reward['description'] as String?) ??
                                      'No description',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isComplete)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: AppColors.surface,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0) as double,
                              minHeight: 8,
                              backgroundColor: AppColors.background,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isComplete
                                    ? AppColors.primary
                                    : AppColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${reward['earned']}/${reward['pointsNeeded']} points',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 28),

            // Earned Rewards History
            Text(
              'Earned Rewards',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...completedRewards.map((reward) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (reward['title'] as String?) ?? 'Reward',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (reward['date'] as String?) ?? 'Unknown date',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '+${reward['points']} pts',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),

            // Learn More Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rewards program details'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Learn More About Rewards'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
