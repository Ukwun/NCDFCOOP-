import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_providers.dart';
import '../../core/models/seller_models.dart';

/// QUICK SELLER ONBOARDING
/// Simplified 3-step seller setup (Alternative to broken complex flow)
class SellerOnboardingQuickScreen extends ConsumerStatefulWidget {
  final String userId;
  final String sellerType; // 'member' or 'wholesale'

  const SellerOnboardingQuickScreen({
    super.key,
    required this.userId,
    required this.sellerType,
  });

  @override
  ConsumerState<SellerOnboardingQuickScreen> createState() =>
      _SellerOnboardingQuickScreenState();
}

class _SellerOnboardingQuickScreenState
    extends ConsumerState<SellerOnboardingQuickScreen> {
  int _currentStep = 1; // 1-3
  final _businessNameController = TextEditingController();
  final _businessDescController = TextEditingController();
  final _businessTypeController = TextEditingController();
  bool _agreeToTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Step $_currentStep of 3 - Setup Your Store',
          style: AppTextStyles.h4,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_currentStep == 1) _buildStep1(),
              if (_currentStep == 2) _buildStep2(),
              if (_currentStep == 3) _buildStep3(),
              const SizedBox(height: 80), // Bottom nav padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.sellerType == 'member'
              ? '👤 Member Seller Information'
              : '🏪 Wholesale Buyer Information',
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 16),
        Text(
          'Tell us about your business so customers know what to expect.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _businessNameController,
          decoration: InputDecoration(
            labelText: 'Business Name',
            hintText: 'e.g., John\'s Farm Fresh Produce',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.business),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _businessTypeController,
          decoration: InputDecoration(
            labelText: 'Business Type',
            hintText: 'e.g., Agriculture, Retail, Services',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.category),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _validateAndContinue,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Continue to Description',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 Business Description',
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 16),
        Text(
          'Write a compelling description that helps customers understand your business.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _businessDescController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Business Description',
            hintText:
                'Tell us about your products, services, and why customers should choose you...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _validateAndContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Continue to Confirmation',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✅ Review & Confirm',
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 16),
        Text(
          'Please review your information before completing setup.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewField('Business Name', _businessNameController.text),
              const SizedBox(height: 12),
              _buildReviewField('Business Type', _businessTypeController.text),
              const SizedBox(height: 12),
              _buildReviewField('Description', _businessDescController.text),
              const SizedBox(height: 12),
              _buildReviewField(
                'Seller Type',
                widget.sellerType == 'member'
                    ? 'Member Seller (Retail)'
                    : 'Wholesale Buyer (B2B)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: _agreeToTerms,
          onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
          title: Text(
            'I agree to the Terms of Service and confirm this information is accurate',
            style: AppTextStyles.bodySmall,
          ),
          activeColor: AppColors.primary,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 2),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _agreeToTerms && !_isSubmitting
                    ? _completeOnboarding
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Complete Setup',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.isEmpty ? '(Not provided)' : value,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  void _validateAndContinue() {
    if (_currentStep == 1) {
      if (_businessNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a business name')),
        );
        return;
      }
      if (_businessTypeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a business type')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_businessDescController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please provide a business description')),
        );
        return;
      }
      setState(() => _currentStep = 3);
    }
  }

  Future<void> _completeOnboarding() async {
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? widget.userId;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to identify current user')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final sellerService = ref.read(sellerServiceProvider);
      final existing = await sellerService.getSellerProfileByUserId(userId);

      // Always upsert so tapping Complete Setup has a concrete effect every time.
      final profile = SellerProfile(
        id: existing?.id,
        userId: userId,
        businessName: _businessNameController.text.trim(),
        sellerType: _businessTypeController.text.trim().toLowerCase(),
        sellingPath: widget.sellerType,
        country: existing?.country.isNotEmpty == true
            ? existing!.country
            : 'Nigeria',
        category: _businessTypeController.text.trim().toLowerCase(),
        targetCustomer: widget.sellerType == 'wholesale'
            ? TargetCustomer.bulk
            : TargetCustomer.individual,
        isVerified: existing?.isVerified ?? false,
        createdAt: existing?.createdAt ?? DateTime.now(),
        approvedAt: existing?.approvedAt,
      );
      await sellerService.createSellerProfile(profile);

      ref.invalidate(sellerProfileByUserIdProvider(userId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller setup completed and saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      context.goNamed('home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete setup: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
