import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/store_manager_analytics_service.dart';
import '../../models/store_manager_analytics_models.dart';

/// Store Manager Dashboard Screen
/// Displays key KPIs: Daily Sales, Top Products, Staff Performance, Inventory Health
class StoreManagerDashboardScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const StoreManagerDashboardScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  ConsumerState<StoreManagerDashboardScreen> createState() =>
      _StoreManagerDashboardScreenState();
}

class _StoreManagerDashboardScreenState
    extends ConsumerState<StoreManagerDashboardScreen> {
  late StoreManagerAnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _analyticsService = StoreManagerAnalyticsService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Analytics'),
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<StoreAnalyticsSummary>(
        future: _analyticsService.getStoreAnalyticsSummary(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final summary = snapshot.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Summary Cards
                Container(
                  color: Colors.teal.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Row 1: Revenue & Transactions
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              title: 'Today\'s Revenue',
                              value: summary != null
                                  ? '₦${(summary.totalRevenue / 7).toStringAsFixed(0)}'
                                  : '₦0',
                              color: Colors.blue,
                              icon: Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKPICard(
                              title: 'Transactions',
                              value:
                                  summary?.transactionCount.toString() ?? '0',
                              color: Colors.orange,
                              icon: Icons.receipt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Row 2: Profit & Customers
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              title: 'Profit Margin',
                              value: summary != null
                                  ? '${summary.profitMargin.toStringAsFixed(1)}%'
                                  : '0%',
                              color: Colors.green,
                              icon: Icons.attach_money,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKPICard(
                              title: 'Customers',
                              value: summary?.customersServed.toString() ?? '0',
                              color: Colors.purple,
                              icon: Icons.people,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Quick Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Navigating to Product Analytics'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text('Products'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Navigating to Staff Performance'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.people_outline),
                          label: const Text('Staff'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Top Products Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Products',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<ProductPerformance>>(
                        future: _analyticsService
                            .getProductPerformanceMetrics(widget.storeId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final products = snapshot.data ?? [];
                          final topFive = products.take(5).toList();

                          if (topFive.isEmpty) {
                            return const Text('No product data available');
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topFive.length,
                            itemBuilder: (context, index) {
                              final product = topFive[index];
                              return _buildProductCard(product, index + 1);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Staff Performance Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Performing Staff',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<StaffPerformance>>(
                        future: _analyticsService
                            .getStaffPerformanceMetrics(widget.storeId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final staff = snapshot.data ?? [];
                          final topThree = staff.take(3).toList();

                          if (topThree.isEmpty) {
                            return const Text('No staff data available');
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topThree.length,
                            itemBuilder: (context, index) {
                              final member = topThree[index];
                              return _buildStaffCard(member, index + 1);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Inventory Health Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory Status',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<InventoryHealth>(
                        future: _analyticsService
                            .getInventoryHealth(widget.storeId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final health = snapshot.data;

                          return _buildInventoryHealthCard(health);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductPerformance product, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank Badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getRankColor(rank),
              ),
              child: Center(
                child: Text(
                  rank.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Sold: ${product.quantitySold}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⚠ Low Stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Revenue
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₦${product.totalRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Turnover: ${product.turnoverRate.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffPerformance staff, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank Badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getRankColor(rank),
              ),
              child: Center(
                child: Text(
                  rank.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Staff Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.staffName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    staff.role,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Performance Metrics
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${staff.performanceScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: staff.performanceScore >= 85
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sales: ₦${(staff.totalSalesGenerated / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryHealthCard(InventoryHealth? health) {
    if (health == null) return const Text('No inventory data');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  health.healthStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: health.healthStatus == 'Healthy'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: health.healthStatus == 'Healthy'
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    health.healthStatus == 'Healthy' ? '✓' : '⚠',
                    style: TextStyle(
                      color: health.healthStatus == 'Healthy'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Inventory Metrics
            _buildInventoryMetricRow(
              'Total Items',
              health.totalItems.toString(),
            ),
            _buildInventoryMetricRow(
              'Low Stock Items',
              health.lowStockItems.toString(),
              color: health.lowStockItems > 0 ? Colors.orange : Colors.grey,
            ),
            _buildInventoryMetricRow(
              'Dead Stock',
              '${health.deadStockPercentage.toStringAsFixed(1)}%',
            ),
            _buildInventoryMetricRow(
              'Avg Turnover',
              '${health.averageTurnoverRate.toStringAsFixed(1)}x',
            ),
            _buildInventoryMetricRow(
              'Inventory Value',
              '₦${(health.inventoryValue / 1000000).toStringAsFixed(1)}M',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryMetricRow(String label, String value,
      {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}
