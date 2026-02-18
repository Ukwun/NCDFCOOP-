import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home_quick_actions_bar.dart';

class HomeScreenV2 extends ConsumerWidget {
  const HomeScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Bar + Header
            _buildHeader(),

            // Welcome Section
            _buildWelcomeSection(context),

            // Navigation Tabs
            _buildNavigationTabs(),

            // Quick Access Shortcuts
            _buildQuickAccessSection(),

            // Search Bar
            _buildSearchBar(),

            // Categories
            _buildCategoriesSection(),

            // Member Exclusives
            _buildSectionTitle(
              'Member Exclusives',
              hasIcon: true,
              onIconTap: () {
                context.pushNamed('membership');
              },
            ),
            _buildMemberExclusivesCarousel(context),

            // Save up to 30% Banner
            _buildPromotionalBanner(),

            // Buy Again
            _buildSectionTitle(
              'Buy again',
              hasIcon: true,
              onIconTap: () {
                context.pushNamed('buy-again');
              },
            ),
            _buildBuyAgainGrid(),

            // Essentials Basket
            _buildSectionTitle(
              'Essentials Basket',
              hasIcon: true,
              onIconTap: () {
                context.pushNamed('essentials');
              },
            ),
            _buildEssentialsBasketGrid(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:45', style: AppTextStyles.h4.copyWith(color: AppColors.text)),
          Row(
            spacing: 6,
            children: [
              _buildStatusIcon('assets/icons/signal.png'),
              _buildStatusIcon('assets/icons/wifi.png'),
              _buildStatusIcon('assets/icons/battery.png'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String assetPath) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.muted, width: 0.5),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                // Welcome Text
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome, ',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                      TextSpan(
                        text: 'Chinedu!',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Savings Info
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Cooperative Savings: ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      TextSpan(
                        text: '₦42,500',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),

                // View Benefits Button
                GestureDetector(
                  onTap: () => context.pushNamed('member-benefits'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'View benefits >>>',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Welcome Image
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Image.asset(
              'assets/images/waving hand1.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs() {
    final tabs = [
      {'icon': Icons.shopping_bag, 'label': 'Shop'},
      {'icon': Icons.local_offer, 'label': 'Deals'},
      {'icon': Icons.card_giftcard, 'label': 'Savings'},
      {'icon': Icons.assignment, 'label': 'Orders'},
      {'icon': Icons.repeat, 'label': 'Reorder'},
    ];

    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        boxShadow: [
          BoxShadow(
            color: const Color(0x3F000000),
            blurRadius: 4,
            offset: const Offset(4, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 12,
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            _buildTabButton(
              icon: tabs[i]['icon'] as IconData,
              label: tabs[i]['label'] as String,
            ),
            if (i < tabs.length - 1)
              Container(width: 1, height: 40, color: const Color(0xFFD3D3D3)),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton({required IconData icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: AppColors.primary),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE9E6E6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AppShadows.sm],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Search products...',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
            Icon(Icons.search, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Essentials Basket', 'image': 'assets/images/onboardimg1.jpg'},
      {'name': 'Groceries', 'image': 'assets/images/onboardimg2.jpg'},
      {'name': 'Household', 'image': 'assets/images/Bulk n buz.png'},
      {'name': 'Meat & Poultry', 'image': 'assets/images/Meat1.png'},
      {'name': 'Seafood', 'image': 'assets/images/Crayfish 1.png'},
      {'name': 'Beverages', 'image': 'assets/images/onboardimg1.jpg'},
      {'name': 'Personal Care', 'image': 'assets/images/onboardimg2.jpg'},
      {'name': 'Electronics', 'image': 'assets/images/Bulk n buz.png'},
      {'name': 'Bulk & Business', 'image': 'assets/images/Meat1.png'},
      {'name': 'Deals & Promotion', 'image': 'assets/images/Crayfish 1.png'},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: AppTextStyles.h2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (listContext, index) {
                final category = categories[index];
                return _buildCategoryCard(
                  context: listContext,
                  name: category['name'] as String,
                  image: category['image'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String name,
    required String image,
  }) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'category-products',
          pathParameters: {'categoryName': Uri.encodeComponent(name)},
        );
      },
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppShadows.sm],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: AssetImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.border,
                      child:
                          Icon(Icons.shopping_basket, color: AppColors.muted),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    bool hasIcon = false,
    VoidCallback? onIconTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h2.copyWith(color: AppColors.text)),
          if (hasIcon)
            GestureDetector(
              onTap: onIconTap,
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.primary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberExclusivesCarousel(BuildContext context) {
    final exclusives = [
      {
        'name': 'Golden Sesame seeds',
        'price': '₦8000',
        'original': '₦10,500',
        'save': 'Save ₦1500',
        'image': 'assets/images/onboardimg1.jpg',
        'company': 'Bulk n Buz',
        'logo': 'assets/images/Bulk n buz.png',
      },
      {
        'name': 'Premium Fresh Meat',
        'price': '₦6,500',
        'original': '₦8,000',
        'save': 'Save ₦1500',
        'image': 'assets/images/Meat1.png',
        'company': 'Fresh Farms',
        'logo': 'assets/images/Meat1.png',
      },
      {
        'name': 'Wild Caught Crayfish',
        'price': '₦4,200',
        'original': '₦5,500',
        'save': 'Save ₦1300',
        'image': 'assets/images/Crayfish 1.png',
        'company': 'Sea Harvest',
        'logo': 'assets/images/Crayfish 1.png',
      },
      {
        'name': 'Buck Wheat',
        'price': '₦8000',
        'original': '₦9500',
        'save': 'Save ₦1500',
        'image': 'assets/images/onboardimg1.jpg',
        'company': 'Bulk n Buz',
        'logo': 'assets/images/Bulk n buz.png',
      },
      {
        'name': 'Golden Flax seeds',
        'price': '₦5000',
        'original': '₦5800',
        'save': 'Save ₦800',
        'image': 'assets/images/onboardimg2.jpg',
        'company': 'Bulk n Buz',
        'logo': 'assets/images/Bulk n buz.png',
      },
      {
        'name': 'Peeled oats',
        'price': '₦5000',
        'original': '₦7000',
        'save': 'Save ₦2000',
        'image': 'assets/images/onboardimg1.jpg',
        'company': 'Bulk n Buz',
        'logo': 'assets/images/Bulk n buz.png',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 300,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: exclusives.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = exclusives[index];
            return _buildProductCard(
              name: item['name'] as String,
              price: item['price'] as String,
              original: item['original'] as String,
              save: item['save'] as String,
              image: item['image'] as String,
              company: item['company'] as String,
              logo: item['logo'] as String,
              context: context,
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required String name,
    required String price,
    required String original,
    required String save,
    required String image,
    required String company,
    required String logo,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'product-detail',
          pathParameters: {'productId': name.replaceAll(' ', '_')},
          queryParameters: {
            'name': name,
            'price': price,
            'image': image,
          },
        );
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                color: AppColors.border,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppColors.muted,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  // Company Logo and Name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 6,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppColors.background,
                        ),
                        child: Image.asset(
                          logo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.store,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Text(
                          company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Product Name
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Original Price (strikethrough)
                  Text(
                    'Per 1.5kg | $original',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted.withValues(alpha: 0.7),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),

                  // Sale Price and Savings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(
                            price,
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            save,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.add_circle,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.accent.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Promotional Image
            Image.asset(
              'assets/images/opening img1.jpg',
              width: 80,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 120,
                  color: AppColors.surface.withValues(alpha: 0.2),
                );
              },
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(
                    'Save up to 30%',
                    style: AppTextStyles.h3.copyWith(color: AppColors.text),
                  ),
                  Text(
                    'Limited-time offers on selected items',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Shop now >>>',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w600,
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

  Widget _buildBuyAgainGrid() {
    final buyAgain = [
      {
        'name': 'Groundnut oil',
        'quantity': '1 ltr',
        'price': '₦2500',
        'image': 'assets/images/onboardimg1.jpg',
      },
      {
        'name': 'Crayfish',
        'quantity': '800g',
        'price': '₦5500',
        'image': 'assets/images/Crayfish 1.png',
      },
      {
        'name': 'Tomatoes',
        'quantity': '3 baskets',
        'price': '₦9000',
        'image': 'assets/images/onboardimg2.jpg',
      },
      {
        'name': 'Beef',
        'quantity': '1.1kg',
        'price': '₦3800',
        'image': 'assets/images/Meat1.png',
      },
      {
        'name': 'Shrimps',
        'quantity': '500g',
        'price': '₦7000',
        'image': 'assets/images/Crayfish 1.png',
      },
      {
        'name': 'Full sized chicken',
        'quantity': '1.8kg',
        'price': '₦20,000',
        'image': 'assets/images/Meat1.png',
      },
      {
        'name': '1 Crate of eggs',
        'quantity': 'x24',
        'price': '₦6500',
        'image': 'assets/images/onboardimg1.jpg',
      },
      {
        'name': 'Bag of garri',
        'quantity': '25kg',
        'price': '₦15,000',
        'image': 'assets/images/onboardimg2.jpg',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: buyAgain.length,
        itemBuilder: (context, index) {
          final item = buyAgain[index];
          return _buildBuyAgainCard(
            name: item['name'] as String,
            quantity: item['quantity'] as String,
            price: item['price'] as String,
            image: item['image'] as String,
            context: context,
          );
        },
      ),
    );
  }

  Widget _buildBuyAgainCard({
    required String name,
    required String quantity,
    required String price,
    required String image,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          'product-detail',
          pathParameters: {'productId': name.replaceAll(' ', '_')},
          queryParameters: {
            'name': name,
            'price': price,
            'image': image,
            'quantity': quantity,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: Container(
                height: 100,
                color: AppColors.border,
                width: double.infinity,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child:
                          Icon(Icons.shopping_basket, color: AppColors.muted),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    quantity,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: AppTextStyles.h4.copyWith(color: AppColors.text),
                      ),
                      Icon(Icons.add_circle,
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssentialsBasketGrid() {
    final essentials = [
      {
        'name': 'Family sized',
        'price': '₦45,000',
        'image': 'assets/images/All inclusive pack.png',
      },
      {
        'name': 'All inclusive pack',
        'price': '₦180,000',
        'image': 'assets/images/All inclusive pack.png',
      },
      {
        'name': 'Spices hamper',
        'price': '₦8000',
        'image': 'assets/images/onboardimg1.jpg',
      },
      {
        'name': 'Student hamper',
        'price': '₦22,000',
        'image': 'assets/images/onboardimg2.jpg',
      },
      {
        'name': 'Mini hamper',
        'price': '₦30,000',
        'image': 'assets/images/onboardimg1.jpg',
      },
      {
        'name': 'Family pack',
        'price': '₦55,000',
        'image': 'assets/images/All inclusive pack.png',
      },
      {
        'name': 'Starter pack',
        'price': '₦10,000',
        'image': 'assets/images/onboardimg2.jpg',
      },
      {
        'name': 'Student hamper',
        'price': '₦20,000',
        'image': 'assets/images/onboardimg1.jpg',
      },
      {
        'name': 'Mini food hamper',
        'price': '₦65,000',
        'image': 'assets/images/All inclusive pack.png',
      },
      {
        'name': 'Student hamper',
        'price': '₦25,000',
        'image': 'assets/images/onboardimg2.jpg',
      },
      {
        'name': 'X2 Family pack',
        'price': '₦10,000',
        'image': 'assets/images/All inclusive pack.png',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: essentials.length,
        itemBuilder: (context, index) {
          final item = essentials[index];
          return _buildBuyAgainCard(
            name: item['name'] as String,
            quantity: '',
            price: item['price'] as String,
            image: item['image'] as String,
            context: context,
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [AppShadows.lg],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(icon: Icons.home, label: 'Home', isActive: true),
            _buildNavItem(
              icon: Icons.shopping_cart,
              label: 'Cart',
              isActive: false,
            ),
            _buildNavItem(
              icon: Icons.person,
              label: 'Profile',
              isActive: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.accent : AppColors.surface,
          size: 24,
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.accent : AppColors.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection() {
    return const HomeQuickActionsBar();
  }
}
