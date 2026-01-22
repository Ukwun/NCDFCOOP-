import 'package:flutter/material.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class PriceTag extends StatelessWidget {
  final double memberPrice;
  final double marketPrice;
  final bool showSavings;
  final bool showLabel;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const PriceTag({
    super.key,
    required this.memberPrice,
    required this.marketPrice,
    this.showSavings = true,
    this.showLabel = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// Calculate savings amount
  double get savingsAmount => marketPrice - memberPrice;

  /// Calculate savings percentage
  double get savingsPercentage => (savingsAmount / marketPrice) * 100;

  /// Check if there's a discount
  bool get hasDiscount => memberPrice < marketPrice;

  /// Format price as currency
  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        // Member Price (Primary)
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (showLabel)
              Text(
                'Member Price: ',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            Text(
              _formatPrice(memberPrice),
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Market Price (Strikethrough) and Savings Badge
        if (hasDiscount)
          Row(
            children: [
              // Market Price with strikethrough
              if (showLabel)
                Text(
                  'Reg. Price: ',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              Text(
                _formatPrice(marketPrice),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              // Savings badge
              if (showSavings)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'Save ${savingsPercentage.toStringAsFixed(0)}%',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          )
        else
          Text(
            'No savings available',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
        // Savings amount breakdown
        if (showSavings && hasDiscount)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'You save ${_formatPrice(savingsAmount)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact version of PriceTag for smaller displays
class CompactPriceTag extends StatelessWidget {
  final double memberPrice;
  final double marketPrice;
  final bool showDiscount;

  const CompactPriceTag({
    super.key,
    required this.memberPrice,
    required this.marketPrice,
    this.showDiscount = true,
  });

  bool get hasDiscount => memberPrice < marketPrice;

  double get savingsPercentage =>
      ((marketPrice - memberPrice) / marketPrice) * 100;

  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _formatPrice(memberPrice),
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            _formatPrice(marketPrice),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.muted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          if (showDiscount) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                '-${savingsPercentage.toStringAsFixed(0)}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Horizontal price comparison card
class PriceComparisonCard extends StatelessWidget {
  final double memberPrice;
  final double marketPrice;
  final String productName;
  final VoidCallback? onTap;

  const PriceComparisonCard({
    super.key,
    required this.memberPrice,
    required this.marketPrice,
    required this.productName,
    this.onTap,
  });

  bool get hasDiscount => memberPrice < marketPrice;

  double get savingsPercentage =>
      ((marketPrice - memberPrice) / marketPrice) * 100;

  String _formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Left section - Prices
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text(
                          'Member: ',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          _formatPrice(memberPrice),
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Reg: ',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            _formatPrice(marketPrice),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Right section - Savings badge
              if (hasDiscount)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SAVE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${savingsPercentage.toStringAsFixed(0)}%',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
