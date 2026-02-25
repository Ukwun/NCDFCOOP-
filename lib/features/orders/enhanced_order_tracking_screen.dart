import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Enhanced Order Tracking Screen - MVP with real-time status simulation
class EnhancedOrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const EnhancedOrderTrackingScreen({Key? key, required this.orderId})
    : super(key: key);

  @override
  ConsumerState<EnhancedOrderTrackingScreen> createState() =>
      _EnhancedOrderTrackingScreenState();
}

class _EnhancedOrderTrackingScreenState
    extends ConsumerState<EnhancedOrderTrackingScreen> {
  late int currentStatusIndex;

  @override
  void initState() {
    super.initState();
    currentStatusIndex = 2; // Start at "Shipped"

    // Simulate status progression every 10 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));
      if (mounted && currentStatusIndex < 4) {
        setState(() {
          currentStatusIndex++;
        });
      }
      return currentStatusIndex < 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    const statuses = [
      'Order Placed',
      'Confirmed',
      'Shipped',
      'Out for Delivery',
      'Delivered',
    ];
    const icons = [
      Icons.shopping_cart,
      Icons.check_circle,
      Icons.local_shipping,
      Icons.delivery_dining,
      Icons.done_all,
    ];
    const times = [
      'Feb 21, 2:30 PM',
      'Feb 21, 2:45 PM',
      'Feb 21, 4:15 PM',
      'Feb 21, 5:00 PM',
      'Feb 21, 5:30 PM',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${widget.orderId}'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Status Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statuses[currentStatusIndex],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentStatusIndex >= 4
                          ? 'Delivered successfully'
                          : 'Expected delivery: Feb 21, 5:30 PM',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order Items Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildOrderItemPreview(
                    productName: 'Premium Rice (25kg)',
                    quantity: 2,
                    price: 12000,
                  ),
                  const SizedBox(height: 8),
                  _buildOrderItemPreview(
                    productName: 'Cooking Oil (5L)',
                    quantity: 1,
                    price: 8500,
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₦32,500',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timeline Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Timeline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(
                    statuses.length,
                    (index) => _buildTimelineStep(
                      icon: icons[index],
                      status: statuses[index],
                      time: times[index],
                      isCompleted: index <= currentStatusIndex,
                      isActive: index == currentStatusIndex,
                      isLastItem: index == statuses.length - 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Delivery Address Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.red[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chinedu Okoro',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '123 Lekki Road, Ikoyi\nLagos, 106104\nNigeria',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '+234 800 123 4567',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (currentStatusIndex >= 3)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening tracker (mock)...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text('Track Delivery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contacting seller (mock)...'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble),
                      label: const Text('Contact Seller'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.green[700]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemPreview({
    required String productName,
    required int quantity,
    required double price,
  }) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.shopping_bag, color: Colors.grey[600], size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: $quantity',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Text(
          '₦${(price * quantity).toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String status,
    required String time,
    required bool isCompleted,
    required bool isActive,
    required bool isLastItem,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green[600] : Colors.grey[300],
                border: isActive
                    ? Border.all(color: Colors.green[600]!, width: 3)
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (!isLastItem)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green[600] : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green[700] : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
