import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/member_models.dart';
import '../../providers/member_providers.dart';
import '../../providers/product_providers.dart';
import '../../widgets/product_image.dart';

// ============================================================================
// MEMBER HOME SCREEN - Welcome screen for logged-in members
// ============================================================================

class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final loyaltyAsync = ref.watch(memberLoyaltyProvider);
    final benefitsAsync = ref.watch(memberTierBenefitsProvider);
    final featuredProductsAsync = ref.watch(featuredProductsProvider);
    final unreadCountAsync = ref.watch(memberUnreadCountProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Member Header with greeting
              memberAsync.when(
                data: (member) => _buildMemberHeader(member),
                loading: () => _buildHeaderSkeleton(),
                error: (e, st) => _buildHeaderError(e.toString()),
              ),

              const SizedBox(height: 20),

              // 2. Loyalty Card
              loyaltyAsync.when(
                data: (loyalty) => _buildLoyaltyCard(loyalty),
                loading: () => _buildLoyaltyCardSkeleton(),
                error: (e, st) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              // 3. Benefits Banner
              benefitsAsync.when(
                data: (benefits) => _buildBenefitsBanner(context, benefits),
                loading: () => _buildBenefitsSkeleton(),
                error: (e, st) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              // 4. Member-Only Deals
              _buildMemberDeals(context),

              const SizedBox(height: 20),

              // 5. Recommendations
              featuredProductsAsync.when(
                data: (products) => _buildRecommendations(context, products),
                loading: () => _buildRecommendationsSkeleton(),
                error: (e, st) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              // 6. Recent Orders Quick Access
              _buildRecentOrdersSection(context),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // BUILD METHODS
  // ========================================================================

  Widget _buildMemberHeader(Member? member) {
    if (member == null) return _buildHeaderError('Member not found');

    // Calculate days as member
    final now = DateTime.now();
    final membershipDuration = now.difference(member.memberSince).inDays;
    final membershipYears = membershipDuration ~/ 365;
    final membershipMonths = (membershipDuration % 365) ~/ 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                    'Welcome, ${member.firstName}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    membershipYears > 0
                        ? 'Member for $membershipYears year${membershipYears > 1 ? 's' : ''}'
                        : membershipMonths > 0
                            ? 'Member for $membershipMonths month${membershipMonths > 1 ? 's' : ''}'
                            : 'New member',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        color: Colors.greenAccent.shade400,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Save 20% on all items this week',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.greenAccent.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.memberTier,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Member',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyCard(MemberLoyalty? loyalty) {
    if (loyalty == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.amber.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
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
              const Text(
                'Loyalty Points',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${loyalty.currentPoints} pts',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: loyalty.progressToNextTier,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(
                Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(loyalty.pointsNeededForNextTier - loyalty.currentPoints).clamp(0, loyalty.pointsNeededForNextTier)} points to ${loyalty.nextTier}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsBanner(
    BuildContext context,
    List<MemberBenefit> benefits,
  ) {
    if (benefits.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Benefits',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: benefits.length > 4 ? 4 : benefits.length,
              itemBuilder: (context, index) {
                final benefit = benefits[index];
                return GestureDetector(
                  onTap: () => context.pushNamed(
                    'member-benefits',
                    extra: benefit.id,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          benefit.name,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberDeals(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Member-Only Deals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Save 20% on all items this week',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Members only exclusive offer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, List<dynamic> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended For You',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length > 5 ? 5 : products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                // Extract product data
                final productId = product['id'] ?? 'unknown';
                final productName = product['name'] ?? 'Product';
                final imageUrl = product['imageUrl'] ?? '';

                // Get price - handle both string and double formats
                dynamic priceValue =
                    product['retailPrice'] ?? product['price'] ?? 0;
                final price = priceValue is String
                    ? double.tryParse(priceValue) ?? 0.0
                    : (priceValue as num).toDouble();
                return GestureDetector(
                  onTap: () => context.goNamed(
                    'product-detail',
                    pathParameters: {'productId': productId},
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                          child: imageUrl.isNotEmpty
                              ? ProductImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Icon(
                                    Icons.shopping_bag,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                productName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₦${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Member Deal',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.pushNamed('member-order-history'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #12345',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Delivered • Jan 28',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '\$125.50',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // SKELETON LOADERS
  // ========================================================================

  Widget _buildHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade300,
      height: 100,
    );
  }

  Widget _buildHeaderError(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text('Error: $error'),
    );
  }

  Widget _buildLoyaltyCardSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildBenefitsSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildRecommendationsSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
