import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/providers/home_providers.dart';
import '../../../core/intelligence/role_commerce_intelligence.dart';
import '../../../providers/savings_provider.dart';
import '../../../core/widgets/dashboard_motion.dart';
import '../../../core/services/user_activity_service.dart';
import '../../../providers/user_activity_providers.dart';

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
    final activityAsync = user == null
        ? const AsyncValue<List<UserActivity>>.data([])
        : ref.watch(userActivityTimelineProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: memberData.when(
            data: (data) {
              final displayData = data;

              if (displayData == null) {
                final isSignedIn = user != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: .35),
                          ),
                        ),
                        child: Text(
                          isSignedIn
                              ? 'Your member benefits profile is still syncing. You can continue shopping and contacting sellers now.'
                              : 'Sign in to purchase products and contact sellers.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ),
                    _buildRecentlyBrowsedProductsSection(
                      context,
                      featuredAsync,
                    ),
                    const SizedBox(height: 16),
                    _buildRoleRelationshipIntelligence(
                      context,
                      featuredAsync,
                    ),
                    const SizedBox(height: 80),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardReveal(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildMemberHero(
                        context,
                        user?.name ?? 'Member',
                        displayData.tier,
                        displayData.rewardsPoints,
                        displayData.ordersCount,
                      ),
                    ),
                  ),
                  if (false)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.84),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${user?.name.split(' ').first ?? 'member'}',
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${displayData.tier.toUpperCase()} member • ${displayData.rewardsPoints} points • ${displayData.ordersCount} orders',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildMembershipTierBanner(
                    context,
                    displayData.tier,
                    displayData.rewardsPoints,
                    displayData.isActive,
                  ),

                  const SizedBox(height: 14),
                  _buildRecentActivity(context, activityAsync),

                  const SizedBox(height: 18),
                  _buildRecentlyBrowsedProductsSection(context, featuredAsync),

                  const SizedBox(height: 16),

                  _buildPlaceholderProductsSection(context, featuredAsync),

                  const SizedBox(height: 24),

                  _buildRoleRelationshipIntelligence(context, featuredAsync),

                  const SizedBox(height: 24),

                  // ═════════════════════════════════════════════════
                  // 2. QUICK ACTIONS - Points & Rewards
                  // ═════════════════════════════════════════════════
                  _buildLoyaltyActionsGrid(context, ref, user?.id ?? ''),

                  const SizedBox(height: 24),

                  // ═════════════════════════════════════════════════
                  // 4. VOTING & GOVERNANCE - Community involvement
                  // ═════════════════════════════════════════════════

                  // ═════════════════════════════════════════════════
                  // 5. TRANSPARENCY & REPORTS - Cooperative financials
                  // ═════════════════════════════════════════════════

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
            error: (err, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Member benefits are temporarily unavailable. No balances, points, or status will be estimated.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _buildRecentlyBrowsedProductsSection(context, featuredAsync),
                  const SizedBox(height: 16),
                  _buildPlaceholderProductsSection(context, featuredAsync),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: user == null
                          ? null
                          : () => ref.invalidate(memberDataProvider(user.id)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry member data'),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    AsyncValue<List<UserActivity>> activityAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DashboardReveal(
        delay: const Duration(milliseconds: 110),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.history_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Your recent CoopX activity', style: AppTextStyles.h4),
              ]),
              const SizedBox(height: 12),
              activityAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text(
                  'Activity is temporarily unavailable. Pull to refresh shortly.',
                ),
                data: (activities) {
                  if (activities.isEmpty) {
                    return const Text(
                      'Your purchases, product views, searches and rewards activity will appear here.',
                      style: TextStyle(color: AppColors.textSecondary),
                    );
                  }
                  return Column(
                    children: activities.take(4).map((activity) {
                      final title = activity.productName?.trim().isNotEmpty ==
                              true
                          ? activity.productName!
                          : activity.activityType
                              .replaceAll('_', ' ')
                              .split(' ')
                              .map((word) => word.isEmpty
                                  ? word
                                  : '${word[0].toUpperCase()}${word.substring(1)}')
                              .join(' ');
                      final date = MaterialLocalizations.of(context)
                          .formatShortDate(activity.timestamp.toLocal());
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE4F4ED),
                          child: Icon(Icons.bolt_rounded,
                              color: AppColors.primary, size: 19),
                        ),
                        title: Text(title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(date),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods (continued from build method)

  Widget _buildMemberHero(
    BuildContext context,
    String name,
    String tier,
    int points,
    int orders,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF502B08), Color(0xFFA26214), Color(0xFFE1A42E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38A26214),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -38,
            child: Icon(
              Icons.diversity_3_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_outlined,
                            size: 15, color: Color(0xFFFFE5A3)),
                        const SizedBox(width: 6),
                        Text(
                          '${tier.toUpperCase()} MEMBER',
                          style: const TextStyle(
                            color: Color(0xFFFFE5A3),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFFFFE5A3)),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Good to see you, ${name.split(' ').first}',
                style: AppTextStyles.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.55,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Member prices, trusted sellers and cooperative rewards—all connected to your account.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: .82),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _memberMetric('$points', 'Points'),
                  const SizedBox(width: 9),
                  _memberMetric('$orders', 'Orders'),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => context.pushNamed('products'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6E3E09),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: const Text('Shop'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memberMetric(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .72), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMembershipTierBanner(
    BuildContext context,
    String currentTier,
    int points,
    bool isActive,
  ) {
    final tier = currentTier.trim().isEmpty ? 'Bronze' : currentTier;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF073F34), Color(0xFF008A67), Color(0xFFF2B441)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33006448),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pushNamed('premium-membership'),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD65A),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tier.toUpperCase()} MEMBER',
                        style: const TextStyle(
                          color: Color(0xFFFFE39A),
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isActive
                            ? 'Membership active'
                            : 'Membership awaiting activation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$points points · Compare Bronze, Silver, Gold & Platinum',
                        maxLines: 2,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyBrowsedProductsSection(
    BuildContext context,
    AsyncValue<List<Product>> featuredAsync,
  ) {
    return _buildHorizontalProductSection(
      context: context,
      featuredAsync: featuredAsync,
      title: 'Live Member Marketplace',
      emptyMessage: 'No live retail products are available yet',
      maxItems: 6,
      showActionButton: false,
    );
  }

  Widget _buildRoleRelationshipIntelligence(
    BuildContext context,
    AsyncValue<List<Product>> featuredAsync,
  ) {
    return featuredAsync.when(
      data: (products) {
        final snapshot = RoleCommerceIntelligence.member(products);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Role Intelligence: Member x Seller x Wholesale',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _insightPill(
                    'Live SKUs ${snapshot.actionableSkus}',
                    Icons.inventory_2_outlined,
                    onTap: () => _handleInsightTap(
                      context,
                      routeName: 'products',
                      label: 'product catalog',
                    ),
                  ),
                  _insightPill(
                    'Restock risk ${snapshot.restockRiskSkus}',
                    Icons.trending_down,
                    onTap: () => _handleInsightTap(
                      context,
                      routeName: 'products',
                      label: 'restock watchlist',
                    ),
                  ),
                  _insightPill(
                    'Trust picks ${snapshot.trustQualifiedSkus}',
                    Icons.verified_outlined,
                    onTap: () => _handleInsightTap(
                      context,
                      routeName: 'my-rewards',
                      label: 'trusted picks',
                    ),
                  ),
                  _insightPill(
                    'Avg member edge ${snapshot.valueSpreadPercent.toStringAsFixed(1)}%',
                    Icons.savings_outlined,
                    onTap: () => _handleInsightTap(
                      context,
                      routeName: 'membership',
                      label: 'membership savings',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                snapshot.narrative,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _insightPill(
    String label,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleInsightTap(
    BuildContext context, {
    required String routeName,
    required String label,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $label...'),
        duration: const Duration(milliseconds: 900),
      ),
    );

    try {
      context.pushNamed(routeName);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action is temporarily unavailable. Please retry.'),
        ),
      );
    }
  }

  Widget _buildPlaceholderProductsSection(
    BuildContext context,
    AsyncValue<List<Product>> featuredAsync,
  ) {
    return _buildHorizontalProductSection(
      context: context,
      featuredAsync: featuredAsync,
      title: 'Recommended For You',
      emptyMessage: 'Products will appear here shortly',
      maxItems: 8,
      showActionButton: true,
    );
  }

  Widget _buildHorizontalProductSection({
    required BuildContext context,
    required AsyncValue<List<Product>> featuredAsync,
    required String title,
    required String emptyMessage,
    required int maxItems,
    required bool showActionButton,
  }) {
    return featuredAsync.when(
      data: (products) {
        final sectionProducts = products
            .where(
              (product) =>
                  product.id.trim().isNotEmpty &&
                  product.name.trim().isNotEmpty,
            )
            .take(maxItems)
            .toList();
        if (sectionProducts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              emptyMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.pushNamed('products'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('See all'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 294,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sectionProducts.length,
                itemBuilder: (context, index) {
                  final product = sectionProducts[index];
                  return _ProductPlaceholderCard(
                    product: product,
                    showActionButton: showActionButton,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SizedBox(
            height: 60, child: Center(child: CircularProgressIndicator())),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Unable to load products right now',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(BuildContext context, dynamic data, dynamic user) {
    final points = data?.rewardsPoints ?? 0;
    final tier = data?.tier ?? user?.membershipTier ?? 'bronze';
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
                    'Membership Status',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View in Profile',
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.pushNamed('my-ncdfcoop'),
              icon: const Icon(Icons.person_outline, color: Colors.white),
              label: const Text(
                'Tier details in profile',
                style: TextStyle(color: Colors.white),
              ),
            ),
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
                const Icon(Icons.verified_outlined, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Verified financial and impact reports will appear here when published by the cooperative.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
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
      data: (products) {
        final validProducts =
            products.where((product) => product.id.trim().isNotEmpty).toList();
        return validProducts.isEmpty
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
                height: 252,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: validProducts.length,
                  itemBuilder: (context, index) {
                    final product = validProducts[index];
                    return _ProductCard(product: product, context: context);
                  },
                ),
              );
      },
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
      data: (products) {
        final validProducts =
            products.where((product) => product.id.trim().isNotEmpty).toList();
        return validProducts.isEmpty
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
                    childAspectRatio: 0.67,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: validProducts.length,
                  itemBuilder: (context, index) {
                    final product = validProducts[index];
                    return _ProductGridItem(product: product, context: context);
                  },
                ),
              );
      },
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
    final savings = _computeSavingsPercent(product);
    final soldText = _estimateSoldText(product);

    return GestureDetector(
      onTap: () {
        final productId = product.id.trim();
        if (productId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product details are unavailable.')),
          );
          return;
        }
        context.goNamed(
          'product-detail',
          pathParameters: {'productId': productId},
        );
      },
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _ProductImage(imageUrl: product.imageUrl),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD84315),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Top Deal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          soldText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
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
                  const SizedBox(height: 2),
                  if (product.retailPrice > 0)
                    Text(
                      '₦${product.retailPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    _formatProductPrice(product),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFD84315),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (savings > 0)
                    Text(
                      'Save $savings%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        final productId = product.id.trim();
                        if (productId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product details are unavailable.'),
                            ),
                          );
                          return;
                        }
                        context.goNamed(
                          'product-detail',
                          pathParameters: {'productId': productId},
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(fontSize: 11),
                      ),
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
    final savings = _computeSavingsPercent(product);
    final soldText = _estimateSoldText(product);

    return GestureDetector(
      onTap: () {
        final productId = product.id.trim();
        if (productId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product details are unavailable.')),
          );
          return;
        }
        context.goNamed(
          'product-detail',
          pathParameters: {'productId': productId},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _ProductImage(imageUrl: product.imageUrl),
                    ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD84315),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Hot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.58),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          soldText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.retailPrice > 0)
                    Text(
                      '₦${product.retailPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    _formatProductPrice(product),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFD84315),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (savings > 0)
                    Text(
                      'Save $savings%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final productId = product.id.trim();
                        if (productId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product details are unavailable.'),
                            ),
                          );
                          return;
                        }
                        context.goNamed(
                          'product-detail',
                          pathParameters: {'productId': productId},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: const Color(0xFFD84315),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Buy'),
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

class _ProductPlaceholderCard extends StatelessWidget {
  final Product product;
  final bool showActionButton;

  const _ProductPlaceholderCard({
    required this.product,
    required this.showActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final savings = _computeSavingsPercent(product);

    return GestureDetector(
      onTap: () {
        final productId = product.id.trim();
        if (productId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product details are unavailable.')),
          );
          return;
        }
        context.goNamed(
          'product-detail',
          pathParameters: {'productId': productId},
        );
      },
      child: Container(
        width: 188,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: Container(
                height: 136,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _ProductImage(imageUrl: product.imageUrl),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Member Deal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.categoryId.isEmpty
                        ? 'General Merchandise'
                        : product.categoryId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatProductPrice(product),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFD84315),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (savings > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Save $savings% vs retail',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (showActionButton)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final productId = product.id.trim();
                          if (productId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Product details are unavailable.'),
                              ),
                            );
                            return;
                          }
                          context.goNamed(
                            'product-detail',
                            pathParameters: {'productId': productId},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD84315),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 15),
                        label: const Text('View & Buy'),
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

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    if (url.isEmpty) {
      return _buildFallbackProductVisual();
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackProductVisual(),
      );
    }

    // Avoid known unstable placeholder hosts that can throw SSL handshake errors on-device.
    if (url.contains('via.placeholder.com')) {
      return _buildFallbackProductVisual();
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, _, __) => _buildFallbackProductVisual(),
    );
  }

  Widget _buildFallbackProductVisual() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE5E7EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                color: Colors.grey.shade500, size: 28),
            const SizedBox(height: 6),
            Text(
              'COOPX PRODUCT',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatProductPrice(Product product) {
  final memberPrice = product.wholesalePrice > 0
      ? product.wholesalePrice
      : (product.retailPrice > 0 ? product.retailPrice : 0);

  if (memberPrice <= 0) {
    return 'Price on request';
  }

  return '₦${memberPrice.toStringAsFixed(0)}';
}

int _computeSavingsPercent(Product product) {
  if (product.retailPrice <= 0 || product.wholesalePrice <= 0) {
    return 0;
  }

  final savings = ((product.retailPrice - product.wholesalePrice) /
          product.retailPrice *
          100)
      .round();
  return savings.clamp(0, 99);
}

String _estimateSoldText(Product product) {
  final base = product.stock <= 0 ? 86 : product.stock * 3;
  if (base >= 1000) {
    return '${(base / 1000).toStringAsFixed(1)}k sold';
  }
  return '$base sold';
}
