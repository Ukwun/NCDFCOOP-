import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class FAQItem {
  final String id;
  final String category;
  final String question;
  final String answer;
  bool _isExpanded;

  FAQItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required bool isExpanded,
  }) : _isExpanded = isExpanded;

  bool get isExpanded => _isExpanded;

  set isExpanded(bool value) {
    _isExpanded = value;
  }
}

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  late List<FAQItem> faqs;
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _initializeFAQs();
  }

  void _initializeFAQs() {
    faqs = [
      FAQItem(
        id: '1',
        category: 'Orders',
        question: 'How do I track my order?',
        answer:
            'You can track your order from the "My Orders" section in your profile. The status will update in real-time as your order moves through our fulfillment process.',
        isExpanded: false,
      ),
      FAQItem(
        id: '2',
        category: 'Orders',
        question: 'Can I cancel or modify an order?',
        answer:
            'Orders can be cancelled within 1 hour of placement. After that, you\'ll need to contact our support team. Modifications are only possible before the order is packed.',
        isExpanded: false,
      ),
      FAQItem(
        id: '3',
        category: 'Payments',
        question: 'What payment methods do you accept?',
        answer:
            'We accept all major credit cards (Visa, Mastercard), debit cards, bank transfers, and our Cooperative Wallet. All transactions are secure and encrypted.',
        isExpanded: false,
      ),
      FAQItem(
        id: '4',
        category: 'Payments',
        question: 'Is my payment information safe?',
        answer:
            'Yes! We use industry-standard SSL encryption and comply with PCI DSS standards to protect your payment information. Your data is never stored on our servers.',
        isExpanded: false,
      ),
      FAQItem(
        id: '5',
        category: 'Delivery',
        question: 'What are your delivery times?',
        answer:
            'Standard delivery takes 2-3 business days within Lagos. Express delivery (next day) is available for orders placed before 2 PM on weekdays.',
        isExpanded: false,
      ),
      FAQItem(
        id: '6',
        category: 'Delivery',
        question: 'Do you deliver outside Lagos?',
        answer:
            'Currently, we deliver within Lagos and surrounding areas. We\'re expanding to other regions soon. Check our delivery coverage map for your area.',
        isExpanded: false,
      ),
      FAQItem(
        id: '7',
        category: 'Returns',
        question: 'What is your return policy?',
        answer:
            'We offer 14-day returns for most items in original condition. Food items cannot be returned. Return shipping is free for defective items.',
        isExpanded: false,
      ),
      FAQItem(
        id: '8',
        category: 'Account',
        question: 'How do I reset my password?',
        answer:
            'Click "Forgot Password" on the login page. Enter your email, and we\'ll send you a reset link. Follow the instructions in the email to create a new password.',
        isExpanded: false,
      ),
    ];
  }

  List<FAQItem> get filteredFAQs {
    if (selectedCategory == 'All') return faqs;
    return faqs.where((faq) => faq.category == selectedCategory).toList();
  }

  List<String> get categories {
    return ['All', ...faqs.map((f) => f.category).toSet()];
  }

  void _toggleFAQ(String id) {
    setState(() {
      for (var faq in faqs) {
        if (faq.id == id) {
          faq.isExpanded = !faq.isExpanded;
        } else {
          faq.isExpanded = false;
        }
      }
    });
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contacting support team - Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildCategoryTabs(),
            _buildFAQsList(),
            _buildContactSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:45',
                style: AppTextStyles.h4.copyWith(color: AppColors.surface),
              ),
              Row(
                spacing: 6,
                children: [
                  _buildStatusIcon('assets/icons/signal.png'),
                  _buildStatusIcon('assets/icons/wifi.png'),
                  _buildStatusIcon('assets/icons/battery.png'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Help & Support',
                style: AppTextStyles.h2.copyWith(color: AppColors.surface),
              ),
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.surface,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String assetPath) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.muted, width: 0.5),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 12,
          children: categories.map((category) {
            final isSelected = selectedCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  category,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? AppColors.surface : AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFAQsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: filteredFAQs.map((faq) {
          return _buildFAQCard(faq);
        }).toList(),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.smList,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _toggleFAQ(faq.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            faq.category,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          faq.question,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    faq.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (faq.isExpanded) ...[
            Divider(
              color: AppColors.border,
              height: 1,
              thickness: 1,
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                faq.answer,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Didn\'t find what you\'re looking for?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact our support team and we\'ll be happy to help you',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _contactSupport,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Icon(
                    Icons.mail_outline,
                    color: AppColors.surface,
                    size: 18,
                  ),
                  Text(
                    'Contact Support',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
