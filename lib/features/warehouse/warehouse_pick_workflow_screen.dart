import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';

/// Warehouse Pick Workflow Screen
/// Manages item picking from warehouse bins
class WarehousePickWorkflowScreen extends ConsumerWidget {
  const WarehousePickWorkflowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Warehouse Pick Workflow'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Pick Lists'),
              Tab(icon: Icon(Icons.assignment), text: 'Active Picks'),
              Tab(icon: Icon(Icons.done), text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PickListsTab(),
            _ActivePicksTab(),
            _CompletedPicksTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _createNewPickList(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('New Pick List'),
        ),
      ),
    );
  }

  void _createNewPickList(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _CreatePickListDialog(),
    );
  }
}

class _PickListsTab extends ConsumerWidget {
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
                'Available Pick Lists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...[
                _PickListCard(
                  listId: 'PICK-001',
                  orderId: 'ORD-2026-0001',
                  itemCount: 15,
                  status: 'created',
                  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
                ),
                _PickListCard(
                  listId: 'PICK-002',
                  orderId: 'ORD-2026-0002',
                  itemCount: 8,
                  status: 'created',
                  createdAt: DateTime.now().subtract(const Duration(hours: 1)),
                ),
                _PickListCard(
                  listId: 'PICK-003',
                  orderId: 'ORD-2026-0003',
                  itemCount: 12,
                  status: 'created',
                  createdAt: DateTime.now(),
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
}

class _ActivePicksTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In-Progress Picks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _ActivePickCard(
            listId: 'PICK-100',
            orderId: 'ORD-2026-0100',
            progress: 0.6,
            itemsPicked: 9,
            itemsTotal: 15,
            currentItem: 'SKU-12345 - Premium Coffee Beans',
            location: 'Bin A-3-2',
          ),
          const SizedBox(height: 12),
          _ActivePickCard(
            listId: 'PICK-101',
            orderId: 'ORD-2026-0101',
            progress: 0.3,
            itemsPicked: 3,
            itemsTotal: 10,
            currentItem: 'SKU-67890 - Organic Tea',
            location: 'Bin B-1-5',
          ),
        ],
      ),
    );
  }
}

class _CompletedPicksTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Completed Picks (Ready for Pack)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...[
            _CompletedPickCard(
              listId: 'PICK-050',
              orderId: 'ORD-2026-0050',
              itemCount: 15,
              completedAt: DateTime.now().subtract(const Duration(minutes: 30)),
              completedBy: 'John Doe',
            ),
            _CompletedPickCard(
              listId: 'PICK-051',
              orderId: 'ORD-2026-0051',
              itemCount: 8,
              completedAt: DateTime.now().subtract(const Duration(hours: 1)),
              completedBy: 'Jane Smith',
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

class _PickListCard extends StatelessWidget {
  final String listId;
  final String orderId;
  final int itemCount;
  final String status;
  final DateTime createdAt;

  const _PickListCard({
    required this.listId,
    required this.orderId,
    required this.itemCount,
    required this.status,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.list_alt),
        title: Text(listId),
        subtitle: Text('Order: $orderId • $itemCount items'),
        trailing: ElevatedButton.icon(
          onPressed: () => _startPicking(context),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Start'),
        ),
      ),
    );
  }

  void _startPicking(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting pick for $listId')),
    );
  }
}

class _ActivePickCard extends StatelessWidget {
  final String listId;
  final String orderId;
  final double progress;
  final int itemsPicked;
  final int itemsTotal;
  final String currentItem;
  final String location;

  const _ActivePickCard({
    required this.listId,
    required this.orderId,
    required this.progress,
    required this.itemsPicked,
    required this.itemsTotal,
    required this.currentItem,
    required this.location,
  });

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
                Text(listId,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$itemsPicked/$itemsTotal items',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Order: $orderId'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Item:',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(currentItem,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(location),
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
                  onPressed: () {},
                  icon: const Icon(Icons.done),
                  label: const Text('Picked'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedPickCard extends StatelessWidget {
  final String listId;
  final String orderId;
  final int itemCount;
  final DateTime completedAt;
  final String completedBy;

  const _CompletedPickCard({
    required this.listId,
    required this.orderId,
    required this.itemCount,
    required this.completedAt,
    required this.completedBy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(listId),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Order: $orderId • $itemCount items'),
            Text('Completed by $completedBy',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.arrow_forward),
          label: const Text('To Pack'),
        ),
      ),
    );
  }
}

class _CreatePickListDialog extends StatelessWidget {
  const _CreatePickListDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Pick List'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Order ID',
              hintText: 'ORD-2026-XXXX',
            ),
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Number of Items',
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
