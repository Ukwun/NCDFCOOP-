import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/b2b_models.dart';
import '../../models/product.dart';
import '../../core/providers/b2b_providers.dart';
import '../../core/services/b2b_service.dart';
import '../../core/utils/error_handler.dart';

// INSTITUTIONAL DASHBOARD
class InstitutionalDashboardScreen extends ConsumerWidget {
  const InstitutionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(b2bMetricsProvider('institution_id'));
    final overdueAsync = ref.watch(overdueInvoicesProvider('institution_id'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institutional Dashboard'),
        elevation: 0,
      ),
      body: metricsAsync.when(
        data: (metrics) => overdueAsync.when(
          data: (overdue) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick stats
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _StatCard(
                      label: 'Total Orders',
                      value: metrics.totalOrders.toString(),
                      icon: Icons.shopping_cart,
                    ),
                    _StatCard(
                      label: 'Pending Approvals',
                      value: metrics.pendingApprovals.toString(),
                      icon: Icons.check_circle,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: 'Total Revenue',
                      value: '\$${metrics.totalRevenue.toStringAsFixed(0)}',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                    _StatCard(
                      label: 'Outstanding',
                      value: '\$${metrics.totalOutstanding.toStringAsFixed(0)}',
                      icon: Icons.receipt,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Overdue invoices alert
                if (overdue.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overdue Invoices: ${overdue.length}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: \$${overdue.fold<double>(0, (sum, inv) => sum + inv.getOutstandingBalance()).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Create Purchase Order',
                  icon: Icons.add,
                  onPressed: () {
                    // Navigate to PO creation
                  },
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'View All Orders',
                  icon: Icons.list,
                  onPressed: () {
                    // Navigate to PO list
                  },
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'View Invoices',
                  icon: Icons.receipt,
                  onPressed: () {
                    // Navigate to invoices
                  },
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Error: ${err.toString()}'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: ${err.toString()}'),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Colors.blue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: cardColor, size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// PURCHASE ORDER LIST
class PurchaseOrderListScreen extends ConsumerWidget {
  final String institutionId;

  const PurchaseOrderListScreen({
    super.key,
    required this.institutionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync =
        ref.watch(institutionPurchaseOrdersProvider(institutionId));
    final selectedStatus = ref.watch(_selectedStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
      ),
      body: Column(
        children: [
          // Status filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: ['All', 'Draft', 'Pending', 'Approved', 'Shipped']
                  .map((status) {
                final isSelected = selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (value) {
                      ref.read(_selectedStatusProvider.notifier).state = status;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // PO list
          Expanded(
            child: posAsync.when(
              data: (pos) {
                final filtered = selectedStatus == 'All'
                    ? pos
                    : pos
                        .where((p) =>
                            p.status.toLowerCase() ==
                            selectedStatus.toLowerCase())
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text('No purchase orders'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final po = filtered[index];
                    return _PurchaseOrderCard(po: po);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to PO creation
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder po;

  const _PurchaseOrderCard({required this.po});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(po.status);
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text('PO ${po.id.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
                '${po.lineItems.length} items • \$${po.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Text(
              po.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to PO detail
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// PURCHASE ORDER CREATION
class PurchaseOrderCreationScreen extends ConsumerStatefulWidget {
  final String institutionId;

  const PurchaseOrderCreationScreen({
    super.key,
    required this.institutionId,
  });

  @override
  ConsumerState<PurchaseOrderCreationScreen> createState() =>
      _PurchaseOrderCreationScreenState();
}

class _PurchaseOrderCreationScreenState
    extends ConsumerState<PurchaseOrderCreationScreen> {
  final List<PurchaseOrderLineItem> _lineItems = [];
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _paymentTermsController = TextEditingController(text: 'Net 30');
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Purchase Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                label: const Text('Delivery Address'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                  'Expected Delivery: ${_formatDate(_expectedDeliveryDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expectedDeliveryDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) {
                  setState(() => _expectedDeliveryDate = date);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _paymentTermsController,
              decoration: InputDecoration(
                label: const Text('Payment Terms'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _instructionsController,
              decoration: InputDecoration(
                label: const Text('Special Instructions'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Line Items (${_lineItems.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_lineItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('No line items added yet'),
              ),
            ..._lineItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _LineItemCard(
                item: item,
                onRemove: () {
                  setState(() => _lineItems.removeAt(index));
                },
              );
            }),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Show dialog to add line item
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Line Item'),
            ),
            const SizedBox(height: 24),
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('\$${_calculateSubtotal().toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax (10%):'),
                      Text(
                          '\$${(_calculateSubtotal() * 0.1).toStringAsFixed(2)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${(_calculateSubtotal() * 1.1).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _lineItems.isEmpty
                        ? null
                        : () => _submitPO(context, ref),
                    child: const Text('Submit for Approval'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    return _lineItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _submitPO(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(purchaseOrderServiceProvider);
      await service.createPurchaseOrder(
        institutionId: widget.institutionId,
        institutionName: 'Institution Name', // Get from context
        lineItems: _lineItems,
        expectedDeliveryDate: _expectedDeliveryDate,
        deliveryAddress: _addressController.text,
        specialInstructions: _instructionsController.text,
        createdBy: 'userId', // Get from auth
        approvalChain: ['approver1', 'approver2'], // Get from institution
        paymentTerms: _paymentTermsController.text,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase order submitted')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }
}

class _LineItemCard extends StatelessWidget {
  final PurchaseOrderLineItem item;
  final VoidCallback onRemove;

  const _LineItemCard({
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName),
                      Text(
                        'SKU: ${item.sku}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Qty: ${item.quantity} ${item.unit}'),
                Text('\$${item.totalPrice.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Provider for selected status filter
final _selectedStatusProvider = StateProvider<String>((ref) => 'All');
