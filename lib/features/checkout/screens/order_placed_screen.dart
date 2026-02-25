import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class OrderPlacedScreen extends StatefulWidget {
  final String orderId;
  final String? orderDate;
  final double? totalAmount;

  const OrderPlacedScreen({
    super.key,
    required this.orderId,
    this.orderDate,
    this.totalAmount,
  });

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen> {
  late String displayDate;
  late String displayAmount;

  @override
  void initState() {
    super.initState();
    displayDate = widget.orderDate ?? DateTime.now().toString().split(' ')[0];
    displayAmount = widget.totalAmount?.toStringAsFixed(0) ?? '0';
  }

  void _trackOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Order tracking - coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to order history with filter
  }

  void _continueShopping() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Success animation/icon
                  _buildSuccessAnimation(),

                  const SizedBox(height: 32),

                  // Order placed message
                  const Text(
                    'Order Placed Successfully!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Thank you for your order. Your payment has been processed.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Order details card
                  _buildOrderDetailsCard(),

                  const SizedBox(height: 24),

                  // Delivery timeline
                  _buildDeliveryTimeline(),

                  const SizedBox(height: 32),

                  // Action buttons
                  _buildActionButtons(),

                  const SizedBox(height: 24),

                  // Help section
                  _buildHelpSection(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.success.withOpacity(0.15),
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withOpacity(0.3),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Number',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📋 Copied: ${widget.orderId}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Text(
                  widget.orderId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),

          // Order date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Date',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                displayDate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),

          // Total amount
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
                '₦$displayAmount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),

          // Estimated delivery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Delivery',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3-5 Business Days',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.local_shipping,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Timeline',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        _buildTimelineStep(
          number: '1',
          title: 'Order Confirmed',
          description: 'Payment received',
          completed: true,
        ),
        _buildTimelineConnector(),
        _buildTimelineStep(
          number: '2',
          title: 'Processing',
          description: 'Preparing your order',
          completed: false,
        ),
        _buildTimelineConnector(),
        _buildTimelineStep(
          number: '3',
          title: 'Shipped',
          description: 'On its way to you',
          completed: false,
        ),
        _buildTimelineConnector(),
        _buildTimelineStep(
          number: '4',
          title: 'Delivered',
          description: 'Estimated in 3-5 days',
          completed: false,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String number,
    required String title,
    required String description,
    required bool completed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? AppColors.success : Colors.grey[300],
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: completed ? AppColors.success : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 0, bottom: 0),
      child: SizedBox(
        height: 20,
        child: VerticalDivider(
          color: Colors.grey[300],
          thickness: 2,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Track order button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _trackOrder,
            icon: const Icon(Icons.location_on),
            label: const Text('Track Your Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Continue shopping button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _continueShopping,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue Shopping',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Need Help?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A confirmation email has been sent to your email address with order details.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📧 Contact support'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Contact Customer Support',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
