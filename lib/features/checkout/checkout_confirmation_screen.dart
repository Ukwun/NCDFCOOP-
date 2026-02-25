import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/checkout_flow_provider.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/cart_provider.dart';
import 'package:coop_commerce/core/services/payment_gateway_service.dart';
import 'package:coop_commerce/providers/user_activity_providers.dart';

class CheckoutConfirmationScreen extends ConsumerWidget {
  const CheckoutConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final checkoutState = ref.watch(checkoutFlowProvider);
    final cartItemsAsync = ref.watch(userCartItemsProvider(userId));
    final orderCalcAsync = ref.watch(orderCalculationProvider({
      'subtotal': 0.0,
      'promoCode': checkoutState.promoCode,
    }));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Review Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(checkoutFlowProvider.notifier).previousStep();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 4,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),

            // Order items section
            _buildOrderItemsSection(context, ref, cartItemsAsync),

            // Delivery address section
            if (checkoutState.selectedAddress != null)
              _buildAddressSection(checkoutState),

            // Payment method section
            if (checkoutState.selectedPaymentMethod != null)
              _buildPaymentSection(checkoutState),

            // Order calculation section
            orderCalcAsync.when(
              data: (calculation) {
                return _buildOrderCalculationSection(calculation);
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error calculating order: $error'),
              ),
            ),

            // Place order button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handlePlaceOrder(context, ref, userId),
                  child: const Text('Place Order'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> cartItemsAsync,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          cartItemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  'No items in cart',
                  style: TextStyle(color: Colors.grey[500]),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.grey[200],
                  height: 16,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['productName'] ?? 'Product',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Qty: ${item['quantity'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₦${((item['price'] ?? 0) * (item['quantity'] ?? 0)).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Text(
              'Error loading items: $error',
              style: TextStyle(color: Colors.red[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(CheckoutFlowState state) {
    final address = state.selectedAddress;
    if (address == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Icon(Icons.location_on, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.label ?? 'Address',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address.street}, ${address.city}, ${address.state} ${address.zipCode}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Phone: ${address.phone}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(CheckoutFlowState state) {
    final method = state.selectedPaymentMethod;
    if (method == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Icon(Icons.payment, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            method.displayName ?? 'Payment Method',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '•••• •••• •••• ${method.lastFour ?? '****'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCalculationSection(OrderCalculation calculation) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Subtotal',
            currencyFormat.format(calculation.subtotal),
          ),
          _buildSummaryRow(
            'Tax (7.5%)',
            currencyFormat.format(calculation.tax),
            color: Colors.grey[600],
          ),
          _buildSummaryRow(
            'Delivery Fee',
            currencyFormat.format(calculation.deliveryFee),
            color: Colors.grey[600],
          ),
          if (calculation.promoDiscount > 0)
            _buildSummaryRow(
              'Promo Discount',
              '-${currencyFormat.format(calculation.promoDiscount)}',
              color: Colors.green[600],
            ),
          Divider(color: Colors.grey[200], height: 16),
          _buildSummaryRow(
            'Total',
            currencyFormat.format(calculation.total),
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: color ?? Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlaceOrder(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final checkoutState = ref.read(checkoutFlowProvider);
    final user = ref.read(currentUserProvider);
    final cartItemsAsync = await ref.read(userCartItemsProvider(userId).future);

    if (checkoutState.selectedAddress == null ||
        checkoutState.selectedPaymentMethod == null ||
        cartItemsAsync.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    // Get order calculation for the total amount
    final orderCalc = await ref.read(orderCalculationProvider({
      'userId': userId,
      'items': cartItemsAsync,
      'addressId': checkoutState.selectedAddress!.id,
      'promoCode': checkoutState.promoCode,
    }).future);

    // Create order with full details
    final orderResult = await ref.read(createOrderProvider({
      'userId': userId,
      'items': cartItemsAsync,
      'selectedAddress': checkoutState.selectedAddress,
      'selectedPaymentMethod': checkoutState.selectedPaymentMethod,
      'promoCode': checkoutState.promoCode,
      'subtotal': orderCalc.subtotal,
      'tax': orderCalc.tax,
      'deliveryFee': orderCalc.deliveryFee,
      'total': orderCalc.total,
    }).future);

    if (!context.mounted) return;

    if (!orderResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error creating order: ${orderResult.error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final orderId = orderResult.orderId!;
    final paymentMethod = checkoutState.selectedPaymentMethod!;
    final totalAmount = orderCalc.total;

    // Show payment processing screen
    if (!context.mounted) return;
    context.push(
      '/payment-processing',
      extra: {
        'orderId': orderId,
        'amount': totalAmount,
        'paymentMethod': paymentMethod.type,
      },
    );

    // Process payment
    try {
      final paymentResult = await _processPayment(
        orderId: orderId,
        amount: totalAmount,
        paymentMethod: paymentMethod.type,
        email: user?.email ?? '',
        phone: user?.phoneNumber ?? '',
        fullName: user?.name ?? '',
      );

      if (!context.mounted) return;

      if (paymentResult.success) {
        // Update order status to completed
        await _updateOrderPaymentStatus(
          ref: ref,
          orderId: orderId,
          paymentResult: paymentResult,
        );

        // Log purchase activity
        try {
          final productNames = cartItemsAsync
              .map((item) => (item['product']['name'] as String?) ?? 'Unknown')
              .toList();
          final productIds = cartItemsAsync
              .map((item) => (item['product']['id'] as String?) ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
          final categories = cartItemsAsync
              .map(
                  (item) => (item['product']['category'] as String?) ?? 'Other')
              .toList();

          final activityLogger = ref.read(activityLoggerProvider.notifier);
          await activityLogger.logPurchase(
            orderId: orderId,
            productIds: productIds,
            productNames: productNames,
            totalAmount: totalAmount,
            categories: categories,
          );
          debugPrint('✅ Purchase activity logged for order $orderId');
        } catch (e) {
          debugPrint('⚠️ Failed to log purchase activity: $e');
          // Don't fail the purchase if activity logging fails
        }

        // Reset checkout state
        ref.read(checkoutFlowProvider.notifier).reset();

        // Navigate to success screen
        context.go(
          '/payment-success',
          extra: {
            'orderId': orderId,
            'transactionId': paymentResult.transactionId,
            'amount': totalAmount,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId paid successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update order status to failed
        await _updateOrderPaymentStatus(
          ref: ref,
          orderId: orderId,
          paymentResult: paymentResult,
        );

        // Navigate to failure screen
        if (!context.mounted) return;
        context.go(
          '/payment-failure',
          extra: {
            'orderId': orderId,
            'errorMessage': paymentResult.message,
            'amount': totalAmount,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${paymentResult.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) return;

      // Update order status to failed
      await _updateOrderPaymentStatus(
        ref: ref,
        orderId: orderId,
        paymentResult: PaymentResult(
          success: false,
          transactionId: '',
          message: 'Payment processing error: $error',
          paymentMethod: paymentMethod.type,
          amount: totalAmount,
          timestamp: DateTime.now(),
        ),
      );

      // Navigate to failure screen
      context.go(
        '/payment-failure',
        extra: {
          'orderId': orderId,
          'errorMessage': 'Payment processing error: $error',
          'amount': totalAmount,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Process payment using the selected payment method
  Future<PaymentResult> _processPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
    required String email,
    required String phone,
    required String fullName,
  }) async {
    final paymentService = PaymentGatewayService.instance;

    if (paymentMethod == 'flutterwave') {
      return await paymentService.processFlutterwave(
        orderId: orderId,
        amount: amount,
        email: email,
        phoneNumber: phone,
        fullName: fullName,
        description: 'Order #$orderId - Coop Commerce',
      );
    } else if (paymentMethod == 'bank_transfer') {
      return PaymentResult(
        success: true,
        transactionId: orderId,
        message: 'Bank transfer initiated. Will be confirmed within 24 hours.',
        paymentMethod: 'bank_transfer',
        amount: amount,
      );
    } else {
      return PaymentResult(
        success: false,
        transactionId: '',
        message: 'Unknown payment method: $paymentMethod',
        paymentMethod: paymentMethod,
        amount: amount,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Update order in Firestore with payment information
  Future<void> _updateOrderPaymentStatus({
    required WidgetRef ref,
    required String orderId,
    required PaymentResult paymentResult,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('orders').doc(orderId).update({
        'paymentStatus': paymentResult.success ? 'completed' : 'failed',
        'transactionId': paymentResult.transactionId,
        'paymentMethod': paymentResult.paymentMethod,
        'paymentMessage': paymentResult.message,
        'paymentTimestamp': paymentResult.timestamp.toIso8601String(),
        'status': paymentResult.success ? 'confirmed' : 'payment_failed',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      debugPrint('Error updating order payment status: $error');
    }
  }
}
