import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/savings_provider.dart';

/// Community Dividends & Rewards Page
class CommunityDividendsPage extends StatelessWidget {
  const CommunityDividendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CommunityDividendsView();
  }
}

class _CommunityDividendsView extends ConsumerWidget {
  const _CommunityDividendsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Community Dividends',
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
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.groups,
                      color: AppColors.accent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Community Dividends',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Share profits with our community. Earn dividends based on your purchases',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // How Dividends Work
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How Community Dividends Work',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStepCard(
                    '1',
                    'Make Purchases',
                    'Every purchase contributes to the community pool',
                  ),
                  _buildStepCard(
                    '2',
                    'Accumulate Points',
                    '1% of every purchase goes to the community fund',
                  ),
                  _buildStepCard(
                    '3',
                    'Earn Dividends',
                    'Profits distributed quarterly to all members',
                  ),
                  _buildStepCard(
                    '4',
                    'Reinvest or Withdraw',
                    'Use dividends for future purchases or withdraw',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Dividend Stats
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Dividends',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStatCard('Earned This Year', '₦2,450', Colors.green),
                  _buildStatCard('Pending Payout', '₦890', Colors.blue),
                  _buildStatCard(
                      'Available Balance', '₦1,560', AppColors.accent),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Benefits
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membership Dividend Rates',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRateRow('Gold Members', '2% per transaction'),
                  _buildRateRow('Platinum Members', '3% per transaction'),
                  _buildRateRow('Diamond Members', '5% per transaction'),
                  _buildRateRow('Annual Bonus', 'Up to ₦50,000'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // CTA
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.accent),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdraw Your Dividends',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Withdraw your earned dividends to your bank account anytime',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (user == null) {
                            context.go('/signin');
                            return;
                          }
                          _showWithdrawDialog(context, ref, user.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Withdraw Now',
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

  Future<void> _showWithdrawDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final amountController = TextEditingController();
    final accountController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw Dividends'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (NGN)',
                hintText: 'Enter amount to withdraw',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account Number (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = _parseAmount(amountController.text);
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid withdrawal amount'),
                  ),
                );
                return;
              }

              try {
                await ref
                    .read(
                      withdrawFromSavingsProvider((
                        userId: userId,
                        amount: amount,
                        description: 'Community dividends withdrawal',
                        accountNumber: accountController.text.trim().isEmpty
                            ? null
                            : accountController.text.trim(),
                      )).future,
                    )
                    .timeout(const Duration(seconds: 20));

                if (!context.mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Withdrawal request submitted: ₦${amount.toStringAsFixed(0)}',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Withdrawal failed: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  double _parseAmount(String raw) {
    return double.tryParse(raw.replaceAll(',', '').trim()) ?? 0;
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
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
      ),
    );
  }

  Widget _buildStatCard(String label, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.labelLarge),
            Text(
              amount,
              style: AppTextStyles.h4.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateRow(String tier, String rate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tier, style: AppTextStyles.labelLarge),
          Container(
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              rate,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
