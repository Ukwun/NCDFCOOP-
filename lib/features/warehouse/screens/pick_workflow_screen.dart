import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/features/warehouse/models/warehouse_models.dart';
import 'package:coop_commerce/features/warehouse/services/warehouse_service.dart';

/// Pick Workflow Screen
class PickWorkflowScreen extends ConsumerStatefulWidget {
  final String warehouseId;

  const PickWorkflowScreen({
    super.key,
    required this.warehouseId,
  });

  @override
  ConsumerState<PickWorkflowScreen> createState() => _PickWorkflowScreenState();
}

class _PickWorkflowScreenState extends ConsumerState<PickWorkflowScreen> {
  PickStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final warehouseService = ref.watch(warehouseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Workflow'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Filter
            _buildStatusFilter(),
            const SizedBox(height: 16),

            // Pick Jobs List
            FutureBuilder<List<PickJob>>(
              future: warehouseService.getPickJobs(
                widget.warehouseId,
                status: _filterStatus,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      _filterStatus == null
                          ? 'No pick jobs available'
                          : 'No ${_filterStatus!.name} pick jobs',
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final job = snapshot.data![index];
                    return _buildPickJobCard(context, job);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', null),
          ...PickStatus.values
              .map((status) => _buildFilterChip(status.name, status)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PickStatus? status) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = selected ? status : null;
          });
        },
      ),
    );
  }

  Widget _buildPickJobCard(BuildContext context, PickJob job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        'Pick Job #${job.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Order: ${job.orderId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Picker: ${job.pickerName ?? 'Unassigned'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(job.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Progress: ${job.completedLines}/${job.totalLines} items'),
                    Text('${job.completionPercentage.toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: job.completionPercentage / 100,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pick lines
            ..._buildPickLines(context, job),
            const SizedBox(height: 12),

            // Action buttons
            _buildActionButtons(context, job),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPickLines(BuildContext context, PickJob job) {
    return job.pickLines.map((line) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.productName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Bin: ${line.binLocation} | SKU: ${line.sku}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${line.pickedQuantity}/${line.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                line.isCompleted
                    ? '✓'
                    : line.isPartial
                        ? '◐'
                        : '○',
                style: TextStyle(
                  fontSize: 18,
                  color: line.isCompleted
                      ? Colors.green
                      : line.isPartial
                          ? Colors.orange
                          : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildActionButtons(BuildContext context, PickJob job) {
    final warehouseService = ref.watch(warehouseServiceProvider);

    return Row(
      children: [
        if (job.status == PickStatus.pending)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                warehouseService.startPickJob(
                    widget.warehouseId, job.id, 'current-user');
                setState(() {});
              },
              child: const Text('Start Pick'),
            ),
          ),
        if (job.status == PickStatus.inProgress) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showCompletionDialog(context, job);
              },
              child: const Text('Complete'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showEditPickDialog(context, job);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Edit Items'),
            ),
          ),
        ],
      ],
    );
  }

  void _showEditPickDialog(BuildContext context, PickJob job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pick Quantities'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: job.pickLines.map((line) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.productName),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(
                                text: line.pickedQuantity.toString()),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              // Update logic here
                            },
                            decoration: const InputDecoration(
                              label: Text('Quantity'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, PickJob job) {
    final notesController = TextEditingController();
    final warehouseService = ref.watch(warehouseServiceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Pick Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this pick job',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              warehouseService.completePickJob(
                widget.warehouseId,
                job.id,
                'current-user',
                notesController.text.isNotEmpty ? notesController.text : null,
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PickStatus status) {
    switch (status) {
      case PickStatus.pending:
        return Colors.grey;
      case PickStatus.inProgress:
        return Colors.blue;
      case PickStatus.completed:
        return Colors.green;
      case PickStatus.cancelled:
        return Colors.red;
      case PickStatus.failed:
        return Colors.orange;
    }
  }
}
