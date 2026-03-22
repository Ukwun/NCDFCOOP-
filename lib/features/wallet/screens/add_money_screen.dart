import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/auth_provider.dart';

class AddMoneyScreen extends ConsumerStatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen> {
  final amountController = TextEditingController();
  String paymentMethod = 'card';
  bool isProcessing = false;

  // Predefined amounts
  final suggestedAmounts = [1000.0, 5000.0, 10000.0, 25000.0, 50000.0];

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void _selectAmount(double amount) {
    setState(() => amountController.text = amount.toStringAsFixed(0));
  }

  Future<void> _processDeposit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (amount < 100 || amount > 500000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Amount must be between ₦100 and ₦500,000'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      // TODO: Integrate with payment provider (Paystack/Flutterwave)
      // For now, deposit is simulated
      await _simulatePaymentFlow(user.id, amount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Successfully added ₦${amount.toStringAsFixed(2)} to wallet'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  Future<void> _simulatePaymentFlow(String userId, double amount) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Call the wallet service to deposit money
    await ref.read(walletServiceProvider).depositMoney(
          userId: userId,
          amount: amount,
          description: 'Wallet Top-up via $paymentMethod',
          paymentMethod: paymentMethod,
        );

    // Invalidate providers to refresh wallet data
    ref.invalidate(userWalletProvider);
    ref.invalidate(walletBalanceProvider);
    ref.invalidate(walletStatsProvider);
    ref.invalidate(transactionHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add Money to Wallet',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              const Text(
                'Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '₦',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: false),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Suggested Amounts
              const Text(
                'Quick Select',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: suggestedAmounts
                    .map(
                      (amount) => GestureDetector(
                        onTap: () => _selectAmount(amount),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: amountController.text ==
                                      amount.toStringAsFixed(0)
                                  ? AppColors.primary
                                  : Colors.grey[200]!,
                              width: amountController.text ==
                                      amount.toStringAsFixed(0)
                                  ? 2
                                  : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '₦${(amount / 1000).toStringAsFixed(0)}K',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: amountController.text ==
                                        amount.toStringAsFixed(0)
                                    ? AppColors.primary
                                    : Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 32),

              // Payment Method
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodOption(
                'card',
                '💳 Debit/Credit Card',
                'Visa, Mastercard, Verve',
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodOption(
                'transfer',
                '🏦 Bank Transfer',
                'Direct bank pickup',
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodOption(
                'mobile',
                '📱 Mobile Money',
                'MTN, Airtel, 9mobile',
              ),

              const SizedBox(height: 32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your money will be added instantly. No hidden fees.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: isProcessing ? null : _processDeposit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Processing...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Add ₦${amountController.text.isEmpty ? '0' : amountController.text}',
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

  Widget _buildPaymentMethodOption(
    String value,
    String title,
    String subtitle,
  ) {
    return GestureDetector(
      onTap: () => setState(() => paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color:
                paymentMethod == value ? AppColors.primary : Colors.grey[200]!,
            width: paymentMethod == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: paymentMethod == value
                      ? AppColors.primary
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: paymentMethod == value
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
}
