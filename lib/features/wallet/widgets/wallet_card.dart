import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/wallet_models.dart';

class WalletCard extends StatelessWidget {
  final Wallet? wallet;

  const WalletCard({super.key, this.wallet});

  @override
  Widget build(BuildContext context) {
    final balance = wallet?.balance ?? 0.0;
    final totalSpent = wallet?.totalSpent ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.credit_card, color: Colors.white70, size: 24),
              ],
            ),

            const SizedBox(height: 16),

            // Balance
            Text(
              '₦${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                    'Total Spent', '₦${totalSpent.toStringAsFixed(2)}'),
                _buildStatItem(
                  'Status',
                  wallet?.isActive ?? false ? 'Active' : 'Inactive',
                  textColor: (wallet?.isActive ?? false)
                      ? Colors.green[300]
                      : Colors.red[300],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Card Number (Mock)
            Row(
              children: [
                Text(
                  '**** **** **** ${wallet?.id.substring(wallet.id.length - 4) ?? '****'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARDHOLDER',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'CoopCommerce Member',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'EXPIRES',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateTime.now().month.toString().padLeft(2, '0')}/${(DateTime.now().year + 5).toString().substring(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    Color? textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
