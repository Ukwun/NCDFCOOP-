import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../core/providers/home_providers.dart';

/// INSTITUTIONAL BUYER HOME SCREEN - REDESIGNED
/// Corporate, government, institutional buyers
/// Focus: PO management, approval workflows, bulk planning, spend analytics
/// Key differentiator: IN-APP approval workflows (department head must approve before submission)
class InstitutionalBuyerHomeScreen extends ConsumerWidget {
  const InstitutionalBuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userRole = 'institutionalBuyer';
    final featuredAsync = ref.watch(roleAwareFeaturedProductsProvider(userRole));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${user?.organisation ?? "My Organization"}',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CONTRACT STATUS BANNER
              _buildContractStatusBanner(context, user),
              const SizedBox(height: 24),

              // 2. SPEND & BUDGET OVERVIEW
              _buildSpendAndBudgetSection(context),
              const SizedBox(height: 24),

              // 3. PENDING APPROVALS ALERT
              _buildPendingApprovalsAlert(context),
              const SizedBox(height: 24),

              // 4. QUICK ACTION: CREATE NEW PO
              _buildCreatePoButton(context),
              const SizedBox(height: 24),

              // 5. PO DASHBOARD - Recent POs
              _buildPoStatusDashboard(context),
              const SizedBox(height: 24),

              // 6. BULK PLANNING TOOLS
              _buildBulkPlanningSection(context),
              const SizedBox(height: 24),

              // 7. CONTRACT PRICING PRODUCTS
              _buildContractPricingSection(context, featuredAsync),
              const SizedBox(height: 24),

              // 8. INVOICING & PAYMENT TERMS
              _buildInvoicingSection(context),
              const SizedBox(height: 24),

              // 9. SUPPORT & ACCOUNT MANAGEMENT
              _buildAccountManagementSection(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HELPER METHODS - B2B Procurement Focused
  // ═════════════════════════════════════════════════════════════════════════

  /// 1. CONTRACT STATUS BANNER
  Widget _buildContractStatusBanner(BuildContext context, dynamic user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contract Status',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Active • Expires Dec 31, 2025',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✓ Live',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Contract ID: CT-2024-001 | Payment Terms: Net-30',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. SPEND & BUDGET OVERVIEW
  Widget _buildSpendAndBudgetSection(BuildContext context) {
    final monthlyBudget = 500000.0;
    final monthlySpent = 187500.0;
    final remaining = monthlyBudget - monthlySpent;
    final percentUsed = (monthlySpent / monthlyBudget) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
              'Monthly Budget Overview',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _BudgetCard(
                    label: 'Total Budget',
                    value: '₦${(monthlyBudget / 1000).toStringAsFixed(0)}K',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BudgetCard(
                    label: 'Spent',
                    value: '₦${(monthlySpent / 1000).toStringAsFixed(0)}K',
                    icon: Icons.trending_down,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BudgetCard(
                    label: 'Remaining',
                    value: '₦${(remaining / 1000).toStringAsFixed(0)}K',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Budget progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Used',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      '${percentUsed.toStringAsFixed(0)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentUsed / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentUsed > 80 ? Colors.red : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 3. PENDING APPROVALS ALERT
  Widget _buildPendingApprovalsAlert(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.hourglass_empty,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2 POs Pending Approval',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Department heads need to review and approve before submission',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.pushNamed('approvals'),
              child: Text(
                'Review',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. CREATE NEW PO BUTTON (Big, prominent call-to-action)
  Widget _buildCreatePoButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.pushNamed('createpo'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Create New Purchase Order',
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 5. PO DASHBOARD
  Widget _buildPoStatusDashboard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Purchase Orders',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('allpos'),
                child: Text(
                  'View All',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PoStatusCard(
            poNumber: 'PO-2026-001234',
            vendor: 'Agricultural Supplies Co.',
            amount: '₦250,000',
            status: 'Approved',
            statusColor: Colors.green,
            date: 'Jan 28, 2026',
          ),
          const SizedBox(height: 8),
          _PoStatusCard(
            poNumber: 'PO-2026-001233',
            vendor: 'Fresh Produce Ltd',
            amount: '₦185,000',
            status: 'Pending Approval',
            statusColor: Colors.orange,
            date: 'Jan 26, 2026',
          ),
          const SizedBox(height: 8),
          _PoStatusCard(
            poNumber: 'PO-2026-001232',
            vendor: 'Logistics Partner Inc',
            amount: '₦420,000',
            status: 'Submitted',
            statusColor: Colors.blue,
            date: 'Jan 24, 2026',
          ),
        ],
      ),
    );
  }

  /// 6. BULK PLANNING TOOLS
  Widget _buildBulkPlanningSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulk Planning Tools',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PlanningToolButton(
                  icon: Icons.file_download_outlined,
                  label: 'Download\nTemplate',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanningToolButton(
                  icon: Icons.file_upload_outlined,
                  label: 'Bulk\nUpload',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanningToolButton(
                  icon: Icons.assessment_outlined,
                  label: 'Demand\nForecast',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 7. CONTRACT PRICING PRODUCTS
  Widget _buildContractPricingSection(
    BuildContext context,
    AsyncValue<List<Product>> featuredAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Contract Pricing',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          featuredAsync.when(
            data: (products) => products.isEmpty
                ? Text(
                    'No products available',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textLight,
                    ),
                  )
                : SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _ContractProductCard(
                          product: product,
                          context: context,
                        );
                      },
                    ),
                  ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text(
              'Error loading products',
              style: AppTextStyles.body.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 8. INVOICING & PAYMENT
  Widget _buildInvoicingSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
              'Invoicing & Payments',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _InvoiceRow(
              title: 'Outstanding Invoices',
              value: '3 invoices',
              amount: '₦847,500',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _InvoiceRow(
              title: 'Payment Terms',
              value: 'Net-30 days',
              amount: 'Next due: Feb 25',
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.pushNamed('invoices'),
              child: Text(
                'View All Invoices →',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 9. ACCOUNT MANAGEMENT
  Widget _buildAccountManagementSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
              'Account & Support',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _AccountLink(
              icon: Icons.person_outline,
              label: 'Manage Approvers',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _AccountLink(
              icon: Icons.settings_outline,
              label: 'Account Settings',
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _AccountLink(
              icon: Icons.help_outline,
              label: 'Contact Account Manager',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═════════════════════════════════════════════════════════════════════════

class _BudgetCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _BudgetCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (color ?? AppColors.primary).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PoStatusCard extends StatelessWidget {
  final String poNumber;
  final String vendor;
  final String amount;
  final String status;
  final Color statusColor;
  final String date;

  const _PoStatusCard({
    required this.poNumber,
    required this.vendor,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poNumber,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vendor,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanningToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlanningToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractProductCard extends StatelessWidget {
  final Product product;
  final BuildContext context;

  const _ContractProductCard({
    required this.product,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: product.imageUrl != null
                  ? Image(
                      image: product.imageUrl!.startsWith('assets/')
                          ? AssetImage(product.imageUrl!)
                          : NetworkImage(product.imageUrl!) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.image, color: Colors.grey[300]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₦${product.contractPrice.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String title;
  final String value;
  final String amount;
  final IconData icon;

  const _InvoiceRow({
    required this.title,
    required this.value,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _AccountLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccountLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
        ],
      ),
    );
  }
}
