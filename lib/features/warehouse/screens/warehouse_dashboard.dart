import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/features/warehouse/models/warehouse_models.dart';
import 'package:coop_commerce/features/warehouse/services/warehouse_service.dart';
import 'package:coop_commerce/features/warehouse/screens/pick_workflow_screen.dart';
import 'package:coop_commerce/features/warehouse/screens/pack_workflow_screen.dart';
import 'package:coop_commerce/features/warehouse/screens/qc_workflow_screen.dart';

/// Warehouse Dashboard - Overview of all workflows
class WarehouseDashboard extends ConsumerStatefulWidget {
  final String warehouseId;
  final String warehouseName;

  const WarehouseDashboard({
    super.key,
    required this.warehouseId,
    required this.warehouseName,
  });

  @override
  ConsumerState<WarehouseDashboard> createState() => _WarehouseDashboardState();
}

class _WarehouseDashboardState extends ConsumerState<WarehouseDashboard>
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
    final warehouseService = ref.watch(warehouseServiceProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.warehouseName} Warehouse'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            onTap: (index) {
              setState(() {
                // Tab changed
              });
            },
            tabs: const [
              Tab(icon: Icon(Icons.assignment), text: 'Pick'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Pack'),
              Tab(icon: Icon(Icons.verified), text: 'QC'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Dashboard Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDashboardStats(warehouseService),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  PickWorkflowScreen(warehouseId: widget.warehouseId),
                  PackWorkflowScreen(warehouseId: widget.warehouseId),
                  QCWorkflowScreen(warehouseId: widget.warehouseId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStats(WarehouseService warehouseService) {
    return FutureBuilder(
      future: Future.wait([
        warehouseService.getPickJobs(widget.warehouseId),
        warehouseService.getPackJobs(widget.warehouseId),
        warehouseService.getQCJobs(widget.warehouseId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final pickJobs = snapshot.data?[0] as List<PickJob>? ?? [];
        final packJobs = snapshot.data?[1] as List<PackJob>? ?? [];
        final qcJobs = snapshot.data?[2] as List<QCJob>? ?? [];

        final pickPending =
            pickJobs.where((j) => j.status == PickStatus.pending).length;
        final pickInProgress =
            pickJobs.where((j) => j.status == PickStatus.inProgress).length;
        final pickCompleted =
            pickJobs.where((j) => j.status == PickStatus.completed).length;

        final packPending =
            packJobs.where((j) => j.status == PackStatus.pending).length;
        final packInProgress =
            packJobs.where((j) => j.status == PackStatus.inProgress).length;
        final packCompleted =
            packJobs.where((j) => j.status == PackStatus.completed).length;

        final qcPending =
            qcJobs.where((j) => j.status == QCStatus.pending).length;
        final qcInProgress =
            qcJobs.where((j) => j.status == QCStatus.inProgress).length;
        final qcPassed =
            qcJobs.where((j) => j.status == QCStatus.passed).length;
        final qcFailed =
            qcJobs.where((j) => j.status == QCStatus.failed).length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatCard(
                context,
                'Pick',
                [
                  ('Pending', pickPending, Colors.orange),
                  ('In Progress', pickInProgress, Colors.blue),
                  ('Completed', pickCompleted, Colors.green),
                ],
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Pack',
                [
                  ('Pending', packPending, Colors.orange),
                  ('In Progress', packInProgress, Colors.blue),
                  ('Completed', packCompleted, Colors.green),
                ],
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'QC',
                [
                  ('Pending', qcPending, Colors.orange),
                  ('In Progress', qcInProgress, Colors.blue),
                  ('Passed', qcPassed, Colors.green),
                  ('Failed', qcFailed, Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    List<(String label, int count, Color color)> stats,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...stats.map((stat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: stat.$3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${stat.$1}: '),
                    Text(
                      '${stat.$2}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
