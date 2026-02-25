import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class FeatureDiscoveryScreen extends StatefulWidget {
  const FeatureDiscoveryScreen({super.key});

  @override
  State<FeatureDiscoveryScreen> createState() => _FeatureDiscoveryScreenState();
}

class _FeatureDiscoveryScreenState extends State<FeatureDiscoveryScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('What You Can Do'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tab Navigation
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FeatureTab(
                      label: 'Member Benefits',
                      isActive: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    _FeatureTab(
                      label: 'Franchise Owner',
                      isActive: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                    _FeatureTab(
                      label: 'Institutional',
                      isActive: _selectedTab == 2,
                      onTap: () => setState(() => _selectedTab = 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            if (_selectedTab == 0)
              _MemberBenefitsContent()
            else if (_selectedTab == 1)
              _FranchiseOwnerContent()
            else
              _InstitutionalContent(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FeatureTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FeatureTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.primary : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _MemberBenefitsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Member Tiers',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 16),
          _TierCard(
            name: 'Basic Member',
            price: '₦0/forever',
            benefits: [
              '10% savings on most items',
              'Monthly newsletter',
              'Member-only deals',
              'Basic customer support',
            ],
          ),
          _TierCard(
            name: 'Gold Member',
            price: '₦5,000/year',
            benefits: [
              '15% off on all items',
              '2% cash back on purchases',
              'Free shipping (over ₦10,000)',
              'Priority customer support',
              'Exclusive member events',
              'Quarterly bonus offers',
            ],
            highlight: true,
          ),
          _TierCard(
            name: 'Platinum Member',
            price: '₦12,000/year',
            benefits: [
              '20% off on all items',
              '5% cash back on purchases',
              'Free priority shipping',
              'VIP customer support',
              'Early access to new products',
              'Quarterly bonus offers + gifts',
              'Dedicated account manager',
            ],
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final String name;
  final String price;
  final List<String> benefits;
  final bool highlight;

  const _TierCard({
    required this.name,
    required this.price,
    required this.benefits,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
          width: highlight ? 2 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: AppTextStyles.h5),
              if (highlight)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _FranchiseOwnerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Own Your Store',
                  style: AppTextStyles.h5,
                ),
                const SizedBox(height: 12),
                _Feature(
                  icon: Icons.storefront,
                  title: 'Full Store Management',
                  subtitle: 'Own and operate your franchise store',
                ),
                _Feature(
                  icon: Icons.show_chart,
                  title: 'Real-time Analytics',
                  subtitle: 'Track sales, inventory, and performance',
                ),
                _Feature(
                  icon: Icons.inventory_2,
                  title: 'Inventory Control',
                  subtitle: 'Manage stock from wholesale distribution',
                ),
                _Feature(
                  icon: Icons.people,
                  title: 'Staff Management',
                  subtitle: 'Hire and manage store employees',
                ),
                _Feature(
                  icon: Icons.trending_up,
                  title: 'Growth Opportunities',
                  subtitle: 'Scale your business with our support',
                ),
                _Feature(
                  icon: Icons.support,
                  title: '24/7 Support',
                  subtitle: 'Dedicated franchise support team',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/signup?type=franchiseOwner'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Become a Franchise Owner'),
          ),
        ],
      ),
    );
  }
}

class _InstitutionalContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Ordering for Organizations',
                  style: AppTextStyles.h5,
                ),
                const SizedBox(height: 12),
                _Feature(
                  icon: Icons.business,
                  title: 'Corporate Accounts',
                  subtitle: 'For companies, schools, and organizations',
                ),
                _Feature(
                  icon: Icons.discount,
                  title: 'Volume Discounts',
                  subtitle: 'Special pricing for bulk orders',
                ),
                _Feature(
                  icon: Icons.article,
                  title: 'Purchase Orders',
                  subtitle: 'Create and manage POs with invoicing',
                ),
                _Feature(
                  icon: Icons.approval,
                  title: 'Approval Workflows',
                  subtitle: 'Multiple approvers for purchase control',
                ),
                _Feature(
                  icon: Icons.local_shipping,
                  title: 'Delivery Management',
                  subtitle: 'Scheduled delivery to your location',
                ),
                _Feature(
                  icon: Icons.analytics,
                  title: 'Spend Analytics',
                  subtitle: 'Reports and insights on purchases',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/signup?type=institutionalBuyer'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Register Organization'),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
