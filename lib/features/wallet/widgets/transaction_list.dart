import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../models/wallet_models.dart';

class TransactionList extends StatelessWidget {
  final List<WalletTransaction> transactions;

  const TransactionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        itemBuilder: (context, index) =>
            _buildTransactionItem(transactions[index]),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Transaction Type Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getTransactionColor(transaction.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: _getTransactionColor(transaction.type),
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTransactionLabel(transaction.type),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Amount and Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_getAmountPrefix(transaction.type)}₦${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _getAmountColor(transaction.type),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, hh:mm a').format(transaction.timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Icons.download_done;
      case TransactionType.withdrawal:
        return Icons.upload;
      case TransactionType.purchase:
        return Icons.shopping_bag;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.savings:
        return Icons.savings;
      case TransactionType.savingsWithdrawal:
        return Icons.withdraw;
    }
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Colors.green;
      case TransactionType.withdrawal:
        return Colors.orange;
      case TransactionType.purchase:
        return Colors.red;
      case TransactionType.refund:
        return Colors.blue;
      case TransactionType.savings:
        return Colors.purple;
      case TransactionType.savingsWithdrawal:
        return Colors.indigo;
    }
  }

  Color _getAmountColor(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
      case TransactionType.refund:
        return Colors.green;
      case TransactionType.withdrawal:
      case TransactionType.purchase:
      case TransactionType.savings:
      case TransactionType.savingsWithdrawal:
        return Colors.red;
    }
  }

  String _getAmountPrefix(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
      case TransactionType.refund:
        return '+';
      default:
        return '-';
    }
  }

  String _getTransactionLabel(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return 'Money Added';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.purchase:
        return 'Purchase';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.savings:
        return 'Transfer to Savings';
      case TransactionType.savingsWithdrawal:
        return 'Savings Withdrawal';
    }
  }
}
