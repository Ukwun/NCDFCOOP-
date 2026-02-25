import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SubscriptionPaymentScreen extends ConsumerStatefulWidget {
  final String tier;

  const SubscriptionPaymentScreen({
    super.key,
    required this.tier,
  });

  @override
  ConsumerState<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState
    extends ConsumerState<SubscriptionPaymentScreen> {
  late String selectedTier;
  bool isProcessing = false;
  String? selectedPaymentMethod; // 'flutterwave' or 'bank_transfer'

  final Map<String, Map<String, dynamic>> tierDetails = {
    'basic': {
      'name': 'Basic',
      'price': 0,
      'currency': '₦',
      'benefits': [
        'Member pricing (10% off)',
        'Access to app features',
        'Basic customer support',
        'Monthly newsletter',
      ]
    },
    'gold': {
      'name': 'Gold',
      'price': 5000,
      'currency': '₦',
      'yearlyPrice': '₦5,000/Year',
      'benefits': [
        'Everything in Basic',
        '15% off member pricing',
        'Priority customer support',
        '2% cash back on purchases',
        'Exclusive member events',
        'Free shipping over ₦10,000',
      ]
    },
    'platinum': {
      'name': 'Platinum',
      'price': 12000,
      'currency': '₦',
      'yearlyPrice': '₦12,000/Year',
      'benefits': [
        'Everything in Gold',
        '20% off member pricing',
        'VIP customer support',
        '3% cash back on purchases',
        'Early access to sales',
        'Free shipping on all orders',
        'Birthday bonus rewards',
        'Personal shopping assistant',
      ]
    },
  };

  @override
  void initState() {
    super.initState();
    selectedTier = widget.tier;
  }

  Future<void> _processFlutterwavePayment() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final tierData = tierDetails[selectedTier];
    final amount = tierData?['price'] as int? ?? 0;

    if (amount == 0) {
      await _completeSubscription();
      return;
    }

    setState(() => isProcessing = true);

    try {
      // Flutterwave payment processing
      // In a real implementation, you would use the Flutterwave SDK
      // For now, showing a simulated payment dialog
      final result = await _showFlutterwavePaymentDialog(amount);

      if (result == true) {
        // Create a mock order ID
        final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

        // Update user's membership tier to the selected tier (lowercase)
        final updatedUser = currentUser.copyWith(
          membershipTier: selectedTier.toLowerCase(),
          membershipExpiryDate: DateTime.now().add(const Duration(days: 365)),
        );

        // Update the user in the provider
        ref.read(currentUserProvider.notifier).setUser(updatedUser);

        // Payment successful - record in database
        await _recordPaymentTransaction(
          gateway: 'flutterwave',
          amount: amount,
          status: 'completed',
        );

        if (mounted) {
          // Navigate to order confirmation with the order ID
          context.goNamed(
            'order-confirmation',
            pathParameters: {'orderId': orderId},
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Payment failed: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _processBankTransfer() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final tierData = tierDetails[selectedTier];
    final amount = tierData?['price'] as int? ?? 0;

    if (amount == 0) {
      await _completeSubscription();
      return;
    }

    setState(() => isProcessing = true);

    try {
      // Show bank transfer details
      await _showBankTransferDialog(amount);

      // Create a mock order ID (in production, this would be from backend)
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      // Update user's membership tier to the selected tier (lowercase)
      final updatedUser = currentUser.copyWith(
        membershipTier: selectedTier.toLowerCase(),
        membershipExpiryDate: DateTime.now().add(const Duration(days: 365)),
      );

      // Update the user in the provider (in production, save to Firebase)
      ref.read(currentUserProvider.notifier).setUser(updatedUser);

      // Record pending transaction
      await _recordPaymentTransaction(
        gateway: 'bank_transfer',
        amount: amount,
        status: 'pending',
      );

      if (mounted) {
        // Navigate to order confirmation with the order ID
        context.goNamed(
          'order-confirmation',
          pathParameters: {'orderId': orderId},
        );
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<bool> _showFlutterwavePaymentDialog(int amount) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Flutterwave Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: ₦$amount'),
                const SizedBox(height: 16),
                const Text('Processing secure payment...'),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<void> _showBankTransferDialog(int amount) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bank Transfer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₦${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Account Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Bank: First Bank Nigeria'),
            const Text('Account Name: Coop Commerce Ltd'),
            const Text('Account Number: 2012345678'),
            const SizedBox(height: 16),
            const Text(
              'After transferring, your subscription will be activated within 24 hours.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordPaymentTransaction({
    required String gateway,
    required int amount,
    required String status,
  }) async {
    // TODO: Record in Firestore
    // This will be handled by backend service
    print('Payment recorded: gateway=$gateway, amount=$amount, status=$status');
  }

  Future<void> _completeSubscription() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Welcome to ${tierDetails[selectedTier]?['name']} membership!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to home after delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving membership: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (selectedPaymentMethod == null &&
        tierDetails[selectedTier]?['price'] != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    final tierData = tierDetails[selectedTier];
    final price = tierData?['price'] as int? ?? 0;

    if (price == 0) {
      // Free tier
      await _completeSubscription();
    } else if (selectedPaymentMethod == 'flutterwave') {
      await _processFlutterwavePayment();
    } else if (selectedPaymentMethod == 'bank_transfer') {
      await _processBankTransfer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final tierData = tierDetails[selectedTier];

    if (tierData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: Text('Invalid tier selected')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Subscription Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Order Summary
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSummaryRow('Membership', tierData['name']),
                      _buildSummaryRow(
                        'Price',
                        tierData['price'] == 0
                            ? 'FREE'
                            : '${tierData['currency']}${tierData['price']}',
                        isPrice: true,
                      ),
                      _buildSummaryRow('Duration', 'Annual (1 Year)'),
                      const Divider(),
                      _buildSummaryRow(
                        'Total',
                        tierData['price'] == 0
                            ? 'FREE'
                            : '${tierData['currency']}${tierData['price']}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Billing Information
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Billing Information',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Center(
                              child: Text(
                                currentUser?.name.isNotEmpty == true
                                    ? currentUser!.name[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser?.name ?? 'User',
                                  style: AppTextStyles.labelLarge,
                                ),
                                Text(
                                  currentUser?.email ?? '',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Payment Method Selection (only for paid tiers)
                if (tierData['price'] != 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Payment Method',
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildPaymentMethodOption(
                          'flutterwave',
                          'Flutterwave',
                          'Instant payment with card or mobile',
                          Icons.credit_card,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildPaymentMethodOption(
                          'bank_transfer',
                          'Bank Transfer',
                          'Direct bank transfer (24 hour confirmation)',
                          Icons.account_balance,
                        ),
                      ],
                    ),
                  ),
                ],

                // Membership Benefits
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Included Benefits',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...((tierData['benefits'] as List<String>?)
                              ?.map((benefit) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Text(
                                            benefit,
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList() ??
                          []),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Space for floating button
              ],
            ),
          ),

          // Floating Payment Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg)
                  .copyWith(top: AppSpacing.md),
              child: ElevatedButton(
                onPressed: isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        tierData['price'] == 0
                            ? 'Activate Basic Membership'
                            : 'Complete Payment',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    String method,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.text,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.text,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isPrice = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium,
          ),
          Text(
            value,
            style:
                (isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium)
                    .copyWith(
              color: isPrice ? AppColors.primary : null,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
