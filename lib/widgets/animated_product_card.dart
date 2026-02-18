import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/cart_provider.dart';

class AnimatedProductCard extends ConsumerStatefulWidget {
  final String productId;
  final String name;
  final String size;
  final double memberPrice;
  final double marketPrice;
  final String? imageUrl;
  final VoidCallback? onTap;

  const AnimatedProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.size,
    required this.memberPrice,
    required this.marketPrice,
    this.imageUrl,
    this.onTap,
  });

  @override
  ConsumerState<AnimatedProductCard> createState() =>
      _AnimatedProductCardState();
}

class _AnimatedProductCardState extends ConsumerState<AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    widget.onTap?.call();
  }

  void _addToCart() {
    setState(() => _isAdding = true);
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final cartItem = CartItem(
      id: widget.productId,
      productId: widget.productId,
      productName: widget.name,
      memberPrice: widget.memberPrice,
      marketPrice: widget.marketPrice,
      imageUrl: widget.imageUrl,
    );

    ref.read(cartProvider.notifier).addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.name} added to cart!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(cartProvider.notifier).removeItem(widget.productId);
          },
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final savings = (widget.marketPrice - widget.memberPrice);
    final savingsPercent =
        ((savings / widget.marketPrice) * 100).toStringAsFixed(0);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with savings badge
              Stack(
                children: [
                  // Product Image
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      image: widget.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(widget.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  // Savings Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Save $savingsPercent%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        widget.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      // Size
                      Text(
                        widget.size,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.tertiary,
                        ),
                      ),
                      const Spacer(),
                      // Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₦${widget.memberPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '₦${widget.marketPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.tertiary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          // Add to Cart Button
                          ScaleTransition(
                            scale: _isAdding
                                ? Tween<double>(begin: 1.0, end: 1.2).animate(
                                    _animationController,
                                  )
                                : AlwaysStoppedAnimation(1.0),
                            child: GestureDetector(
                              onTap: _addToCart,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  boxShadow: _isAdding
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated button for quick add to cart with bounce effect
class AnimatedAddToCartButton extends ConsumerStatefulWidget {
  final String productId;
  final String productName;
  final String size;
  final double memberPrice;
  final double marketPrice;
  final String? imageUrl;
  final bool isCompact;

  const AnimatedAddToCartButton({
    super.key,
    required this.productId,
    required this.productName,
    required this.size,
    required this.memberPrice,
    required this.marketPrice,
    this.imageUrl,
    this.isCompact = false,
  });

  @override
  ConsumerState<AnimatedAddToCartButton> createState() =>
      _AnimatedAddToCartButtonState();
}

class _AnimatedAddToCartButtonState
    extends ConsumerState<AnimatedAddToCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAddToCart() {
    _controller.forward().then((_) {
      _controller.reverse();
    });

    final cartItem = CartItem(
      id: widget.productId,
      productId: widget.productId,
      productName: widget.productName,
      memberPrice: widget.memberPrice,
      marketPrice: widget.marketPrice,
      imageUrl: widget.imageUrl,
    );

    ref.read(cartProvider.notifier).addItem(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.productName} added to cart!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton.small(
          onPressed: _handleAddToCart,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton.icon(
        onPressed: _handleAddToCart,
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Add to Cart'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
