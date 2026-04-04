import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// SCREEN 1 - SELLER ONBOARDING LANDING
/// "Start Selling on NCDF COOP"
class SellerOnboardingLandingScreen extends StatelessWidget {
  final VoidCallback onStartSelling;

  const SellerOnboardingLandingScreen({
    super.key,
    required this.onStartSelling,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'Sell Now',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Headline
                  Text(
                    'Start Selling on\nNCD COOP',
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtext
                  Text(
                    'A cooperative marketplace helping you sell locally and globally.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStartSelling,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'Start Selling',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Why NCDF COOP section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why NCDF COOP',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Benefits
                  _buildBenefitItem(
                    icon: Icons.verified_user,
                    title: 'Access to verified buyers',
                    description:
                        'Reach thousands of pre-qualified buyers who are looking for quality products.',
                  ),
                  const SizedBox(height: 20),

                  _buildBenefitItem(
                    icon: Icons.people,
                    title: 'Cooperative-based model',
                    description:
                        'Be part of a community-driven marketplace where everyone benefits.',
                  ),
                  const SizedBox(height: 20),

                  _buildBenefitItem(
                    icon: Icons.public,
                    title: 'Export support',
                    description:
                        'Get help with international shipping and compliance requirements.',
                  ),
                  const SizedBox(height: 20),

                  _buildBenefitItem(
                    icon: Icons.attach_money,
                    title: 'Transparent pricing',
                    description:
                        'No hidden fees. You always know exactly what you\'re paying.',
                  ),
                  const SizedBox(height: 32),

                  // Trust section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      border:
                          Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(
                                Icons.shield_verified,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'A Curated, Trusted Marketplace',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'NCDF COOP is not just a marketplace—it\'s a curated, 
trusted, cooperative trade platform. Every product is reviewed before going live to ensure quality and build buyer confidence.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
