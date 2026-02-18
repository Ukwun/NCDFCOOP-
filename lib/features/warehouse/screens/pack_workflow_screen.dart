import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/features/warehouse/models/warehouse_models.dart';
import 'package:coop_commerce/features/warehouse/services/warehouse_service.dart';

/// Pack Workflow Screen
class PackWorkflowScreen extends ConsumerStatefulWidget {
  final String warehouseId;

  const PackWorkflowScreen({
    super.key,
    required this.warehouseId,
  });

  @override
  ConsumerState<PackWorkflowScreen> createState() => _PackWorkflowScreenState();
}

class _PackWorkflowScreenState extends ConsumerState<PackWorkflowScreen> {
  PackStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final warehouseService = ref.watch(warehouseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Workflow'),
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

            // Pack Jobs List
            FutureBuilder<List<PackJob>>(
              future: warehouseService.getPackJobs(
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
                          ? 'No pack jobs available'
                          : 'No ${_filterStatus!.name} pack jobs',
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final job = snapshot.data![index];
                    return _buildPackJobCard(context, job);
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
          ...PackStatus.values
              .map((status) => _buildFilterChip(status.name, status)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PackStatus? status) {
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

  Widget _buildPackJobCard(BuildContext context, PackJob job) {
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
                        'Pack Job #${job.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Order: ${job.orderId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Packer: ${job.packerName ?? 'Unassigned'}',
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

            // Pack lines
            ..._buildPackLines(context, job),
            const SizedBox(height: 12),

            // Action buttons
            _buildActionButtons(context, job),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPackLines(BuildContext context, PackJob job) {
    return job.packLines.map((line) {
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
                      'SKU: ${line.sku}${line.boxNumber != null ? ' | Box: ${line.boxNumber}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${line.packedQuantity}/${line.quantity}',
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

  Widget _buildActionButtons(BuildContext context, PackJob job) {
    final warehouseService = ref.watch(warehouseServiceProvider);

    return Row(
      children: [
        if (job.status == PackStatus.pending)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                warehouseService.startPackJob(
                    widget.warehouseId, job.id, 'current-user');
                setState(() {});
              },
              child: const Text('Start Pack'),
            ),
          ),
        if (job.status == PackStatus.inProgress) ...[
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
                _showEditPackDialog(context, job);
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

  void _showEditPackDialog(BuildContext context, PackJob job) {
    final controllers = <String, TextEditingController>{};
    for (final line in job.packLines) {
      controllers['${line.id}_qty'] = TextEditingController(
        text: line.packedQuantity.toString(),
      );
      controllers['${line.id}_box'] =
          TextEditingController(text: line.boxNumber ?? '');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pack Quantities'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: job.packLines.map((line) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers['${line.id}_qty'],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              label: Text('Qty'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controllers['${line.id}_box'],
                            decoration: const InputDecoration(
                              label: Text('Box #'),
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

  void _showCompletionDialog(BuildContext context, PackJob job) {
    final weightController = TextEditingController();
    final dimensionsController = TextEditingController();
    final notesController = TextEditingController();
    final warehouseService = ref.watch(warehouseServiceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Pack Job'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dimensionsController,
                decoration: const InputDecoration(
                  labelText: 'Dimensions (L×W×H cm)',
                  hintText: '30×20×15',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
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
              final weight = weightController.text.isNotEmpty
                  ? double.parse(weightController.text)
                  : null;
              warehouseService.completePackJob(
                widget.warehouseId,
                job.id,
                'current-user',
                weight,
                dimensionsController.text.isNotEmpty
                    ? dimensionsController.text
                    : null,
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

  Color _getStatusColor(PackStatus status) {
    switch (status) {
      case PackStatus.pending:
        return Colors.grey;
      case PackStatus.inProgress:
        return Colors.blue;
      case PackStatus.completed:
        return Colors.green;
      case PackStatus.cancelled:
        return Colors.red;
    }
  }
}
