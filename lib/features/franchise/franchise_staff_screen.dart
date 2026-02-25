import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/providers/franchise_providers.dart';
import 'package:coop_commerce/models/franchise_models.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Franchise staff management and performance tracking screen
class FranchiseStaffScreen extends ConsumerStatefulWidget {
  final String storeId;

  const FranchiseStaffScreen({
    super.key,
    required this.storeId,
  });

  @override
  ConsumerState<FranchiseStaffScreen> createState() =>
      _FranchiseStaffScreenState();
}

class _FranchiseStaffScreenState extends ConsumerState<FranchiseStaffScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

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
    final staffAsync = ref.watch(franchiseStaffProvider(widget.storeId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Performance'),
            Tab(text: 'Commissions'),
          ],
        ),
      ),
      body: staffAsync.when(
        data: (staff) {
          final activeStaff = staff.where((s) => s.status == 'active').toList();
          final filteredStaff = activeStaff
              .where((s) =>
                  s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  s.position.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Active Staff Tab
              _buildActiveStaffTab(filteredStaff),
              // Performance Tab
              _buildPerformanceTab(filteredStaff),
              // Commissions Tab
              _buildCommissionsTab(filteredStaff),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
        onPressed: () => _showAddStaffDialog(),
      ),
    );
  }

  Widget _buildActiveStaffTab(List<StaffMember> staff) {
    return CustomScrollView(
      slivers: [
        // Search Bar
        SliverAppBar(
          pinned: true,
          floating: true,
          elevation: 0,
          backgroundColor: Colors.grey[50],
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search staff...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final member = staff[index];
                return _StaffCard(
                  member: member,
                  onTap: () => _showStaffDetailsDialog(member),
                  onEdit: () => _showEditStaffDialog(member),
                );
              },
              childCount: staff.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceTab(List<StaffMember> staff) {
    // Sort by orders processed descending
    final sortedStaff = [...staff]
      ..sort((a, b) => b.ordersProcessed.compareTo(a.ordersProcessed));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Summary
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PerformanceMetric(
                    label: 'Avg Orders',
                    value:
                        (staff.fold<int>(0, (a, b) => a + b.ordersProcessed) /
                                (staff.isNotEmpty ? staff.length : 1))
                            .toStringAsFixed(0),
                  ),
                  _PerformanceMetric(
                    label: 'Total Sales',
                    value:
                        '\$${staff.fold<double>(0, (a, b) => a + b.totalSales).toStringAsFixed(0)}',
                  ),
                  _PerformanceMetric(
                    label: 'Active Staff',
                    value: '${staff.length}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Performers
          Text(
            'Top Performers',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (sortedStaff.length > 5 ? 5 : sortedStaff.length),
            itemBuilder: (context, index) {
              final member = sortedStaff[index];
              return _PerformanceRankCard(
                rank: index + 1,
                member: member,
                onTap: () => _showStaffDetailsDialog(member),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionsTab(List<StaffMember> staff) {
    final totalCommissions = staff.fold<double>(0, (a, b) => a + b.commission);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commission Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commission Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Commission Rate',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(totalCommissions / (staff.isNotEmpty ? staff.length : 1)).toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Staff with Commission',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${staff.where((s) => s.commission > 0).length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
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

          // Commission Details
          Text(
            'Commission Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final member = staff[index];
              return _CommissionCard(
                member: member,
                totalStaffEarnings:
                    staff.fold<double>(0, (a, b) => a + b.commission),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedPosition = 'Staff Member';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPosition,
                items: ['Staff Member', 'Team Lead', 'Manager']
                    .map((role) =>
                        DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) =>
                    selectedPosition = value ?? selectedPosition,
                decoration: const InputDecoration(labelText: 'Position'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Staff added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showStaffDetailsDialog(StaffMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Position', member.position),
              _DetailRow('Email', member.email),
              _DetailRow('Phone', member.phoneNumber),
              _DetailRow('Orders Processed', '${member.ordersProcessed}'),
              _DetailRow(
                  'Total Sales', '\$${member.totalSales.toStringAsFixed(2)}'),
              _DetailRow(
                  'Commission', '${member.commission.toStringAsFixed(2)}%'),
              _DetailRow('Status', member.status),
              _DetailRow(
                'Hire Date',
                member.hireDate.toString().split(' ')[0],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditStaffDialog(StaffMember member) {
    final nameController = TextEditingController(text: member.name);
    final commissionController =
        TextEditingController(text: member.commission.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commissionController,
                decoration: const InputDecoration(labelText: 'Commission %'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Staff updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMember member;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _StaffCard({
    required this.member,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(
            member.name[0].toUpperCase(),
            style: const TextStyle(color: AppColors.primary),
          ),
        ),
        title: Text(member.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              member.position,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              '${member.ordersProcessed} orders • \$${member.totalSales.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onTap,
              child: const Text('View Details'),
            ),
            PopupMenuItem(
              onTap: onEdit,
              child: const Text('Edit'),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PerformanceRankCard extends StatelessWidget {
  final int rank;
  final StaffMember member;
  final VoidCallback onTap;

  const _PerformanceRankCard({
    required this.rank,
    required this.member,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? rank == 1
                        ? Colors.amber
                        : rank == 2
                            ? Colors.grey[400]
                            : Colors.orange[700]
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${member.ordersProcessed} orders',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '\$${member.totalSales.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionCard extends StatelessWidget {
  final StaffMember member;
  final double totalStaffEarnings;

  const _CommissionCard({
    required this.member,
    required this.totalStaffEarnings,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalStaffEarnings > 0
        ? (member.commission / totalStaffEarnings) * 100
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                        member.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        member.position,
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${member.commission.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PerformanceMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

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
