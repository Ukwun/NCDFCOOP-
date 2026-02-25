import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/services/payment_gateway_service.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/real_time_orders_provider.dart';
import 'package:coop_commerce/models/order.dart';

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final double amount;
  final String paymentMethod;

  const PaymentProcessingScreen({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  ConsumerState<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState
    extends ConsumerState<PaymentProcessingScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  bool _paymentSuccess = false;

  @override
  void initState() {
    super.initState();
    // Auto-initiate payment processing
    Future.delayed(const Duration(milliseconds: 500), _initiatePayment);
  }

  Future<void> _initiatePayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw 'User not authenticated';
      }

      // Get payment method details
      final paymentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('payment_methods')
          .doc(widget.paymentMethod)
          .get();

      if (!paymentDoc.exists) {
        throw 'Payment method not found';
      }

      final methodData = paymentDoc.data()!;
      final paymentType = methodData['type'] as String? ?? 'credit_card';

      // Show payment dialog based on method type
      if (!mounted) return;

      if (paymentType == 'bank_transfer') {
        _showBankTransferDialog();
      } else {
        await _processCardPayment(user.id, methodData);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _processCardPayment(
      String userId, Map<String, dynamic> methodData) async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Process payment via Flutterwave
      final paymentService = PaymentGatewayService.instance;
      final result = await paymentService.processFlutterwave(
        orderId: widget.orderId,
        amount: widget.amount,
        email: user.email,
        phoneNumber: user.phoneNumber,
        fullName: user.name,
        description: 'Order #${widget.orderId}',
      );

      if (!mounted) return;

      if (result.success) {
        // Update order payment status in Firestore
        await updateOrderPaymentStatus(
          userId,
          widget.orderId,
          PaymentStatus.success,
        );

        // Add transaction record
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'transactionId': result.transactionId,
          'paymentMethod': result.paymentMethod,
          'paidAt': DateTime.now().toIso8601String(),
        });

        setState(() => _paymentSuccess = true);

        if (!mounted) return;
        _showSuccessDialog();
      } else {
        throw result.message;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Payment failed: $e';
        });
      }
    }
  }

  void _showBankTransferDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bank Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please transfer ₦${widget.amount.toStringAsFixed(0)} to:'),
            const SizedBox(height: 16),
            _buildBankDetails(),
            const SizedBox(height: 16),
            Text(
              'Reference: ${widget.orderId}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'After completing the transfer, payment will be confirmed within 24 hours.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Mark order as pending bank transfer confirmation
              _confirmBankTransfer();
              context.pop();
            },
            child: const Text('I\'ve Transferred'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coop Commerce Ltd',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Bank: Zenith Bank'),
          const SizedBox(height: 4),
          const Text('Account: 1234567890'),
          const SizedBox(height: 4),
          const Text('Account Type: Current'),
        ],
      ),
    );
  }

  Future<void> _confirmBankTransfer() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Update order status to pending bank verification
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'paymentStatus': 'pending_verification',
        'paymentMethod': 'bank_transfer',
        'bankTransferAt': DateTime.now().toIso8601String(),
      });

      setState(() => _paymentSuccess = true);

      if (!mounted) return;
      _showBankTransferPendingDialog();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Order #${widget.orderId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '₦${widget.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your payment has been processed successfully. Your order is now being prepared.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.go('/order-tracking/${widget.orderId}');
            },
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }

  void _showBankTransferPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bank Transfer Initiated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pending,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Order #${widget.orderId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your payment will be verified within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/order-tracking/${widget.orderId}');
            },
            child: const Text('View Order'),
          ),
          ElevatedButton(
            onPressed: () {
              context.go('/');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Your order is waiting for payment confirmation'),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            },
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentSuccess) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '₦${widget.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment Failed'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isProcessing = false;
                  });
                  _initiatePayment();
                },
                child: const Text('Retry Payment'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Payment'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Processing ₦${widget.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Order #${widget.orderId}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Please wait...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
