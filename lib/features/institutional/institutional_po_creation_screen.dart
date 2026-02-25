import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/b2b_providers.dart';

/// Purchase Order creation form screen
class InstitutionalPOCreationScreen extends ConsumerStatefulWidget {
  const InstitutionalPOCreationScreen({super.key});

  @override
  ConsumerState<InstitutionalPOCreationScreen> createState() =>
      _POCreationScreenState();
}

class _POCreationScreenState
    extends ConsumerState<InstitutionalPOCreationScreen> {
  late TextEditingController _poNumberController;
  late TextEditingController _notesController;
  late TextEditingController _deliveryAddressController;

  String? _selectedContractId;
  DateTime? _requiredDeliveryDate;
  final List<POLineItem> _lineItems = [];

  @override
  void initState() {
    super.initState();
    _poNumberController = TextEditingController();
    _notesController = TextEditingController();
    _deliveryAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _poNumberController.dispose();
    _notesController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractsAsync =
        ref.watch(institutionContractPricesProvider('institution_id'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Purchase Order'),
        elevation: 0,
      ),
      body: contractsAsync.when(
        data: (contracts) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 24),

              // Contract Selection
              _buildContractSection(contracts),
              const SizedBox(height: 24),

              // Line Items
              _buildLineItemsSection(),
              const SizedBox(height: 24),

              // Delivery Details
              _buildDeliverySection(),
              const SizedBox(height: 24),

              // Terms & Conditions
              _buildTermsSection(),
              const SizedBox(height: 24),

              // Summary
              _buildSummarySection(),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchase Order Details',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _poNumberController,
          decoration: InputDecoration(
            hintText: 'PO Number (Auto-generated)',
            labelText: 'PO Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildContractSection(List<dynamic> contracts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Contract',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedContractId,
          items: contracts
              .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name ?? 'Unnamed Contract'),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedContractId = value);
          },
          decoration: InputDecoration(
            labelText: 'Contract',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Line Items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ElevatedButton.icon(
              onPressed: _showAddLineItemDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lineItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text('No line items added yet'),
            ),
          )
        else
          Column(
            children: [
              ..._lineItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _LineItemCard(
                  item: item,
                  onDelete: () {
                    setState(() => _lineItems.removeAt(index));
                  },
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deliveryAddressController,
          decoration: InputDecoration(
            labelText: 'Delivery Address',
            hintText: 'Enter delivery address',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _requiredDeliveryDate ??
                  DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (date != null) {
              setState(() => _requiredDeliveryDate = date);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Required Delivery Date',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _requiredDeliveryDate?.toString().split(' ')[0] ?? 'Select date',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Special Instructions/Notes',
            hintText: 'Enter any special requirements',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    final subtotal = _lineItems.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    final tax = subtotal * 0.075; // 7.5% tax
    final total = subtotal + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax (7.5%):'),
              Text(
                '\$${tax.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
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
            onPressed: _lineItems.isEmpty ? null : _submitPO,
            child: const Text('Submit PO'),
          ),
        ),
      ],
    );
  }

  void _showAddLineItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddLineItemDialog(
        onAdd: (item) {
          setState(() => _lineItems.add(item));
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _submitPO() async {
    // TODO: Implement PO submission to Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PO submitted successfully')),
    );
    Navigator.pop(context);
  }
}

class POLineItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  POLineItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });
}

class _LineItemCard extends StatelessWidget {
  final POLineItem item;
  final VoidCallback onDelete;

  const _LineItemCard({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = item.quantity * item.unitPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Unit: \$${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete, size: 18, color: Colors.red[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddLineItemDialog extends StatefulWidget {
  final Function(POLineItem) onAdd;

  const _AddLineItemDialog({required this.onAdd});

  @override
  State<_AddLineItemDialog> createState() => _AddLineItemDialogState();
}

class _AddLineItemDialogState extends State<_AddLineItemDialog> {
  late TextEditingController _productNameController;
  late TextEditingController _unitPriceController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _unitPriceController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _unitPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Line Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitPriceController,
              decoration: const InputDecoration(
                labelText: 'Unit Price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
          onPressed: () {
            final item = POLineItem(
              productId: DateTime.now().toString(),
              productName: _productNameController.text,
              unitPrice: double.tryParse(_unitPriceController.text) ?? 0,
              quantity: int.tryParse(_quantityController.text) ?? 1,
            );
            widget.onAdd(item);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
