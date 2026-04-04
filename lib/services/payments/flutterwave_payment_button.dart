import 'package:flutter/material.dart';
import 'dart:async';
import 'bank_transfer_details_dialog.dart';

/// Payment method selection widget for Flutterwave payments
/// Allows users to choose between card and bank transfer
class FlutterwavePaymentButton extends StatefulWidget {
  final String orderId;
  final double amount;
  final String customerEmail;
  final String customerName;
  final String phoneNumber;
  final String customerId;
  final VoidCallback? onPaymentInitiated;
  final Function(String reference)? onCardPaymentSuccess;
  final Function(Map<String, dynamic> bankDetails)? onBankTransferDetails;
  final VoidCallback? onPaymentFailed;

  const FlutterwavePaymentButton({
    super.key,
    required this.orderId,
    required this.amount,
    required this.customerEmail,
    required this.customerName,
    required this.phoneNumber,
    required this.customerId,
    this.onPaymentInitiated,
    this.onCardPaymentSuccess,
    this.onBankTransferDetails,
    this.onPaymentFailed,
  });

  @override
  State<FlutterwavePaymentButton> createState() =>
      _FlutterwavePaymentButtonState();
}

class _FlutterwavePaymentButtonState extends State<FlutterwavePaymentButton> {
  bool _isLoading = false;
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Payment method selection
        if (_selectedPaymentMethod == null) ...[
          const SizedBox(height: 16),
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildPaymentMethodOptions(),
        ] else ...[
          // Selected method info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedPaymentMethod == 'card'
                      ? Icons.credit_card
                      : Icons.account_balance,
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPaymentMethod == 'card'
                            ? 'Card Payment'
                            : 'Bank Transfer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedPaymentMethod == 'bank_transfer')
                        const Text(
                          'You\'ll see account details after proceeding',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() => _selectedPaymentMethod = null);
                        },
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Proceed button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _proceedWithPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _selectedPaymentMethod == 'card'
                          ? 'Pay ₦${widget.amount.toStringAsFixed(2)}'
                          : 'Continue to Bank Details',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _selectedPaymentMethod = null);
                  },
            child: const Text('Back to Methods'),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildPaymentMethodOptions() {
    return [
      _buildPaymentMethodCard(
        method: 'card',
        icon: Icons.credit_card,
        title: 'Card Payment',
        description: 'Instant payment with Debit/Credit Card',
      ),
      const SizedBox(height: 12),
      _buildPaymentMethodCard(
        method: 'bank_transfer',
        icon: Icons.account_balance,
        title: 'Bank Transfer',
        description: 'Manual bank transfer with manual verification',
      ),
    ];
  }

  Widget _buildPaymentMethodCard({
    required String method,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Future<void> _proceedWithPayment() async {
    if (_selectedPaymentMethod == null) return;

    widget.onPaymentInitiated?.call();

    setState(() => _isLoading = true);

    try {
      // TODO: Inject FlutterwaveCheckoutPaymentService from provider/DI
      // For now, this is a placeholder structure
      // Final implementation will use GetIt or Riverpod

      if (_selectedPaymentMethod == 'card') {
        // Card payment will redirect to Flutterwave hosted payment page
        // This requires integration with the actual service from checkout screen
        _handleCardPayment();
      } else {
        // Bank transfer shows account details
        _handleBankTransferPayment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      widget.onPaymentFailed?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleCardPayment() {
    // Card payment will open Flutterwave's hosted payment page in browser/webview
    // The webhook will handle confirmation
    // For now, show a dialog with next steps
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to Flutterwave to complete payment...'),
        duration: Duration(seconds: 3),
      ),
    );

    // Widget callback
    widget.onCardPaymentSuccess?.call('pending-${widget.orderId}');

    // Navigate to confirmation screen or payment status screen
    // This will be handled by parent widget
  }

  void _handleBankTransferPayment() {
    // Show bank transfer details dialog with account information
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => BankTransferDetailsDialog(
        orderId: widget.orderId,
        amount: widget.amount,
        customerName: widget.customerName,
        onConfirm: () {
          Navigator.of(context).pop();
          widget.onBankTransferDetails?.call({
            'orderId': widget.orderId,
            'amount': widget.amount,
            'paymentMethod': 'bank_transfer',
          });
          // Navigate to bank transfer confirmation screen
        },
        onCancel: () {
          Navigator.of(context).pop();
          setState(() => _selectedPaymentMethod = null);
        },
      ),
    );
  }
}
