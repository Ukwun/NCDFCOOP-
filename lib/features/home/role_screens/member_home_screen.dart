import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/providers/home_providers.dart';
import '../../../providers/savings_provider.dart';

/// MEMBER HOME SCREEN
/// Co-operative members with loyalty benefits
/// Focus: Loyalty points, tier progression, savings tracking, voting, transparency
/// Shopping is secondary - loyalty engagement is primary
class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Get role-specific featured products for members
    final userRole = 'coopMember';
    final memberData = ref.watch(memberDataProvider(user?.id ?? ''));
    final featuredAsync =
        ref.watch(roleAwareFeaturedProductsProvider(userRole));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: memberData.when(
            data: (data) {
              // Handle null member data - create fallback from current user
              final displayData = data ??
                  (user != null
                      ? MemberData(
                          memberId: user.id,
                          tier: 'bronze',
                          rewardsPoints: 0,
                          lifetimePoints: 0,
                          memberSince: DateTime.now(),
                          isActive: true,
                          discountPercentage: 0.0,
                          ordersCount: 0,
                          totalSpent: 0.0,
                        )
                      : null);

              // If still no data, show error
              if (displayData == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.person_off,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Not Logged In',
                        style: AppTextStyles.h2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please log in to view member benefits.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.go('/signin');
                        },
                        child: const Text('Log In'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DEBUG: Clear role identifier
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.purple[800],
                    child: Text(
                      '♥️ MEMBER HOME (Loyalty Focused)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // ═════════════════════════════════════════════════
                  // 1. LOYALTY CARD - CENTER PIECE (Tier + Points)
                  // ═════════════════════════════════════════════════
                  _buildLoyaltyCard(context, displayData, user),

                  const SizedBox(height: 24),

                  // ═════════════════════════════════════════════════
                  // 2. SAVINGS & IMPACT - Show member value
                  // ═════════════════════════════════════════════════
                  _buildSavingsAndImpactSection(
                    context,
                    ref,
                    displayData,
                    user?.id ?? '',
                  ),

                  const SizedBox(height: 24),

                  // ═════════════════════════════════════════════════
                  // 3. QUICK ACTIONS - Points & Rewards
                  // ═════════════════════════════════════════════════
                  _buildLoyaltyActionsGrid(context, ref, user?.id ?? ''),

                  const SizedBox(height: 24),

                  // ═════════════════════════════════════════════════
                  // 4. VOTING & GOVERNANCE - Community involvement
                  // ═════════════════════════════════════════════════
                  _buildVotingEngagementSection(context),

                  const SizedBox(height: 24),

                  // ═════════════════════════════════════════════════
                  // 5. TRANSPARENCY & REPORTS - Cooperative financials
                  // ═════════════════════════════════════════════════
                  _buildTransparencyReportsSection(context),

                  const SizedBox(height: 24),

                  // ═════════════════════════════════════════════════
                  // 6. EXCLUSIVE MEMBER DEALS - Secondary to loyalty
                  // ═════════════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Exclusive Member Deals',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildExclusiveDealsList(context, featuredAsync),

                  const SizedBox(height: 24),

                  // ═════════════════════════════════════════════════
                  // 7. SHOPPING SECONDARY - All Products
                  // ═════════════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Shop All Member Products',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMemberProductsList(context, featuredAsync),

                  const SizedBox(height: 24),
                  const SizedBox(height: 80), // Bottom padding for nav bar
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('Error loading member data: $err'),
            ),
          ),
        ),
      ),
    );
  }

  // Helper Methods (continued from build method)

  Widget _buildLoyaltyCard(BuildContext context, dynamic data, dynamic user) {
    final tier = (data?.tier ?? 'BRONZE').toUpperCase();
    final points = data?.rewardsPoints ?? 0;
    final tierColor = _getTierColor(tier);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColor, tierColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                    'Your Tier',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tier,
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_membership,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Points',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$points',
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.pushNamed('my-rewards'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Redeem',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsAndImpactSection(
    BuildContext context,
    WidgetRef ref,
    dynamic data,
    String userId,
  ) {
    final totalSpent = data?.totalSpent ?? 0.0;
    final savingsPercentage = data?.discountPercentage ?? 5.0;
    final estimatedSavings = totalSpent * (savingsPercentage / 100);
    final savingsGoal = 50000.0; // Example goal: ₦50,000
    final currentSavings = estimatedSavings; // Current accumulated savings
    final goalProgress = (currentSavings / savingsGoal * 100).clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // SAVINGS CARDS - Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SavingsCard(
                  label: 'Total Spent',
                  value: '₦${(totalSpent).toStringAsFixed(0)}',
                  icon: Icons.shopping_bag_outlined,
                ),
                _SavingsCard(
                  label: 'Saved This Year',
                  value: '₦${estimatedSavings.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                _SavingsCard(
                  label: 'Discount Rate',
                  value: '${savingsPercentage.toStringAsFixed(0)}%',
                  icon: Icons.local_offer_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SAVINGS GOAL TRACKER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
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
                          'Savings Goal',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₦${savingsGoal.toStringAsFixed(0)}',
                          style: AppTextStyles.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${goalProgress.toStringAsFixed(0)}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goalProgress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Goal Status
                Text(
                  'You have saved ₦${currentSavings.toStringAsFixed(0)} towards your goal',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // DEPOSIT MONEY BUTTON - PROMINENT ACTION
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Show deposit dialog
                _showDepositDialog(context, ref, userId);
              },
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text(
                'Deposit Money to Savings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog(BuildContext context, WidgetRef ref, String userId) {
    final depositController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deposit to Savings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: depositController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₦)',
                prefixText: '₦',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: '5,000',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Funds will be secured in your savings account',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = _parseCurrencyAmount(depositController.text);
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Enter a valid amount to deposit')),
                );
                return;
              }
              if (userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Sign in required to deposit funds')),
                );
                return;
              }

              try {
                await ref
                    .read(
                      depositToSavingsProvider((
                        userId: userId,
                        amount: amount,
                        description: 'Member savings deposit',
                        source: 'member_home',
                      )).future,
                    )
                    .timeout(const Duration(seconds: 20));

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Deposit successful: ₦${amount.toStringAsFixed(0)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deposit failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text('Confirm Deposit'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, WidgetRef ref, String userId) {
    final withdrawController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw from Savings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: withdrawController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (\u20a6)',
                prefixText: '\u20a6',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: '5,000',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Funds will be transferred to your registered account',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Processing time: 1-3 business days',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = _parseCurrencyAmount(withdrawController.text);
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Enter a valid amount to withdraw')),
                );
                return;
              }
              if (userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Sign in required to withdraw funds')),
                );
                return;
              }

              try {
                await ref
                    .read(
                      withdrawFromSavingsProvider((
                        userId: userId,
                        amount: amount,
                        description: 'Member savings withdrawal',
                        accountNumber: null,
                      )).future,
                    )
                    .timeout(const Duration(seconds: 20));

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Withdrawal request submitted: ₦${amount.toStringAsFixed(0)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Withdrawal failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Confirm Withdrawal'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyActionsGrid(
      BuildContext context, WidgetRef ref, String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Rewards, Benefits, Refer
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.pushNamed('my-rewards'),
                  child: _ActionButton(
                    icon: Icons.card_giftcard,
                    label: 'Redeem\nRewards',
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.pushNamed('member-benefits'),
                  child: _ActionButton(
                    icon: Icons.star,
                    label: 'Your\nBenefits',
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.pushNamed('member-loyalty'),
                  child: _ActionButton(
                    icon: Icons.people_alt_outlined,
                    label: 'Refer &\nEarn',
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Quick Deposit and Withdrawal
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showDepositDialog(context, ref, userId),
                  child: _ActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Quick\nDeposit',
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showWithdrawDialog(context, ref, userId),
                  child: _ActionButton(
                    icon: Icons.remove_circle_outline,
                    label: 'Quick\nWithdraw',
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.pushNamed('member-savings'),
                  child: _ActionButton(
                    icon: Icons.trending_up,
                    label: 'My\nSavings',
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVotingEngagementSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.how_to_vote,
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
                    'Upcoming Voting',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3 votes open • Annual board election & budget approval',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.pushNamed('member-voting'),
              child: Text(
                'Vote',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparencyReportsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cooperative Transparency',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pushNamed('member-transparency'),
                  child: Text(
                    'View All',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReportItem(
              title: 'Annual Financials (2025)',
              subtitle: 'Revenue ₦2.5M | Members 5,000',
              onTap: () => context.pushNamed('member-transparency'),
            ),
            const SizedBox(height: 8),
            _ReportItem(
              title: 'Impact Report (Q4 2025)',
              subtitle: 'Savings distributed: ₦850K',
              onTap: () => context.pushNamed('member-transparency'),
            ),
            const SizedBox(height: 8),
            _ReportItem(
              title: 'Farmer Support Fund',
              subtitle: 'Allocated ₦250K for smallholder support',
              onTap: () => context.pushNamed('member-transparency'),
            ),
          ],
        ),
      ),
    );
  }

  double _parseCurrencyAmount(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0;
  }

  Widget _buildExclusiveDealsList(
    BuildContext context,
    AsyncValue<List<Product>> featuredAsync,
  ) {
    return featuredAsync.when(
      data: (products) => products.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No exclusive deals available',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            )
          : SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _ProductCard(product: product, context: context);
                },
              ),
            ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Error loading deals',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildMemberProductsList(
    BuildContext context,
    AsyncValue<List<Product>> featuredAsync,
  ) {
    return featuredAsync.when(
      data: (products) => products.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No products available for members',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _ProductGridItem(product: product, context: context);
                },
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text(
        'Error loading products',
        style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
      ),
    );
  }

  Color _getTierColor(String tier) {
    return switch (tier) {
      'PLATINUM' => Colors.purple,
      'GOLD' => Colors.amber,
      'SILVER' => Colors.grey[400] ?? Colors.grey,
      _ => Colors.brown[300] ?? Colors.brown,
    };
  }
}

// Reusable widgets
class _SavingsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _SavingsCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color ?? AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: AppColors.textLight, size: 14),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final BuildContext context;

  const _ProductCard({required this.product, required this.context});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed(
        'product-detail',
        pathParameters: {'productId': product.id},
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: product.imageUrl != null
                    ? Image(
                        image: product.imageUrl!.startsWith('assets/')
                            ? AssetImage(product.imageUrl!)
                            : NetworkImage(product.imageUrl!) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.image, color: Colors.grey[300]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${product.wholesalePrice.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // closes Container
    ); // closes GestureDetector
  }
}

class _ProductGridItem extends StatelessWidget {
  final Product product;
  final BuildContext context;

  const _ProductGridItem({required this.product, required this.context});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed(
        'product-detail',
        pathParameters: {'productId': product.id},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: product.imageUrl != null
                    ? Image(
                        image: product.imageUrl!.startsWith('assets/')
                            ? AssetImage(product.imageUrl!)
                            : NetworkImage(product.imageUrl!) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.image, color: Colors.grey[300]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${product.wholesalePrice.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall.copyWith(
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
}
