import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/services/pricing_engine_service.dart';
import 'package:coop_commerce/models/pricing/pricing_models.dart';

/// Provider for pending price overrides
final pendingPriceOverridesProvider = FutureProvider<List<PriceOverride>>(
  (ref) async {
    final pricingService = ref.watch(pricingEngineServiceProvider);
    return pricingService.getPendingPriceOverrides();
  },
);

/// Provider for price audit log (retrieves a sample - all changes)
final priceAuditLogProvider = FutureProvider<List<PriceAuditLog>>(
  (ref) async {
    // For demo, we'll return empty list - in real app, query all from Firestore directly
    return [];
  },
);

/// Simple provider for pricing service
final pricingEngineServiceProvider =
    Provider<PricingEngineService>((ref) => PricingEngineService());

/// Admin Dashboard for Price Override Approvals
class PriceOverrideAdminDashboard extends ConsumerStatefulWidget {
  const PriceOverrideAdminDashboard({super.key});

  @override
  ConsumerState<PriceOverrideAdminDashboard> createState() =>
      _PriceOverrideAdminDashboardState();
}

class _PriceOverrideAdminDashboardState
    extends ConsumerState<PriceOverrideAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pricing Control Tower'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Approvals', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Price History', icon: Icon(Icons.history)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingApprovalsTab(),
          _buildPriceHistoryTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  /// Tab 1: Pending Approvals
  Widget _buildPendingApprovalsTab() {
    final pendingAsync = ref.watch(pendingPriceOverridesProvider);

    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading pending overrides\n$error',
                textAlign: TextAlign.center),
          ],
        ),
      ),
      data: (pendingOverrides) {
        if (pendingOverrides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('No pending price overrides',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                const Text('All price override requests have been processed.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingOverrides.length,
          itemBuilder: (context, index) {
            final override = pendingOverrides[index];
            return _PriceOverrideCard(
              override: override,
              onApprove: () => _approvePriceOverride(override),
              onReject: () => _showRejectDialog(override),
            );
          },
        );
      },
    );
  }

  /// Tab 2: Price History
  Widget _buildPriceHistoryTab() {
    final auditLogAsync = ref.watch(priceAuditLogProvider);

    return auditLogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading price history\n$error',
                textAlign: TextAlign.center),
          ],
        ),
      ),
      data: (auditLog) {
        if (auditLog.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No price change history',
                    style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: auditLog.length,
          itemBuilder: (context, index) {
            final log = auditLog[index];
            return _PriceAuditLogCard(log: log);
          },
        );
      },
    );
  }

  /// Tab 3: Analytics
  Widget _buildAnalyticsTab() {
    final pendingAsync = ref.watch(pendingPriceOverridesProvider);
    final auditLogAsync = ref.watch(priceAuditLogProvider);

    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) =>
          const Center(child: Text('Error loading analytics')),
      data: (pending) {
        return auditLogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, st) =>
              const Center(child: Text('Error loading analytics')),
          data: (auditLog) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StatCard(
                        label: 'Pending Approvals',
                        value: pending.length.toString(),
                        color: Colors.orange,
                        icon: Icons.pending_actions,
                      ),
                      _StatCard(
                        label: 'Total Changes',
                        value: auditLog.length.toString(),
                        color: AppColors.primary,
                        icon: Icons.trending_up,
                      ),
                      _StatCard(
                        label: 'Overrides This Month',
                        value: _countOverridesThisMonth(auditLog),
                        color: AppColors.accent,
                        icon: Icons.edit,
                      ),
                      _StatCard(
                        label: 'Avg Discount %',
                        value: _averageDiscount(auditLog),
                        color: Colors.blue,
                        icon: Icons.percent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Most Changed Products
                  Text('Most Changed Products',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ..._getMostChangedProducts(auditLog)
                      .entries
                      .toList()
                      .take(5)
                      .map((entry) => _MostChangedProductTile(
                            productId: entry.key,
                            changeCount: entry.value,
                          )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper methods
  Future<void> _approvePriceOverride(PriceOverride override) async {
    try {
      final pricingService = ref.read(pricingEngineServiceProvider);
      await pricingService.approvePriceOverride(
        overrideId: override.id,
        approvedBy: 'admin_user', // TODO: Get from user context
      );

      // Refresh the pending overrides list
      ref.refresh(pendingPriceOverridesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Price override approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving override: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(PriceOverride override) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Price Override'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${override.id}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
                hintText: 'Why are you rejecting this override?',
              ),
              minLines: 3,
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final pricingService = ref.read(pricingEngineServiceProvider);
                await pricingService.rejectPriceOverride(
                  overrideId: override.id,
                  rejectionReason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : 'No reason provided',
                );

                ref.refresh(pendingPriceOverridesProvider);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Price override rejected'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error rejecting override: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  String _countOverridesThisMonth(List<PriceAuditLog> logs) {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1 < 1 ? 12 : now.month - 1);

    return logs
        .where((log) =>
            log.changedAt.isAfter(monthAgo) &&
            log.changeReason.contains('override'))
        .length
        .toString();
  }

  String _averageDiscount(List<PriceAuditLog> logs) {
    if (logs.isEmpty) return '0%';

    final discounts = logs
        .map((log) =>
            ((log.previousPrice - log.newPrice) / log.previousPrice * 100))
        .where((discount) => discount > 0)
        .toList();

    if (discounts.isEmpty) return '0%';
    final avg = discounts.reduce((a, b) => a + b) / discounts.length;
    return '${avg.toStringAsFixed(1)}%';
  }

  Map<String, int> _getMostChangedProducts(List<PriceAuditLog> logs) {
    final counts = <String, int>{};
    for (var log in logs) {
      counts[log.productId] = (counts[log.productId] ?? 0) + 1;
    }
    return Map.fromEntries(
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}

/// Card for displaying a pending price override
class _PriceOverrideCard extends StatelessWidget {
  final PriceOverride override;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PriceOverrideCard({
    required this.override,
    required this.onApprove,
    required this.onReject,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product ID: ${override.productId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested: ${_formatDate(override.requestedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Price Comparison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Price',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '₦${override.requestedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward, color: AppColors.primary),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Requested Price',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '₦${override.requestedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Metadata
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Requested By',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(override.requestedBy,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (override.customerId != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('For Customer',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(override.customerId!,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Card for displaying price audit log entry
class _PriceAuditLogCard extends StatelessWidget {
  final PriceAuditLog log;

  const _PriceAuditLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final change = log.newPrice - log.previousPrice;
    final percentChange = (change / log.previousPrice * 100);
    final isIncrease = change > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        'Product: ${log.productId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        log.changeReason,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIncrease
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isIncrease ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isIncrease ? Colors.red : Colors.green,
                      fontSize: 12,
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
                  '₦${log.previousPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  '→',
                  style: TextStyle(color: AppColors.primary),
                ),
                Text(
                  '₦${log.newPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'by ${log.changedBy}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat card for dashboard
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Most changed products tile
class _MostChangedProductTile extends StatelessWidget {
  final String productId;
  final int changeCount;

  const _MostChangedProductTile({
    required this.productId,
    required this.changeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(productId, style: const TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$changeCount changes',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
