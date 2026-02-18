import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Member benefits screen showing all member perks and advantages
class MemberBenefitsScreen extends StatelessWidget {
  const MemberBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Member Benefits',
          style: AppTextStyles.h4.copyWith(color: AppColors.text),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Member Status Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Membership Tier',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.3),
                          AppColors.accent.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.gold),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gold Member',
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Member since December 2023',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Benefits Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                spacing: AppSpacing.lg,
                children: [
                  _BenefitCategory(
                    icon: Icons.local_offer,
                    title: 'Exclusive Pricing',
                    description: 'Save up to 40% on member-exclusive deals',
                    routeName: 'exclusive-pricing',
                    details: [
                      'Member-only pricing on all products',
                      'Access to flash sales 24 hours early',
                      'Special discounts on bulk orders',
                      'Cumulative savings tracked automatically',
                    ],
                  ),
                  _BenefitCategory(
                    icon: Icons.card_giftcard,
                    title: 'Loyalty Points',
                    description: 'Earn 1 point per ₦1 spent',
                    routeName: 'community-dividends',
                    details: [
                      'Gold members earn 5% bonus points',
                      'Redeem points for exclusive products',
                      'Double points on selected categories',
                      'Points never expire',
                    ],
                  ),
                  _BenefitCategory(
                    icon: Icons.local_shipping,
                    title: 'Free Shipping',
                    description: 'Free delivery on orders over ₦50,000',
                    routeName: 'bulk-access',
                    details: [
                      'Free shipping on qualifying orders',
                      'Express delivery options available',
                      'Track your order in real-time',
                      'Same-day delivery in select cities',
                    ],
                  ),
                  _BenefitCategory(
                    icon: Icons.favorite,
                    title: 'Priority Support',
                    description: 'Dedicated customer service',
                    routeName: 'members-only',
                    details: [
                      '24/7 priority customer support',
                      'Dedicated account manager available',
                      'Faster resolution on returns',
                      'VIP customer service phone line',
                    ],
                  ),
                  _BenefitCategory(
                    icon: Icons.flash_on,
                    title: 'Flash Sales',
                    description: 'Exclusive member promotions & events',
                    routeName: 'flash-sales',
                    details: [
                      'Early access to new product launches',
                      'Invitation-only sales & events',
                      'Member birthday rewards',
                      'Seasonal exclusive collections',
                    ],
                  ),
                  _BenefitCategory(
                    icon: Icons.verified,
                    title: 'Member Exclusive',
                    description: '100% satisfaction guarantee',
                    routeName: 'members-only',
                    details: [
                      '30-day money-back guarantee',
                      'Extended warranty on electronics',
                      'Fraud protection on all purchases',
                      'Easy return and exchange process',
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Upgrade Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Want to Upgrade?',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Upgrade to Platinum membership to unlock additional benefits like dedicated shopping assistance and exclusive events.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      onPressed: () {
                        context.pushNamed('premium-membership');
                      },
                      child: Text(
                        'Learn About Platinum',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
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
}

class _BenefitCategory extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String routeName;
  final List<String> details;

  const _BenefitCategory({
    required this.icon,
    required this.title,
    required this.description,
    required this.routeName,
    required this.details,
  });

  @override
  State<_BenefitCategory> createState() => _BenefitCategoryState();
}

class _BenefitCategoryState extends State<_BenefitCategory> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.smList,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (_isExpanded) {
                setState(() => _isExpanded = !_isExpanded);
              } else {
                // Navigate to detail page on first tap
                context.pushNamed(widget.routeName);
              }
            },
            onLongPress: () {
              // Allow expanding/collapsing with long press
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.description,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.details.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            detail,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
