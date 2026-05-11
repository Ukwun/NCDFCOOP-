import 'package:flutter/material.dart';
import 'package:coop_commerce/core/models/seller_models.dart';
import 'package:coop_commerce/core/services/seller_service.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class SellerProductDetailRouteScreen extends StatelessWidget {
  final String productId;
  final bool editable;

  const SellerProductDetailRouteScreen({
    super.key,
    required this.productId,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    final service = SellerService();
    return FutureBuilder<SellerProduct>(
      future: service.getProductById(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product Details')),
            body: const Center(
              child: Text('Unable to load this product right now.'),
            ),
          );
        }

        return SellerProductDetailScreen(
          product: snapshot.data!,
          editable: editable,
        );
      },
    );
  }
}

/// Seller product detail and edit screen.
class SellerProductDetailScreen extends StatefulWidget {
  final SellerProduct product;
  final bool editable;

  const SellerProductDetailScreen({
    super.key,
    required this.product,
    this.editable = true,
  });

  @override
  State<SellerProductDetailScreen> createState() =>
      _SellerProductDetailScreenState();
}

class _SellerProductDetailScreenState extends State<SellerProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SellerService();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _moqController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.productName);
    _priceController =
        TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _quantityController =
        TextEditingController(text: widget.product.quantity.toString());
    _moqController = TextEditingController(text: widget.product.moq.toString());
    _descriptionController =
        TextEditingController(text: widget.product.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _moqController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.product.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    widget.product.imageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Product Name',
                controller: _nameController,
                enabled: widget.editable,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField(
                label: 'Price (NGN)',
                controller: _priceController,
                enabled: widget.editable,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      label: 'Quantity',
                      controller: _quantityController,
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 0) {
                          return 'Invalid qty';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      label: 'MOQ',
                      controller: _moqController,
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Invalid MOQ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                enabled: widget.editable,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Status: ${widget.product.status.displayName}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (widget.editable)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: !enabled,
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.product.id == null || widget.product.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot update product without an id')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = SellerProduct(
        id: widget.product.id,
        sellerId: widget.product.sellerId,
        productName: _nameController.text.trim(),
        category: widget.product.category,
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        moq: int.parse(_moqController.text.trim()),
        imageUrl: widget.product.imageUrl,
        description: _descriptionController.text.trim(),
        status: widget.product.status,
        rejectionReason: widget.product.rejectionReason,
        createdAt: widget.product.createdAt,
        approvedAt: widget.product.approvedAt,
        rejectedAt: widget.product.rejectedAt,
      );

      await _service.updateProduct(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update product: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
