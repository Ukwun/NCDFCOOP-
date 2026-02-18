import 'package:flutter/material.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Flash Sales & Exclusive Deals Page
class FlashSalesPage extends StatelessWidget {
  const FlashSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Flash Sales',
          style: AppTextStyles.h4.copyWith(color: AppColors.text),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Flash Sales & Deals',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Limited-time offers with massive discounts on top products',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Active Deals
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Deals Today',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDealCard(
                    'Electronics Sale',
                    '50% OFF',
                    'Ends in 2 hours',
                    Colors.red,
                  ),
                  _buildDealCard(
                    'Grocery Bundle',
                    '35% OFF',
                    'Ends in 4 hours',
                    Colors.orange,
                  ),
                  _buildDealCard(
                    'Home & Garden',
                    '40% OFF',
                    'Ends in 6 hours',
                    Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // How Flash Sales Work
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How Flash Sales Work',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildInfoRow(
                    '⏰',
                    'Limited Time',
                    'Deals last only a few hours',
                  ),
                  _buildInfoRow(
                    '📍',
                    'Limited Quantity',
                    'First come, first served basis',
                  ),
                  _buildInfoRow(
                    '🔔',
                    'Get Notified',
                    'Enable notifications to catch deals',
                  ),
                  _buildInfoRow(
                    '⚡',
                    'Exclusive Prices',
                    'Biggest discounts of the week',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Notification Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.red),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Never Miss a Deal',
                          style: AppTextStyles.h4,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Enable push notifications to get instant alerts when flash sales go live',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Enable Notifications',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealCard(
    String title,
    String discount,
    String timeLeft,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(timeLeft, style: AppTextStyles.bodySmall),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                discount,
                style: AppTextStyles.h4.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
