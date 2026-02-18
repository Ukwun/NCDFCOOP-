import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'home_viewmodel.dart';
import 'home_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with search and notifications
              _buildHeader(context),
              const SizedBox(height: AppSpacing.md),

              // Member Savings Banner
              homeState.when(
                data: (data) => MemberSavingsBanner(
                  totalSavings: data.totalMemberSavings,
                  itemsSaved: data.itemsSavedCount,
                ),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SizedBox(
                  height: 120,
                  child: Center(child: Text('Error loading savings: $err')),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Featured Categories Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shop by Category', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              homeState.when(
                data: (data) =>
                    CategoryGridWidget(categories: data.featuredCategories),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SizedBox(
                  height: 200,
                  child: Center(child: Text('Error loading categories: $err')),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Member Exclusive Deals Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Member Exclusive', style: AppTextStyles.h3),
                        Text(
                          'Limited time offers for members',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'View All',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              homeState.when(
                data: (data) =>
                    MemberExclusiveSlider(products: data.exclusiveProducts),
                loading: () => const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SizedBox(
                  height: 280,
                  child: Center(child: Text('Error loading products: $err')),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Trending Products Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trending Now', style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              homeState.when(
                data: (data) =>
                    TrendingProductsGrid(products: data.trendingProducts),
                loading: () => const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SizedBox(
                  height: 300,
                  child: Center(child: Text('Error loading trending: $err')),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Logo and notifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coop Commerce',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    'Member Benefits Unlocked',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.smList,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Search bar
          TextField(
            onTap: () {
              context.pushNamed('search');
            },
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Search products, categories...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
