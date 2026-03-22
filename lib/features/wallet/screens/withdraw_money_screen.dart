import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/auth_provider.dart';

class WithdrawMoneyScreen extends ConsumerStatefulWidget {
  const WithdrawMoneyScreen({super.key});

  @override
  ConsumerState<WithdrawMoneyScreen> createState() =>
      _WithdrawMoneyScreenState();
}

class _WithdrawMoneyScreenState extends ConsumerState<WithdrawMoneyScreen> {
  final amountController = TextEditingController();
  final bankNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final accountNameController = TextEditingController();

  bool isProcessing = false;
  double? availableBalance;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  @override
  void dispose() {
    amountController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    accountNameController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletBalance() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final wallet = await ref.read(walletServiceProvider).getWallet(user.id);
      setState(() => availableBalance = wallet?.balance ?? 0.0);
    } catch (e) {
      debugPrint('Error loading wallet: $e');
    }
  }

  Future<void> _processWithdrawal() async {
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

    if (availableBalance != null && amount > availableBalance!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. Available: ₦${availableBalance!.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (bankNameController.text.isEmpty ||
        accountNumberController.text.isEmpty ||
        accountNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all bank details'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      await ref.read(walletServiceProvider).withdrawMoney(
            userId: user.id,
            amount: amount,
            description: 'Withdrawal to ${bankNameController.text}',
            accountNumber: accountNumberController.text,
            bankName: bankNameController.text,
          );

      // Invalidate providers to refresh wallet data
      ref.invalidate(userWalletProvider);
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletStatsProvider);
      ref.invalidate(transactionHistoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Withdrawal request submitted. Expected: 1-2 business days'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Withdraw Money',
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
              // Available Balance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₦${(availableBalance ?? 0.0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Amount Input
              const Text(
                'Withdrawal Amount',
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
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bank Details
              const Text(
                'Bank Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Bank Name
              _buildTextField(
                controller: bankNameController,
                label: 'Bank Name',
                hint: 'e.g., GTBank, First Bank',
                icon: Icons.account_balance,
              ),

              const SizedBox(height: 16),

              // Account Number
              _buildTextField(
                controller: accountNumberController,
                label: 'Account Number',
                hint: '10 digits',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Account Name
              _buildTextField(
                controller: accountNameController,
                label: 'Account Name',
                hint: 'As it appears on your bank',
                icon: Icons.person,
              ),

              const SizedBox(height: 32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Withdrawals are processed to your bank account in 1-2 business days. Zero fees.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
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
            onPressed: isProcessing ? null : _processWithdrawal,
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
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
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
                    'Withdraw ₦${amountController.text.isEmpty ? '0' : amountController.text}',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
