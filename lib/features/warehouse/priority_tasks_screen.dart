import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Priority Tasks Screen for Warehouse Staff
/// Displays priority operational tasks assigned to the warehouse staff member
class PriorityTasksScreen extends StatefulWidget {
  const PriorityTasksScreen({Key? key}) : super(key: key);

  @override
  State<PriorityTasksScreen> createState() => _PriorityTasksScreenState();
}

class _PriorityTasksScreenState extends State<PriorityTasksScreen> {
  String _filterStatus = 'all'; // all, pending, in-progress, completed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Priority Tasks',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All Tasks',
                      selected: _filterStatus == 'all',
                      onTap: () => setState(() => _filterStatus = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pending',
                      selected: _filterStatus == 'pending',
                      onTap: () => setState(() => _filterStatus = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'In Progress',
                      selected: _filterStatus == 'in-progress',
                      onTap: () =>
                          setState(() => _filterStatus = 'in-progress'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Completed',
                      selected: _filterStatus == 'completed',
                      onTap: () => setState(() => _filterStatus = 'completed'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tasks list
              ..._buildTaskList(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTaskList() {
    final tasks = [
      {
        'id': 'TSK-001',
        'title': 'Prepare Order #ORD-2026-5432',
        'status': 'pending',
        'priority': 'urgency_high',
        'assignedTime': '10:30 AM',
        'location': 'Shelf A-12',
        'items': 8,
        'dueTime': '2:00 PM',
      },
      {
        'id': 'TSK-002',
        'title': 'Quality Check - Rice (50kg bags)',
        'status': 'in-progress',
        'priority': 'high',
        'assignedTime': '09:15 AM',
        'location': 'QC Area',
        'items': 24,
        'dueTime': '1:30 PM',
      },
      {
        'id': 'TSK-003',
        'title': 'Stock Transfer - Palm Oil to Shelf B-5',
        'status': 'pending',
        'priority': 'normal',
        'assignedTime': '11:00 AM',
        'location': 'Warehouse C',
        'items': 12,
        'dueTime': '4:00 PM',
      },
      {
        'id': 'TSK-004',
        'title': 'Pack Items for Delivery #DEL-892',
        'status': 'completed',
        'priority': 'high',
        'assignedTime': '08:45 AM',
        'location': 'Pack Station 2',
        'items': 15,
        'dueTime': '12:00 PM',
      },
      {
        'id': 'TSK-005',
        'title': 'Bin Organization - Aisle 3',
        'status': 'completed',
        'priority': 'normal',
        'assignedTime': '07:30 AM',
        'location': 'Aisle 3',
        'items': 32,
        'dueTime': '10:00 AM',
      },
    ];

    // Filter tasks
    final filtered = tasks.where((task) {
      if (_filterStatus == 'all') return true;
      return task['status'] == _filterStatus;
    }).toList();

    if (filtered.isEmpty) {
      return [
        SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt_outlined,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All tasks in this category are complete',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return filtered.map((task) {
      return Column(
        children: [
          _TaskCard(
            id: task['id'] as String,
            title: task['title'] as String,
            status: task['status'] as String,
            priority: task['priority'] as String,
            assignedTime: task['assignedTime'] as String,
            location: task['location'] as String,
            itemCount: task['items'] as int,
            dueTime: task['dueTime'] as String,
            onStatusChange: (newStatus) {
              setState(() {
                task['status'] = newStatus;
              });
            },
          ),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

/// Task card widget
class _TaskCard extends StatefulWidget {
  final String id;
  final String title;
  final String status;
  final String priority;
  final String assignedTime;
  final String location;
  final int itemCount;
  final String dueTime;
  final Function(String) onStatusChange;

  const _TaskCard({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.assignedTime,
    required this.location,
    required this.itemCount,
    required this.dueTime,
    required this.onStatusChange,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _currentStatus == 'completed'
        ? Colors.green
        : _currentStatus == 'in-progress'
            ? Colors.blue
            : Colors.orange;

    final statusText = _currentStatus == 'completed'
        ? 'Completed'
        : _currentStatus == 'in-progress'
            ? 'In Progress'
            : 'Pending';

    final priorityColor =
        widget.priority.contains('high') ? Colors.red : Colors.orange;

    final priorityText = widget.priority.contains('urgency')
        ? 'Very High'
        : widget.priority.contains('high')
            ? 'High'
            : 'Normal';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with ID and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.id,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 160,
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Details grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _DetailItem(
                      icon: Icons.location_on_outlined,
                      label: widget.location,
                    ),
                    _DetailItem(
                      icon: Icons.access_time_outlined,
                      label: widget.dueTime,
                    ),
                    _DetailItem(
                      icon: Icons.inventory_2_outlined,
                      label: '${widget.itemCount} items',
                    ),
                    _DetailItem(
                      icon: Icons.flag_outlined,
                      label: priorityText,
                      labelColor: priorityColor,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    if (_currentStatus == 'pending')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _currentStatus = 'in-progress');
                            widget.onStatusChange('in-progress');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task marked as in progress'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Start Task',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStatus == 'in-progress')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _currentStatus = 'completed');
                            widget.onStatusChange('completed');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task marked as completed'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Complete Task',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStatus == 'completed')
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 6),
                              const Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail item widget for task cards
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: labelColor ?? Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor ?? Colors.grey[700],
              fontWeight:
                  labelColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
