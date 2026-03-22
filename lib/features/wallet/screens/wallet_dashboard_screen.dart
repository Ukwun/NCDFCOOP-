import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../models/wallet_models.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/wallet_card.dart';
import '../widgets/transaction_list.dart';

class WalletDashboardScreen extends ConsumerWidget {
  const WalletDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(title: const Text('Wallet')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Please log in to view your wallet'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/signin'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final walletAsync = ref.watch(userWalletProvider(userId));
    final transactionHistoryAsync =
        ref.watch(transactionHistoryProvider((userId, 10)));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '💳 Wallet',
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userWalletProvider);
          ref.invalidate(transactionHistoryProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Card
              walletAsync.when(
                data: (wallet) => WalletCard(wallet: wallet),
                loading: () => _buildLoadingCard(),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.add_circle_outline,
                            label: 'Add Money',
                            onTap: () => context.push('/wallet/add-money'),
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.remove_circle_outline,
                            label: 'Withdraw',
                            onTap: () => context.push('/wallet/withdraw'),
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.savings_outlined,
                            label: 'Savings',
                            onTap: () => context.push('/savings/dashboard'),
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Recent Transactions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/wallet/transactions'),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Transaction List
              transactionHistoryAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildEmptyState(),
                    );
                  }
                  return TransactionList(transactions: transactions);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error loading transactions: $error'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 48),
          const SizedBox(height: 12),
          Text(
            'Error loading wallet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transactions will appear here',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
