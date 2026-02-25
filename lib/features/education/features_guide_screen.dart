import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// Features guide showing all app capabilities and how to use them
class FeaturesGuideScreen extends StatefulWidget {
  const FeaturesGuideScreen({super.key});

  @override
  State<FeaturesGuideScreen> createState() => _FeaturesGuideScreenState();
}

class _FeaturesGuideScreenState extends State<FeaturesGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'App Features',
          style: AppTextStyles.h4.copyWith(color: AppColors.text),
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              tabs: const [
                Tab(text: 'Shopping'),
                Tab(text: 'Community'),
                Tab(text: 'Features'),
                Tab(text: 'Roles'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShoppingTab(),
                _buildCommunityTab(),
                _buildFeaturesTab(),
                _buildRolesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildFeatureGroup(
          title: '🏪 Shopping Features',
          features: [
            FeatureItem(
              icon: '🔍',
              title: 'Browse Products',
              description: 'Search, filter, and discover thousands of products from local and global brands.',
              steps: [
                'Open the Home tab',
                'Search by category or product name',
                'Apply filters for brand, price, ratings',
                'Add items to your cart',
              ],
            ),
            FeatureItem(
              icon: '⭐',
              title: 'Product Reviews',
              description: 'Read and write honest reviews to help the community make informed choices.',
              steps: [
                'Click on any product',
                'Scroll to "Reviews" section',
                'Read other members\' reviews and ratings',
                'Write your own review after purchase',
              ],
            ),
            FeatureItem(
              icon: '💳',
              title: 'Member-Only Pricing',
              description: 'Access exclusive deals and fair prices based on your membership tier.',
              steps: [
                'View products at your tier\'s price',
                'Upgrade membership for better rates',
                'Check "Your Benefits" for tier details',
              ],
            ),
            FeatureItem(
              icon: '🛍️',
              title: 'Flash Sales',
              description: 'Get early access to limited-time flash sales as a member.',
              steps: [
                'Check Home tab for "Flash Sales" section',
                'Members get 2 hours early access',
                'Limited quantities, first come first served',
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommunityTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildFeatureGroup(
          title: '👥 Community Features',
          features: [
            FeatureItem(
              icon: '📊',
              title: 'Analytics Dashboard',
              description: 'Track your impact, savings, and community contributions in real-time.',
              steps: [
                'Go to Dashboard or Profile',
                'View your total savings',
                'See community impact metrics',
                'Track your purchase history',
                'Monitor reward points',
              ],
            ),
            FeatureItem(
              icon: '🎁',
              title: 'Rewards & Points',
              description: 'Earn points on every purchase and redeem for discounts.',
              steps: [
                'Earn 1 point per ₦1 spent',
                'Gold members earn 5% bonus points',
                'Redeem points in wallet section',
                'Transfer points to family',
              ],
            ),
            FeatureItem(
              icon: '💰',
              title: 'Community Dividends',
              description: 'Earn a share of cooperative profits as a member.',
              steps: [
                'Your membership gives you ownership',
                'Dividends distributed quarterly',
                'Amount based on community sales',
                'Check "Earnings" section for details',
              ],
            ),
            FeatureItem(
              icon: '🤝',
              title: 'Member Voting',
              description: 'Have a voice in cooperative decisions that affect everyone.',
              steps: [
                'Check notifications for active votes',
                'Review voting topics carefully',
                'Cast your one-member-one-vote',
                'Track voting outcomes',
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildFeatureGroup(
          title: '🛠️ Advanced Features',
          features: [
            FeatureItem(
              icon: '📝',
              title: 'Invoices & Billing',
              description: 'Generate and manage invoices for your orders and transactions.',
              steps: [
                'Go to Orders section',
                'Tap "Generate Invoice" on any order',
                'Download or email invoice',
                'Keep for business records',
              ],
            ),
            FeatureItem(
              icon: '📦',
              title: 'Bulk Ordering',
              description: 'Place large orders with special bulk pricing and terms.',
              steps: [
                'Wholesale members see bulk pricing',
                'Set up recurring orders',
                'Get personalized business support',
                'Track bulk shipments',
              ],
            ),
            FeatureItem(
              icon: '🚚',
              title: 'Order Tracking',
              description: 'Real-time tracking from warehouse to your door.',
              steps: [
                'Go to your active orders',
                'See live tracking updates',
                'Get delivery notifications',
                'Confirm delivery',
              ],
            ),
            FeatureItem(
              icon: '💬',
              title: 'Customer Support',
              description: 'Chat with support team or browse help articles.',
              steps: [
                'Go to Help & Support',
                'Start chat with agent',
                'Browse FAQ articles',
                'Call support hotline',
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRolesTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'User Roles in Cooperative Commerce',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildRoleCard(
          role: 'Regular Member',
          icon: '👤',
          description: 'Individual consumer making purchases',
          canAccess: [
            'Browse and buy products',
            'Leave product reviews',
            'Earn and redeem rewards',
            'Track personal analytics',
            'Vote on cooperative matters',
            'Access member-only deals',
          ],
        ),
        _buildRoleCard(
          role: 'Wholesale Member',
          icon: '🏢',
          description: 'Small business or bulk buyer',
          canAccess: [
            'Bulk product ordering',
            'Business-level pricing',
            'Institutional approval workflows',
            'Generate invoices & reports',
            'Dedicated account manager',
            'Same voting rights as members',
          ],
        ),
        _buildRoleCard(
          role: 'Store Manager',
          icon: '🏪',
          description: 'Manages a store location or franchise',
          canAccess: [
            'Manage store inventory',
            'View store analytics',
            'Handle customer orders',
            'Process payments',
            'Staff management',
            'Generate business reports',
          ],
        ),
        _buildRoleCard(
          role: 'Institutional Approver',
          icon: '✅',
          description: 'Approves large orders and POs',
          canAccess: [
            'Review purchase orders',
            'Verify budgets',
            'Approve/reject orders',
            'Access audit logs',
            'View approval workflows',
            'Generate compliance reports',
          ],
        ),
        _buildRoleCard(
          role: 'Admin',
          icon: '⚙️',
          description: 'System administrator',
          canAccess: [
            'Full system access',
            'User management',
            'Settings configuration',
            'Analytics & reporting',
            'Compliance auditing',
            'System monitoring',
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureGroup({
    required String title,
    required List<FeatureItem> features,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h4),
        const SizedBox(height: AppSpacing.lg),
        ...features.map((feature) => _buildFeatureCard(feature)),
      ],
    );
  }

  Widget _buildFeatureCard(FeatureItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: GestureDetector(
        onTap: () => _showFeatureDetail(item),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.h5),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String icon,
    required String description,
    required List<String> canAccess,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role, style: AppTextStyles.h5),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Can access:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...canAccess.map((access) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      access,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showFeatureDetail(FeatureItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          color: Colors.white,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Text(item.icon, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: AppTextStyles.h4),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'How to use:',
                style: AppTextStyles.h5,
              ),
              const SizedBox(height: AppSpacing.md),
              ...item.steps.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$index',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            step,
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got It',
                  style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureItem {
  final String icon;
  final String title;
  final String description;
  final List<String> steps;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.steps,
  });
}
