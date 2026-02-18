import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/auth_provider.dart';

class FranchiseOwnerHomeScreenV2 extends ConsumerWidget {
  const FranchiseOwnerHomeScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildFranchiseHeader(user?.name ?? 'Store Owner'),

              // Revenue KPI Cards
              _buildRevenueKPIs(),

              // Inventory Status
              _buildInventorySection(),

              // Quick Actions
              _buildQuickActions(),

              // Reorder Suggestions
              _buildReorderSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFranchiseHeader(String storeName) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
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
                    'Franchise Store',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: Store-001',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store_outlined,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueKPIs() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Overview',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Colors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _KPIMetric(
                      label: 'Today',
                      value: '₦12,450',
                      trend: '+15%',
                      isPositive: true,
                    ),
                    _KPIMetric(
                      label: 'This Week',
                      value: '₦78,200',
                      trend: '+8%',
                      isPositive: true,
                    ),
                    _KPIMetric(
                      label: 'This Month',
                      value: '₦245,800',
                      trend: '+22%',
                      isPositive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Compliance Score',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '98%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Inventory Status',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 12),
          _InventoryCard(
            label: 'Total Stock Items',
            value: '1,245',
            status: 'Healthy',
            statusColor: Colors.green,
          ),
          const SizedBox(height: 12),
          _InventoryCard(
            label: 'Low Stock Items',
            value: '23',
            status: 'Action Needed',
            statusColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          _InventoryCard(
            label: 'Out of Stock',
            value: '5',
            status: 'Critical',
            statusColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  color: AppColors.primary,
                  onTap: (context) {
                    context.pushNamed('franchise-dashboard',
                        queryParameters: {'storeId': 'Store-001'});
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.inventory_2,
                  label: 'Inventory',
                  color: Colors.blue,
                  onTap: (context) {
                    context.pushNamed('franchise-inventory',
                        queryParameters: {'storeId': 'Store-001'});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.people,
                  label: 'Staff',
                  color: Colors.orange,
                  onTap: (context) {
                    context.pushNamed('franchise-staff',
                        queryParameters: {'storeId': 'Store-001'});
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bar_chart,
                  label: 'Analytics',
                  color: Colors.green,
                  onTap: (context) {
                    context.pushNamed('franchise-analytics',
                        queryParameters: {'storeId': 'Store-001'});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.store,
                  label: 'Store Mgmt',
                  color: Colors.purple,
                  onTap: (context) {
                    context.pushNamed('franchise-store-management',
                        queryParameters: {'storeId': 'Store-001'});
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.receipt,
                  label: 'Orders',
                  color: Colors.red,
                  onTap: (context) {
                    context.pushNamed('orders');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReorderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Suggested Reorders',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 12),
          _ReorderItem(
            productName: 'Premium Rice',
            currentStock: '45 bags',
            suggestedQty: '200 bags',
            priority: 'High',
          ),
          const SizedBox(height: 12),
          _ReorderItem(
            productName: 'Cooking Oil',
            currentStock: '12 cans',
            suggestedQty: '100 cans',
            priority: 'High',
          ),
          const SizedBox(height: 12),
          _ReorderItem(
            productName: 'Canned Tomatoes',
            currentStock: '67 cans',
            suggestedQty: '150 cans',
            priority: 'Medium',
          ),
        ],
      ),
    );
  }
}

class _KPIMetric extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool isPositive;

  const _KPIMetric({
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? Colors.green : Colors.red,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              trend,
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final Color statusColor;

  const _InventoryCard({
    required this.label,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Function(BuildContext)? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap?.call(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReorderItem extends StatelessWidget {
  final String productName;
  final String currentStock;
  final String suggestedQty;
  final String priority;

  const _ReorderItem({
    required this.productName,
    required this.currentStock,
    required this.suggestedQty,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = priority == 'High' ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 4),
                Text(
                  'Current: $currentStock → Suggested: $suggestedQty',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              priority,
              style: TextStyle(
                color: priorityColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
