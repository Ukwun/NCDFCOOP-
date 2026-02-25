import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/widgets/product_image.dart';

/// Cart item model
class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double memberPrice;
  final int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.memberPrice,
    required this.quantity,
  });

  double get subtotal => memberPrice * quantity;
}

class CartDisplayScreen extends StatefulWidget {
  final List<CartItem>? initialItems; // For demo/testing

  const CartDisplayScreen({super.key, this.initialItems});

  @override
  State<CartDisplayScreen> createState() => _CartDisplayScreenState();
}

class _CartDisplayScreenState extends State<CartDisplayScreen> {
  late List<CartItem> cartItems;

  @override
  void initState() {
    super.initState();
    cartItems = widget.initialItems ??
        [
          CartItem(
            id: '1',
            productId: 'prod_001',
            name: 'Premium Basmati Rice',
            imageUrl: 'assets/images/ijebugarri1.png',
            memberPrice: 6800,
            quantity: 2,
          ),
          CartItem(
            id: '2',
            productId: 'prod_002',
            name: 'Organic Sugar',
            imageUrl: 'assets/images/All inclusive pack.png',
            memberPrice: 2500,
            quantity: 1,
          ),
        ];
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }
    setState(() {
      cartItems[index] = CartItem(
        id: cartItems[index].id,
        productId: cartItems[index].productId,
        name: cartItems[index].name,
        imageUrl: cartItems[index].imageUrl,
        memberPrice: cartItems[index].memberPrice,
        quantity: newQuantity,
      );
    });
  }

  void _removeItem(int index) {
    final itemName = cartItems[index].name;
    setState(() {
      cartItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Removed $itemName from cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double get subtotal => cartItems.fold(0, (sum, item) => sum + item.subtotal);

  double get memberDiscount => subtotal * 0.05; // 5% member discount
  double get tax => (subtotal - memberDiscount) * 0.075; // 7.5% VAT
  double get total => subtotal - memberDiscount + tax;

  void _proceedToCheckout() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigate to checkout address step
    context.push('/checkout/address');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '🛒 Your Cart',
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
        centerTitle: false,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) =>
                        _buildCartItem(context, cartItems[index], index),
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),

                // Order Summary
                _buildOrderSummary(),
              ],
            ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '₦${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start shopping to add items to your cart',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continue Shopping',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // Price
                Text(
                  '₦${item.memberPrice.toStringAsFixed(0)} x ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),

                // Subtotal (Green)
                Text(
                  'Total: ₦${item.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Quantity Controls & Remove
          Column(
            children: [
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        icon: const Icon(Icons.remove, size: 14),
                        onPressed: () =>
                            _updateQuantity(index, item.quantity - 1),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    SizedBox(
                      width: 35,
                      child: Center(
                        child: Text(
                          item.quantity.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        icon: const Icon(Icons.add, size: 14),
                        onPressed: () =>
                            _updateQuantity(index, item.quantity + 1),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Remove button
              SizedBox(
                width: 100,
                child: TextButton(
                  onPressed: () => _removeItem(index),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  child: const Text(
                    '🗑️ Remove',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Subtotal
          _buildSummaryRow(
            'Subtotal',
            '₦${subtotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),

          // Member Discount (Green)
          _buildSummaryRow(
            '💳 Member Discount (5%)',
            '-₦${memberDiscount.toStringAsFixed(0)}',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),

          // Tax
          _buildSummaryRow(
            'Tax (7.5%)',
            '₦${tax.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),

          // Divider
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),

          // Total (Bold, Large)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '₦${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // Savings info
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '✅ You\'re saving ₦${memberDiscount.toStringAsFixed(0)} with your membership!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
