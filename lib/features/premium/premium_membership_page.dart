import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Premium Membership & Subscription Page
class PremiumMembershipPage extends StatefulWidget {
  const PremiumMembershipPage({super.key});

  @override
  State<PremiumMembershipPage> createState() => _PremiumMembershipPageState();
}

class _PremiumMembershipPageState extends State<PremiumMembershipPage> {
  String selectedTier = 'gold';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Premium Membership',
          style: AppTextStyles.h4.copyWith(color: AppColors.text),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade Your Membership',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Get exclusive benefits and save even more with premium membership',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),

            // Membership Tiers
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membership Tiers',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTierCard(
                    'Basic',
                    'FREE',
                    [
                      'Member pricing (10% off)',
                      'Access to app features',
                      'Basic customer support',
                      'Monthly newsletter',
                    ],
                    false,
                    'basic',
                  ),
                  _buildTierCard(
                    'Gold',
                    '₦5,000/Year',
                    [
                      'Everything in Basic',
                      '15% off member pricing',
                      'Priority customer support',
                      '2% cash back on purchases',
                      'Exclusive member events',
                      'Free shipping over ₦10,000',
                    ],
                    true,
                    'gold',
                  ),
                  _buildTierCard(
                    'Platinum',
                    '₦12,000/Year',
                    [
                      'Everything in Gold',
                      '20% off member pricing',
                      'VIP customer support',
                      '3% cash back on purchases',
                      'Early access to sales',
                      'Free shipping on all orders',
                      'Birthday bonus rewards',
                      'Personal shopping assistant',
                    ],
                    false,
                    'platinum',
                  ),
                  _buildTierCard(
                    'Diamond',
                    '₦25,000/Year',
                    [
                      'Everything in Platinum',
                      '25% off member pricing',
                      'Dedicated account manager',
                      '5% cash back on purchases',
                      'Concierge service',
                      'Priority bulk ordering',
                      'Exclusive member-only products',
                      'Annual rewards gift',
                      'Invitation to VIP events',
                    ],
                    false,
                    'diamond',
                  ),
                ],
              ),
            ),

            // Comparison Table
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feature Comparison',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildComparisonRow(
                      'Price', 'Free', '₦5K/yr', '₦12K/yr', '₦25K/yr'),
                  _buildComparisonRow('Discount %', '10%', '15%', '20%', '25%'),
                  _buildComparisonRow('Cash Back', '0%', '2%', '3%', '5%'),
                  _buildComparisonRow(
                      'Free Shipping', 'No', '₦10K+', 'All', 'All'),
                  _buildComparisonRow(
                      'Support', 'Basic', 'Priority', 'VIP', 'Dedicated'),
                ],
              ),
            ),

            // Why Upgrade Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Upgrade?',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildBenefitRow(
                      '💰', 'Save Money', 'Get deeper discounts and cash back'),
                  _buildBenefitRow(
                      '🚚', 'Free Shipping', 'Save on delivery costs'),
                  _buildBenefitRow('⭐', 'VIP Treatment',
                      'Priority support and exclusive access'),
                  _buildBenefitRow(
                      '🎁', 'Rewards', 'Earn points and get special gifts'),
                  _buildBenefitRow(
                      '📢', 'Early Access', 'Be first to see flash sales'),
                  _buildBenefitRow(
                      '👥', 'Community', 'Join exclusive member events'),
                ],
              ),
            ),

            // Payment Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscribe Now',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Selected: ${selectedTier.toUpperCase()}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        context
                            .pushNamed('subscription-payment', pathParameters: {
                          'tier': selectedTier,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'Continue to Payment',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(
    String tierName,
    String price,
    List<String> features,
    bool isSelected,
    String tierId,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTier = tierId;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color:
                  selectedTier == tierId ? AppColors.primary : AppColors.border,
              width: selectedTier == tierId ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tierName,
                    style: AppTextStyles.h4,
                  ),
                  if (selectedTier == tierId)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                price,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    String basic,
    String gold,
    String platinum,
    String diamond,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: AppTextStyles.labelLarge,
            ),
          ),
          Expanded(
            child: Text(basic,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(gold,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(platinum,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(diamond,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
