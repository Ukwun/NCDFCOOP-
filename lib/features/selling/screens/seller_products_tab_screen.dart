import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/models/seller_models.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/seller_providers.dart';

class SellerProductsTabScreen extends ConsumerWidget {
  const SellerProductsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Seller Products'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Sign in to access your seller products'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/signin'),
                  child: const Text('Go to Sign In'),
                ),
              ],
            ),
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
          title: const Text('Seller Products'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Seller Products'),
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
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Seller Products'),
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
                      'Set up your seller profile to see your uploaded products here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.pushNamed(
                          'seller-onboarding',
                          extra: {'userId': user.id, 'sellerType': 'member'},
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
              title: const Text('Seller Products'),
              backgroundColor: AppColors.primary,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Seller Products'),
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
                    const Text(
                      'Unable to load your seller products right now.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(
                        sellerProductsForSellerProvider(
                          (userId: user.id, sellerProfileId: sellerProfile.id),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (products) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Seller Products'),
                backgroundColor: AppColors.primary,
              ),
              body: products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 72, color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              'You have not uploaded any products yet.',
                              style: AppTextStyles.h4
                                  .copyWith(color: AppColors.text),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Products you upload will appear here. Tap the add button on your dashboard to upload a new product.',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _SellerProductCard(
                          product: product,
                          onTap: () => _openProductActions(context, product),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  void _openProductActions(BuildContext context, SellerProduct product) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              Text('Quantity: ${product.quantity} | MOQ: ${product.moq}'),
              Text('Status: ${product.status.displayName}'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if ((product.id ?? '').isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Product is not ready for editing yet.'),
                        ),
                      );
                      return;
                    }
                    context.pushNamed(
                      'seller-product-detail-edit',
                      pathParameters: {'productId': product.id!},
                      extra: {'editable': true},
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Product'),
                ),
              ),
              const SizedBox(height: 8),
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
  }
}

class _SellerProductCard extends StatelessWidget {
  final SellerProduct product;
  final VoidCallback onTap;

  const _SellerProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (product.status) {
      case ProductApprovalStatus.pending:
        statusColor = Colors.amber;
        statusLabel = '🟡 Pending';
        break;
      case ProductApprovalStatus.approved:
        statusColor = Colors.green;
        statusLabel = '🟢 Approved';
        break;
      case ProductApprovalStatus.rejected:
        statusColor = Colors.red;
        statusLabel = '🔴 Rejected';
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12004C39),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: product.imageUrl.trim().isEmpty
                    ? Container(
                        width: 80,
                        height: 80,
                        color: AppColors.background,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textLight,
                        ),
                      )
                    : Image.network(
                        product.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.background,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${product.price.toStringAsFixed(2)}',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Qty: ${product.quantity} | MOQ: ${product.moq}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
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
