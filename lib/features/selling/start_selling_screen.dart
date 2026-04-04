import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// START SELLING NOW SCREEN
/// Allows users to transition from buyer to seller
/// Offers two seller paths: Member Seller or Wholesale Buyer Seller
class StartSellingScreen extends ConsumerStatefulWidget {
  const StartSellingScreen({super.key});

  @override
  ConsumerState<StartSellingScreen> createState() => _StartSellingScreenState();
}

class _StartSellingScreenState extends ConsumerState<StartSellingScreen> {
  int _selectedPath = 0; // 0 = Member, 1 = Wholesale Buyer

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Start Selling Now',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(),
              const SizedBox(height: 32),

              // Why Sell Section
              _buildWhysellSection(),
              const SizedBox(height: 32),

              // Seller Path Selection
              Text(
                'Choose Your Selling Path',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Path 1: Member Seller (Co-op Member)
              _buildSellerPathCard(
                index: 0,
                title: 'Member Seller',
                badge: 'Recommended',
                badgeColor: Colors.amber,
                description: 'Sell to Co-op Members with member pricing',
                features: [
                  '✓ Access to member-exclusive buyers',
                  '✓ Set member-only prices (10-30% discounts)',
                  '✓ Loyalty points integration',
                  '✓ Member community support',
                  '✓ Revenue sharing & dividend benefits',
                  '✓ Priority payment processing',
                ],
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),

              // Path 2: Wholesale Buyer Seller
              _buildSellerPathCard(
                index: 1,
                title: 'Wholesale Buyer Seller',
                badge: 'Volume Sales',
                badgeColor: Colors.green,
                description: 'Sell bulk orders to wholesale buyers',
                features: [
                  '✓ Reach wholesale buyers platform-wide',
                  '✓ Bulk order capabilities',
                  '✓ Wholesale pricing tiers',
                  '✓ B2B payment terms',
                  '✓ Invoice & PO management',
                  '✓ Volume-based incentives',
                ],
                color: Colors.green[700]!,
              ),
              const SizedBox(height: 32),

              // Requirements Section
              _buildRequirementsSection(),
              const SizedBox(height: 32),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'Continue with ${_selectedPath == 0 ? 'Member' : 'Wholesale Buyer'} Selling',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Learn More Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Show help/documentation
                    _showHelpDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'Learn More',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to become a seller?',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expand your business and reach more buyers',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhysellSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Sell on NCDFCOOP?',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildWhyItem(
          icon: Icons.trending_up,
          title: 'Reach More Customers',
          description: 'Access thousands of verified buyers in our platform',
        ),
        const SizedBox(height: 12),
        _buildWhyItem(
          icon: Icons.verified_user,
          title: 'Secure Transactions',
          description: 'All payments are protected and verified',
        ),
        const SizedBox(height: 12),
        _buildWhyItem(
          icon: Icons.account_balance_wallet,
          title: 'Fast Payouts',
          description: 'Get paid quickly with multiple payout options',
        ),
        const SizedBox(height: 12),
        _buildWhyItem(
          icon: Icons.headset_mic,
          title: 'Dedicated Support',
          description: 'Our team is here to help you succeed',
        ),
      ],
    );
  }

  Widget _buildWhyItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSellerPathCard({
    required int index,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required List<String> features,
    required Color color,
  }) {
    final isSelected = _selectedPath == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPath = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? color : AppColors.border,
                          width: 2,
                        ),
                        color: isSelected ? color : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 16),
            ...features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      feature,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.text),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements to Start Selling',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRequirementItem(
          number: '1',
          title: 'Active Account',
          description: 'You need a verified NCDFCOOP account',
        ),
        const SizedBox(height: 12),
        _buildRequirementItem(
          number: '2',
          title: 'Business Information',
          description: 'Provide business details and bank account',
        ),
        const SizedBox(height: 12),
        _buildRequirementItem(
          number: '3',
          title: 'Valid Products',
          description: 'Add at least one product to your inventory',
        ),
        const SizedBox(height: 12),
        _buildRequirementItem(
          number: '4',
          title: 'Verification',
          description: 'Complete identity and document verification',
        ),
      ],
    );
  }

  Widget _buildRequirementItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleContinue() {
    final sellerType = _selectedPath == 0 ? 'member' : 'wholesale';

    // Get current user
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please log in to start selling'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚀 Starting ${sellerType == 'member' ? 'Member' : 'Wholesale Buyer'} seller setup...',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate to real seller onboarding flow with seller type
    context.pushNamed(
      'seller-onboarding',
      extra: {
        'userId': user.id,
        'sellerType': sellerType,
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seller Help'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Member Seller:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  'Sell products exclusively to cooperative members with special member pricing and benefits.'),
              SizedBox(height: 16),
              Text(
                'Wholesale Buyer Seller:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  'Sell bulk orders to wholesale buyers with volume discounts and bulk order management.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
