import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/services/payments/flutterwave_payment_service.dart';
import 'package:coop_commerce/core/payments/payment_config.dart';

enum PaymentMethod {
  card,
  bankTransfer,
  mobileMoney,
  ussd,
}

extension PaymentMethodExt on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.card:
        return '💳 Debit/Credit Card';
      case PaymentMethod.bankTransfer:
        return '🏦 Bank Transfer';
      case PaymentMethod.mobileMoney:
        return '📱 Mobile Money';
      case PaymentMethod.ussd:
        return '☎️ USSD Code';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.ussd:
        return Icons.dialpad;
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.card:
        return 'Visa, Mastercard, Verve';
      case PaymentMethod.bankTransfer:
        return 'Direct bank transfer';
      case PaymentMethod.mobileMoney:
        return 'MTN Mobile Money, Airtel';
      case PaymentMethod.ussd:
        return 'Dial *901*50*AMOUNT#';
    }
  }
}

class PaymentFormScreen extends StatefulWidget {
  final double totalAmount;
  final String? orderId;
  final Map<String, dynamic>? cartData;

  const PaymentFormScreen({
    super.key,
    required this.totalAmount,
    this.orderId,
    this.cartData,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  PaymentMethod? selectedPaymentMethod;
  bool isProcessing = false;
  bool _paymentServiceInitialized = false;
  late final FlutterwavePaymentService _flutterwavePaymentService;

  // Form controllers
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();
  final cardNameController = TextEditingController();

  final bankNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final accountNameController = TextEditingController();

  final phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _flutterwavePaymentService = FlutterwavePaymentService();
    _initializePaymentService();
  }

  Future<void> _initializePaymentService() async {
    try {
      await _flutterwavePaymentService.initialize(
        publicKey: PaymentConfig.flutterwavePublicKey,
        secretKey: PaymentConfig.flutterwaveSecretKey,
        testMode: !PaymentConfig.isProduction(),
      );
      if (mounted) {
        setState(() => _paymentServiceInitialized = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _paymentServiceInitialized = false);
      }
    }
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    cardNameController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    accountNameController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate form
    if (!_validatePaymentForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_paymentServiceInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment gateway is unavailable. Try again shortly.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final orderId = widget.orderId?.trim().isNotEmpty == true
          ? widget.orderId!.trim()
          : 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final customerEmail =
          (widget.cartData?['email'] as String?) ?? 'customer@coopcommerce.app';
      final enteredName = cardNameController.text.trim();
      final enteredPhone = phoneNumberController.text.trim();
      final customerName = (widget.cartData?['customerName'] as String?) ??
          (enteredName.isNotEmpty ? enteredName : 'Coop Commerce Customer');
      final customerPhone = (widget.cartData?['phoneNumber'] as String?) ??
          (enteredPhone.isNotEmpty ? enteredPhone : '+2340000000000');
      final customerId =
          (widget.cartData?['customerId'] as String?) ?? 'guest-$orderId';

      final paymentResult = await _flutterwavePaymentService.initiatePayment(
        email: customerEmail,
        amount: widget.totalAmount,
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        phoneNumber: customerPhone,
        paymentType: selectedPaymentMethod == PaymentMethod.bankTransfer
            ? 'bank_transfer'
            : 'card',
      );

      if (paymentResult['success'] != true) {
        throw Exception(
            paymentResult['error'] ?? 'Payment initialization failed');
      }

      if (selectedPaymentMethod == PaymentMethod.bankTransfer) {
        final bankDetailsResult =
            await _flutterwavePaymentService.getBankTransferDetails(
          orderId: orderId,
          amount: widget.totalAmount,
        );

        if (mounted) {
          await _showBankTransferDetailsDialog(
              bankDetailsResult['details'] as Map<String, dynamic>?);
        }
      } else {
        final authUrlRaw = paymentResult['authorizationUrl'] as String?;
        final authUrl = authUrlRaw == null ? null : Uri.tryParse(authUrlRaw);
        if (authUrl == null) {
          throw Exception(
              'Invalid payment authorization URL returned by gateway');
        }

        final launched =
            await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw Exception('Unable to open payment gateway. Please try again.');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Complete payment in Flutterwave, then return to the app.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _showBankTransferDetailsDialog(
      Map<String, dynamic>? details) async {
    final bankName = details?['bankName']?.toString() ?? 'N/A';
    final accountName = details?['accountName']?.toString() ?? 'N/A';
    final accountNumber = details?['accountNumber']?.toString() ?? 'N/A';
    final reference =
        details?['reference']?.toString() ?? (widget.orderId ?? 'N/A');

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bank Transfer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bank: $bankName'),
            Text('Account Name: $accountName'),
            Text('Account Number: $accountNumber'),
            Text('Reference: $reference'),
            const SizedBox(height: 12),
            const Text(
                'Use the exact amount and reference for reconciliation.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  bool _validatePaymentForm() {
    switch (selectedPaymentMethod) {
      case PaymentMethod.card:
        return cardNumberController.text.isNotEmpty &&
            expiryController.text.isNotEmpty &&
            cvvController.text.isNotEmpty &&
            cardNameController.text.isNotEmpty;
      case PaymentMethod.bankTransfer:
        return bankNameController.text.isNotEmpty &&
            accountNumberController.text.isNotEmpty &&
            accountNameController.text.isNotEmpty;
      case PaymentMethod.mobileMoney:
        return phoneNumberController.text.isNotEmpty;
      case PaymentMethod.ussd:
        return true; // USSD doesn't require form validation
      case null:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '💳 Payment Method',
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
      ),
      body: isProcessing
          ? _buildProcessingState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Amount Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Amount to Pay',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₦${widget.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment Methods Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Payment Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...PaymentMethod.values.map(
                          (method) => _buildPaymentMethodCard(method),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Form
                  if (selectedPaymentMethod != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Enter Payment Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentFormSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: selectedPaymentMethod == null || isProcessing
                ? null
                : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isProcessing
                  ? 'Processing...'
                  : 'Complete Payment (₦${widget.totalAmount.toStringAsFixed(0)})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Processing Your Payment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color:
              isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[400]!,
                  width: isSelected ? 6 : 1,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Method info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        method.icon,
                        size: 20,
                        color:
                            isSelected ? AppColors.primary : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        method.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentFormSection() {
    switch (selectedPaymentMethod) {
      case PaymentMethod.card:
        return _buildCardForm();
      case PaymentMethod.bankTransfer:
        return _buildBankTransferForm();
      case PaymentMethod.mobileMoney:
        return _buildMobileMoneyForm();
      case PaymentMethod.ussd:
        return _buildUSSDForm();
      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        TextField(
          controller: cardNumberController,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.credit_card),
          ),
          keyboardType: TextInputType.number,
          maxLength: 19,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: expiryController,
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: cvvController,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: cardNameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
      ],
    );
  }

  Widget _buildBankTransferForm() {
    return Column(
      children: [
        TextField(
          controller: bankNameController,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.account_balance),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: accountNumberController,
          decoration: InputDecoration(
            labelText: 'Account Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: accountNameController,
          decoration: InputDecoration(
            labelText: 'Account Holder Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Transfer will be processed within 24 hours',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileMoneyForm() {
    return Column(
      children: [
        TextField(
          controller: phoneNumberController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '+234...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.green[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You will receive a prompt on your phone to authorize the payment',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUSSDForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.dialpad,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'USSD Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Dial this code from your mobile phone:',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '*901*50*${widget.totalAmount}#',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('USSD code copied!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Follow the prompts on your phone to complete the payment.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
