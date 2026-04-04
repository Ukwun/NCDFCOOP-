import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/seller_models.dart';

/// SCREEN 2 - SELLER SETUP
/// Create Your Seller Profile with Target Customer Selection
class SellerSetupScreen extends StatefulWidget {
  final Function(String businessName, String sellerType, String country,
      String category, TargetCustomer targetCustomer) onContinue;
  final VoidCallback onBack;
  final String sellingPath; // 'member' or 'wholesale'

  const SellerSetupScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
    this.sellingPath = 'member',
  });

  @override
  State<SellerSetupScreen> createState() => _SellerSetupScreenState();
}

class _SellerSetupScreenState extends State<SellerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _countryController = TextEditingController();

  String _sellerType = 'individual';
  String _category = 'agriculture';
  TargetCustomer? _targetCustomer;

  final List<String> _sellerTypes = ['individual', 'business', 'cooperative'];
  final List<String> _categories = [
    'agriculture',
    'retail',
    'manufacturing',
    'services',
    'other'
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _countryController.dispose();
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
              _buildProgressIndicator(2),
              const SizedBox(height: 32),

              // Title
              Text(
                'Create Your Seller Profile',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about your business',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 32),

              // Business Name
              Text(
                'Business Name',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessNameController,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your business name';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter your business name',
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
              const SizedBox(height: 24),

              // Seller Type
              Text(
                'Seller Type',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _sellerTypes
                    .map((type) => _buildSellerTypeChip(type))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Country / Location
              Text(
                'Country / Location',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _countryController,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your country';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Select or type your country',
                  prefixIcon: const Icon(Icons.location_on_outlined),
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
              const SizedBox(height: 24),

              // Category
              Text(
                'Product Category',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: _category,
                isExpanded: true,
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(_getCategoryDisplay(cat)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // TARGET CUSTOMER SELECTION - NEW FEATURE
              Text(
                'Who do you want to sell to?',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose your primary target customer type',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 16),

              // Individual Customers Option
              _buildTargetCustomerCard(
                target: TargetCustomer.individual,
                icon: Icons.people_outline,
                title: 'Individual Customers',
                description: 'Sell to end consumers and retail buyers',
                isSelected: _targetCustomer == TargetCustomer.individual,
              ),
              const SizedBox(height: 12),

              // Bulk Buyers Option
              _buildTargetCustomerCard(
                target: TargetCustomer.bulk,
                icon: Icons.apartment_outlined,
                title: 'Bulk Buyers',
                description:
                    'Sell to businesses, wholesalers, and large orders',
                isSelected: _targetCustomer == TargetCustomer.bulk,
              ),
              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _targetCustomer == null ? null : _handleContinue,
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
                    'Continue',
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
        'Seller Setup',
        style: AppTextStyles.h3.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int step) {
    return Row(
      children: List.generate(5, (index) {
        final stepNum = index + 1;
        final isActive = stepNum <= step;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (index < 4) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSellerTypeChip(String type) {
    final isSelected = _sellerType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sellerType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          _getSellerTypeDisplay(type),
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetCustomerCard({
    required TargetCustomer target,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _targetCustomer = target;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate() && _targetCustomer != null) {
      widget.onContinue(
        _businessNameController.text,
        _sellerType,
        _countryController.text,
        _category,
        _targetCustomer!,
      );
    }
  }

  String _getSellerTypeDisplay(String type) {
    switch (type) {
      case 'individual':
        return 'Individual';
      case 'business':
        return 'Business';
      case 'cooperative':
        return 'Cooperative';
      default:
        return type;
    }
  }

  String _getCategoryDisplay(String category) {
    switch (category) {
      case 'agriculture':
        return '🌾 Agriculture';
      case 'retail':
        return '🛍️ Retail';
      case 'manufacturing':
        return '🏭 Manufacturing';
      case 'services':
        return '🔧 Services';
      case 'other':
        return '📦 Other';
      default:
        return category;
    }
  }
}
