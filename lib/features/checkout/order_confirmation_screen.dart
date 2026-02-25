import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/order_providers.dart';
import 'package:coop_commerce/core/services/order_fulfillment_service.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final currentUser = ref.watch(currentUserProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: orderAsync.when(
            data: (order) {
              // If order is null but user's membership tier has been updated, show success
              if (order == null &&
                  currentUser != null &&
                  currentUser.membershipTier != 'free') {
                return _buildMockOrderSuccess(context, currentUser);
              }
              if (order == null) {
                return Center(
                  child:
                      Text('Order not found', style: AppTextStyles.bodyMedium),
                );
              }
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Animated checkmark
                      _buildAnimatedCheckmark(),
                      const SizedBox(height: AppSpacing.lg),

                      // Slide in content
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _slideController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Order Confirmed!',
                              style: AppTextStyles.h1,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Your order has been placed successfully',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.tertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Order details
                      _buildOrderDetails(order),
                      const SizedBox(height: AppSpacing.lg),

                      // Delivery address
                      _buildDeliveryInfo(order),
                      const SizedBox(height: AppSpacing.lg),

                      // Payment info
                      _buildPaymentInfo(order),
                      const SizedBox(height: AppSpacing.xl),

                      // Action buttons
                      _buildActionButtons(context, order),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load order',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCheckmark() {
    return ScaleTransition(
      scale:
          CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
          ),
          child: Center(
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(OrderData order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow('Order ID', order.id.substring(0, 8).toUpperCase()),
          _buildDetailRow('Tracking', order.trackingNumber ?? 'N/A'),
          _buildDetailRow('Order Date', _formatDate(order.createdAt)),
          _buildDetailRow(
            'Estimated Delivery',
            order.estimatedDeliveryAt != null
                ? _formatDate(order.estimatedDeliveryAt!)
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(OrderData order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.address['fullName'] as String? ??
                          'Delivery Address',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.address['fullAddress'] as String? ?? '',
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.address['phoneNumber'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(OrderData order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSummaryRow(
            'Subtotal',
            '₦${order.subtotal.toStringAsFixed(0)}',
          ),
          _buildSummaryRow(
            'Delivery Fee',
            order.deliveryFee == 0
                ? 'Free'
                : '₦${order.deliveryFee.toStringAsFixed(0)}',
          ),
          _buildSummaryRow(
            'You Save',
            '₦${order.totalSavings.toStringAsFixed(0)}',
            color: AppColors.primary,
          ),
          const Divider(height: 16),
          _buildSummaryRow(
            'Total',
            '₦${order.total.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.tertiary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderData order) {
    return Column(
      spacing: AppSpacing.md,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            context.pushNamed('order-tracking', pathParameters: {
              'orderId': order.id,
            });
          },
          icon: const Icon(Icons.local_shipping),
          label: const Text('Track Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        OutlinedButton(
          onPressed: () => context.go('/'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: BorderSide(color: AppColors.primary),
          ),
          child: Text(
            'Continue Shopping',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Build success screen for mock membership orders
  Widget _buildMockOrderSuccess(BuildContext context, User user) {
    final membershipTier = user.membershipTier.toUpperCase();
    final tierColors = {
      'BASIC': Colors.blue,
      'GOLD': Colors.amber,
      'PLATINUM': Colors.purple,
    };
    final tierColor = tierColors[membershipTier] ?? Colors.grey;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Animated checkmark
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[100],
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Payment Successful!',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'You are now a $membershipTier Member',
              style: AppTextStyles.h3.copyWith(
                color: tierColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Membership badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tierColor, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    membershipTier,
                    style: AppTextStyles.h2.copyWith(
                      color: tierColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tier Member',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (membershipTier == 'GOLD')
                    Column(
                      children: [
                        _BenefitRow('15% discount on all products'),
                        _BenefitRow('Free shipping on orders 5000+'),
                        _BenefitRow('Priority customer support'),
                      ],
                    )
                  else if (membershipTier == 'PLATINUM')
                    Column(
                      children: [
                        _BenefitRow('20% discount on all products'),
                        _BenefitRow('Free shipping on all orders'),
                        _BenefitRow('Priority + 24/7 concierge support'),
                        _BenefitRow('Exclusive Platinum store access'),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Order details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membership Details',
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow('Member Name', user.name),
                  _DetailRow('Email', user.email),
                  _DetailRow(
                    'Valid Until',
                    user.membershipExpiryDate != null
                        ? _formatDate(user.membershipExpiryDate!)
                        : 'Active',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tierColor,
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String benefit;

  const _BenefitRow(this.benefit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(benefit, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textLight)),
          Text(value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
