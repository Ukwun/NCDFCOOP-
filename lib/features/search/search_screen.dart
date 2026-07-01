import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/core/providers/product_providers.dart';
import 'package:coop_commerce/models/product.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/search_preferences_providers.dart';
import 'package:coop_commerce/providers/user_activity_providers.dart';
import 'package:coop_commerce/theme/app_theme.dart';

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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearchQuery);

    final initial = widget.initialQuery.trim();
    if (initial.isNotEmpty) {
      _searchController.text = initial;
      _searchController.selection =
          TextSelection.collapsed(offset: initial.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateSearchQuery();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchQuery() {
    final query = _searchController.text.trim();
    ref.read(productSearchQueryProvider.notifier).state = query;
    ref.read(paginationNotifierProvider.notifier).state = 0;

    if (query.isNotEmpty) {
      _logSearchActivity(query);
      _saveToRecentSearches(query);
    }
  }

  Future<void> _saveToRecentSearches(String query) async {
    try {
      final service = ref.read(searchPreferencesServiceProvider);
      final role = ref.read(currentRoleProvider);
      await service.saveRecentSearch(role, query);
      ref.invalidate(recentSearchesForRoleProvider);
    } catch (e) {
      debugPrint('⚠️ Failed to save recent search: $e');
    }
  }

  Future<void> _logSearchActivity(String query) async {
    try {
      final activityLogger = ref.read(activityLoggerProvider.notifier);
      await activityLogger.logSearch(
        query: query,
        resultsCount: 0,
        category: null,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to log search: $e');
    }
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

  List<Product> _buildSuggestions(List<Product> products, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return const [];

    final scored = products
        .map((product) {
          var score = 0;
          final name = product.name.toLowerCase();
          final description = product.description.toLowerCase();
          final category = product.categoryId.toLowerCase();

          if (name.startsWith(normalized)) score += 50;
          if (name.contains(normalized)) score += 30;
          if (description.contains(normalized)) score += 15;
          if (category.contains(normalized)) score += 10;

          return MapEntry(product, score);
        })
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.map((entry) => entry.key).take(6).toList();
  }

  Future<void> _activateIntent(_SearchIntentAction intent) async {
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

  Widget _buildIntentCard(BuildContext context, _SearchIntentAction intent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(intent.icon, color: AppColors.primary),
        ),
        title: Text(intent.title, style: AppTextStyles.labelLarge),
        subtitle: Text('Search: "${intent.query}"'),
        onTap: () => _activateIntent(intent),
        trailing: TextButton(
          onPressed: () => _openIntentRoute(context, intent),
          child: const Text('Open'),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Consumer(
      builder: (context, ref, child) {
        final recentSearches = ref.watch(recentSearchesForRoleProvider);

        return recentSearches.when(
          data: (searches) {
            if (searches.isEmpty) return const SizedBox.shrink();

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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: searches
                      .map(
                        (query) => ActionChip(
                          avatar: const Icon(Icons.history, size: 16),
                          label: Text(query),
                          onPressed: () {
                            _searchController.text = query;
                            _searchController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _searchController.text.length),
                            );
                            _updateSearchQuery();
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildDiscovery(BuildContext context, UserRole role) {
    final intents = _intentsForRole(role);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRecentSearches(),
        const SizedBox(height: 16),
        Text(
          'Browse by intent',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Discovery actions tuned to ${role.displayName}',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(height: 16),
        ...intents.map((intent) => _buildIntentCard(context, intent)),
      ],
    );
  }

  Widget _buildSuggestionsPanel(List<Product> suggestions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions',
            style:
                AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (product) => ActionChip(
                    avatar: const Icon(Icons.search, size: 16),
                    label: Text(product.name),
                    onPressed: () {
                      _searchController.text = product.name;
                      _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _searchController.text.length),
                      );
                      _updateSearchQuery();
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: AppColors.border),
          const SizedBox(height: 16),
          Text('No products found', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          context.goNamed(
            'product-detail',
            pathParameters: {'productId': product.id},
            extra: product.toJson(),
          );
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
                              : NetworkImage(product.imageUrl!)
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl == null
                    ? Icon(Icons.shopping_basket,
                        size: 40, color: AppColors.muted)
                    : null,
              ),
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
                        style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.xs),
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
                                const Icon(Icons.star_rounded,
                                    size: 12, color: Colors.amber),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: AppTextStyles.bodySmall
                                      .copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        product.stock > 0
                            ? '${product.stock} in stock'
                            : 'Out of stock',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: product.stock > 0
                              ? Colors.green
                              : AppColors.error,
                        ),
                      ),
                      const Spacer(),
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
                                            'Added ${product.name} to cart')),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(productSearchQueryProvider);
    final searchResults = ref.watch(productSearchProvider(searchQuery));
    final allProductsAsync = ref.watch(allProductsProvider);
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
            hintStyle:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
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
          ? _buildDiscovery(context, role)
          : searchResults.when(
              data: (results) {
                return allProductsAsync.when(
                  data: (catalog) {
                    final suggestions = _buildSuggestions(catalog, searchQuery);

                    return CustomScrollView(
                      slivers: [
                        if (suggestions.isNotEmpty)
                          SliverToBoxAdapter(
                              child: _buildSuggestionsPanel(suggestions)),
                        if (results.isEmpty)
                          SliverToBoxAdapter(child: _buildNoResultsState())
                        else
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildProductCard(results[index]),
                                childCount: results.length,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error loading suggestions: $error',
                          textAlign: TextAlign.center),
                    ),
                  ),
                );
              },
              loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error searching products: $error',
                      textAlign: TextAlign.center),
                ),
              ),
            ),
    );
  }
}
