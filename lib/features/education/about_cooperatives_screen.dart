import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// Educational screen explaining what cooperatives are and their benefits
class AboutCooperativesScreen extends StatelessWidget {
  const AboutCooperativesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'What is a Cooperative?',
          style: AppTextStyles.h4.copyWith(color: AppColors.text),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.group,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'A Cooperative is about People, Not Profit',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Cooperatives are businesses owned and controlled by members who share a common goal.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Core Principles
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7 Core Principles of Cooperatives',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPrincipleCard(
                    number: '1',
                    title: 'Voluntary & Open Membership',
                    description: 'Anyone can join. No discrimination.',
                  ),
                  _buildPrincipleCard(
                    number: '2',
                    title: 'Member Democratic Control',
                    description: 'Members make decisions together. One member, one vote.',
                  ),
                  _buildPrincipleCard(
                    number: '3',
                    title: 'Member Economic Participation',
                    description: 'Members own the business and share profits fairly.',
                  ),
                  _buildPrincipleCard(
                    number: '4',
                    title: 'Autonomy & Independence',
                    description: 'Members control the cooperative, not external forces.',
                  ),
                  _buildPrincipleCard(
                    number: '5',
                    title: 'Education & Training',
                    description: 'Members learn cooperative values and improve skills.',
                  ),
                  _buildPrincipleCard(
                    number: '6',
                    title: 'Cooperation Among Cooperatives',
                    description: 'Cooperatives work together to strengthen communities.',
                  ),
                  _buildPrincipleCard(
                    number: '7',
                    title: 'Community Commitment',
                    description: 'Cooperatives support sustainable community development.',
                  ),
                ],
              ),
            ),

            // How It Works
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How Our Cooperative Works',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStepCard(
                    step: 'Step 1',
                    title: 'You Join',
                    description: 'Become a member and own a piece of the cooperative.',
                  ),
                  _buildStepCard(
                    step: 'Step 2',
                    title: 'You Shop',
                    description: 'Access fair prices and member-exclusive deals.',
                  ),
                  _buildStepCard(
                    step: 'Step 3',
                    title: 'You Earn',
                    description: 'Earn rewards, points, and community dividends.',
                  ),
                  _buildStepCard(
                    step: 'Step 4',
                    title: 'You Decide',
                    description: 'Vote on cooperative decisions that affect us all.',
                  ),
                ],
              ),
            ),

            // Benefits
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Benefits as a Member',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildBenefitRow('📊', 'Access member-only analytics', 'Track savings and community impact'),
                  _buildBenefitRow('💰', 'Fair pricing', 'Transparent pricing with no hidden markup'),
                  _buildBenefitRow('🎁', 'Community dividends', 'Share profits with other members'),
                  _buildBenefitRow('🤝', 'Voice & vote', 'Have a say in cooperative decisions'),
                  _buildBenefitRow('📱', 'Member app features', 'Reviews, invoices, and bulk ordering'),
                  _buildBenefitRow('🌱', 'Support growth', 'Help local businesses and communities thrive'),
                ],
              ),
            ),

            // Membership Tiers
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membership Tiers',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTierCard(
                    tier: 'Wholesale',
                    icon: '🏢',
                    description: 'For bulk buyers and small businesses',
                    benefits: ['Bulk ordering', 'Business pricing', 'Dedicated support'],
                  ),
                  _buildTierCard(
                    tier: 'Regular Member',
                    icon: '👤',
                    description: 'For individual shoppers',
                    benefits: ['Fair pricing', 'Member rewards', 'Access to sales'],
                  ),
                  _buildTierCard(
                    tier: 'Gold Member',
                    icon: '👑',
                    description: 'For committed members',
                    benefits: ['5% bonus rewards', 'Priority support', 'Extra dividends'],
                  ),
                  _buildTierCard(
                    tier: 'Cooperative Owner',
                    icon: '🏆',
                    description: 'For those who want to participate in management',
                    benefits: ['Full voting rights', 'Board access', 'Highest dividends'],
                  ),
                ],
              ),
            ),

            // CTA
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/features-guide'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Discover App Features',
                      style: AppTextStyles.buttonText.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildPrincipleCard({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              step.split(' ')[1],
              style: AppTextStyles.h4.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required String tier,
    required String icon,
    required String description,
    required List<String> benefits,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(benefit, style: AppTextStyles.bodySmall),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
