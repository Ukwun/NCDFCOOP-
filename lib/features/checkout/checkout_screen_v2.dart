import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/models/address.dart';
import 'package:coop_commerce/providers/cart_provider.dart';
import 'package:coop_commerce/core/providers/checkout_providers.dart';
import 'package:coop_commerce/core/providers/order_providers.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/core/services/order_fulfillment_service.dart';
import 'package:coop_commerce/core/services/payment_processing_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  int _currentStep = 0;
  final _promoCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _slideController.forward(from: 0);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _slideController.forward(from: 0);
    }
  }

  Future<void> _completeOrder() async {
    final checkoutState = ref.read(checkoutStateProvider);
    final user = ref.read(currentUserProvider);
    final cart = ref.read(cartProvider);

    if (checkoutState.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to continue')),
      );
      return;
    }

    ref.read(checkoutStateProvider.notifier).setLoading(true);

    try {
      // Step 1: Create order via order fulfillment service
      final fulfillmentService = ref.read(orderFulfillmentServiceProvider);

      // Convert cart items to order items
      final orderItems = cart.items
          .map((item) => OrderItem(
                id: item.id,
                productId: item.productId,
                name: item.productName,
                price: item.memberPrice,
                quantity: item.quantity,
                sku: 'SKU-${item.productId}',
              ))
          .toList();

      final orderId = await fulfillmentService.createOrder(
        buyerId: user.id,
        items: orderItems,
        totalAmount: cart.totalPrice,
        shippingAddress: checkoutState.selectedAddress!.fullAddress,
        billingAddress: checkoutState.selectedAddress!.fullAddress,
        paymentMethodId: checkoutState.selectedPaymentMethod,
        notes: checkoutState.deliverySlot != null
            ? 'Delivery Slot: ${checkoutState.deliverySlot!.date} at ${checkoutState.deliverySlot!.time}'
            : null,
      );

      // Step 2: Create payment record
      final paymentService = ref.read(paymentProcessingServiceProvider);
      final paymentMethod =
          _mapPaymentMethod(checkoutState.selectedPaymentMethod);

      await paymentService.createPayment(
        orderId: orderId,
        buyerId: user.id,
        amount: cart.totalPrice,
        method: paymentMethod,
        paymentMethodId: checkoutState.selectedPaymentMethod,
        currency: 'NGN',
        notes: checkoutState.promoCode.isNotEmpty
            ? 'Promo Code: ${checkoutState.promoCode}'
            : null,
      );

      // Step 3: Clear cart after successful order creation
      ref.read(cartProvider.notifier).clearCart();

      // Step 4: Reset checkout state
      ref.read(checkoutStateProvider.notifier).reset();

      if (mounted) {
        // Navigate to order confirmation with order ID
        context.pushNamed(
          'order-confirmation',
          extra: orderId,
        );
      }
    } catch (e) {
      ref.read(checkoutStateProvider.notifier).setError(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      ref.read(checkoutStateProvider.notifier).setLoading(false);
    }
  }

  /// Convert UI payment method to service PaymentMethod enum
  PaymentMethod _mapPaymentMethod(String uiMethod) {
    switch (uiMethod) {
      case 'card':
        return PaymentMethod.creditCard;
      case 'bank':
        return PaymentMethod.bankTransfer;
      case 'wallet':
        return PaymentMethod.mobileWallet;
      default:
        return PaymentMethod.creditCard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _fadeController,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  if (_currentStep == 0)
                    _buildAddressStep(checkoutState)
                  else if (_currentStep == 1)
                    _buildDeliverySlotStep(checkoutState)
                  else if (_currentStep == 2)
                    _buildPaymentStep(checkoutState)
                  else
                    _buildReviewStep(checkoutState),
                  const SizedBox(height: 24),
                  _buildNavButtons(checkoutState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Address', 'Delivery', 'Payment', 'Review'];

    return Column(
      children: [
        Row(
          children: List.generate(4, (index) {
            final isActive = index <= _currentStep;
            final isCompleted = index < _currentStep;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.primary : Colors.grey[300],
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            minHeight: 4,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressStep(CheckoutState state) {
    final addressAsyncValue = ref
        .watch(userAddressesProvider(ref.read(currentUserProvider)?.id ?? ''));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Delivery Address', style: AppTextStyles.h2),
        const SizedBox(height: 16),
        addressAsyncValue.when(
          data: (addresses) => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              final isSelected = state.selectedAddress?.id == address.id;

              return _buildAddressItem(
                address,
                isSelected,
                () => ref
                    .read(checkoutStateProvider.notifier)
                    .selectAddress(address),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Error loading addresses: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressItem(
    Address address,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
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
                  Text(address.type.toUpperCase(),
                      style: AppTextStyles.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySlotStep(CheckoutState state) {
    final deliverySlots = [
      ('2024-02-01', '09:00 - 12:00', 'Morning'),
      ('2024-02-01', '12:00 - 15:00', 'Afternoon'),
      ('2024-02-01', '15:00 - 18:00', 'Evening'),
      ('2024-02-02', '09:00 - 12:00', 'Next Day Morning'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Delivery Slot', style: AppTextStyles.h2),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: deliverySlots.length,
          itemBuilder: (context, index) {
            final (date, time, label) = deliverySlots[index];
            final isSelected = state.deliverySlot?.date == date &&
                state.deliverySlot?.time == time;

            return GestureDetector(
              onTap: () {
                ref
                    .read(checkoutStateProvider.notifier)
                    .selectDeliverySlot(date, time);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : null,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppTextStyles.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          '$date • $time',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentStep(CheckoutState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: AppTextStyles.h2),
        const SizedBox(height: 16),
        ..._buildPaymentMethods(state),
        const SizedBox(height: 16),
        if (state.selectedPaymentMethod == 'card')
          Column(
            children: [
              CheckboxListTile(
                value: state.saveCard,
                onChanged: (value) {
                  ref
                      .read(checkoutStateProvider.notifier)
                      .toggleSaveCard(value ?? false);
                },
                title: const Text('Save card for future purchases'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        Text('Promo Code', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        TextField(
          controller: _promoCodeController,
          decoration: InputDecoration(
            hintText: 'Enter promo code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                ref
                    .read(checkoutStateProvider.notifier)
                    .applyPromoCode(_promoCodeController.text);
              },
            ),
          ),
          onSubmitted: (value) {
            ref.read(checkoutStateProvider.notifier).applyPromoCode(value);
          },
        ),
        if (state.promoCode.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Promo code "${state.promoCode}" applied',
                style: const TextStyle(color: Colors.green, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildPaymentMethods(CheckoutState state) {
    final methods = [
      ('card', 'Debit Card', Icons.credit_card),
      ('bank', 'Bank Transfer', Icons.account_balance),
      ('wallet', 'Mobile Wallet', Icons.wallet_membership),
    ];

    return methods.map((method) {
      final (id, label, icon) = method;
      final isSelected = state.selectedPaymentMethod == id;

      return GestureDetector(
        onTap: () =>
            ref.read(checkoutStateProvider.notifier).selectPaymentMethod(id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(label, style: AppTextStyles.labelMedium),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildReviewStep(CheckoutState state) {
    final cart = ref.watch(cartProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Review', style: AppTextStyles.h2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivery Address', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              if (state.selectedAddress != null)
                Text(
                  state.selectedAddress!.fullAddress,
                  style: AppTextStyles.bodySmall,
                ),
              const SizedBox(height: 16),
              Text('Delivery Slot', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              if (state.deliverySlot != null)
                Text(
                  '${state.deliverySlot!.date} • ${state.deliverySlot!.time}',
                  style: AppTextStyles.bodySmall,
                ),
              const SizedBox(height: 16),
              Text('Payment', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              Text(
                state.selectedPaymentMethod.toUpperCase(),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                  'Subtotal', '₦${cart.subtotal.toStringAsFixed(0)}'),
              _buildSummaryRow('Delivery', 'FREE'),
              if (state.promoCode.isNotEmpty)
                _buildSummaryRow(
                  'Promo Discount',
                  '-₦${(cart.subtotal * 0.1).toStringAsFixed(0)}',
                  color: Colors.green,
                ),
              _buildSummaryRow(
                'You Save',
                '₦${cart.totalSavings.toStringAsFixed(0)}',
                color: AppColors.primary,
              ),
              const Divider(height: 16),
              _buildSummaryRow(
                'Total',
                '₦${cart.totalPrice.toStringAsFixed(0)}',
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons(CheckoutState state) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: ElevatedButton(
              onPressed: _previousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: state.isLoading
                ? null
                : (_currentStep == 3 ? _completeOrder : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _currentStep == 3 ? 'Place Order' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
