import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: cartState.items.isEmpty
          ? _buildEmptyCart()
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context, cartState),
                  _buildCartItems(context, ref, cartState, cartNotifier),
                  const SizedBox(height: 20),
                  _buildSummary(cartState),
                  const SizedBox(height: 20),
                  _buildCheckoutButton(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }



  Widget _buildHeader(BuildContext context, cartState) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('9:45',
                  style: AppTextStyles.h4.copyWith(
                      color: AppColors.surface)),
              Row(spacing: 6, children: [
                _buildStatusIcon('assets/icons/signal.png'),
                _buildStatusIcon('assets/icons/wifi.png'),
                _buildStatusIcon('assets/icons/battery.png'),
              ]),
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
                    context.go('/');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: AppColors.surface, size: 18),
                ),
              ),
              Text('Shopping Cart',
                  style: AppTextStyles.h3
                      .copyWith(color: AppColors.surface)),
              Container(
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    cartState.itemCount.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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

  Widget _buildCartItems(BuildContext context, WidgetRef ref, cartState,
      cartNotifier) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(cartState.items.length, (index) {
          final item = cartState.items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCartItemCard(context, ref, item, cartNotifier),
          );
        }),
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, WidgetRef ref, item,
      cartNotifier) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [AppShadows.sm],
      ),
      child: Row(
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
            ),
            child: item.imageUrl != null
                ? item.imageUrl!.startsWith('assets/')
                    ? Image.asset(item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.shopping_basket,
                              color: AppColors.muted);
                        })
                    : Image.network(item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.shopping_basket,
                              color: AppColors.muted);
                        })
                : Icon(Icons.shopping_basket, color: AppColors.muted),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    spacing: 8,
                    children: [
                      Text(
                        '₦${item.memberPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '₦${item.marketPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                cartNotifier.updateQuantity(
                                    item.productId, item.quantity - 1);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                child: Icon(Icons.remove,
                                    size: 16,
                                    color: AppColors.primary),
                              ),
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                item.quantity.toString(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                cartNotifier.updateQuantity(
                                    item.productId, item.quantity + 1);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                child: Icon(Icons.add,
                                    size: 16,
                                    color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          cartNotifier.removeItem(item.productId);
                        },
                        child: Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 80, color: AppColors.muted),
            const SizedBox(height: 16),
            Text('Your cart is empty',
                style: AppTextStyles.h3
                    .copyWith(color: AppColors.text)),
            const SizedBox(height: 8),
            Text('Add items to get started',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(cartState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [AppShadows.sm],
      ),
      child: Column(
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.muted)),
              Text(
                '₦${cartState.subtotal.toStringAsFixed(0)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('You Save',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
                Text(
                  '₦${cartState.totalSavings.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.muted)),
              Text(
                cartState.deliveryFee == 0
                    ? 'FREE'
                    : '₦${cartState.deliveryFee}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: cartState.deliveryFee == 0
                      ? AppColors.accent
                      : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Divider(color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  )),
              Text(
                '₦${cartState.totalPrice.toStringAsFixed(0)}',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8)
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [AppShadows.md],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            }
            context.goNamed('checkout-address');
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    color: AppColors.surface),
                Text(
                  'Proceed to Checkout',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
