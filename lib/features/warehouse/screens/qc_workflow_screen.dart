import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/features/warehouse/models/warehouse_models.dart';
import 'package:coop_commerce/features/warehouse/services/warehouse_service.dart';

/// QC (Quality Control) Workflow Screen
class QCWorkflowScreen extends ConsumerStatefulWidget {
  final String warehouseId;

  const QCWorkflowScreen({
    super.key,
    required this.warehouseId,
  });

  @override
  ConsumerState<QCWorkflowScreen> createState() => _QCWorkflowScreenState();
}

class _QCWorkflowScreenState extends ConsumerState<QCWorkflowScreen> {
  QCStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final warehouseService = ref.watch(warehouseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Control'),
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

            // QC Jobs List
            FutureBuilder<List<QCJob>>(
              future: warehouseService.getQCJobs(
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
                          ? 'No QC jobs available'
                          : 'No ${_filterStatus!.name} QC jobs',
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final job = snapshot.data![index];
                    return _buildQCJobCard(context, job);
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
          ...QCStatus.values
              .map((status) => _buildFilterChip(status.name, status)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, QCStatus? status) {
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

  Widget _buildQCJobCard(BuildContext context, QCJob job) {
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
                        'QC Job #${job.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Order: ${job.orderId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'QC Officer: ${job.qcPersonName ?? 'Unassigned'}',
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
                        'Progress: ${job.checkedLines}/${job.totalLines} items'),
                    Text('${job.checkProgress.toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: job.checkProgress / 100,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 4),
                      Text('${job.passedLines} Passed'),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      Text('${job.failedLines} Failed'),
                    ],
                  ),
                  if (job.issues.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.warning,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text('${job.issues.length} Issues'),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // QC lines
            ..._buildQCLines(context, job),
            const SizedBox(height: 12),

            // Issues section
            if (job.issues.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text('Issues Found:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._buildIssuesList(context, job),
              const SizedBox(height: 12),
            ],

            // Action buttons
            _buildActionButtons(context, job),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQCLines(BuildContext context, QCJob job) {
    return job.qcLines.map((line) {
      final isChecked = line.isChecked;
      final passed = line.passed;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: job.status == QCStatus.inProgress
              ? () {
                  _showQCDialog(context, job, line);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: !isChecked
                  ? Colors.grey.shade100
                  : passed == true
                      ? Colors.green.shade50
                      : Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: !isChecked
                    ? Colors.grey
                    : passed == true
                        ? Colors.green
                        : Colors.red,
              ),
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
                        'SKU: ${line.sku} | Qty: ${line.quantity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (line.failureReason != null)
                        Text(
                          'Issue: ${line.failureReason}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isChecked)
                  Icon(
                    passed == true ? Icons.check_circle : Icons.cancel,
                    color: passed == true ? Colors.green : Colors.red,
                  ),
                if (!isChecked && job.status == QCStatus.inProgress)
                  const Icon(Icons.edit, color: Colors.blue),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildIssuesList(BuildContext context, QCJob job) {
    return job.issues.map((issue) {
      final severityColor = issue.severity == 'high'
          ? Colors.red
          : issue.severity == 'medium'
              ? Colors.orange
              : Colors.yellow;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: severityColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: severityColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    issue.severity.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  issue.issueType,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              issue.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildActionButtons(BuildContext context, QCJob job) {
    final warehouseService = ref.watch(warehouseServiceProvider);

    return Row(
      children: [
        if (job.status == QCStatus.pending)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                warehouseService.startQCJob(
                    widget.warehouseId, job.id, 'current-user');
                setState(() {});
              },
              child: const Text('Start QC'),
            ),
          ),
        if (job.status == QCStatus.inProgress) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showCompleteDialog(context, job, false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Fail'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showCompleteDialog(context, job, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Pass'),
            ),
          ),
        ],
      ],
    );
  }

  void _showQCDialog(BuildContext context, QCJob job, QCLine line) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Check: ${line.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quantity: ${line.quantity}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _updateQCLine(context, job, line, true, null);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Pass'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                _showFailureDialog(context, job, line);
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Fail'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureDialog(BuildContext context, QCJob job, QCLine line) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Failure'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Failure Reason',
            hintText: 'Explain why this item failed QC',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateQCLine(context, job, line, false, reasonController.text);
            },
            child: const Text('Confirm Failure'),
          ),
        ],
      ),
    );
  }

  void _updateQCLine(BuildContext context, QCJob job, QCLine line, bool passed,
      String? reason) {
    final warehouseService = ref.watch(warehouseServiceProvider);

    warehouseService
        .checkQCLine(
            widget.warehouseId, job.id, line.id, passed, reason, 'current-user')
        .then((_) {
      if (mounted) {
        Navigator.pop(context);
        setState(() {});
      }
    });
  }

  void _showCompleteDialog(BuildContext context, QCJob job, bool passed) {
    final notesController = TextEditingController();
    final warehouseService = ref.watch(warehouseServiceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(passed ? 'Pass QC Job' : 'Fail QC Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              passed
                  ? 'Mark this order as passed QC?'
                  : 'This order has failed QC. Add notes about the issues.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
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
              warehouseService.completeQCJob(
                widget.warehouseId,
                job.id,
                passed ? QCStatus.passed : QCStatus.failed,
                'current-user',
                notesController.text.isNotEmpty ? notesController.text : null,
              );
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: passed ? Colors.green : Colors.red,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(QCStatus status) {
    switch (status) {
      case QCStatus.pending:
        return Colors.grey;
      case QCStatus.inProgress:
        return Colors.blue;
      case QCStatus.passed:
        return Colors.green;
      case QCStatus.failed:
        return Colors.red;
      case QCStatus.needsReview:
        return Colors.orange;
    }
  }
}
