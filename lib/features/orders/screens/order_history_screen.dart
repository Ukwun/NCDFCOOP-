import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/widgets/product_image.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

extension OrderStatusExt on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return '⏳ Pending';
      case OrderStatus.processing:
        return '📦 Processing';
      case OrderStatus.shipped:
        return '🚚 Shipped';
      case OrderStatus.delivered:
        return '✅ Delivered';
      case OrderStatus.cancelled:
        return '❌ Cancelled';
    }
  }

  Color get statusColor {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return AppColors.primary;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }
}

class OrderItem {
  final String orderId;
  final String orderDate;
  final double totalAmount;
  final OrderStatus status;
  final List<OrderProduct> products;
  final String deliveryAddress;
  final String? trackingNumber;

  OrderItem({
    required this.orderId,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.products,
    required this.deliveryAddress,
    this.trackingNumber,
  });
}

class OrderProduct {
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;

  OrderProduct({
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });
}

class OrderHistoryScreen extends StatefulWidget {
  final List<OrderItem>? mockOrders;

  const OrderHistoryScreen({super.key, this.mockOrders});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late List<OrderItem> orders;
  OrderStatus? selectedFilter;

  @override
  void initState() {
    super.initState();
    orders = widget.mockOrders ??
        [
          OrderItem(
            orderId: 'ORD-2026-001',
            orderDate: 'Feb 14, 2026',
            totalAmount: 15650,
            status: OrderStatus.delivered,
            products: [
              OrderProduct(
                name: 'Premium Basmati Rice (5kg)',
                quantity: 2,
                price: 6800,
                imageUrl:
                    'https://images.unsplash.com/photo-1638551112442-20fcf9f96f64?w=100&h=100&fit=crop',
              ),
              OrderProduct(
                name: 'Organic Sugar (2kg)',
                quantity: 1,
                price: 2500,
                imageUrl:
                    'https://images.unsplash.com/photo-1599599810694-b6be7d4a7c67?w=100&h=100&fit=crop',
              ),
            ],
            deliveryAddress: '123 Lagos Street, Victoria Island, Lagos',
            trackingNumber: 'TRK-2026-001-ABC',
          ),
          OrderItem(
            orderId: 'ORD-2026-002',
            orderDate: 'Feb 10, 2026',
            totalAmount: 8200,
            status: OrderStatus.shipped,
            products: [
              OrderProduct(
                name: 'Ground Pepper (500g)',
                quantity: 1,
                price: 8200,
                imageUrl:
                    'https://images.unsplash.com/photo-1599599810694-b6be7d4a7c67?w=100&h=100&fit=crop',
              ),
            ],
            deliveryAddress: '456 Abuja Road, Central Area, Abuja',
            trackingNumber: 'TRK-2026-002-XYZ',
          ),
          OrderItem(
            orderId: 'ORD-2026-003',
            orderDate: 'Feb 5, 2026',
            totalAmount: 3800,
            status: OrderStatus.processing,
            products: [
              OrderProduct(
                name: 'Cooking Oil (1L)',
                quantity: 1,
                price: 3800,
                imageUrl:
                    'https://images.unsplash.com/photo-1599599810694-b6be7d4a7c67?w=100&h=100&fit=crop',
              ),
            ],
            deliveryAddress: '789 Kano Street, Kano City, Kano',
            trackingNumber: null,
          ),
          OrderItem(
            orderId: 'ORD-2026-004',
            orderDate: 'Jan 28, 2026',
            totalAmount: 12500,
            status: OrderStatus.cancelled,
            products: [
              OrderProduct(
                name: 'Tomato Paste (2kg)',
                quantity: 2,
                price: 6250,
                imageUrl:
                    'https://images.unsplash.com/photo-1599599810694-b6be7d4a7c67?w=100&h=100&fit=crop',
              ),
            ],
            deliveryAddress: '321 Enugu Avenue, Enugu, Enugu',
            trackingNumber: null,
          ),
        ];
  }

  List<OrderItem> get filteredOrders {
    if (selectedFilter == null) return orders;
    return orders.where((order) => order.status == selectedFilter).toList();
  }

  void _reorderItems(OrderItem order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('🛒 Added ${order.products.length} items from order to cart'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Add items to cart programmatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '📦 Order History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // All orders chip
                FilterChip(
                  label: const Text('All Orders'),
                  selected: selectedFilter == null,
                  onSelected: (selected) {
                    setState(() => selectedFilter = null);
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppColors.primary.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                // Status filter chips
                ...OrderStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.displayName),
                      selected: selectedFilter == status,
                      onSelected: (selected) {
                        setState(
                          () => selectedFilter = selected ? status : null,
                        );
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: status.statusColor.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(filteredOrders[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Orders Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedFilter != null
                ? 'No orders with this status'
                : 'Start shopping to see orders here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderItem order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.orderDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: order.status.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: order.status.statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: ProductImage(
                            imageUrl: product.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${product.quantity}x @ ₦${product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.grey[200], height: 1),

          // Footer info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₦${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (order.trackingNumber != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tracking #',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        order.trackingNumber!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  order.deliveryAddress,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('📊 Order details: ${order.orderId}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _reorderItems(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Reorder',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
