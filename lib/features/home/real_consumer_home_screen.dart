import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/membership_provider.dart';
import '../../providers/real_products_provider.dart';
import '../../models/real_product_model.dart';

class RealConsumerHomeScreen extends ConsumerWidget {
  const RealConsumerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final membershipTier = ref.watch(userMembershipTierProvider);
    final membershipExpiry = ref.watch(userMembershipExpiryProvider);
    final totalSavings = ref.watch(totalPotentialSavingsProvider);
    final exclusiveProducts =
        ref.watch(memberExclusiveProductsProvider);
    final allProducts = ref.watch(productsWithMemberPricingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          user?.name ?? 'Welcome',
          style: AppTextStyles.h4,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personalized Welcome Section
            if (membershipTier.value != null)
              _buildMembershipBanner(
                context,
                ref,
                user?.name ?? 'Member',
                membershipTier.value!,
                membershipExpiry,
                totalSavings,
              )
            else
              _buildUpgradePrompt(context),

            // Featured Products Section
            if (membershipTier.value != null &&
                membershipTier.value != 'basic')
              _buildExclusiveSection(context, exclusiveProducts),

            // All Products with Real Pricing
            _buildProductsSection(context, allProducts),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipBanner(
    BuildContext context,
    WidgetRef ref,
    String userName,
    String tier,
    AsyncValue<DateTime?> expiryAsync,
    AsyncValue<double> savingsAsync,
  ) {
    final tierColors = {
      'gold': Colors.amber,
      'platinum': Colors.grey[400],
      'basic': Colors.green,
    };

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                    'Welcome back, $userName! 👋',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tierColors[tier]?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tier.toUpperCase()} Member',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: tierColors[tier],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Icon(
                tier == 'platinum'
                    ? Icons.star
                    : tier == 'gold'
                        ? Icons.workspace_premium
                        : Icons.verified,
                color: tierColors[tier],
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Real Savings Display
          savingsAsync.when(
            data: (totalSavings) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Membership Savings',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${totalSavings.toStringAsFixed(0)}',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    'potential savings across all products',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.md),

          // Membership Expiry Info
          expiryAsync.when(
            data: (expiry) {
              if (expiry == null) return const SizedBox.shrink();
              final daysLeft = expiry.difference(DateTime.now()).inDays;
              return Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Membership renews in $daysLeft days',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.blue[700],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unlock Member Benefits 🎁',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Join our membership program to get exclusive products, special pricing, and more!',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => context.push('/premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Explore Membership',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExclusiveSection(
    BuildContext context,
    AsyncValue<List<Product>> exclusiveAsync,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Member-Exclusive Products',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.md),
          exclusiveAsync.when(
            data: (products) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: products
                    .map((product) =>
                        _buildProductCard(context, product))
                    .toList(),
              ),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const Text('Error loading products'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(
    BuildContext context,
    AsyncValue<List<Product>> productsAsync,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Products',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.md),
          productsAsync.when(
            data: (products) => Column(
              children: products
                  .map((product) => _buildProductListItem(context, product))
                  .toList(),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const Text('Error loading products'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              color: Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.shopping_bag,
                  color: Colors.grey[400],
                  size: 40,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${product.regularPrice.toInt()}',
                    style: AppTextStyles.bodySmall.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '₦${product.memberGoldPrice?.toInt() ?? product.regularPrice.toInt()}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
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

  Widget _buildProductListItem(BuildContext context, Product product) {
    final isMemberExclusive = product.isMemberExclusive;

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: isMemberExclusive ? Colors.amber.withOpacity(0.3) : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isMemberExclusive ? Colors.amber.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.shopping_bag,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: AppTextStyles.labelMedium,
                        ),
                      ),
                      if (isMemberExclusive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'EXCLUSIVE',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₦${product.regularPrice.toInt()}',
                        style: AppTextStyles.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₦${product.memberGoldPrice?.toInt() ?? product.regularPrice.toInt()}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save ₦${(product.regularPrice - (product.memberGoldPrice ?? product.regularPrice)).toInt()}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
