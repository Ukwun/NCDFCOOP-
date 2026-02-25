import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/product_providers.dart';
import 'package:coop_commerce/providers/user_activity_providers.dart';

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

    // Log search activity to Firestore if query is not empty
    if (query.isNotEmpty) {
      _logSearchActivity(query);
    }
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search products, categories...',
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
          ? _buildEmptyState()
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
