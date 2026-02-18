import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/franchise_models.dart';
import '../../core/providers/franchise_providers.dart';

// FRANCHISE DASHBOARD
class FranchiseDashboardScreen extends ConsumerWidget {
  final String storeId;

  const FranchiseDashboardScreen({
    super.key,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(franchiseDashboardMetricsProvider(storeId));
    final storeAsync = ref.watch(franchiseStoreProvider(storeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Dashboard'),
        elevation: 0,
      ),
      body: metricsAsync.when(
        data: (metrics) => storeAsync.when(
          data: (store) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store header
                if (store != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${store.city}, ${store.state}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Sales metrics
                Text(
                  'Today\'s Sales',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Sales',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${metrics.todaysSales.toStringAsFixed(2)}',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Transactions',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  metrics.todaysTransactions.toString(),
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Weekly summary
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Sales',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${metrics.weeksSales.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Avg Daily',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${metrics.weeksAvgDailySales.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Inventory alerts
                Text(
                  'Inventory',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _MetricCard(
                      label: 'Inventory Value',
                      value: '\$${metrics.inventoryValue.toStringAsFixed(0)}',
                      icon: Icons.inventory_2,
                    ),
                    _MetricCard(
                      label: 'Low Stock Items',
                      value: metrics.lowStockItems.toString(),
                      icon: Icons.warning,
                      color: Colors.orange,
                    ),
                    _MetricCard(
                      label: 'Reorder Needed',
                      value: metrics.reorderItems.toString(),
                      icon: Icons.add_shopping_cart,
                      color: Colors.red,
                    ),
                    _MetricCard(
                      label: 'In Stock',
                      value: 'Good',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Compliance
                Text(
                  'Compliance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Score',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      metrics.complianceScore
                                          .toStringAsFixed(1),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getGradeColor(
                                            metrics.complianceGrade),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        metrics.complianceGrade,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (metrics.violations.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Violations',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      metrics.violations.length.toString(),
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _ActionTile(
                      label: 'View Inventory',
                      icon: Icons.inventory_2,
                      onTap: () {
                        // Navigate to inventory screen
                      },
                    ),
                    _ActionTile(
                      label: 'Compliance',
                      icon: Icons.checklist,
                      onTap: () {
                        // Navigate to compliance screen
                      },
                    ),
                    _ActionTile(
                      label: 'Sales Report',
                      icon: Icons.trending_up,
                      onTap: () {
                        // Navigate to reports screen
                      },
                    ),
                    _ActionTile(
                      label: 'Settings',
                      icon: Icons.settings,
                      onTap: () {
                        // Navigate to settings
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Colors.blue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: cardColor, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// COMPLIANCE CHECKLIST SCREEN
class ComplianceChecklistScreen extends ConsumerStatefulWidget {
  final String storeId;

  const ComplianceChecklistScreen({
    super.key,
    required this.storeId,
  });

  @override
  ConsumerState<ComplianceChecklistScreen> createState() =>
      _ComplianceChecklistScreenState();
}

class _ComplianceChecklistScreenState
    extends ConsumerState<ComplianceChecklistScreen> {
  late final List<String> _completedItems;

  @override
  void initState() {
    super.initState();
    _completedItems = [];
  }

  @override
  Widget build(BuildContext context) {
    final checklistAsync =
        ref.watch(todaysComplianceChecklistProvider(widget.storeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Compliance'),
      ),
      body: checklistAsync.when(
        data: (checklist) {
          if (checklist == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.checklist,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('No checklist for today'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${checklist.completedCount}/${checklist.totalCount}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: checklist.totalCount > 0
                            ? checklist.completedCount / checklist.totalCount
                            : 0,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

                // Checklist items
                ..._buildChecklistItems(context, checklist),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<Widget> _buildChecklistItems(
      BuildContext context, ComplianceChecklist checklist) {
    final items = <Widget>[];

    for (final item in checklist.items) {
      items.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: CheckboxListTile(
            value: item.isCompleted || _completedItems.contains(item.id),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _completedItems.add(item.id);
                } else {
                  _completedItems.remove(item.id);
                }
              });
            },
            title: Text(item.title),
            subtitle: Text(item.description),
          ),
        ),
      );
    }

    items.add(const SizedBox(height: 24));
    items.add(
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              _completedItems.isEmpty ? null : () => _submitChecklist(context),
          child: const Text('Submit Checklist'),
        ),
      ),
    );

    return items;
  }

  Future<void> _submitChecklist(BuildContext context) async {
    // Submit logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checklist submitted')),
    );
  }
}

// FRANCHISE REPORTS SCREEN
class FranchiseReportsScreen extends ConsumerWidget {
  final String storeId;

  const FranchiseReportsScreen({
    super.key,
    required this.storeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final monthlySalesAsync = ref.watch(
      franchiseSalesSummaryProvider((storeId, startOfMonth, now)),
    );
    final complianceAsync = ref.watch(
      complianceScoreProvider((storeId, startOfMonth, now)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly sales
            Text(
              'Monthly Sales Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            monthlySalesAsync.when(
              data: (summary) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ReportRow(
                        label: 'Total Sales',
                        value: '\$${summary.totalSales.toStringAsFixed(2)}',
                      ),
                      _ReportRow(
                        label: 'Avg Daily',
                        value: '\$${summary.avgDailySales.toStringAsFixed(2)}',
                      ),
                      _ReportRow(
                        label: 'Total COGS',
                        value: '\$${summary.totalCogs.toStringAsFixed(2)}',
                      ),
                      _ReportRow(
                        label: 'Gross Profit',
                        value:
                            '\$${summary.totalGrossProfit.toStringAsFixed(2)}',
                      ),
                      _ReportRow(
                        label: 'Avg Profit Margin',
                        value: '${summary.avgProfitMargin.toStringAsFixed(1)}%',
                      ),
                      _ReportRow(
                        label: 'Total Transactions',
                        value: summary.totalTransactions.toString(),
                      ),
                      _ReportRow(
                        label: 'Avg Transaction',
                        value:
                            '\$${summary.avgTransactionValue.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 24),

            // Compliance report
            Text(
              'Compliance Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            complianceAsync.when(
              data: (score) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Overall Score'),
                          Text(
                            '${score.complianceScore.toStringAsFixed(1)}/100',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _ReportRow(
                        label: 'Checklists Completed',
                        value:
                            '${score.totalChecklistsCompleted}/${score.totalChecklistsRequired}',
                      ),
                      _ReportRow(
                        label: 'Completion Rate',
                        value: '${score.completionRate.toStringAsFixed(1)}%',
                      ),
                      _ReportRow(
                        label: 'Grade',
                        value: score.getGrade(),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
