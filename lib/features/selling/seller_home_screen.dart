import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/seller_dashboard_screen.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_providers.dart';
import '../../core/auth/role.dart';
import '../../core/models/seller_models.dart';

/// Seller Home Screen - wrapper for SellerDashboardScreen
/// Provides the necessary data from providers
class SellerHomeScreen extends ConsumerWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Sign in to access your seller dashboard'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/signin'),
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final sellerProfileAsync =
        ref.watch(sellerProfileByUserIdProvider(user.id));

    return sellerProfileAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 10),
                Text('Unable to load seller profile: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(sellerProfileByUserIdProvider(user.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (sellerProfile) {
        if (sellerProfile == null || (sellerProfile.id?.isEmpty ?? true)) {
          final sellerType =
              user.hasRole(UserRole.wholesaleBuyer) ? 'wholesale' : 'member';
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Seller Dashboard'),
              backgroundColor: AppColors.primary,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_mall_directory,
                        size: 64, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Set up your seller profile to start listing products.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.pushNamed(
                          'seller-onboarding',
                          extra: {'userId': user.id, 'sellerType': sellerType},
                        );
                      },
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('Start Seller Setup'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final productsAsync = ref.watch(
          sellerProductsForSellerProvider(
            (userId: user.id, sellerProfileId: sellerProfile.id),
          ),
        );
        return productsAsync.when(
          loading: () => Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Seller Dashboard'),
              backgroundColor: AppColors.primary,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Seller Dashboard'),
              backgroundColor: AppColors.primary,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 56, color: Colors.red),
                    const SizedBox(height: 10),
                    Text('Unable to load products: $error'),
                  ],
                ),
              ),
            ),
          ),
          data: (products) {
            return SellerDashboardScreen(
              businessName: sellerProfile.businessName,
              products: products,
              onAddNewProduct: () async {
                final added = await context.pushNamed<bool>(
                  'seller-add-product',
                  extra: {
                    'userId': user.id,
                    'sellerType': sellerProfile.sellingPath,
                  },
                );

                if (added == true) {
                  ref.invalidate(
                    sellerProductsForSellerProvider(
                      (userId: user.id, sellerProfileId: sellerProfile.id),
                    ),
                  );
                }
              },
              onProductTap: (SellerProduct product) {
                showModalBottomSheet<void>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.productName, style: AppTextStyles.h3),
                          const SizedBox(height: 8),
                          Text('Price: ₦${product.price.toStringAsFixed(2)}'),
                          Text(
                              'Quantity: ${product.quantity} | MOQ: ${product.moq}'),
                          Text('Status: ${product.status.displayName}'),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
