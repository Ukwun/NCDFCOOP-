import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/product_providers.dart';
import 'package:coop_commerce/core/providers/real_time_providers.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/models/product.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/cart_provider.dart';
import 'package:coop_commerce/providers/wishlist_provider.dart' as wl;

/// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class ProductsListingScreen extends ConsumerStatefulWidget {
  final String title;
  final String? category; // Optional: category filter

  const ProductsListingScreen({
    super.key,
    required this.title,
    this.category,
  });

  @override
  ConsumerState<ProductsListingScreen> createState() =>
      _ProductsListingScreenState();
}

class _ProductsListingScreenState extends ConsumerState<ProductsListingScreen> {
  String viewType = 'grid'; // grid or list
  late ScrollController _scrollController;
  String searchQuery = '';
  String sortOption = 'popularity';
  double? minPriceFilter;
  double? maxPriceFilter;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // If category is passed, set it in the filter
    if (widget.category?.isNotEmpty == true) {
      Future.microtask(() {
        ref.read(productFiltersProvider.notifier).setCategory(widget.category);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Pagination handled through provider refresh
    }
  }

  void _onSortChanged(String newSort) {
    setState(() {
      sortOption = newSort;
    });
    ref.read(productFiltersProvider.notifier).setSortBy(newSort);
  }

  bool _isSellerMarketplaceProduct(Product product) {
    return product.franchiseId == 'seller_marketplace' ||
        product.uploadedBy.isNotEmpty;
  }

  bool _canCurrentRoleSeeProduct(Product product, UserRole role) {
    if (_isSellerMarketplaceProduct(product)) {
      return role == UserRole.coopMember ||
          role == UserRole.premiumMember ||
          role == UserRole.wholesaleBuyer;
    }

    switch (role) {
      case UserRole.institutionalBuyer:
      case UserRole.institutionalApprover:
        return product.visibleToInstitutions;
      case UserRole.coopMember:
      case UserRole.premiumMember:
      case UserRole.wholesaleBuyer:
        return product.visibleToWholesale || product.visibleToRetail;
      default:
        return product.visibleToRetail;
    }
  }

  double _getPriceForRole(Product product, UserRole role) {
    switch (role) {
      case UserRole.institutionalBuyer:
      case UserRole.institutionalApprover:
        return product.contractPrice > 0
            ? product.contractPrice
            : (product.wholesalePrice > 0
                ? product.wholesalePrice
                : product.retailPrice);
      case UserRole.coopMember:
      case UserRole.premiumMember:
      case UserRole.wholesaleBuyer:
        return product.wholesalePrice > 0
            ? product.wholesalePrice
            : product.retailPrice;
      default:
        return product.retailPrice;
    }
  }

  Future<void> _addProductToCart(Product product) async {
    if (product.stock <= 0) return;

    final role = ref.read(currentRoleProvider);
    final effectivePrice = _getPriceForRole(product, role);

    final cartNotifier = ref.read(cartProvider.notifier);
    await cartNotifier.addItem(
      CartItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productId: product.id,
        productName: product.name,
        memberPrice: effectivePrice,
        marketPrice: product.retailPrice,
        imageUrl: product.imageUrl,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFavorite(Product product) {
    final isFavorite = ref.read(wl.wishlistProvider).contains(product.id);
    final nowFavorite = ref.read(wl.wishlistProvider.notifier).toggleWishlist(
          productId: product.id,
          productName: product.name,
          price: product.retailPrice,
          originalPrice: product.retailPrice,
          imageUrl: product.imageUrl,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nowFavorite
              ? '${product.name} added to favorites'
              : '${product.name} removed from favorites',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    if (isFavorite == nowFavorite) {
      // no-op guard for unexpected state
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsByFiltersProvider);

    // Watch for real-time pricing updates for all products
    final allProductIds = productsAsync.maybeWhen(
      data: (products) => products.map((p) => p.id).toList(),
      orElse: () => <String>[],
    );
    final pricingUpdate = ref.watch(
      cartPricingUpdatesProvider(allProductIds),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Real-time Pricing Update Banner
          SliverToBoxAdapter(
            child: pricingUpdate.when(
              data: (update) {
                if (update.promotionActive &&
                    update.newPrice != null &&
                    update.oldPrice != null) {
                  final discountPercent =
                      (((update.oldPrice! - update.newPrice!) /
                                  update.oldPrice!) *
                              100)
                          .toStringAsFixed(0);
                  return Container(
                    margin: const EdgeInsets.all(AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_offer,
                          color: Colors.amber[700],
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Special Promotion!',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[700],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Save up to $discountPercent% on selected items',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.amber[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildViewOptions()),
          SliverToBoxAdapter(child: _buildSortOptions()),
          SliverToBoxAdapter(child: _buildProductsView()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:45',
                style: AppTextStyles.h4.copyWith(color: AppColors.surface),
              ),
              Row(
                spacing: 6,
                children: [
                  Icon(Icons.signal_cellular_4_bar,
                      color: AppColors.surface, size: 16),
                  Icon(Icons.wifi, color: AppColors.surface, size: 16),
                  Icon(Icons.battery_full, color: AppColors.surface, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.surface,
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.title,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.surface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.pushNamed('wishlist');
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.favorite_outline,
                    color: AppColors.surface,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewOptions() {
    final displayedProducts = ref.watch(productsByFiltersProvider);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          displayedProducts.when(
            data: (products) => Text(
              '${products.length} items',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
            loading: () => Text(
              'Loading...',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
            error: (_, __) => Text(
              'Error loading',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ),
          Row(
            spacing: 8,
            children: [
              GestureDetector(
                onTap: () => setState(() => viewType = 'grid'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: viewType == 'grid'
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.grid_3x3,
                    color: viewType == 'grid'
                        ? AppColors.surface
                        : AppColors.muted,
                    size: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => viewType = 'list'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: viewType == 'list'
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.list,
                    color: viewType == 'list'
                        ? AppColors.surface
                        : AppColors.muted,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    final sortOptions = ['popularity', 'price', 'rating', 'newest', 'name'];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: sortOptions.map((option) {
            final isSelected = sortOption == option;
            return GestureDetector(
              onTap: () => _onSortChanged(option),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  option.capitalize(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? AppColors.surface : AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductsView() {
    final displayedProducts = ref.watch(productsByFiltersProvider);
    final role = ref.watch(currentRoleProvider);

    return displayedProducts.when(
      data: (products) {
        final visibleProducts = products
            .where((product) => _canCurrentRoleSeeProduct(product, role))
            .toList();

        if (visibleProducts.isEmpty) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 48, color: AppColors.muted),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: AppTextStyles.h4.copyWith(color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          );
        }

        if (viewType == 'grid') {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: visibleProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(visibleProducts[index], ref);
              },
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: visibleProducts.map((product) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildProductListItem(product, ref),
                );
              }).toList(),
            ),
          );
        }
      },
      loading: () => SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stackTrace) {
        // Show mock products on error as fallback
        final mockProducts = [
          Product(
            id: 'mock_001',
            name: 'Premium Rice 50kg',
            retailPrice: 22000.0,
            wholesalePrice: 19800.0,
            contractPrice: 18000.0,
            description: 'High quality long grain rice',
            imageUrl: 'https://picsum.photos/300/300?random=1',
            categoryId: 'grains',
            stock: 100,
          ),
          Product(
            id: 'mock_002',
            name: 'Palm Oil 25L',
            retailPrice: 45000.0,
            wholesalePrice: 40500.0,
            contractPrice: 40000.0,
            description: 'Premium edible palm oil',
            imageUrl: 'https://picsum.photos/300/300?random=2',
            categoryId: 'oils',
            stock: 50,
          ),
          Product(
            id: 'mock_003',
            name: 'Black Beans 20kg',
            retailPrice: 15000.0,
            wholesalePrice: 13500.0,
            contractPrice: 12000.0,
            description: 'Quality black beans',
            imageUrl: 'https://picsum.photos/300/300?random=3',
            categoryId: 'legumes',
            stock: 75,
          ),
          Product(
            id: 'mock_004',
            name: 'White Sugar 25kg',
            retailPrice: 28000.0,
            wholesalePrice: 25200.0,
            contractPrice: 24000.0,
            description: 'Pure white granulated sugar',
            imageUrl: 'https://picsum.photos/300/300?random=4',
            categoryId: 'sweeteners',
            stock: 60,
          ),
          Product(
            id: 'mock_005',
            name: 'Garlic Powder 500g',
            retailPrice: 3500.0,
            wholesalePrice: 3150.0,
            contractPrice: 3000.0,
            description: 'Premium garlic powder',
            imageUrl: 'https://picsum.photos/300/300?random=5',
            categoryId: 'spices',
            stock: 120,
          ),
          Product(
            id: 'mock_006',
            name: 'Tomato Paste 1kg',
            retailPrice: 5000.0,
            wholesalePrice: 4500.0,
            contractPrice: 4200.0,
            description: 'Rich tomato paste',
            imageUrl: 'https://picsum.photos/300/300?random=6',
            categoryId: 'condiments',
            stock: 90,
          ),
          Product(
            id: 'mock_007',
            name: 'Onion Powder 300g',
            retailPrice: 2800.0,
            wholesalePrice: 2520.0,
            contractPrice: 2400.0,
            description: 'Fine onion powder seasoning',
            imageUrl: 'https://picsum.photos/300/300?random=7',
            categoryId: 'spices',
            stock: 110,
          ),
          Product(
            id: 'mock_008',
            name: 'Chicken Seasoning 250g',
            retailPrice: 3200.0,
            wholesalePrice: 2880.0,
            contractPrice: 2700.0,
            description: 'Delicious chicken seasoning',
            imageUrl: 'https://picsum.photos/300/300?random=8',
            categoryId: 'spices',
            stock: 95,
          ),
        ];

        if (viewType == 'grid') {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: mockProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(mockProducts[index], ref);
              },
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: mockProducts.map((product) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildProductListItem(product, ref),
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildProductCard(Product product, WidgetRef ref) {
    // Watch inventory status for this product
    final inventoryStatus = ref.watch(
      productInventoryStatusProvider(product.id),
    );
    final isFavorite = ref.watch(wl.isProductInWishlistProvider(product.id));

    return GestureDetector(
      onTap: () {
        context.goNamed('product-detail',
            pathParameters: {'productId': product.id});
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [AppShadows.sm],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Inventory Badge
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                    color: AppColors.background,
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
                      ? Icon(
                          Icons.shopping_basket,
                          color: AppColors.muted,
                          size: 40,
                        )
                      : null,
                ),
                // Inventory Status Badge
                inventoryStatus.when(
                  data: (status) {
                    if (status.status == 'out_of_stock') {
                      return Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Out of Stock',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    } else if (status.status == 'low_stock') {
                      return Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Low Stock',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
              ],
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Price Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₦${product.retailPrice.toStringAsFixed(0)}',
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            // Show rating
                            Row(
                              spacing: 4,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 12, color: Colors.amber),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _toggleFavorite(product);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isFavorite
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : AppColors.background,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(
                                    color: isFavorite
                                        ? Colors.red
                                        : AppColors.border,
                                  ),
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      isFavorite ? Colors.red : AppColors.muted,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: product.stock > 0
                                  ? () async {
                                      await _addProductToCart(product);
                                    }
                                  : null,
                              onLongPress: () {
                                _toggleFavorite(product);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: product.stock > 0
                                      ? AppColors.primary
                                      : AppColors.muted,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.surface,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildProductListItem(Product product, WidgetRef ref) {
    // Watch inventory status for this product
    final inventoryStatus = ref.watch(
      productInventoryStatusProvider(product.id),
    );
    final isFavorite = ref.watch(wl.isProductInWishlistProvider(product.id));

    return GestureDetector(
      onTap: () {
        context.goNamed('product-detail',
            pathParameters: {'productId': product.id});
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [AppShadows.sm],
        ),
        child: Row(
          children: [
            // Product Image with Inventory Badge
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                    ),
                    color: AppColors.background,
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
                      ? Icon(
                          Icons.shopping_basket,
                          color: AppColors.muted,
                        )
                      : null,
                ),
                // Inventory Status Badge
                inventoryStatus.when(
                  data: (status) {
                    if (status.status == 'out_of_stock') {
                      return Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'Out',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      );
                    } else if (status.status == 'low_stock') {
                      return Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'Low',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
              ],
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Price and Rating
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          '₦${product.retailPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          spacing: 4,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 12, color: Colors.amber),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Stock Status
                    Text(
                      product.stock > 0
                          ? '${product.stock} in stock'
                          : 'Out of stock',
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            product.stock > 0 ? Colors.green : AppColors.error,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      _toggleFavorite(product);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isFavorite
                            ? Colors.red.withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: isFavorite ? Colors.red : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : AppColors.muted,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: product.stock > 0
                        ? () async {
                            await _addProductToCart(product);
                          }
                        : null,
                    onLongPress: () {
                      _toggleFavorite(product);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: product.stock > 0
                            ? AppColors.primary
                            : AppColors.muted,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.add,
                        color: AppColors.surface,
                        size: 18,
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
  }
}
