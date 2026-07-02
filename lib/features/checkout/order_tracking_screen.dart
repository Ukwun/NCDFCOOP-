import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmf;
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/models/order.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/core/providers/order_providers.dart';
import 'package:coop_commerce/core/providers/real_time_providers.dart';
import 'package:coop_commerce/core/widgets/order_notification_listener.dart';
import 'package:coop_commerce/core/services/map_service.dart';
import 'package:coop_commerce/core/services/order_fulfillment_service.dart'
    as ofs;
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/cart_provider.dart';
import 'package:coop_commerce/core/providers/home_providers.dart';
import 'package:coop_commerce/features/checkout/order_tracking_helpers.dart';
import 'package:coop_commerce/features/selling/seller_earnings_screen.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final ofs.OrderFulfillmentService _fulfillmentService =
      ofs.OrderFulfillmentService();
  gmf.GoogleMapController? _mapController;
  final List<OrderStatus> _statusProgression = [
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.dispatched,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final role = ref.watch(currentRoleProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Real-time order fulfillment status updates
    final fulfillmentUpdateAsync =
        ref.watch(orderFulfillmentUpdateProvider(widget.orderId));

    // Real-time warehouse progress
    final warehouseProgressAsync =
        ref.watch(warehouseOperationsProgressProvider(widget.orderId));

    return OrderNotificationListener(
      orderId: widget.orderId,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Track Order'),
          elevation: 0,
        ),
        body: orderAsync.when(
          data: (orderData) {
            if (orderData == null) {
              return Center(
                child: Text('Order not found', style: AppTextStyles.bodyMedium),
              );
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    // Order ID and Status
                    _buildOrderHeader(orderData, role),
                    const SizedBox(height: AppSpacing.lg),

                    _buildRoleAwareSummary(orderData, role, currentUser),
                    const SizedBox(height: AppSpacing.lg),

                    _buildRoleAwareActions(orderData, role),
                    const SizedBox(height: AppSpacing.lg),

                    // Timeline
                    _buildStatusTimeline(orderData),
                    const SizedBox(height: AppSpacing.lg),

                    // Real-time Fulfillment Status Updates
                    fulfillmentUpdateAsync.when(
                      data: (fulfillmentUpdate) {
                        // Only show banner if status changed
                        if (fulfillmentUpdate.previousStatus != null &&
                            fulfillmentUpdate.previousStatus !=
                                fulfillmentUpdate.status) {
                          return Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                      size: 24,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order Status Updated',
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.xs,
                                          ),
                                          Text(
                                            'Status: ${fulfillmentUpdate.status.toUpperCase()}',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: Colors.green[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      error: (error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                    ),

                    // Live Warehouse Progress (Real-Time)
                    warehouseProgressAsync.when(
                      data: (progress) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Warehouse Progress',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      Text(
                                        '${progress.percentComplete.toInt()}%',
                                        style: AppTextStyles.h4.copyWith(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress.percentComplete / 100,
                                      minHeight: 6,
                                      backgroundColor: Colors.blue[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue[700]!,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Current: ${progress.currentStep}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                  if (progress.estimatedCompletionTime != null)
                                    Text(
                                      'Est. completion: ${progress.estimatedCompletionTime!.difference(DateTime.now()).inMinutes} min',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.blue[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),

                    // Driver Info
                    if (orderData.orderStatus.index >=
                        OrderStatus.dispatched.index)
                      _buildDriverInfo(orderData),

                    if (orderData.orderStatus.index >=
                        OrderStatus.outForDelivery.index)
                      Column(
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          _buildMapPlaceholder(),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),

                    // Order Details
                    _buildOrderItems(orderData),
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
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style:
                AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Future<void> _reorderItems(ofs.OrderData order) async {
    final cartNotifier = ref.read(cartProvider.notifier);
    for (final item in order.items) {
      await cartNotifier.addItem(
        CartItem(
          id: '${item.productId}-${DateTime.now().microsecondsSinceEpoch}',
          productId: item.productId,
          productName: item.name,
          memberPrice: item.price,
          marketPrice: item.price,
          quantity: item.quantity,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Reordered ${order.items.length} item(s) into your cart.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _handleSellerAction(
      Future<void> Function() action, String label, String successText) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(successText), backgroundColor: AppColors.primary),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Unable to $label: $error'),
            backgroundColor: AppColors.error),
      );
    }
  }

  Color _roleAccentColor(UserRole role) {
    return switch (role) {
      UserRole.seller => AppColors.primary,
      UserRole.wholesaleBuyer => AppColors.accent,
      _ => AppColors.tertiary,
    };
  }

  IconData _roleIcon(UserRole role) {
    return switch (role) {
      UserRole.seller => Icons.storefront_outlined,
      UserRole.wholesaleBuyer => Icons.warehouse_outlined,
      _ => Icons.person_outline,
    };
  }

  String _roleLabel(UserRole role) => roleDisplayLabel(role);

  String _roleFocusText(UserRole role) => roleFocusText(role);

  Widget _buildMapPlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Live tracking map',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(ofs.OrderData order, UserRole role) {
    final accent = _roleAccentColor(role);
    final roleLabel = _roleLabel(role);
    final focusText = _roleFocusText(role);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${orderReferenceLabel(order.id)}',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$roleLabel view · ${order.trackingNumber ?? 'Live update'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(order.orderStatus).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.orderStatus.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(order.orderStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            focusText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.orderStatus.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleAwareSummary(
      ofs.OrderData order, UserRole role, dynamic currentUser) {
    final accent = _roleAccentColor(role);
    final summaryLabel = roleSummaryLabel(role);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_roleIcon(role), color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summaryLabel,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      currentUser?.name?.isNotEmpty == true
                          ? 'Signed in as ${currentUser!.name}'
                          : 'Live order view',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip('Items', '${order.items.length}'),
              _infoChip('Total', '₦${order.totalAmount.toStringAsFixed(0)}'),
              _infoChip('Address',
                  order.shippingAddress.isNotEmpty ? 'Set' : 'Pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleAwareActions(ofs.OrderData order, UserRole role) {
    if (role == UserRole.seller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seller actions', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (['submitted', 'pending', 'draft']
                  .contains(order.status.toLowerCase()))
                FilledButton.icon(
                  onPressed: () => _handleSellerAction(
                      () => _fulfillmentService.approveOrder(order.id),
                      'Approved',
                      'Order approved for fulfillment.'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Approve'),
                ),
              if (['approved', 'processing']
                  .contains(order.status.toLowerCase()))
                FilledButton.icon(
                  onPressed: () => _handleSellerAction(
                      () => _fulfillmentService.startFulfillment(order.id),
                      'Processing',
                      'Fulfillment started.'),
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('Process'),
                ),
              if (['processing', 'packed'].contains(order.status.toLowerCase()))
                FilledButton.icon(
                  onPressed: () => _handleSellerAction(
                      () => _fulfillmentService.markItemsPacked(
                          orderId: order.id,
                          itemIds: order.items.map((item) => item.id).toList()),
                      'Packed',
                      'Items marked as packed.'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Pack'),
                ),
              if (order.status.toLowerCase() == 'packed')
                FilledButton.icon(
                  onPressed: () => _handleSellerAction(
                      () => _fulfillmentService.shipOrder(
                          orderId: order.id,
                          carrier: 'Coop Delivery',
                          trackingNumber:
                              'CD-${order.id.substring(0, 6).toUpperCase()}',
                          estimatedDelivery: '2 business days'),
                      'Shipped',
                      'Order shipped.'),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Ship'),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SellerEarningsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Payouts'),
              ),
              if (order.status.toLowerCase() == 'shipped')
                FilledButton.icon(
                  onPressed: () => _handleSellerAction(
                      () => _fulfillmentService.markDelivered(order.id),
                      'Delivered',
                      'Order marked delivered.'),
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Deliver'),
                ),
              if (!['delivered', 'cancelled']
                  .contains(order.status.toLowerCase()))
                OutlinedButton.icon(
                  onPressed: () => _handleSellerAction(
                      () => _fulfillmentService.cancelOrder(
                          orderId: order.id,
                          reason: 'Seller cancelled after review.'),
                      'Cancelled',
                      'Order cancelled.'),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role == UserRole.wholesaleBuyer
              ? 'Wholesale buyer actions'
              : 'Member actions',
          style: AppTextStyles.labelMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _reorderItems(order),
              icon: const Icon(Icons.refresh),
              label: const Text('Reorder items'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.pushNamed('orders'),
              icon: const Icon(Icons.history),
              label: const Text('View history'),
            ),
            if (role == UserRole.wholesaleBuyer)
              OutlinedButton.icon(
                onPressed: () => _showWholesaleSupportSheet(order),
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('Talk to support'),
              ),
            if (role != UserRole.wholesaleBuyer)
              OutlinedButton.icon(
                onPressed: () => _showMemberBenefitsSheet(order),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Member benefits'),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _showMemberBenefitsSheet(ofs.OrderData order) async {
    final userId = ref.read(currentUserProvider)?.id ?? '';
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final memberDataAsync = ref.watch(memberDataProvider(userId));

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Member benefits are active',
                      style: AppTextStyles.h4,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your membership unlocks savings, dividends, and faster support on real orders.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              memberDataAsync.when(
                data: (memberData) {
                  final tier = (memberData?.tier ?? 'bronze').toUpperCase();
                  final discount = memberData?.discountPercentage ?? 0.0;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current tier: $tier',
                            style: AppTextStyles.labelMedium),
                        const SizedBox(height: 6),
                        Text(
                            'Member discount: ${discount.toStringAsFixed(0)}%'),
                        const SizedBox(height: 6),
                        Text(
                            'Your order qualifies for member pricing and priority support.'),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) =>
                    const Text('Member benefits are currently syncing.'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.pushNamed('dashboard');
                },
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('Open member dashboard'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showWholesaleSupportSheet(ofs.OrderData order) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Wholesale support desk',
                      style: AppTextStyles.h4,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your bulk order receives priority handling and a live account specialist with every update.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Order value: ₦${order.totalAmount.toStringAsFixed(0)}',
                        style: AppTextStyles.labelMedium),
                    const SizedBox(height: 6),
                    Text(
                        'Expected response: within 30 minutes during business hours.'),
                    const SizedBox(height: 6),
                    Text(
                        'Next step: we will confirm your delivery and stock availability.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Wholesale support has been notified.')),
                  );
                },
                icon: const Icon(Icons.headset_mic_outlined),
                label: const Text('Request a callback'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusTimeline(ofs.OrderData order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ..._statusProgression.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isCompleted = order.orderStatus.index >= index;
            final isCurrent = order.orderStatus == status;

            return Column(
              children: [
                Row(
                  children: [
                    // Timeline dot
                    ScaleTransition(
                      scale: isCurrent
                          ? Tween<double>(begin: 1.0, end: 1.3).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Curves.elasticOut,
                              ),
                            )
                          : AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.secondary.withValues(alpha: 0.3),
                          border: isCurrent
                              ? Border.all(
                                  color: AppColors.primary,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: isCompleted
                            ? Center(
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isCompleted
                                  ? Colors.black87
                                  : AppColors.tertiary,
                            ),
                          ),
                          if (status == OrderStatus.delivered &&
                              order.deliveredAt != null)
                            Text(
                              'Delivered on ${_formatDate(order.deliveredAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.tertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index < _statusProgression.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 13),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 24,
                      width: 2,
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDriverInfo(ofs.OrderData order) {
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
            'Driver Details',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                  image: order.driverImage != null
                      ? DecorationImage(
                          image: NetworkImage(order.driverImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: order.driverImage == null
                    ? Center(
                        child: Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.driverName ?? 'Driver',
                      style: AppTextStyles.labelMedium,
                    ),
                    if (order.driverRating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < order.driverRating!.toInt()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${order.driverRating}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (order.driverPhone != null)
                GestureDetector(
                  onTap: () {
                    // Call driver
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling ${order.driverPhone}'),
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.call,
                      color: AppColors.primary,
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

  Set<gmf.Marker> _buildMapMarkers(
      ofs.OrderData order, gmf.LatLng deliveryLocation) {
    final markers = <gmf.Marker>{};

    // Warehouse marker
    markers.add(
      gmf.Marker(
        markerId: const gmf.MarkerId('warehouse'),
        position: MapService.getWarehouseLocation(),
        infoWindow: const gmf.InfoWindow(
          title: 'Warehouse',
          snippet: 'Order Distribution Hub',
        ),
      ),
    );

    // Delivery location marker
    markers.add(
      gmf.Marker(
        markerId: const gmf.MarkerId('delivery'),
        position: deliveryLocation,
        infoWindow: gmf.InfoWindow(
          title: 'Delivery Location',
          snippet:
              order.address['fullAddress'] as String? ?? 'Delivery Address',
        ),
      ),
    );

    return markers;
  }

  Set<gmf.Polyline> _buildMapPolylines(gmf.LatLng deliveryLocation) {
    return {
      gmf.Polyline(
        polylineId: const gmf.PolylineId('route'),
        points: [
          MapService.getWarehouseLocation(),
          deliveryLocation,
        ],
        color: AppColors.primary,
        width: 4,
        geodesic: true,
      ),
    };
  }

  Set<gmf.Circle> _buildMapCircles(
      ofs.OrderData order, gmf.LatLng deliveryLocation) {
    return {
      // Delivery area radius (500m)
      gmf.Circle(
        circleId: const gmf.CircleId('delivery_area'),
        center: deliveryLocation,
        radius: 500,
        fillColor: AppColors.primary.withValues(alpha: 0.1),
        strokeColor: AppColors.primary,
        strokeWidth: 1,
      ),
    };
  }

  void _updateMapCamera(gmf.LatLng location) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        gmf.CameraUpdate.newCameraPosition(
          gmf.CameraPosition(
            target: location,
            zoom: 15,
          ),
        ),
      );
    }
  }

  Widget _buildDeliveryLocationCard() {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return orderAsync.when(
      data: (order) {
        if (order == null) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Order not found'),
          );
        }
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Location',
                          style: AppTextStyles.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.address['fullAddress'] as String? ??
                              'Delivery Address',
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (order.estimatedDeliveryAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: AppColors.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Est. Delivery',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    Text(
                      _formatDeliveryTime(order.estimatedDeliveryAt!),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stackTrace) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Location unavailable',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
        ),
      ),
    );
  }

  String _formatDeliveryTime(DateTime deliveryTime) {
    final now = DateTime.now();
    final difference = deliveryTime.difference(now);

    if (difference.isNegative) {
      return 'Delivered';
    } else if (difference.inHours == 0) {
      return 'In ${difference.inMinutes} mins';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      final days = difference.inDays;
      return 'In $days day${days > 1 ? 's' : ''}';
    }
  }

  Widget _buildOrderItems(ofs.OrderData order) {
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
            'Items in Order (${order.items.length})',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  if (item.imageUrl != null)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: item.imageUrl!.startsWith('assets/')
                              ? AssetImage(item.imageUrl!)
                              : NetworkImage(item.imageUrl!) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.secondary.withValues(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.shopping_bag,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.quantity} x ₦${item.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₦${(item.price * item.quantity).toStringAsFixed(0)}',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending ||
      OrderStatus.confirmed ||
      OrderStatus.processing =>
        Colors.orange,
      OrderStatus.dispatched || OrderStatus.outForDelivery => Colors.blue,
      OrderStatus.delivered => Colors.green,
      OrderStatus.cancelled || OrderStatus.failed => Colors.red,
    };
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
}
