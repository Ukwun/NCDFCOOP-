import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/seller_models.dart';

/// SCREEN 5 - SELLER DASHBOARD
/// Simple dashboard showing All products, Pending, and Approved
class SellerDashboardScreen extends StatefulWidget {
  final String businessName;
  final List<SellerProduct> products;
  final VoidCallback onAddNewProduct;
  final VoidCallback onProductTap;

  const SellerDashboardScreen({
    super.key,
    required this.businessName,
    required this.products,
    required this.onAddNewProduct,
    required this.onProductTap,
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
  Widget build(BuildContext context) {
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

            // Stats section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStatsSection(),
            ),
            const SizedBox(height: 32),

            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildFilterTabs(),
            ),
            const SizedBox(height: 24),

            // Products section
            if (_filteredProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildEmptyState(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildProductsList(),
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
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.account_circle_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ),
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
                icon: Icons.packages_outlined,
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
      onTap: widget.onProductTap,
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
