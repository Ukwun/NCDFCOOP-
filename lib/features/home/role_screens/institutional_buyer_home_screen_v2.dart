import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/models/product.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/core/providers/home_providers.dart';
import 'package:coop_commerce/core/providers/product_providers.dart';
import 'package:coop_commerce/providers/user_activity_providers.dart';

/// INSTITUTIONAL BUYER HOME SCREEN - REDESIGNED
/// Corporate, government, institutional buyers
/// Focus: PO management, approval workflows, bulk planning, spend analytics
/// Key differentiator: IN-APP approval workflows (department head must approve before submission)
class InstitutionalBuyerHomeScreenV2 extends ConsumerWidget {
  const InstitutionalBuyerHomeScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final allProductsAsync = ref.watch(allProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final recommendedProductIdsAsync = user == null
        ? const AsyncValue<List<String>>.data(<String>[])
        : ref.watch(userRecommendedProductsProvider(user.id));
    final favoriteCategoriesAsync = user == null
        ? const AsyncValue<List<String>>.data(<String>[])
        : ref.watch(userFavoriteCategoriesProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
                child: _buildContractStatusBanner(context, user)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildPendingApprovalsAlert(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildCreatePoButton(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: _buildRecommendedProductsSection(
                context,
                ref,
                allProductsAsync,
                categoriesAsync,
                recommendedProductIdsAsync,
                favoriteCategoriesAsync,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: _buildTopDealsSection(context, ref, allProductsAsync),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildPoStatusDashboard(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildBulkPlanningSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: _buildTailoredSelectionSection(
                context,
                ref,
                allProductsAsync,
                recommendedProductIdsAsync,
                favoriteCategoriesAsync,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildInvoicingSection(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HELPER METHODS - B2B Procurement Focused
  // ═════════════════════════════════════════════════════════════════════════

  /// 1. CONTRACT STATUS BANNER
  Widget _buildContractStatusBanner(BuildContext context, dynamic user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
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
                    'Contract Status',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Active • Expires Dec 31, 2025',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✓ Live',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Contract ID: CT-2024-001 | Payment Terms: Net-30',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. PENDING APPROVALS ALERT
  Widget _buildPendingApprovalsAlert(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.hourglass_empty,
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
                    '2 POs Pending Approval',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Department heads need to review and approve before submission',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.pushNamed('approval-dashboard'),
              child: Text(
                'Review',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. CREATE NEW PO BUTTON (Big, prominent call-to-action)
  Widget _buildCreatePoButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => context.pushNamed('institutional-po-create'),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Create New Purchase Order'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            textStyle: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  /// 5. PO DASHBOARD
  Widget _buildPoStatusDashboard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Purchase Orders',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('institutional-po-list'),
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
          _PoStatusCard(
            poNumber: 'PO-2026-001234',
            vendor: 'Agricultural Supplies Co.',
            amount: '₦250,000',
            status: 'Approved',
            statusColor: Colors.green,
            date: 'Jan 28, 2026',
            onTap: () => context.pushNamed('institutional-po-list'),
          ),
          const SizedBox(height: 8),
          _PoStatusCard(
            poNumber: 'PO-2026-001233',
            vendor: 'Fresh Produce Ltd',
            amount: '₦185,000',
            status: 'Pending Approval',
            statusColor: Colors.orange,
            date: 'Jan 26, 2026',
            onTap: () => context.pushNamed('institutional-po-list'),
          ),
          const SizedBox(height: 8),
          _PoStatusCard(
            poNumber: 'PO-2026-001232',
            vendor: 'Logistics Partner Inc',
            amount: '₦420,000',
            status: 'Submitted',
            statusColor: Colors.blue,
            date: 'Jan 24, 2026',
            onTap: () => context.pushNamed('institutional-po-list'),
          ),
        ],
      ),
    );
  }

  /// 5. ACTIVITY-RANKED PRODUCT FEED
  Widget _buildRecommendedProductsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Product>> allProductsAsync,
    AsyncValue<List<String>> categoriesAsync,
    AsyncValue<List<String>> recommendedProductIdsAsync,
    AsyncValue<List<String>> favoriteCategoriesAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended for You',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('products'),
                child: Text(
                  'View all',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          categoriesAsync.when(
            data: (categoryIds) {
              return favoriteCategoriesAsync.when(
                data: (favoriteCategories) {
                  final realisticCategories = _buildRealisticCategories(
                    categoryIds,
                    favoriteCategories,
                  );
                  return SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: realisticCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = realisticCategories[index];
                        return _CategoryChip(
                          label: _formatCategoryLabel(category),
                          icon: _categoryIcon(category),
                          highlighted: favoriteCategories.contains(category),
                          onTap: () => context.pushNamed(
                            'products',
                            queryParameters: {'category': category},
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          allProductsAsync.when(
            data: (products) {
              return recommendedProductIdsAsync.when(
                data: (recommendedIds) {
                  return favoriteCategoriesAsync.when(
                    data: (favoriteCategories) {
                      final feed = _rankInstitutionalProducts(
                        products,
                        recommendedIds,
                        favoriteCategories,
                      );

                      if (feed.isEmpty) {
                        return Text(
                          'No products available yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                          ),
                        );
                      }

                      return SizedBox(
                          height: 238,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: feed.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final product = feed[index];
                              final isRecommended =
                                  recommendedIds.contains(product.id);
                              final matchesCategory = favoriteCategories
                                  .contains(product.categoryId);
                              return SizedBox(
                                  width: 320,
                                  child: _VerticalProductCard(
                                    product: product,
                                    isRecommended: isRecommended,
                                    matchesCategory: matchesCategory,
                                    onTap: () async {
                                      await ref
                                          .read(activityLoggerProvider.notifier)
                                          .logProductView(
                                            productId: product.id,
                                            productName: product.name,
                                            category: product.categoryId,
                                            price: product.contractPrice,
                                          );
                                      if (!context.mounted) return;
                                      context.goNamed(
                                        'product-detail',
                                        pathParameters: {
                                          'productId': product.id
                                        },
                                        extra: product.toJson(),
                                      );
                                    },
                                    onBuyTap: () async {
                                      await ref
                                          .read(activityLoggerProvider.notifier)
                                          .logProductView(
                                            productId: product.id,
                                            productName: product.name,
                                            category: product.categoryId,
                                            price: product.contractPrice,
                                          );
                                      if (!context.mounted) return;
                                      context.goNamed(
                                        'product-detail',
                                        pathParameters: {
                                          'productId': product.id
                                        },
                                        extra: product.toJson(),
                                      );
                                    },
                                  ));
                            },
                          ));
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text(
                      'Could not load your preferences',
                      style:
                          AppTextStyles.bodySmall.copyWith(color: Colors.red),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text(
                  'Could not load recommendations',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text(
              'Error loading products',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _rankInstitutionalProducts(
    List<Product> products,
    List<String> recommendedIds,
    List<String> favoriteCategories,
  ) {
    final institutionalProducts = products.where((product) {
      return product.visibleToInstitutions ||
          product.visibleToWholesale ||
          product.visibleToRetail;
    }).toList();

    institutionalProducts.sort((a, b) {
      int score(Product product) {
        var total = 0;
        if (recommendedIds.contains(product.id)) total += 100;
        if (favoriteCategories.contains(product.categoryId)) total += 40;
        if (product.stock > 0) total += 20;
        total += (product.rating * 5).round();
        return total;
      }

      return score(b).compareTo(score(a));
    });

    return institutionalProducts.take(8).toList();
  }

  Widget _buildTopDealsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Product>> allProductsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Deals',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('products'),
                child: Text(
                  'View all deals',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          allProductsAsync.when(
            data: (products) {
              final deals = _rankTopDeals(products);
              if (deals.isEmpty) {
                return Text(
                  'No active deals currently',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                );
              }

              return SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: deals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = deals[index];
                    final savedAmount =
                        (product.retailPrice - product.contractPrice)
                            .clamp(0.0, double.infinity);
                    final discountPercent = product.retailPrice > 0
                        ? ((savedAmount / product.retailPrice) * 100).round()
                        : 0;

                    return SizedBox(
                      width: 180,
                      child: _TopDealProductCard(
                        product: product,
                        discountPercent: discountPercent,
                        savedAmount: savedAmount,
                        onTap: () async {
                          await ref
                              .read(activityLoggerProvider.notifier)
                              .logProductView(
                                productId: product.id,
                                productName: product.name,
                                category: product.categoryId,
                                price: product.contractPrice,
                              );
                          if (!context.mounted) return;
                          context.goNamed(
                            'product-detail',
                            pathParameters: {'productId': product.id},
                            extra: product.toJson(),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text(
              'Could not load top deals',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _rankTopDeals(List<Product> products) {
    final visible = products.where((product) {
      return product.visibleToInstitutions ||
          product.visibleToWholesale ||
          product.visibleToRetail;
    }).toList();

    visible.sort((a, b) {
      final aSave =
          (a.retailPrice - a.contractPrice).clamp(0.0, double.infinity);
      final bSave =
          (b.retailPrice - b.contractPrice).clamp(0.0, double.infinity);
      final aPercent = a.retailPrice > 0 ? aSave / a.retailPrice : 0;
      final bPercent = b.retailPrice > 0 ? bSave / b.retailPrice : 0;
      final aScore = (aPercent * 1000).round() + (a.stock > 0 ? 25 : 0);
      final bScore = (bPercent * 1000).round() + (b.stock > 0 ? 25 : 0);
      return bScore.compareTo(aScore);
    });

    return visible.take(8).toList();
  }

  List<String> _buildRealisticCategories(
    List<String> categoryIds,
    List<String> favoriteCategories,
  ) {
    final seed = <String>[
      'grains',
      'oils',
      'legumes',
      'spices',
      'condiments',
      'proteins',
      'beverages',
      'dairy',
      'household',
    ];
    final merged = <String>{
      ...favoriteCategories,
      ...categoryIds,
      ...seed,
    };
    return merged.where((e) => e.trim().isNotEmpty).take(12).toList();
  }

  String _formatCategoryLabel(String category) {
    final normalized =
        category.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (normalized.isEmpty) return 'Category';
    return normalized
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  IconData _categoryIcon(String category) {
    final key = category.toLowerCase();
    if (key.contains('grain') || key.contains('rice')) return Icons.grain;
    if (key.contains('oil')) return Icons.oil_barrel_outlined;
    if (key.contains('legume') || key.contains('bean'))
      return Icons.spa_outlined;
    if (key.contains('spice')) return Icons.local_fire_department_outlined;
    if (key.contains('condiment') || key.contains('sauce'))
      return Icons.lunch_dining_outlined;
    if (key.contains('protein') || key.contains('meat'))
      return Icons.set_meal_outlined;
    if (key.contains('beverage') || key.contains('drink'))
      return Icons.local_drink_outlined;
    if (key.contains('dairy') || key.contains('milk'))
      return Icons.egg_alt_outlined;
    if (key.contains('household')) return Icons.home_outlined;
    return Icons.category_outlined;
  }

  /// 6. BULK PLANNING TOOLS
  Widget _buildBulkPlanningSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulk Planning Tools',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PlanningToolButton(
                  icon: Icons.file_download_outlined,
                  label: 'Download\nTemplate',
                  onTap: () => context.pushNamed('bulk-order'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanningToolButton(
                  icon: Icons.file_upload_outlined,
                  label: 'Bulk\nUpload',
                  onTap: () => context.pushNamed('products'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanningToolButton(
                  icon: Icons.assessment_outlined,
                  label: 'Demand\nForecast',
                  onTap: () => context.pushNamed('analytics-dashboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 7. TAILORED SELECTION (REALISTIC BUYER-SPECIFIC PICKS)
  Widget _buildTailoredSelectionSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Product>> allProductsAsync,
    AsyncValue<List<String>> recommendedProductIdsAsync,
    AsyncValue<List<String>> favoriteCategoriesAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tailored Selection',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('products'),
                child: Text(
                  'See all',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Products matched to your buying pattern, stock needs, and preferred categories.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TailoredActionChip(
                  icon: Icons.replay_outlined,
                  label: 'Reorder list',
                  onTap: () => context.pushNamed('institutional-po-list'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TailoredActionChip(
                  icon: Icons.add_shopping_cart_outlined,
                  label: 'Create PO',
                  onTap: () => context.pushNamed('institutional-po-create'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TailoredActionChip(
                  icon: Icons.insights_outlined,
                  label: 'Forecast',
                  onTap: () => context.pushNamed('analytics-dashboard'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          allProductsAsync.when(
            data: (products) {
              return recommendedProductIdsAsync.when(
                data: (recommendedIds) {
                  return favoriteCategoriesAsync.when(
                    data: (favoriteCategories) {
                      final tailoredProducts = _rankTailoredSelection(
                        products,
                        recommendedIds,
                        favoriteCategories,
                      );

                      if (tailoredProducts.isEmpty) {
                        return Text(
                          'No tailored products available at the moment',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        );
                      }

                      return SizedBox(
                        height: 246,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: tailoredProducts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final product = tailoredProducts[index];
                            final isPreferredCategory =
                                favoriteCategories.contains(product.categoryId);
                            final reorderHint =
                                recommendedIds.contains(product.id);

                            return SizedBox(
                              width: 280,
                              child: _TailoredSelectionProductCard(
                                product: product,
                                preferredCategory: isPreferredCategory,
                                reorderHint: reorderHint,
                                onOpen: () async {
                                  await _logProductViewSafe(ref, product);
                                  if (!context.mounted) return;
                                  context.goNamed(
                                    'product-detail',
                                    pathParameters: {'productId': product.id},
                                    extra: product.toJson(),
                                  );
                                },
                                onCreatePo: () async {
                                  await _logProductViewSafe(ref, product);
                                  if (!context.mounted) return;
                                  context.pushNamed('institutional-po-create');
                                },
                                onBrowseCategory: () => context.pushNamed(
                                  'products',
                                  queryParameters: {
                                    'category': product.categoryId,
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Text(
                      'Could not load tailored preferences',
                      style:
                          AppTextStyles.bodySmall.copyWith(color: Colors.red),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(
                  'Could not load tailored recommendations',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              'Could not load tailored products',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _rankTailoredSelection(
    List<Product> products,
    List<String> recommendedIds,
    List<String> favoriteCategories,
  ) {
    final visibleProducts = products.where((product) {
      return product.visibleToInstitutions ||
          product.visibleToWholesale ||
          product.visibleToRetail;
    }).toList();

    visibleProducts.sort((a, b) {
      int score(Product product) {
        var total = 0;
        if (recommendedIds.contains(product.id)) total += 60;
        if (favoriteCategories.contains(product.categoryId)) total += 40;
        if (product.stock > 0) total += 25;
        if (product.stock >= 50) total += 10;
        final savings = (product.retailPrice - product.contractPrice)
            .clamp(0.0, double.infinity);
        if (savings > 0) total += 15;
        total += (product.rating * 4).round();
        return total;
      }

      return score(b).compareTo(score(a));
    });

    return visibleProducts.take(6).toList();
  }

  Future<void> _logProductViewSafe(WidgetRef ref, Product product) async {
    try {
      await ref.read(activityLoggerProvider.notifier).logProductView(
            productId: product.id,
            productName: product.name,
            category: product.categoryId,
            price: product.contractPrice,
          );
    } catch (_) {
      // Keep navigation responsive even when activity tracking is unavailable.
    }
  }

  /// 7. CONTRACT PRICING PRODUCTS
  Widget _buildContractPricingSection(
    BuildContext context,
    AsyncValue<List<Product>> featuredAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Contract Pricing',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          featuredAsync.when(
            data: (products) {
              final institutionalProducts =
                  products.where((p) => p.visibleToInstitutions).toList();
              if (institutionalProducts.isEmpty) {
                return Text(
                  'No products available',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                );
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: institutionalProducts.length,
                  itemBuilder: (context, index) {
                    final product = institutionalProducts[index];
                    return _ContractProductCard(
                      product: product,
                      context: context,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text(
              'Error loading products',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 8. INVOICING & PAYMENT
  Widget _buildInvoicingSection(BuildContext context) {
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
            Text(
              'Invoicing & Payments',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _InvoiceRow(
              title: 'Outstanding Invoices',
              value: '3 invoices',
              amount: '₦847,500',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _InvoiceRow(
              title: 'Payment Terms',
              value: 'Net-30 days',
              amount: 'Next due: Feb 25',
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.pushNamed('institutional-invoices'),
              child: Text(
                'View All Invoices →',
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
}

// ═════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═════════════════════════════════════════════════════════════════════════

class _BudgetCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _BudgetCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (color ?? AppColors.primary).withOpacity(0.2),
        ),
      ),
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

class _PoStatusCard extends StatelessWidget {
  final String poNumber;
  final String vendor;
  final String amount;
  final String status;
  final Color statusColor;
  final String date;
  final VoidCallback onTap;

  const _PoStatusCard({
    required this.poNumber,
    required this.vendor,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poNumber,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlanningToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractProductCard extends StatelessWidget {
  final Product product;
  final BuildContext context;

  const _ContractProductCard({
    required this.product,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => this.context.pushNamed(
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
                    '₦${product.contractPrice.toStringAsFixed(0)}',
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

class _VerticalProductCard extends StatelessWidget {
  final Product product;
  final bool isRecommended;
  final bool matchesCategory;
  final VoidCallback onTap;
  final VoidCallback onBuyTap;

  const _VerticalProductCard({
    required this.product,
    required this.isRecommended,
    required this.matchesCategory,
    required this.onTap,
    required this.onBuyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 88,
                  height: 88,
                  color: Colors.grey[100],
                  child: product.imageUrl != null
                      ? Image(
                          image: product.imageUrl!.startsWith('assets/')
                              ? AssetImage(product.imageUrl!)
                              : NetworkImage(product.imageUrl!)
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isRecommended)
                          _FeedBadge(
                              label: 'For you', color: AppColors.primary),
                        if (isRecommended && matchesCategory)
                          const SizedBox(width: 6),
                        if (matchesCategory)
                          _FeedBadge(
                              label: 'Your category', color: Colors.green),
                      ],
                    ),
                    if (isRecommended || matchesCategory)
                      const SizedBox(height: 6),
                    Text(
                      product.name,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₦${product.contractPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.stock > 0
                              ? '${product.stock} in stock'
                              : 'Out of stock',
                          style: AppTextStyles.bodySmall.copyWith(
                            color:
                                product.stock > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onBuyTap,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('View details & buy'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _FeedBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted
          ? AppColors.primary.withValues(alpha: 0.14)
          : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlighted
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: highlighted ? AppColors.primary : AppColors.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: highlighted ? AppColors.primary : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopDealProductCard extends StatelessWidget {
  final Product product;
  final int discountPercent;
  final double savedAmount;
  final VoidCallback onTap;

  const _TopDealProductCard({
    required this.product,
    required this.discountPercent,
    required this.savedAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        child: product.imageUrl != null
                            ? Image(
                                image: product.imageUrl!.startsWith('assets/')
                                    ? AssetImage(product.imageUrl!)
                                    : NetworkImage(product.imageUrl!)
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[100],
                                child: const Icon(Icons.local_offer_outlined),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${product.contractPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Save ₦${savedAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TailoredActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TailoredActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TailoredSelectionProductCard extends StatelessWidget {
  final Product product;
  final bool preferredCategory;
  final bool reorderHint;
  final VoidCallback onOpen;
  final VoidCallback onCreatePo;
  final VoidCallback onBrowseCategory;

  const _TailoredSelectionProductCard({
    required this.product,
    required this.preferredCategory,
    required this.reorderHint,
    required this.onOpen,
    required this.onCreatePo,
    required this.onBrowseCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpen,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 76,
                          height: 76,
                          color: Colors.grey[100],
                          child: product.imageUrl != null
                              ? Image(
                                  image: product.imageUrl!.startsWith('assets/')
                                      ? AssetImage(product.imageUrl!)
                                      : NetworkImage(product.imageUrl!)
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.inventory_2_outlined),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (preferredCategory)
                                  _FeedBadge(
                                    label: 'Preferred',
                                    color: Colors.green,
                                  ),
                                if (reorderHint)
                                  _FeedBadge(
                                    label: 'Reorder fit',
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₦${product.contractPrice.toStringAsFixed(0)} • ${product.stock} units',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _buildCategoryLine(product.categoryId),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(38),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Open product'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onCreatePo,
                    icon: const Icon(Icons.post_add_outlined),
                    tooltip: 'Create PO',
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: onBrowseCategory,
                    icon: const Icon(Icons.travel_explore_outlined),
                    tooltip: 'Browse category',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildCategoryLine(String category) {
    final normalized =
        category.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (normalized.isEmpty) return 'General catalog fit';
    final label = normalized
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
    return '$label category';
  }
}

class _InvoiceRow extends StatelessWidget {
  final String title;
  final String value;
  final String amount;
  final IconData icon;

  const _InvoiceRow({
    required this.title,
    required this.value,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _AccountLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccountLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
        ],
      ),
    );
  }
}
