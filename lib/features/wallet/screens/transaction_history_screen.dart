import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/wallet_models.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: ['All', 'Credit', 'Debit', 'Pending'].map((filter) {
                final isSelected = selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Transactions List
          Expanded(
            child: ref.watch(walletTransactionsProvider).when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Filter transactions
                    final filtered = transactions.where((tx) {
                      if (selectedFilter == 'All') return true;
                  final isCredit = tx.type == TransactionType.deposit || 
                                   tx.type == TransactionType.refund ||
                                   tx.type == TransactionType.savingsWithdrawal;
                  if (selectedFilter == 'Credit') return isCredit;
                  if (selectedFilter == 'Debit') return !isCredit;
                  if (selectedFilter == 'Pending') return tx.status == 'pending';
                    return ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        final transaction = filtered[index];
                        return _buildTransactionTile(transaction);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction transaction) {
    final isCredit = transaction.type == TransactionType.deposit || 
                     transaction.type == TransactionType.refund ||
                     transaction.type == TransactionType.savingsWithdrawal;
    final isPending = transaction.status == 'pending';
    final isFailed = transaction.status == 'failed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Transaction Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isFailed
                  ? Colors.grey.withOpacity(0.1)
                  : isCredit
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: isFailed
                    ? Colors.grey
                    : isCredit
                        ? Colors.green
                        : Colors.red,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(transaction.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (isFailed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Failed',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '${isCredit ? '+' : '-'}₦${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isFailed
                  ? Colors.grey
                  : isCredit
                      ? Colors.green
                      : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (transactionDate ==
        DateTime(yesterday.year, yesterday.month, yesterday.day)) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Icons.arrow_downward;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.purchase:
        return Icons.shopping_bag;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.savings:
        return Icons.savings;
      case TransactionType.savingsWithdrawal:
        return Icons.withdraw_money;
    }
  }
}
