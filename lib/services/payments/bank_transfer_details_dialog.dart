import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog showing bank transfer account details
/// Displayed when customer selects bank transfer payment method
class BankTransferDetailsDialog extends StatefulWidget {
  final String orderId;
  final double amount;
  final String customerName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BankTransferDetailsDialog({
    super.key,
    required this.orderId,
    required this.amount,
    required this.customerName,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<BankTransferDetailsDialog> createState() =>
      _BankTransferDetailsDialogState();
}

class _BankTransferDetailsDialogState extends State<BankTransferDetailsDialog> {
  bool _agreedToTerms = false;

  // TODO: Replace with actual bank details from Flutterwave
  final String bankName = 'Flutterwave Bank';
  final String accountName = 'CoopCommerce Store';
  final String accountNumber = '0123456789'; // Replace with actual account
  final String bankCode = '999111'; // Replace with actual bank code

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bank Transfer Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your order will be confirmed once we receive your payment',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment amount
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Amount to Transfer',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '₦${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bank details header
              const Text(
                'Account Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Bank details cards
              _buildDetailCard(
                label: 'Bank Name',
                value: bankName,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                label: 'Account Name',
                value: accountName,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                label: 'Account Number',
                value: accountNumber,
                isCopyable: true,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                label: 'Reference (Description)',
                value: 'ORD-${widget.orderId}',
                isCopyable: true,
              ),

              const SizedBox(height: 20),

              // Instructions
              const Text(
                'Transfer Instructions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                number: 1,
                instruction: 'Open your bank app or online banking',
              ),
              _buildInstructionStep(
                number: 2,
                instruction: 'Select "Transfer" or "Send Money"',
              ),
              _buildInstructionStep(
                number: 3,
                instruction: 'Enter the account details above',
              ),
              _buildInstructionStep(
                number: 4,
                instruction: 'Use the reference code as the description',
              ),
              _buildInstructionStep(
                number: 5,
                instruction: 'Confirm and complete the transfer',
              ),

              const SizedBox(height: 20),

              // Terms agreement
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _agreedToTerms = !_agreedToTerms);
                      },
                      child: const Text(
                        'I confirm I will transfer the exact amount shown above',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _agreedToTerms ? widget.onConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'I\'ve Transferred the Money',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Your order will be confirmed within minutes of receiving your payment',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String label,
    required String value,
    bool isCopyable = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (isCopyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $label'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required int number,
    required String instruction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                instruction,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
