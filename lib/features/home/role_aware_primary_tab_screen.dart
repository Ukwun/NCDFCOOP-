import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/cart/cart_screen.dart';
import 'package:coop_commerce/features/dashboard/personalized_dashboard_screen.dart';
import 'package:coop_commerce/features/home/role_aware_home_screen.dart';
import 'package:coop_commerce/features/messages/messages_screen.dart';
import 'package:coop_commerce/features/ncdfcoop/my_ncdfcoop_screen.dart';
import 'package:coop_commerce/features/offers/offers_screen.dart';
import 'package:coop_commerce/features/products/products_listing_screen.dart';
import 'package:coop_commerce/features/profile/payment_methods_screen.dart';
import 'package:coop_commerce/features/selling/seller_home_screen.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoleAwarePrimaryTabScreen extends ConsumerWidget {
  const RoleAwarePrimaryTabScreen({required this.tabIndex, super.key});

  final int tabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);

    if (_isMember(role)) {
      return _buildMemberTab(tabIndex);
    }

    if (_isSeller(role)) {
      return _buildSellerTab(tabIndex);
    }

    if (_isWholesale(role)) {
      return _buildWholesaleTab(tabIndex);
    }

    return _buildDefaultTab(tabIndex);
  }

  bool _isMember(UserRole role) {
    return role == UserRole.coopMember || role == UserRole.premiumMember;
  }

  bool _isSeller(UserRole role) {
    return role == UserRole.seller;
  }

  bool _isWholesale(UserRole role) {
    return role == UserRole.wholesaleBuyer ||
        role == UserRole.institutionalBuyer ||
        role == UserRole.institutionalApprover;
  }

  Widget _buildMemberTab(int index) {
    switch (index) {
      case 0:
        return const RoleAwareHomeScreen();
      case 1:
        return const PaymentMethodsScreen();
      case 2:
        return const _MemberSavingsTabScreen();
      case 3:
        return const _MemberInvestmentsTabScreen();
      case 4:
        return const MyNCDFCOOPScreen();
      default:
        return const RoleAwareHomeScreen();
    }
  }

  Widget _buildSellerTab(int index) {
    switch (index) {
      case 0:
        return const SellerHomeScreen();
      case 1:
        return const MessagesScreen();
      case 2:
        return const ProductsListingScreen(title: 'Seller Products');
      case 3:
        return const _SellerEarningsTabScreen();
      case 4:
        return const MyNCDFCOOPScreen();
      default:
        return const SellerHomeScreen();
    }
  }

  Widget _buildWholesaleTab(int index) {
    switch (index) {
      case 0:
        return const PersonalizedDashboardScreen();
      case 1:
        return const _WholesalePortfolioTabScreen();
      case 2:
        return const ProductsListingScreen(title: 'Bulk Investments');
      case 3:
        return const AnalyticsDashboardShell();
      case 4:
        return const MyNCDFCOOPScreen();
      default:
        return const PersonalizedDashboardScreen();
    }
  }

  Widget _buildDefaultTab(int index) {
    switch (index) {
      case 0:
        return const RoleAwareHomeScreen();
      case 1:
        return const OffersScreen();
      case 2:
        return const MessagesScreen();
      case 3:
        return const CartScreen();
      case 4:
        return const MyNCDFCOOPScreen();
      default:
        return const RoleAwareHomeScreen();
    }
  }
}

class AnalyticsDashboardShell extends StatelessWidget {
  const AnalyticsDashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const PersonalizedDashboardScreen();
  }
}

class _MemberSavingsTabScreen extends StatelessWidget {
  const _MemberSavingsTabScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Savings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            title: 'Savings Balance',
            value: 'NGN 245,000',
            subtitle: 'Monthly cooperative savings position',
            icon: Icons.savings_outlined,
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Manage funding source',
            subtitle: 'Update wallet and payment methods',
            onTap: () => context.pushNamed('payment-methods'),
          ),
          _ActionTile(
            icon: Icons.bar_chart_outlined,
            title: 'Open savings ledger',
            subtitle: 'Review deposits, withdrawals, and history',
            onTap: () => context.pushNamed('member-savings'),
          ),
          _ActionTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Member benefits',
            subtitle: 'See returns unlocked by your participation',
            onTap: () => context.pushNamed('member-benefits'),
          ),
        ],
      ),
    );
  }
}

class _MemberInvestmentsTabScreen extends StatelessWidget {
  const _MemberInvestmentsTabScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Investments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            title: 'Cooperative Growth',
            value: '12.4%',
            subtitle: 'Projected return across your active programs',
            icon: Icons.trending_up_outlined,
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.card_giftcard_outlined,
            title: 'Loyalty portfolio',
            subtitle: 'Track loyalty value and redemption momentum',
            onTap: () => context.pushNamed('member-loyalty'),
          ),
          _ActionTile(
            icon: Icons.dashboard_outlined,
            title: 'Open dashboard',
            subtitle: 'View broader portfolio intelligence',
            onTap: () => context.pushNamed('dashboard'),
          ),
          _ActionTile(
            icon: Icons.how_to_vote_outlined,
            title: 'Member voting',
            subtitle: 'Participate in capital allocation decisions',
            onTap: () => context.pushNamed('member-voting'),
          ),
        ],
      ),
    );
  }
}

class _SellerEarningsTabScreen extends StatelessWidget {
  const _SellerEarningsTabScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            title: 'Net Earnings',
            value: 'NGN 1,480,000',
            subtitle: 'Live payout position for your seller account',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            title: 'Sales ledger',
            subtitle: 'Review orders, fulfillment, and settlements',
            onTap: () => context.pushNamed('seller-sales-ledger'),
          ),
          _ActionTile(
            icon: Icons.payment_outlined,
            title: 'Payout methods',
            subtitle: 'Configure where your earnings are settled',
            onTap: () => context.pushNamed('payment-methods'),
          ),
          _ActionTile(
            icon: Icons.storefront_outlined,
            title: 'Product performance',
            subtitle: 'Open your products and optimize your catalog',
            onTap: () => context.pushNamed('products'),
          ),
        ],
      ),
    );
  }
}

class _WholesalePortfolioTabScreen extends StatelessWidget {
  const _WholesalePortfolioTabScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Portfolio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            title: 'Portfolio Value',
            value: 'NGN 8,920,000',
            subtitle: 'Active positions across bulk procurement cycles',
            icon: Icons.workspaces_outline,
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            title: 'Procurement orders',
            subtitle: 'Review active orders and contract status',
            onTap: () => context.pushNamed('orders'),
          ),
          _ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Account structure',
            subtitle: 'Inspect payment methods and settlement channels',
            onTap: () => context.pushNamed('payment-methods'),
          ),
          _ActionTile(
            icon: Icons.inventory_2_outlined,
            title: 'Bulk catalog',
            subtitle: 'Re-enter the bulk investment marketplace',
            onTap: () => context.pushNamed('products'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
