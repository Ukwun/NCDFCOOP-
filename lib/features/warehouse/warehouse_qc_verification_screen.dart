import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/providers/warehouse_providers.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class WarehouseQCVerificationScreen extends ConsumerStatefulWidget {
  final String pickListId;

  const WarehouseQCVerificationScreen({
    Key? key,
    required this.pickListId,
  }) : super(key: key);

  @override
  ConsumerState<WarehouseQCVerificationScreen> createState() =>
      _WarehouseQCVerificationScreenState();
}

class _WarehouseQCVerificationScreenState
    extends ConsumerState<WarehouseQCVerificationScreen> {
  final Map<String, QCCheckResult> qcResults = {};
  final TextEditingController notesController = TextEditingController();
  String qcStatus = 'pending'; // pending, pass, fail

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickListAsync = ref.watch(pickListDetailProvider(widget.pickListId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Control Verification'),
        elevation: 0,
        backgroundColor: Colors.purple.shade600,
      ),
      body: pickListAsync.when(
        data: (pickList) => _buildQCContent(context, pickList),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: ${err.toString()}'),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goBackToPacking,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _submitQCResults,
                icon: const Icon(Icons.done_all),
                label: const Text('Submit QC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQCContent(BuildContext context, dynamic pickList) {
    final items = (pickList['items'] as List?) ?? [];
    final orderId = pickList['orderId'] as String? ?? 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildQCHeaderCard(orderId, items.length),
          const SizedBox(height: 20),

          // QC Checklist
          _buildQCChecklistSection(items),
          const SizedBox(height: 20),

          // Notes Section
          _buildNotesSection(),
          const SizedBox(height: 20),

          // QC Status Summary
          _buildQCStatusSection(),
          const SizedBox(height: 20),

          // Issues & Audit Trail
          _buildAuditSection(),
        ],
      ),
    );
  }

  Widget _buildQCHeaderCard(String orderId, int itemCount) {
    final passedCount =
        qcResults.values.where((r) => r.status == 'pass').length;
    final failedCount =
        qcResults.values.where((r) => r.status == 'fail').length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      'QC Verification',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order: $orderId',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getQCStatusColor(qcStatus).shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    qcStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getQCStatusColor(qcStatus),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQCStatItem(
                    'Total Items', '$itemCount', Icons.inventory_2),
                _buildQCStatItem('Passed', '$passedCount', Icons.check_circle),
                _buildQCStatItem('Failed', '$failedCount', Icons.cancel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQCStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon,
            color: label == 'Failed' ? Colors.red : Colors.green, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQCChecklistSection(List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QC Checklist',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No items to verify',
                style: TextStyle(color: Colors.purple.shade700),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildQCItemCard(item, index);
            },
          ),
      ],
    );
  }

  Widget _buildQCItemCard(dynamic item, int index) {
    final itemId = item['itemId'] as String? ?? 'item_$index';
    final productName = item['productName'] as String? ?? 'Product $index';
    final quantity = item['quantity'] as int? ?? 1;
    final sku = item['sku'] as String? ?? 'SKU-$index';

    final result = qcResults[itemId] ?? QCCheckResult(status: 'pending');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getQCResultColor(result.status),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sku,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildQCResultBadge(result.status),
              ],
            ),
            const SizedBox(height: 12),

            // Quantity Verification
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expected Qty: $quantity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '$quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      onChanged: (value) {
                        final actualQty = int.tryParse(value) ?? quantity;
                        _updateQCResult(itemId, actualQty == quantity);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // QC Pass/Fail Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _setQCResult(itemId, 'pass'),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Pass'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: result.status == 'pass'
                          ? Colors.green.shade600
                          : Colors.green.shade100,
                      foregroundColor: result.status == 'pass'
                          ? Colors.white
                          : Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFailDialog(itemId),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Fail'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: result.status == 'fail'
                          ? Colors.red.shade600
                          : Colors.red.shade100,
                      foregroundColor: result.status == 'fail'
                          ? Colors.white
                          : Colors.red.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (result.notes != null && result.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQCResultBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'pass':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'fail':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QC Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Add any issues, discrepancies, or additional notes about this order...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.note),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildQCStatusSection() {
    final totalChecks = qcResults.length;
    final passCount = qcResults.values.where((r) => r.status == 'pass').length;
    final failCount = qcResults.values.where((r) => r.status == 'fail').length;

    final passPercentage = totalChecks > 0
        ? (passCount / totalChecks * 100).toStringAsFixed(0)
        : 0;
    final overallPass = failCount == 0 && totalChecks > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QC Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Status:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: overallPass
                            ? Colors.green.shade100
                            : failCount > 0
                                ? Colors.red.shade100
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        overallPass
                            ? 'PASS'
                            : failCount > 0
                                ? 'FAIL'
                                : 'PENDING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: overallPass
                              ? Colors.green.shade700
                              : failCount > 0
                                  ? Colors.red.shade700
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalChecks > 0 ? passCount / totalChecks : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overallPass ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$passCount / $totalChecks items passed ($passPercentage%)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audit Trail',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuditItem(
                    'QC Started', 'Jan 30, 2026 2:30 PM', Icons.start),
                _buildAuditItem('Items Verified', '${qcResults.length} items',
                    Icons.verified_user),
                if (notesController.text.isNotEmpty)
                  _buildAuditItem(
                      'Notes Added', notesController.text, Icons.note),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAuditItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setQCResult(String itemId, String status) {
    setState(() {
      qcResults[itemId] = QCCheckResult(status: status);
      _updateQCStatus();
    });
  }

  void _showFailDialog(String itemId) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Item as Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Why did this item fail QC?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
              Navigator.pop(context);
              setState(() {
                qcResults[itemId] = QCCheckResult(
                  status: 'fail',
                  notes: noteController.text,
                );
                _updateQCStatus();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Fail Item'),
          ),
        ],
      ),
    );
  }

  void _updateQCResult(String itemId, bool passed) {
    setState(() {
      if (passed) {
        qcResults[itemId] = QCCheckResult(status: 'pass');
      }
    });
  }

  void _updateQCStatus() {
    if (qcResults.isEmpty) {
      qcStatus = 'pending';
    } else {
      final failCount =
          qcResults.values.where((r) => r.status == 'fail').length;
      qcStatus = failCount > 0 ? 'fail' : 'pass';
    }
  }

  void _goBackToPacking() {
    Navigator.pop(context);
  }

  void _submitQCResults() {
    if (qcResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify at least one item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final failCount = qcResults.values.where((r) => r.status == 'fail').length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm QC Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items Verified: ${qcResults.length}',
            ),
            Text(
              'Passed: ${qcResults.values.where((r) => r.status == 'pass').length}',
            ),
            Text(
              'Failed: $failCount',
              style: TextStyle(
                color: failCount > 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            if (notesController.text.isNotEmpty)
              Text(
                'Notes: ${notesController.text}',
                style: TextStyle(color: Colors.grey.shade600),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'QC submitted - ${failCount > 0 ? 'Issues found' : 'All passed'}'),
                  backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );

              // Navigate back to warehouse home
              Navigator.of(context).popUntil((route) {
                return route.settings.name == '/' ||
                    route.isFirst ||
                    route.settings.name?.contains('warehouse') == false;
              });
            },
            child: const Text('Submit QC'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  MaterialColor _getQCStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pass':
        return Colors.green;
      case 'fail':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getQCResultColor(String status) {
    switch (status) {
      case 'pass':
        return Colors.green.shade300;
      case 'fail':
        return Colors.red.shade300;
      default:
        return Colors.grey.shade300;
    }
  }
}

class QCCheckResult {
  final String status; // pass, fail, pending
  final String? notes;

  QCCheckResult({
    required this.status,
    this.notes,
  });
}
