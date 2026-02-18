import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';

/// Warehouse Pack Workflow Screen
/// Manages packing items into boxes/shipments with QC verification
class WarehousePackWorkflowScreen extends ConsumerWidget {
  const WarehousePackWorkflowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Warehouse Pack & QC Workflow'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inbox), text: 'To Pack'),
              Tab(icon: Icon(Icons.local_shipping), text: 'In Progress'),
              Tab(icon: Icon(Icons.verified), text: 'QC Ready'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ToPackTab(),
            _InProgressTab(),
            _QCReadyTab(),
          ],
        ),
      ),
    );
  }
}

class _ToPackTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const SizedBox();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ready for Packing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...[
                _PackListCard(
                  pickId: 'PICK-100',
                  orderId: 'ORD-2026-0100',
                  itemCount: 15,
                  status: 'ready_for_pack',
                  onTap: () => _startPacking(context),
                ),
                _PackListCard(
                  pickId: 'PICK-101',
                  orderId: 'ORD-2026-0101',
                  itemCount: 10,
                  status: 'ready_for_pack',
                  onTap: () => _startPacking(context),
                ),
              ].map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  )),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(child: Text('Error: $error')),
    );
  }

  void _startPacking(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting pack operation')),
    );
  }
}

class _InProgressTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Currently Packing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _ActivePackCard(
            packId: 'PACK-200',
            orderId: 'ORD-2026-0200',
            boxNumber: 1,
            totalBoxes: 3,
            itemsAdded: 8,
            itemsTotal: 15,
            packingBy: 'John Doe',
            startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
          const SizedBox(height: 12),
          _ActivePackCard(
            packId: 'PACK-201',
            orderId: 'ORD-2026-0201',
            boxNumber: 2,
            totalBoxes: 2,
            itemsAdded: 10,
            itemsTotal: 10,
            packingBy: 'Jane Smith',
            startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ],
      ),
    );
  }
}

class _QCReadyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready for Quality Check',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...[
            _QCCheckCard(
              packId: 'PACK-100',
              orderId: 'ORD-2026-0100',
              boxCount: 3,
              weight: 12.5,
              packedBy: 'John Doe',
              readyAt: DateTime.now().subtract(const Duration(minutes: 30)),
            ),
            _QCCheckCard(
              packId: 'PACK-101',
              orderId: 'ORD-2026-0101',
              boxCount: 2,
              weight: 8.3,
              packedBy: 'Jane Smith',
              readyAt: DateTime.now().subtract(const Duration(minutes: 15)),
            ),
          ].map((card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: card,
              )),
        ],
      ),
    );
  }
}

class _PackListCard extends StatelessWidget {
  final String pickId;
  final String orderId;
  final int itemCount;
  final String status;
  final VoidCallback onTap;

  const _PackListCard({
    required this.pickId,
    required this.orderId,
    required this.itemCount,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.inventory_2),
        title: Text(pickId),
        subtitle: Text('Order: $orderId • $itemCount items'),
        trailing: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Start Pack'),
        ),
      ),
    );
  }
}

class _ActivePackCard extends StatefulWidget {
  final String packId;
  final String orderId;
  final int boxNumber;
  final int totalBoxes;
  final int itemsAdded;
  final int itemsTotal;
  final String packingBy;
  final DateTime startedAt;

  const _ActivePackCard({
    required this.packId,
    required this.orderId,
    required this.boxNumber,
    required this.totalBoxes,
    required this.itemsAdded,
    required this.itemsTotal,
    required this.packingBy,
    required this.startedAt,
  });

  @override
  State<_ActivePackCard> createState() => _ActivePackCardState();
}

class _ActivePackCardState extends State<_ActivePackCard> {
  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(widget.startedAt);
    final progress = widget.itemsAdded / widget.itemsTotal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.packId,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${duration.inMinutes}m elapsed',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Order: ${widget.orderId}'),
            Text(
              'Box ${widget.boxNumber}/${widget.totalBoxes}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('${widget.itemsAdded}/${widget.itemsTotal} items packed'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Packing by: ${widget.packingBy}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addItem(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
                if (widget.itemsAdded == widget.itemsTotal)
                  ElevatedButton.icon(
                    onPressed: () => _completeBox(context),
                    icon: const Icon(Icons.done),
                    label: const Text('Complete Box'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.clear),
                    label: const Text('Pause'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addItem(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to box')),
    );
  }

  void _completeBox(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Box ${widget.boxNumber} completed')),
    );
  }
}

class _QCCheckCard extends StatefulWidget {
  final String packId;
  final String orderId;
  final int boxCount;
  final double weight;
  final String packedBy;
  final DateTime readyAt;

  const _QCCheckCard({
    required this.packId,
    required this.orderId,
    required this.boxCount,
    required this.weight,
    required this.packedBy,
    required this.readyAt,
  });

  @override
  State<_QCCheckCard> createState() => _QCCheckCardState();
}

class _QCCheckCardState extends State<_QCCheckCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.packId,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      const Text('Pending QC', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Order: ${widget.orderId}'),
            Text('${widget.boxCount} boxes • ${widget.weight}kg total weight',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            if (_expanded) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Packed by: ${widget.packedBy}'),
                    const SizedBox(height: 8),
                    Text(
                      'Ready for QC since ${widget.readyAt.hour}:${widget.readyAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  label: Text(_expanded ? 'Hide' : 'Details'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _startQC(context),
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Start QC'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startQC(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _QCCheckDialog(packId: widget.packId),
    );
  }
}

class _QCCheckDialog extends StatefulWidget {
  final String packId;

  const _QCCheckDialog({required this.packId});

  @override
  State<_QCCheckDialog> createState() => _QCCheckDialogState();
}

class _QCCheckDialogState extends State<_QCCheckDialog> {
  bool _itemCountVerified = false;
  bool _packagingInspected = false;
  bool _labelsVerified = false;
  bool _weighingAccurate = false;
  String _notes = '';

  @override
  Widget build(BuildContext context) {
    final allChecked = _itemCountVerified &&
        _packagingInspected &&
        _labelsVerified &&
        _weighingAccurate;

    return AlertDialog(
      title: const Text('Quality Check'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pack: ${widget.packId}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Verification Checklist:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Item count verified'),
              value: _itemCountVerified,
              onChanged: (v) => setState(() => _itemCountVerified = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Packaging inspected'),
              value: _packagingInspected,
              onChanged: (v) =>
                  setState(() => _packagingInspected = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Labels verified'),
              value: _labelsVerified,
              onChanged: (v) => setState(() => _labelsVerified = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Weight accurate'),
              value: _weighingAccurate,
              onChanged: (v) => setState(() => _weighingAccurate = v ?? false),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Any issues or notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (v) => _notes = v,
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
          onPressed: allChecked
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.packId} passed QC'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Pass QC'),
        ),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.packId} failed QC - rework needed'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Fail QC'),
        ),
      ],
    );
  }
}
