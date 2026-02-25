import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/store_manager_analytics_service.dart';
import '../../models/store_manager_analytics_models.dart';

/// Product Performance Screen
/// Shows detailed analytics for each product: sales, revenue, stock levels, profitability
class ProductPerformanceScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const ProductPerformanceScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  ConsumerState<ProductPerformanceScreen> createState() =>
      _ProductPerformanceScreenState();
}

class _ProductPerformanceScreenState
    extends ConsumerState<ProductPerformanceScreen> {
  late StoreManagerAnalyticsService _analyticsService;
  String _sortBy = 'revenue'; // revenue, sales, turnover

  @override
  void initState() {
    super.initState();
    _analyticsService = StoreManagerAnalyticsService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Performance'),
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sort Options
            Container(
              color: Colors.teal.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSortButton(
                          'Revenue',
                          'revenue',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSortButton(
                          'Units Sold',
                          'sales',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSortButton(
                          'Turnover',
                          'turnover',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Products List
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<ProductPerformance>>(
                future: _analyticsService
                    .getProductPerformanceMetrics(widget.storeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  var products = snapshot.data ?? [];

                  // Sort products
                  switch (_sortBy) {
                    case 'revenue':
                      products.sort(
                          (a, b) => b.totalRevenue.compareTo(a.totalRevenue));
                      break;
                    case 'sales':
                      products.sort((a, b) =>
                          b.quantitySold.compareTo(a.quantitySold));
                      break;
                    case 'turnover':
                      products.sort(
                          (a, b) => b.turnoverRate.compareTo(a.turnoverRate));
                      break;
                  }

                  if (products.isEmpty) {
                    return const Center(
                      child: Text('No product data available'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductDetailCard(products[index], index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, String value) {
    final isSelected = _sortBy == value;
    return ElevatedButton(
      onPressed: () {
        setState(() => _sortBy = value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.teal,
        side: BorderSide(
          color:
              isSelected ? Colors.teal : Colors.teal.shade200,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _buildProductDetailCard(ProductPerformance product, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with product name and stock status
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
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${product.sku}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stock Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: product.isLowStock
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.isLowStock
                        ? '⚠ Low Stock'
                        : '✓ In Stock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: product.isLowStock
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            // Sales & Revenue Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Revenue',
                    '₦${product.totalRevenue.toStringAsFixed(0)}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Units Sold',
                    product.quantitySold.toString(),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Profit Margin',
                    '${product.profitMargin.toStringAsFixed(1)}%',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pricing & Inventory Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Avg Price',
                    '₦${product.averagePrice.toStringAsFixed(0)}',
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Turnover Rate',
                    '${product.turnoverRate.toStringAsFixed(1)}x',
                    Colors.cyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Current Stock',
                    product.stockLevel.toString(),
                    product.stockLevel <= product.minimumStock
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stock Level Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${product.stockLevel}/${(product.minimumStock * 3).toString()} units',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (product.stockLevel / (product.minimumStock * 3))
                        .clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      product.isLowStock
                          ? Colors.red
                          : product.stockLevel > (product.minimumStock * 2)
                              ? Colors.green
                              : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Recommendation
            if (product.isLowStock)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consider reordering. Current stock below minimum.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
