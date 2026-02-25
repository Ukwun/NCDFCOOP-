import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/store_manager_analytics_service.dart';
import '../../models/store_manager_analytics_models.dart';

/// Staff Performance Screen
/// Shows detailed analytics for each staff member: sales, transactions, customer satisfaction
class StaffPerformanceScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;

  const StaffPerformanceScreen({
    Key? key,
    required this.storeId,
    required this.storeName,
  }) : super(key: key);

  @override
  ConsumerState<StaffPerformanceScreen> createState() =>
      _StaffPerformanceScreenState();
}

class _StaffPerformanceScreenState
    extends ConsumerState<StaffPerformanceScreen> {
  late StoreManagerAnalyticsService _analyticsService;
  String _filterBy = 'all'; // all, pos, sales, inventory

  @override
  void initState() {
    super.initState();
    _analyticsService = StoreManagerAnalyticsService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Performance'),
        elevation: 0,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Filter Options
            Container(
              color: Colors.teal.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Role',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Staff', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('POS Operators', 'pos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Sales', 'sales'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Inventory', 'inventory'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Staff List
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<StaffPerformance>>(
                future: _analyticsService
                    .getStaffPerformanceMetrics(widget.storeId),
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

                  var staff = snapshot.data ?? [];

                  // Filter by role
                  if (_filterBy != 'all') {
                    staff = staff
                        .where((s) =>
                            s.role.toLowerCase().contains(_filterBy))
                        .toList();
                  }

                  // Sort by performance score
                  staff.sort((a, b) =>
                      b.performanceScore.compareTo(a.performanceScore));

                  if (staff.isEmpty) {
                    return const Center(
                      child: Text('No staff members found'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: staff.length,
                    itemBuilder: (context, index) {
                      return _buildStaffDetailCard(staff[index], index + 1);
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterBy = value);
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.teal,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.teal,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? Colors.teal : Colors.teal.shade200,
      ),
    );
  }

  Widget _buildStaffDetailCard(StaffPerformance staff, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and rank badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.staffName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staff.role,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Performance Rating Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getPerformanceColor(staff.performanceScore)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${staff.performanceScore.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _getPerformanceColor(staff.performanceScore),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        staff.performanceRating,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPerformanceColor(staff.performanceScore),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            // Performance Metrics Row 1
            Row(
              children: [
                Expanded(
                  child: _buildPerfMetricCard(
                    'Transactions',
                    staff.transactionsProcessed.toString(),
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerfMetricCard(
                    'Total Sales',
                    '₦${(staff.totalSalesGenerated / 1000).toStringAsFixed(0)}k',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Performance Metrics Row 2
            Row(
              children: [
                Expanded(
                  child: _buildPerfMetricCard(
                    'Avg Transaction',
                    '₦${staff.averageTransactionValue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerfMetricCard(
                    'Customers Saved',
                    staff.customersSaved.toString(),
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Performance Score Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Performance Score',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${staff.performanceScore.toStringAsFixed(1)}/100',
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
                    value: staff.performanceScore / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getPerformanceColor(staff.performanceScore),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Performance Insights
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPerformanceInsight(staff),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
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

  Widget _buildPerfMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
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

  Color _getPerformanceColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blueAccent;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getPerformanceInsight(StaffPerformance staff) {
    if (staff.performanceScore >= 90) {
      return 'Outstanding performer. High sales and customer satisfaction.';
    } else if (staff.performanceScore >= 75) {
      return 'Good performance. Meeting and exceeding targets consistently.';
    } else if (staff.performanceScore >= 60) {
      return 'Satisfactory performance. Room for improvement in efficiency.';
    } else {
      return 'Performance needs attention. Consider providing additional training.';
    }
  }
}
