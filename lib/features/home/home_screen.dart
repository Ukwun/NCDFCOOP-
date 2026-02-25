import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/features/member/member_tier_progress_widget.dart';
import 'package:coop_commerce/core/providers/notification_providers.dart';
import 'home_viewmodel.dart';
import 'home_widgets.dart';
import 'recommendation_widgets.dart';

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
              _buildHeader(context, ref),
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

              // Quick Access Cards - NEW FEATURES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/member/loyalty'),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green[700]!,
                                    Colors.green[500]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.star_rate,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  const Text(
                                    'Loyalty',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    '2,450 pts',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/orders/tracking'),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[600]!,
                                    Colors.blue[400]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  const Text(
                                    'Delivery',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Track Order',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Member Tier Mini Card
                    MiniMemberTierCard(
                      currentPoints: 2450,
                      currentTier: 'GOLD',
                      onTap: () => context.push('/member/loyalty'),
                    ),
                  ],
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

              // Personalized Recommendations Section
              const PersonalizedRecommendationsSection(),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final unreadNotifications = ref.watch(unreadNotificationsProvider);

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
              // Notification button with badge
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: AppShadows.smList,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        context.push('/notifications');
                      },
                    ),
                  ),
                  // Badge showing unread count
                  unreadNotifications.when(
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            notifications.length > 99
                                ? '99+'
                                : notifications.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
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
