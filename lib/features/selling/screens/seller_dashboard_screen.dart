import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/intelligence/role_commerce_intelligence.dart';
import '../../../theme/app_theme.dart';
import '../../../core/models/seller_models.dart';

/// SCREEN 5 - SELLER DASHBOARD
/// Simple dashboard showing All products, Pending, and Approved
class SellerDashboardScreen extends StatefulWidget {
  final String businessName;
  final String sellerId;
  final List<SellerProduct> products;
  final VoidCallback onAddNewProduct;
  final ValueChanged<SellerProduct> onProductTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSalesLedgerTap;
  final VoidCallback? onRefreshTap;

  const SellerDashboardScreen({
    super.key,
    required this.businessName,
    required this.sellerId,
    required this.products,
    required this.onAddNewProduct,
    required this.onProductTap,
    this.onProfileTap,
    this.onSalesLedgerTap,
    this.onRefreshTap,
  });

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  late List<SellerProduct> _filteredProducts;
  String _filterStatus = 'all'; // all, pending, approved

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  @override
  void didUpdateWidget(covariant SellerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _filterProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = RoleCommerceIntelligence.seller(widget.products);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Store',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.businessName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildFilterTabs(),
            ),
            const SizedBox(height: 16),
            if (_filteredProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildEmptyState(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildProductsList(),
              ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildBulkEnquiriesPanel(),
            ),
            const SizedBox(height: 24),

            // Stats section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStatsSection(),
            ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildRelationshipPanel(snapshot),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'Seller Dashboard',
        style: AppTextStyles.h3.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (widget.onSalesLedgerTap != null)
          IconButton(
            onPressed: widget.onSalesLedgerTap,
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Sales ledger',
          ),
        if (widget.onRefreshTap != null)
          IconButton(
            onPressed: widget.onRefreshTap,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        if (widget.onProfileTap != null)
          IconButton(
            onPressed: widget.onProfileTap,
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsSection() {
    final totalProducts = widget.products.length;
    final pendingCount = widget.products
        .where((p) => p.status == ProductApprovalStatus.pending)
        .length;
    final approvedCount = widget.products
        .where((p) => p.status == ProductApprovalStatus.approved)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.inventory_2_outlined,
                label: 'Total Products',
                value: totalProducts.toString(),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.hourglass_empty,
                label: 'Pending',
                value: pendingCount.toString(),
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle_outline,
                label: 'Approved',
                value: approvedCount.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipPanel(RoleRelationshipSnapshot snapshot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Buyer Relationship Intelligence',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(
                'Bulk-ready ${snapshot.bulkReadySkus}',
                Icons.inventory,
                onTap: () => _runBadgeAction(
                  'bulk-ready stock update',
                  widget.onAddNewProduct,
                ),
              ),
              _badge(
                'Restock risk ${snapshot.restockRiskSkus}',
                Icons.trending_down,
                onTap: () => _runBadgeAction(
                  'restock workflow',
                  widget.onAddNewProduct,
                ),
              ),
              _badge(
                'Approved/trusted ${snapshot.trustQualifiedSkus}',
                Icons.verified,
                onTap: () => _runBadgeAction(
                  'approval status refresh',
                  widget.onRefreshTap,
                ),
              ),
              _badge(
                'Price edge ${snapshot.valueSpreadPercent.toStringAsFixed(1)}%',
                Icons.savings_outlined,
                onTap: () => _runBadgeAction(
                  'price edge insights',
                  widget.onSalesLedgerTap ?? widget.onRefreshTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            snapshot.narrative,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(
    String label,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runBadgeAction(String label, VoidCallback? action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $label...'),
        duration: const Duration(milliseconds: 900),
      ),
    );

    if (action == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action is temporarily unavailable. Please retry.'),
        ),
      );
      return;
    }

    try {
      action();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That action is unavailable right now. Please retry.'),
        ),
      );
    }
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Approved', 'approved'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isActive = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = value;
          _filterProducts();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isActive ? Colors.white : AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Products',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._filteredProducts.map((product) => Column(
              children: [
                _buildProductCard(product),
                const SizedBox(height: 12),
              ],
            )),
      ],
    );
  }

  Widget _buildProductCard(SellerProduct product) {
    Color statusColor;
    String statusLabel;

    switch (product.status) {
      case ProductApprovalStatus.pending:
        statusColor = Colors.amber;
        statusLabel = '🟡 Pending';
        break;
      case ProductApprovalStatus.approved:
        statusColor = Colors.green;
        statusLabel = '🟢 Approved';
        break;
      case ProductApprovalStatus.rejected:
        statusColor = Colors.red;
        statusLabel = '🔴 Rejected';
        break;
    }

    return GestureDetector(
      onTap: () => widget.onProductTap(product),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₦${product.price.toStringAsFixed(2)}',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Qty: ${product.quantity} | MOQ: ${product.moq}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkEnquiriesPanel() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('quote_requests')
          .where('sellerId', isEqualTo: widget.sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        final enquiries = snapshot.data?.docs ?? const [];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.request_quote_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Bulk enquiries', style: AppTextStyles.h4),
                  const Spacer(),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.hasError)
                const Text(
                  'Enquiries will appear here when buyers contact you. Please refresh shortly.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else if (enquiries.isEmpty)
                const Text('No bulk enquiries yet.')
              else
                ...enquiries.take(5).map((document) {
                  final enquiry = document.data();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(enquiry['productName'] ?? 'Product enquiry'),
                    subtitle: Text(
                      '${enquiry['quantity'] ?? 0} units · NGN ${enquiry['targetUnitPrice'] ?? 0} each',
                    ),
                    trailing: Chip(
                      label: Text((enquiry['status'] ?? 'pending').toString()),
                    ),
                    onTap: () =>
                        _showEnquiryActions(document.reference, enquiry),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEnquiryActions(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> enquiry,
  ) async {
    final response = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(enquiry['productName'] ?? 'Bulk enquiry'),
        content: Text(enquiry['message']?.toString().trim().isNotEmpty == true
            ? enquiry['message']
            : 'The buyer did not add extra requirements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'declined'),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'accepted'),
            child: const Text('Accept & continue in chat'),
          ),
        ],
      ),
    );
    if (response == null) return;
    await reference.update({
      'status': response,
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.textLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding your products to the marketplace',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onAddNewProduct,
            icon: const Icon(Icons.add),
            label: const Text('Add New Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _filterProducts() {
    _filteredProducts = widget.products.where((product) {
      if (_filterStatus == 'all') return true;
      if (_filterStatus == 'pending') {
        return product.status == ProductApprovalStatus.pending;
      }
      if (_filterStatus == 'approved') {
        return product.status == ProductApprovalStatus.approved;
      }
      return true;
    }).toList();
  }
}
