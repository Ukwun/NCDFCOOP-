import 'package:flutter/material.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Help Center Screen - User support and contact options
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int selectedContactMethod = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Help & Support',
          style: AppTextStyles.h4.copyWith(color: AppColors.text),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help?',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Get instant support from our team',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFAQItem(
                    'How do I earn member rewards?',
                    'You earn 1 point for every ₦1 spent. Gold members get 5% bonus points.',
                  ),
                  _buildFAQItem(
                    'How long do refunds take?',
                    'Refunds are processed within 7-10 business days from return approval.',
                  ),
                  _buildFAQItem(
                    'Can I upgrade my membership?',
                    'Yes! You can upgrade anytime from the Premium Membership page.',
                  ),
                  _buildFAQItem(
                    'What payment methods do you accept?',
                    'We accept credit cards, debit cards, and bank transfers.',
                  ),
                  _buildFAQItem(
                    'How do I track my order?',
                    'Go to My Orders and tap on any order to track in real-time.',
                  ),
                ],
              ),
            ),

            // Contact Methods
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Our Team',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildContactMethod(
                    index: 0,
                    icon: Icons.chat_bubble_outline,
                    title: 'Live Chat',
                    description:
                        'Chat with our support team (Available 9am-6pm)',
                    onTap: () => _showContactDialog(context, 'live-chat'),
                  ),
                  _buildContactMethod(
                    index: 1,
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    description: 'support@coopcommerce.com',
                    onTap: () => _showContactDialog(context, 'email'),
                  ),
                  _buildContactMethod(
                    index: 2,
                    icon: Icons.phone_outlined,
                    title: 'Call Us',
                    description: '+234 (0) 700 123 4567',
                    onTap: () => _showContactDialog(context, 'phone'),
                  ),
                  _buildContactMethod(
                    index: 3,
                    icon: Icons.schedule_outlined,
                    title: 'Schedule a Call',
                    description: 'Book a time that works for you',
                    onTap: () => _showContactDialog(context, 'schedule'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              answer,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedContactMethod == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          setState(() => selectedContactMethod = index);
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context, String method) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildContactBottomSheet(method),
    );
  }

  Widget _buildContactBottomSheet(String method) {
    final title = {
          'live-chat': 'Start Live Chat',
          'email': 'Send Email',
          'phone': 'Call Support',
          'schedule': 'Schedule Call',
        }[method] ??
        'Contact';

    final message = {
          'live-chat':
              'Connecting you to our support team...\n\nYou will be connected shortly.',
          'email': 'Opening email...\n\nEmail: support@coopcommerce.com',
          'phone': 'Preparing call...\n\nNumber: +234 (0) 700 123 4567',
          'schedule':
              'Opening booking calendar...\n\nSelect your preferred time slot.',
        }[method] ??
        '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              message,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'You will be connected shortly!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    duration: const Duration(seconds: 3),
                    backgroundColor: AppColors.primary,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'Continue',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
