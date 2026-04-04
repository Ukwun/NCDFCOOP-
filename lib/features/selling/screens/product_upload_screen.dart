import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/seller_models.dart';

/// SCREEN 3 - PRODUCT UPLOAD
/// Add Product with prominent approval notice
class ProductUploadScreen extends StatefulWidget {
  final TargetCustomer targetCustomer;
  final Function(String name, String category, double price, int quantity,
      int moq, String imageUrl, String description) onProductAdded;
  final VoidCallback onBack;

  const ProductUploadScreen({
    super.key,
    required this.targetCustomer,
    required this.onProductAdded,
    required this.onBack,
  });

  @override
  State<ProductUploadScreen> createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _moqController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'agriculture';
  String _imageUrl = '';
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _productNameController.dispose();
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
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _buildProgressIndicator(3),
              const SizedBox(height: 32),

              // CRITICAL APPROVAL NOTICE
              _buildApprovalNotice(),
              const SizedBox(height: 24),

              // Title
              Text(
                'Add Product',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selling to ${widget.targetCustomer.displayName}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 32),

              // Product Name
              _buildFormField(
                label: 'Product Name',
                controller: _productNameController,
                hint: 'Enter product name',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              Text(
                'Category',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _category,
                isExpanded: true,
                items: _buildCategoryItems(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Price
              _buildFormField(
                label: 'Price (₦)',
                controller: _priceController,
                hint: 'Enter price',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Quantity
              _buildFormField(
                label: 'Available Quantity',
                controller: _quantityController,
                hint: 'Enter quantity',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value!) == null) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // MOQ (Minimum Order Quantity)
              _buildFormField(
                label: 'Minimum Order Quantity',
                controller: _moqController,
                hint: 'Minimum units per order',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter MOQ';
                  }
                  if (int.tryParse(value!) == null) {
                    return 'Please enter a valid MOQ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'Product Description',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter product description';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Describe your product in detail',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Image Upload (placeholder)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outline,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Click to upload product image',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PNG, JPG up to 10MB',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Terms agreement
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return Colors.transparent;
                    }),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'I agree that my product will be reviewed before it goes live',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.text),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _agreedToTerms ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'Submit for Review',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: GestureDetector(
        onTap: widget.onBack,
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.arrow_back,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
      title: Text(
        'Add Product',
        style: AppTextStyles.h3.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildApprovalNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⏳ Approval Required',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.amber[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your product will be reviewed by NCDF COOP before it goes live. '
                  'This ensures quality and builds buyer trust.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.amber[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(int step) {
    return Row(
      children: List.generate(5, (index) {
        final stepNum = index + 1;
        final isActive = stepNum <= step;
        return Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  List<DropdownMenuItem<String>> _buildCategoryItems() {
    return [
      DropdownMenuItem(
        value: 'agriculture',
        child: Text('🌾 Agriculture'),
      ),
      DropdownMenuItem(
        value: 'retail',
        child: Text('🛍️ Retail'),
      ),
      DropdownMenuItem(
        value: 'manufacturing',
        child: Text('🏭 Manufacturing'),
      ),
      DropdownMenuItem(
        value: 'services',
        child: Text('🔧 Services'),
      ),
      DropdownMenuItem(
        value: 'other',
        child: Text('📦 Other'),
      ),
    ];
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onProductAdded(
        _productNameController.text,
        _category,
        double.parse(_priceController.text),
        int.parse(_quantityController.text),
        int.parse(_moqController.text),
        _imageUrl,
        _descriptionController.text,
      );
    }
  }
}
