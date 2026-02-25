import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/store_manager_analytics_service.dart';
import '../../models/store_manager_analytics_models.dart';

/// Inventory Health Screen
/// Shows inventory status: stock levels, turnover rates, dead stock, low stock alerts
class InventoryHealthScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const InventoryHealthScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  ConsumerState<InventoryHealthScreen> createState() =>
      _InventoryHealthScreenState();
}

class _InventoryHealthScreenState
    extends ConsumerState<InventoryHealthScreen> {
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
        title: const Text('Inventory Health'),
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<InventoryHealth>(
        future: _analyticsService.getInventoryHealth(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final health = snapshot.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Health Status Header
                Container(
                  color: Colors.teal.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall Health Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Status',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                health?.healthStatus ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getHealthColor(health?.healthStatus),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getHealthColor(health?.healthStatus)
                                  .withOpacity(0.2),
                            ),
                            child: Center(
                              child: Text(
                                health?.healthStatus == 'Healthy'
                                    ? '✓'
                                    : '⚠',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _getHealthColor(health?.healthStatus),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Key Metrics Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Row 1: Total Items & Low Stock
                      Row(
                        children: [
                          Expanded(
                            child: _buildHealthMetricCard(
                              'Total Items',
                              health?.totalItems.toString() ?? '0',
                              'SKUs in inventory',
                              Colors.blue,
                              Icons.inventory_2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildHealthMetricCard(
                              'Low Stock Items',
                              health?.lowStockItems.toString() ?? '0',
                              'Require reorder',
                              health != null && health.lowStockItems > 0
                                  ? Colors.red
                                  : Colors.green,
                              Icons.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Row 2: Overstock & Dead Stock
                      Row(
                        children: [
                          Expanded(
                            child: _buildHealthMetricCard(
                              'Overstocked Items',
                              health?.overstockedItems.toString() ?? '0',
                              'Excess inventory',
                              Colors.orange,
                              Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildHealthMetricCard(
                              'Dead Stock %',
                              '${health?.deadStockPercentage.toStringAsFixed(1) ?? '0'}%',
                              'Non-moving items',
                              Colors.purple,
                              Icons.trending_down,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Row 3: Turnover & Value
                      Row(
                        children: [
                          Expanded(
                            child: _buildHealthMetricCard(
                              'Avg Turnover',
                              '${health?.averageTurnoverRate.toStringAsFixed(1) ?? '0'}x',
                              'Times per period',
                              Colors.teal,
                              Icons.repeat,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildHealthMetricCard(
                              'Inventory Value',
                              '₦${(health?.inventoryValue ?? 0) / 1000000 > 1 ? (health?.inventoryValue ?? 0) / 1000000 : (health?.inventoryValue ?? 0) / 1000}${(health?.inventoryValue ?? 0) / 1000000 > 1 ? 'M' : 'k'}',
                              'Total value',
                              Colors.green,
                              Icons.attach_money,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Low Stock Alerts Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Low Stock Alerts',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<ProductPerformance>>(
                        future: _analyticsService
                            .getLowStockAlerts(widget.storeId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final lowStockItems = snapshot.data ?? [];

                          if (lowStockItems.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'All items are well stocked',
                                      style: TextStyle(
                                        color: Colors.green.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lowStockItems.length,
                            itemBuilder: (context, index) {
                              final item = lowStockItems[index];
                              return _buildLowStockAlert(item);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Recommendations Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendations',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildRecommendationCard(
                        '📦 Optimize Stock Levels',
                        'Review and adjust minimum stock levels based on sales velocity',
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _buildRecommendationCard(
                        '🔄 Improve Turnover Rate',
                        'Consider promotions for slow-moving items to increase turnover',
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildRecommendationCard(
                        '⚡ Reduce Dead Stock',
                        'Plan clearance sales for items with low turnover rates',
                        Colors.red,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthMetricCard(
    String label,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert(ProductPerformance product) {
    final stockPercentage =
        (product.stockLevel / (product.minimumStock * 2)).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${product.sku}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${product.stockLevel} units',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Minimum: ${product.minimumStock} units',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${(stockPercentage * 100).toStringAsFixed(0)}% of target',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: stockPercentage,
                minHeight: 4,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String? status) {
    if (status == 'Healthy') return Colors.green;
    if (status == 'Low Stock Alert') return Colors.red;
    if (status == 'Excess Dead Stock') return Colors.orange;
    if (status == 'Slow Moving') return Colors.amber;
    return Colors.grey;
  }
}
