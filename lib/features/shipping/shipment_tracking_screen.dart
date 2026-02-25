import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/shipment_providers.dart';
import 'package:coop_commerce/models/logistics_models.dart';

/// Shipment Tracking Screen
/// View orders, track shipments, and delivery status in real-time
class ShipmentTrackingScreen extends ConsumerStatefulWidget {
  final String memberId;

  const ShipmentTrackingScreen({
    super.key,
    required this.memberId,
  });

  @override
  ConsumerState<ShipmentTrackingScreen> createState() =>
      _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState
    extends ConsumerState<ShipmentTrackingScreen> {
  String _statusFilter = 'all'; // all, pending, inTransit, delivered

  @override
  Widget build(BuildContext context) {
    final shipmentsAsync = ref.watch(
      memberShipmentsProvider(widget.memberId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('My Orders'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(memberShipmentsProvider(widget.memberId));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab('all', 'All Orders'),
                  _buildFilterTab('pending', 'Pending'),
                  _buildFilterTab('inTransit', 'In Transit'),
                  _buildFilterTab('delivered', 'Delivered'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Shipments List
          Expanded(
            child: shipmentsAsync.when(
              data: (shipments) {
                final filtered = _filterShipments(shipments);

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your orders will appear here',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(memberShipmentsProvider(widget.memberId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildShipmentCard(
                        context,
                        ref,
                        filtered[index],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading orders: $err'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isActive = _statusFilter == value;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => setState(() => _statusFilter = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? AppColors.primary : AppColors.textLight,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 20,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Shipment> _filterShipments(List<Shipment> shipments) {
    if (_statusFilter == 'all') return shipments;

    return shipments.where((shipment) {
      switch (_statusFilter) {
        case 'pending':
          return shipment.status == ShipmentStatus.pending ||
              shipment.status == ShipmentStatus.confirmed ||
              shipment.status == ShipmentStatus.picked;
        case 'inTransit':
          return shipment.status == ShipmentStatus.inTransit ||
              shipment.status == ShipmentStatus.outForDelivery;
        case 'delivered':
          return shipment.status == ShipmentStatus.delivered;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildShipmentCard(
    BuildContext context,
    WidgetRef ref,
    Shipment shipment,
  ) {
    final statusColor = _getStatusColor(shipment.status);
    final statusIcon = _getStatusIcon(shipment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showShipmentDetails(context, ref, shipment);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${shipment.orderId.substring(0, 8).toUpperCase()}',
                        style: AppTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(shipment.createdAt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(color: statusColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          shipment.statusDisplayName,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Items summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${shipment.items.length} item${shipment.items.length != 1 ? 's' : ''}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...shipment.items.take(2).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${item.productName} x${item.quantity}',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    if (shipment.items.length > 2)
                      Text(
                        '+ ${shipment.items.length - 2} more',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Shipping info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carrier',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shipment.carrierDisplayName,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tracking',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shipment.trackingNumber,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'KES ${shipment.totalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Delivery estimate
              if (shipment.estimatedDeliveryDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shipment.isDelivered
                              ? 'Delivered ${DateFormat('MMM d, yyyy').format(shipment.deliveredAt!)}'
                              : 'Est. delivery ${DateFormat('MMM d').format(shipment.estimatedDeliveryDate!)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.blue[600],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending:
      case ShipmentStatus.confirmed:
      case ShipmentStatus.picked:
        return Colors.orange;
      case ShipmentStatus.inTransit:
      case ShipmentStatus.outForDelivery:
        return Colors.blue;
      case ShipmentStatus.delivered:
        return Colors.green;
      case ShipmentStatus.failed:
      case ShipmentStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending:
        return Icons.schedule;
      case ShipmentStatus.confirmed:
        return Icons.check_circle_outline;
      case ShipmentStatus.picked:
        return Icons.inventory_2;
      case ShipmentStatus.inTransit:
        return Icons.local_shipping;
      case ShipmentStatus.outForDelivery:
        return Icons.directions_car;
      case ShipmentStatus.delivered:
        return Icons.check_circle;
      case ShipmentStatus.failed:
        return Icons.error_outline;
      case ShipmentStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  void _showShipmentDetails(
    BuildContext context,
    WidgetRef ref,
    Shipment shipment,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ShipmentDetailsPanel(shipment: shipment),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}

/// Detailed shipment information panel
class _ShipmentDetailsPanel extends ConsumerWidget {
  final Shipment shipment;

  const _ShipmentDetailsPanel({required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync =
        ref.watch(trackingHistoryProvider(shipment.shipmentId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${shipment.orderId.substring(0, 8).toUpperCase()}',
                          style: AppTextStyles.titleLarge,
                        ),
                        Text(
                          shipment.trackingNumber,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Recipient info
                _buildSection(
                  'Delivery Address',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipment.shippingAddress.recipientName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        shipment.shippingAddress.fullAddress,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phone: ${shipment.shippingAddress.phoneNumber}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tracking timeline
                _buildSection(
                  'Tracking History',
                  trackingAsync.when(
                    data: (events) {
                      if (events.isEmpty) {
                        return Text(
                          'No tracking updates yet',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        );
                      }

                      return Column(
                        children: List.generate(
                          events.length,
                          (index) => _buildTimelineEvent(
                              events[index], index, events.length),
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, st) => Text('Error: $err'),
                  ),
                ),
                const SizedBox(height: 16),

                // Order summary
                _buildSection(
                  'Order Summary',
                  Column(
                    children: [
                      ...shipment.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName} x${item.quantity}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              Text(
                                'KES ${item.totalPrice.toStringAsFixed(0)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shipping',
                            style: AppTextStyles.bodySmall,
                          ),
                          Text(
                            'KES ${shipment.shippingCost.toStringAsFixed(0)}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: AppTextStyles.titleSmall,
                          ),
                          Text(
                            'KES ${(shipment.totalPrice + shipment.shippingCost).toStringAsFixed(0)}',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: Colors.green,
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
      },
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildTimelineEvent(
    TrackingEvent event,
    int index,
    int total,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getEventColor(event.status),
              ),
            ),
            if (index < total - 1)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.message,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${event.location} • ${DateFormat('MMM d, HH:mm').format(event.timestamp)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getEventColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.delivered:
        return Colors.green;
      case ShipmentStatus.inTransit:
      case ShipmentStatus.outForDelivery:
        return Colors.blue;
      case ShipmentStatus.failed:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
