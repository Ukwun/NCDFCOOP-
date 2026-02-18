import 'package:flutter/material.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Exclusive Pricing Benefits Detail Page
class ExclusivePricingPage extends StatelessWidget {
  const ExclusivePricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Exclusive Pricing',
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.local_offer,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Save Up to 40%',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Exclusive member pricing on all products - save money on every purchase',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Benefits List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBenefitItem(
                    '✓ Member-only pricing',
                    'Access prices not available to non-members',
                  ),
                  _buildBenefitItem(
                    '✓ Automatic savings',
                    'Discounts applied instantly at checkout',
                  ),
                  _buildBenefitItem(
                    '✓ Savings tracking',
                    'See how much you save with real-time tracking',
                  ),
                  _buildBenefitItem(
                    '✓ Bundle discounts',
                    'Save even more when buying multiple items',
                  ),
                  _buildBenefitItem(
                    '✓ Seasonal promotions',
                    'Extra discounts during special seasons',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // How It Works
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How It Works',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStep('1', 'Browse products', 'Visit any product page'),
                  _buildStep(
                      '2', 'Check prices', 'Compare member vs market price'),
                  _buildStep(
                      '3', 'Add to cart', 'Member price applied automatically'),
                  _buildStep('4', 'Save money', 'See savings at checkout'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
