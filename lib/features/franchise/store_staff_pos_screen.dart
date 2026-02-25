import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/core/services/store_staff_service.dart';
import 'package:coop_commerce/models/store_staff_models.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/auth_provider.dart';

/// Store Staff POS Transaction Screen
/// Allows store staff to ring up sales and process transactions
class StoreStaffPOSScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const StoreStaffPOSScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  ConsumerState<StoreStaffPOSScreen> createState() =>
      _StoreStaffPOSScreenState();
}

class _StoreStaffPOSScreenState extends ConsumerState<StoreStaffPOSScreen> {
  final _transactionController = TextEditingController();
  String _selectedPaymentMethod = 'cash';
  List<POSTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final service = StoreStaffService();
    final transactions = await service.getTransactions(
      widget.storeId,
      startDate: DateTime.now().subtract(Duration(days: 1)),
    );
    setState(() => _transactions = transactions);
  }

  void _showNewTransactionDialog() {
    final productController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Unit Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() => _selectedPaymentMethod = value ?? 'cash');
                },
                items: ['cash', 'card', 'mobile_money']
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child:
                              Text(method.replaceAll('_', ' ').toUpperCase()),
                        ))
                    .toList(),
                decoration: const InputDecoration(labelText: 'Payment Method'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (productController.text.isEmpty ||
                  quantityController.text.isEmpty ||
                  priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All fields are required')),
                );
                return;
              }

              final user = ref.read(currentUserProvider);
              if (user == null) return;

              final service = StoreStaffService();
              try {
                await service.recordPOSTransaction(
                  storeId: widget.storeId,
                  staffId: user.id,
                  staffName: user.name ?? 'Staff',
                  productId: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                  productName: productController.text,
                  unitPrice: double.parse(priceController.text),
                  quantity: int.parse(quantityController.text),
                  paymentMethod: _selectedPaymentMethod,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _loadTransactions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction recorded successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Complete Sale'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('POS - ${widget.storeName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Transactions',
                    value: '${_transactions.length}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Total Revenue',
                    value:
                        '₦${_transactions.fold(0.0, (sum, t) => sum + t.total).toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // New Transaction Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showNewTransactionDialog,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('New Transaction'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Transactions List
            Text(
              'Today\'s Transactions',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final trans = _transactions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        trans.paymentMethod == 'cash'
                            ? Icons.attach_money
                            : Icons.credit_card,
                        color: AppColors.primary,
                      ),
                      title: Text(trans.productName),
                      subtitle: Text(
                        'Qty: ${trans.quantity} × ₦${trans.unitPrice.toStringAsFixed(0)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₦${trans.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            trans.paymentMethod
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
