import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/product_providers.dart';
import 'package:coop_commerce/providers/user_activity_providers.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/search_preferences_providers.dart';

class _SearchIntentAction {
  final String title;
  final String query;
  final String routeName;
  final IconData icon;

  const _SearchIntentAction({
    required this.title,
    required this.query,
    required this.routeName,
    required this.icon,
  });
}

/// Search screen for browsing products with real-time search
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchQuery() {
    final query = _searchController.text;

    // Update the provider state with the new search query
    ref.read(productSearchQueryProvider.notifier).state = query;

    // Reset pagination when search changes
    ref.read(paginationNotifierProvider.notifier).state = 0;

    // Log search activity and save to recent searches if query is not empty
    if (query.isNotEmpty) {
      _logSearchActivity(query);
      _saveToRecentSearches(query);
    }
  }

  /// Save search to recent searches for current role
  Future<void> _saveToRecentSearches(String query) async {
    try {
      final service = ref.read(searchPreferencesServiceProvider);
      final role = ref.read(currentRoleProvider);
      await service.saveRecentSearch(role, query);

      // Refresh recent searches provider
      ref.invalidate(recentSearchesForRoleProvider);
    } catch (e) {
      debugPrint('⚠️ Failed to save recent search: $e');
    }
  }

  /// Activate a recent search
  Future<void> _activateRecentSearch(String query) async {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _updateSearchQuery();
    await _logSearchActivity(query);
  }

  /// Log search activity to Firestore
  Future<void> _logSearchActivity(String query) async {
    try {
      final activityLogger = ref.read(activityLoggerProvider.notifier);
      await activityLogger.logSearch(
        query: query,
        resultsCount: 0, // Will be updated when results load
        category: null,
      );
      debugPrint('✅ Search logged: "$query"');
    } catch (e) {
      debugPrint('⚠️ Failed to log search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(productSearchQueryProvider);
    final searchResults = ref.watch(productSearchProvider(searchQuery));
    final role = ref.watch(currentRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _hintForRole(role),
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textLight),
                    onPressed: () {
                      _searchController.clear();
                      _updateSearchQuery();
                    },
                  )
                : null,
          ),
        ),
      ),
      body: searchQuery.isEmpty
          ? _buildIntentDiscoveryState(context, role)
          : searchResults.when(
              data: (data) {
                if (data.isEmpty) {
                  return _buildNoResultsState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final product = data[index];
                    return _buildSearchProductCard(product);
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Error searching products',
                      style: AppTextStyles.h4.copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      error.toString(),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _hintForRole(UserRole role) {
    if (role == UserRole.coopMember || role == UserRole.premiumMember) {
      return 'Search investment products, savings plans, transactions...';
    }

    if (role == UserRole.wholesaleBuyer ||
        role == UserRole.institutionalBuyer ||
        role == UserRole.institutionalApprover) {
      return 'Search institutional products, reports, accounts...';
    }

    if (role == UserRole.seller) {
      return 'Search clients, catalogues, leads, campaigns...';
    }

    return 'Search products, categories...';
  }

  List<_SearchIntentAction> _intentsForRole(UserRole role) {
    if (role == UserRole.coopMember || role == UserRole.premiumMember) {
      return const [
        _SearchIntentAction(
          title: 'Investment Products',
          query: 'investment products',
          routeName: 'products',
          icon: Icons.trending_up_outlined,
        ),
        _SearchIntentAction(
          title: 'Savings Plans',
          query: 'savings plans',
          routeName: 'member-savings',
          icon: Icons.savings_outlined,
        ),
        _SearchIntentAction(
          title: 'Transaction History',
          query: 'transaction history',
          routeName: 'orders',
          icon: Icons.receipt_long_outlined,
        ),
      ];
    }

    if (role == UserRole.wholesaleBuyer ||
        role == UserRole.institutionalBuyer ||
        role == UserRole.institutionalApprover) {
      return const [
        _SearchIntentAction(
          title: 'Institutional Products',
          query: 'institutional products',
          routeName: 'products',
          icon: Icons.apartment_outlined,
        ),
        _SearchIntentAction(
          title: 'Reports',
          query: 'reports',
          routeName: 'analytics-dashboard',
          icon: Icons.insert_chart_outlined,
        ),
        _SearchIntentAction(
          title: 'Accounts',
          query: 'accounts',
          routeName: 'my-ncdfcoop',
          icon: Icons.manage_accounts_outlined,
        ),
        _SearchIntentAction(
          title: 'Large Portfolios',
          query: 'large portfolios',
          routeName: 'bulk-order',
          icon: Icons.account_balance_outlined,
        ),
      ];
    }

    if (role == UserRole.seller) {
      return const [
        _SearchIntentAction(
          title: 'Clients',
          query: 'clients',
          routeName: 'messages',
          icon: Icons.groups_outlined,
        ),
        _SearchIntentAction(
          title: 'Product Catalogues',
          query: 'product catalogues',
          routeName: 'products',
          icon: Icons.inventory_2_outlined,
        ),
        _SearchIntentAction(
          title: 'Leads',
          query: 'leads',
          routeName: 'dashboard',
          icon: Icons.track_changes_outlined,
        ),
        _SearchIntentAction(
          title: 'Campaigns',
          query: 'campaigns',
          routeName: 'offers',
          icon: Icons.campaign_outlined,
        ),
      ];
    }

    return const [
      _SearchIntentAction(
        title: 'Products',
        query: 'products',
        routeName: 'products',
        icon: Icons.shopping_bag_outlined,
      ),
      _SearchIntentAction(
        title: 'Orders',
        query: 'orders',
        routeName: 'orders',
        icon: Icons.local_shipping_outlined,
      ),
    ];
  }

  Future<void> _activateIntent(
      BuildContext context, _SearchIntentAction intent) async {
    _searchController.text = intent.query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _updateSearchQuery();

    await _logSearchActivity(intent.query);
  }

  void _openIntentRoute(BuildContext context, _SearchIntentAction intent) {
    try {
      context.pushNamed(intent.routeName);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Route ${intent.routeName} is not available yet')),
      );
    }
  }

  Widget _buildIntentDiscoveryState(BuildContext context, UserRole role) {
    final intents = _intentsForRole(role);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== RECENT SEARCHES SECTION ==========
          _buildRecentSearchesSection(),
          const SizedBox(height: AppSpacing.xl),

          // ========== PINNED INTENTS & ALL INTENTS SECTION ==========
          Text(
            'Intent Search Layer',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Discovery actions tuned to ${role.displayName}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Pinned intents section (if any pinned)
          _buildPinnedIntentsSection(context, intents),

          // All intents
          ...intents.map(
            (intent) => _buildIntentCard(context, intent),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildEmptyState(),
        ],
      ),
    );
  }

  /// Build recent searches section with role-specific history
  Widget _buildRecentSearchesSection() {
    return Consumer(
      builder: (context, ref, child) {
        final recentSearches = ref.watch(recentSearchesForRoleProvider);

        return recentSearches.when(
          data: (searches) {
            if (searches.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Searches',
                      style: AppTextStyles.h4
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () async {
                        final role = ref.read(currentRoleProvider);
                        final service =
                            ref.read(searchPreferencesServiceProvider);
                        await service.clearRecentSearches(role);
                        ref.invalidate(recentSearchesForRoleProvider);
                      },
                      child: Text(
                        'Clear',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: searches
                      .map(
                        (query) => GestureDetector(
                          onTap: () => _activateRecentSearch(query),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  query,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: SizedBox(
              height: 40,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  /// Build pinned intents section with visual indicators
  Widget _buildPinnedIntentsSection(
      BuildContext context, List<_SearchIntentAction> allIntents) {
    return Consumer(
      builder: (context, ref, child) {
        final pinnedIntents = ref.watch(pinnedIntentsForRoleProvider);

        return pinnedIntents.when(
          data: (pinned) {
            if (pinned.isEmpty) {
              return const SizedBox.shrink();
            }

            // Filter intents to only show pinned ones
            final pinnedIntentCards = allIntents
                .where((intent) => pinned.contains(intent.title))
                .toList();

            if (pinnedIntentCards.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⭐ Pinned Workflows',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...pinnedIntentCards.map(
                  (intent) => _buildIntentCard(context, intent, isPinned: true),
                ),
                const SizedBox(height: AppSpacing.lg),
                Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  /// Build a single intent card with pin/unpin button
  Widget _buildIntentCard(
    BuildContext context,
    _SearchIntentAction intent, {
    bool isPinned = false,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final isIntentPinned = ref.watch(isIntentPinnedProvider(intent.title));

        return isIntentPinned.when(
          data: (pinned) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: pinned ? AppColors.primary : AppColors.border,
                  width: pinned ? 2 : 1,
                ),
                boxShadow: pinned
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(intent.icon, color: AppColors.primary),
                ),
                title: Text(intent.title, style: AppTextStyles.labelLarge),
                subtitle: Text('Search: "${intent.query}"'),
                onTap: () => _activateIntent(context, intent),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pin button
                    IconButton(
                      icon: Icon(
                        pinned ? Icons.star : Icons.star_outline,
                        color: pinned ? Colors.amber : AppColors.textLight,
                      ),
                      onPressed: () async {
                        if (pinned) {
                          await ref
                              .read(unpinIntentProvider(intent.title).future);
                        } else {
                          await ref
                              .read(pinIntentProvider(intent.title).future);
                        }
                      },
                      tooltip: pinned ? 'Unpin workflow' : 'Pin workflow',
                    ),
                    // Open button
                    TextButton(
                      onPressed: () => _openIntentRoute(context, intent),
                      child: const Text('Open'),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(intent.icon, color: AppColors.primary),
              ),
              title: Text(intent.title, style: AppTextStyles.labelLarge),
              subtitle: Text('Search: "${intent.query}"'),
            ),
          ),
          error: (err, stack) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(intent.icon, color: AppColors.primary),
              ),
              title: Text(intent.title, style: AppTextStyles.labelLarge),
              subtitle: Text('Search: "${intent.query}"'),
              onTap: () => _activateIntent(context, intent),
              trailing: TextButton(
                onPressed: () => _openIntentRoute(context, intent),
                child: const Text('Open'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.border,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Search for products',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Browse our collection of products',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 80,
            color: AppColors.border,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No products found',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try searching with different keywords',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchProductCard(dynamic product) {
    return GestureDetector(
      onTap: () {
        context.goNamed('product-detail',
            pathParameters: {'productId': product.id});
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [AppShadows.sm],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                ),
                image: product.imageUrl != null
                    ? DecorationImage(
                        image: product.imageUrl!.startsWith('assets/')
                            ? AssetImage(product.imageUrl!)
                            : NetworkImage(product.imageUrl!) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl == null
                  ? Icon(
                      Icons.shopping_basket,
                      size: 40,
                      color: AppColors.muted,
                    )
                  : null,
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Prices
                    Row(
                      children: [
                        Text(
                          '₦${product.retailPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (product.rating > 0)
                          Row(
                            spacing: 2,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 12, color: Colors.amber),
                              Text(
                                '${product.rating.toStringAsFixed(1)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Stock Status
                    Text(
                      product.stock > 0
                          ? '${product.stock} in stock'
                          : 'Out of stock',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color:
                            product.stock > 0 ? Colors.green : AppColors.error,
                      ),
                    ),
                    const Spacer(),
                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: product.stock > 0
                              ? AppColors.primary
                              : AppColors.muted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        onPressed: product.stock > 0
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added ${product.name} to cart',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                        child: Text(
                          'Add to Cart',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
