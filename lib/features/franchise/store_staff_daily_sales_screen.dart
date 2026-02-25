import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/store_staff_service.dart';
import 'package:coop_commerce/models/store_staff_models.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Store Staff Daily Sales Summary Screen
/// Displays daily sales metrics, top products, and payment breakdown
class StoreStaffDailySalesScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const StoreStaffDailySalesScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  ConsumerState<StoreStaffDailySalesScreen> createState() =>
      _StoreStaffDailySalesScreenState();
}

class _StoreStaffDailySalesScreenState
    extends ConsumerState<StoreStaffDailySalesScreen> {
  late Future<DailySalesSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() {
    final service = StoreStaffService();
    setState(() {
      _summaryFuture = service.getDailySalesSummary(widget.storeId, widget.storeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Daily Sales - ${widget.storeName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: FutureBuilder<DailySalesSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSummary,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final summary = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: summary.status == 'open' ? Colors.blue[50] : Colors.green[50],
                    border: Border.all(
                      color: summary.status == 'open'
                          ? Colors.blue[200]!
                          : Colors.green[200]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Status: ${summary.status.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: summary.status == 'open'
                          ? Colors.blue[700]
                          : Colors.green[700],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main KPIs
                _buildKPIRow(
                  [
                    (
                      'Total Transactions',
                      '${summary.totalTransactions}',
                      Colors.blue
                    ),
                    (
                      'Total Revenue',
                      '₦${summary.totalRevenue.toStringAsFixed(0)}',
                      Colors.green
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildKPIRow(
                  [
                    (
                      'Total Profit',
                      '₦${summary.totalProfit.toStringAsFixed(0)}',
                      Colors.purple
                    ),
                    (
                      'Avg Transaction',
                      '₦${summary.averageTransaction.toStringAsFixed(0)}',
                      Colors.orange
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Payment Method Breakdown
                Text(
                  'Payment Methods',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: summary.paymentMethodBreakdown.entries
                        .map((entry) => _buildPaymentRow(
                              entry.key.replaceAll('_', ' ').toUpperCase(),
                              entry.value,
                              summary.totalTransactions,
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Top Products
                if (summary.topProducts.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Products',
                        style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: summary.topProducts.length,
                        itemBuilder: (context, index) {
                          final product = summary.topProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(product.productName),
                              subtitle:
                                  Text('${product.unitsSold} units sold'),
                              trailing: Text(
                                '₦${product.revenue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPIRow(
    List<(String label, String value, Color color)> items,
  ) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: item.$3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList()
          .expand((widget) {
        return [widget];
      }).toList()
          .dropLast(1)
          .fold<List<Widget>>(
        [],
        (list, widget) => [
          ...list,
          widget,
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    String method,
    int count,
    int total,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(method, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('$count (${percentage.toStringAsFixed(1)}%)'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPaymentMethodColor(method),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'mobile money':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

extension on List {
  List dropLast(int n) => sublist(0, length - n);
}
