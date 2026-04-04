/**
 * PAYMENT BUTTON WIDGET
 * Handles payment initiation and shows loading states
 * Integrates with Paystack payment flow
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order_model.dart';
import '../services/checkout_payment_service.dart';

class PaymentButton extends ConsumerStatefulWidget {
  final OrderModel order;
  final String customerEmail;
  final String customerName;
  final String phoneNumber;
  final VoidCallback? onPaymentSuccess;
  final Function(String)? onPaymentError;

  const PaymentButton({
    Key? key,
    required this.order,
    required this.customerEmail,
    required this.customerName,
    required this.phoneNumber,
    this.onPaymentSuccess,
    this.onPaymentError,
  }) : super(key: key);

  @override
  ConsumerState<PaymentButton> createState() => _PaymentButtonState();
}

class _PaymentButtonState extends ConsumerState<PaymentButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final paymentFlowState = ref.watch(paymentFlowProvider);
    final checkoutPaymentService = ref.watch(checkoutPaymentServiceProvider);

    return paymentFlowState.when(
      idle: () => _buildPayNowButton(),
      loading: () => _buildLoadingButton('Initializing Payment...'),
      verifying: () => _buildLoadingButton('Verifying Payment...'),
      paymentInitiated: (response) =>
          _buildPaymentInitiatedUI(response, context),
      paymentVerified: (response) => _buildPaymentVerifiedUI(response, context),
      error: (message) => _buildErrorUI(message, context),
    );
  }

  Widget _buildPayNowButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _initiatePayment,
        icon: const Icon(Icons.payment),
        label: const Text(
          'Pay Now',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInitiatedUI(
    InitiatePaymentResponse response,
    BuildContext context,
  ) {
    // Auto-launch payment URL
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (response.authorizationUrl.isNotEmpty) {
        if (await canLaunchUrl(Uri.parse(response.authorizationUrl))) {
          await launchUrl(
            Uri.parse(response.authorizationUrl),
            mode: LaunchMode.externalApplication,
          );

          // After redirect, show verification UI
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Completing payment verification...'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    });

    return Column(
      children: [
        const SizedBox(height: 16),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Redirecting to Paystack...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              // Allow manual retry
              ref.invalidate(paymentFlowProvider);
            },
            child: const Text('Cancel Payment'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentVerifiedUI(
    VerifyPaymentResponse response,
    BuildContext context,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        widget.onPaymentSuccess?.call();

        // Navigate to order confirmation
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/order-confirmation',
              arguments: {'orderId': response.orderId},
            );
          }
        });
      }
    });

    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: Colors.green[700],
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Successful!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Order #${response.orderId}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildErrorUI(String message, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.red[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            color: Colors.red[700],
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Failed',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              // Retry payment
              ref.invalidate(paymentFlowProvider);
              _initiatePayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry Payment'),
          ),
        ),
      ],
    );
  }

  Future<void> _initiatePayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(paymentFlowProvider.notifier);

      await notifier.initiatePayment(
        orderId: widget.order.id,
        customerEmail: widget.customerEmail,
        customerName: widget.customerName,
        phoneNumber: widget.phoneNumber,
        amount: widget.order.totalAmount,
      );
    } catch (e) {
      widget.onPaymentError?.call(e.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
