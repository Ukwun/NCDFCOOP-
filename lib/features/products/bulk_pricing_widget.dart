import 'package:flutter/material.dart';

/// Bulk Pricing Data Model
class BulkPricingTier {
  final int minQuantity;
  final int maxQuantity;
  final double price;
  final double discount;

  BulkPricingTier({
    required this.minQuantity,
    required this.maxQuantity,
    required this.price,
    required this.discount,
  });

  String get quantityRange =>
      maxQuantity >= 999 ? '$minQuantity+' : '$minQuantity - $maxQuantity';

  double get savingsPercent =>
      ((discount / (price + discount)) * 100).toStringAsFixed(1) as double;
}

/// Bulk Pricing Display Widget - MVP
class BulkPricingWidget extends StatefulWidget {
  final List<BulkPricingTier> tiers;
  final int currentQuantity;
  final Function(int) onQuantityChanged;

  const BulkPricingWidget({
    Key? key,
    required this.tiers,
    required this.currentQuantity,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  State<BulkPricingWidget> createState() => _BulkPricingWidgetState();
}

class _BulkPricingWidgetState extends State<BulkPricingWidget> {
  late int selectedQuantity;

  @override
  void initState() {
    super.initState();
    selectedQuantity = widget.currentQuantity;
  }

  BulkPricingTier getCurrentTier() {
    return widget.tiers.firstWhere(
      (tier) =>
          selectedQuantity >= tier.minQuantity &&
          selectedQuantity <= tier.maxQuantity,
      orElse: () => widget.tiers.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = getCurrentTier();
    final savings = currentTier.discount * selectedQuantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quantity selector
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: selectedQuantity > 1
                              ? () {
                                  setState(() {
                                    selectedQuantity--;
                                    widget.onQuantityChanged(selectedQuantity);
                                  });
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.remove,
                              size: 18,
                              color: selectedQuantity > 1
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            selectedQuantity.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedQuantity++;
                              widget.onQuantityChanged(selectedQuantity);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Price: ₦${currentTier.price.toStringAsFixed(0)} per unit',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bulk pricing tiers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bulk Pricing Tiers',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...widget.tiers.asMap().entries.map((entry) {
                final index = entry.key;
                final tier = entry.value;
                final isCurrentTier =
                    selectedQuantity >= tier.minQuantity &&
                    selectedQuantity <= tier.maxQuantity;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedQuantity = tier.minQuantity;
                        widget.onQuantityChanged(selectedQuantity);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isCurrentTier
                              ? Colors.green[600]!
                              : Colors.grey[300]!,
                          width: isCurrentTier ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isCurrentTier ? Colors.green[50] : Colors.white,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (isCurrentTier)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green[600],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buy ${tier.quantityRange} units',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrentTier
                                        ? Colors.green[700]
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Save ₦${tier.discount.toStringAsFixed(0)} per unit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCurrentTier
                                        ? Colors.green[600]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentTier
                                  ? Colors.green[100]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '₦${tier.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrentTier
                                    ? Colors.green[700]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Savings display
        if (savings > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.amber[600], size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bulk Savings',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Save ₦${savings.toStringAsFixed(0)} on this purchase',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Example pricing data - use this when adding to product detail screen
List<BulkPricingTier> getExampleBulkPricing() {
  return [
    BulkPricingTier(minQuantity: 1, maxQuantity: 10, price: 5000, discount: 0),
    BulkPricingTier(
      minQuantity: 11,
      maxQuantity: 50,
      price: 4500,
      discount: 500,
    ),
    BulkPricingTier(
      minQuantity: 51,
      maxQuantity: 100,
      price: 4000,
      discount: 1000,
    ),
    BulkPricingTier(
      minQuantity: 101,
      maxQuantity: 999,
      price: 3500,
      discount: 1500,
    ),
  ];
}
