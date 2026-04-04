import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// OFFERS & DEALS SCREEN
/// Shows member exclusive offers, flash deals, and promotions
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '🎁 Offers & Deals',
          style: AppTextStyles.h3.copyWith(color: AppColors.text),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search deals...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Flash Deals Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚡ Flash Deals (Today Only)',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOfferCard(
                    title: 'Fresh Vegetables Bundle',
                    discount: '-30%',
                    description: 'Save ₦2,500 on fresh farm produce',
                    expiresIn: 'Ends in 3 hours',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildOfferCard(
                    title: 'Premium Grains Package',
                    discount: '-25%',
                    description: 'Bulk buy at wholesale rates',
                    expiresIn: 'Ends in 5 hours',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Member Exclusive Offers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⭐ Member Exclusive',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOfferCard(
                    title: 'Double Points Weekend',
                    discount: '2x Points',
                    description: 'Earn 2 points for every ₦1 spent',
                    expiresIn: 'This weekend',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildOfferCard(
                    title: 'Free Shipping for Orders ₦5000+',
                    discount: 'Free',
                    description: 'No minimum order during member week',
                    expiresIn: 'Until Friday',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tier-Based Offers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏅 Your Tier Benefits',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOfferCard(
                    title: 'Birthday Month Special',
                    discount: '-15%',
                    description:
                        'Get 15% off on everything in your birth month',
                    expiresIn: 'Valid year-round',
                    color: Colors.pink,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80), // Bottom nav padding
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard({
    required String title,
    required String discount,
    required String description,
    required String expiresIn,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.05),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  expiresIn,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  discount,
                  style: AppTextStyles.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
