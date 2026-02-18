import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Audit log entry model
class AuditLogEntry {
  final String id;
  final String userId;
  final String userRole;
  final String action; // 'create', 'update', 'delete', 'approve', 'reject'
  final String resourceType; // 'user', 'product', 'order', 'price', 'franchise'
  final String resourceId;
  final String? details;
  final DateTime timestamp;
  final String status; // 'success', 'failed'
  final String ipAddress;

  AuditLogEntry({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    this.details,
    required this.timestamp,
    required this.status,
    required this.ipAddress,
  });
}

/// Provider for audit logs
final auditLogsProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  // TODO: Integrate with audit log service
  await Future.delayed(const Duration(milliseconds: 500));

  return [
    AuditLogEntry(
      id: 'audit-001',
      userId: 'admin-001',
      userRole: 'admin',
      action: 'approve',
      resourceType: 'price',
      resourceId: 'override-001',
      details: 'Approved price override for SKU-2451: ₦50,000 → ₦45,000',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'success',
      ipAddress: '192.168.1.100',
    ),
    AuditLogEntry(
      id: 'audit-002',
      userId: 'user-002',
      userRole: 'franchisee',
      action: 'create',
      resourceType: 'order',
      resourceId: 'ORD-5821',
      details: 'Created purchase order for contract CONT-001',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      status: 'success',
      ipAddress: '192.168.1.45',
    ),
    AuditLogEntry(
      id: 'audit-003',
      userId: 'admin-001',
      userRole: 'admin',
      action: 'update',
      resourceType: 'user',
      resourceId: 'user-123',
      details: 'Updated user roles: added warehousse_staff',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      status: 'success',
      ipAddress: '192.168.1.100',
    ),
    AuditLogEntry(
      id: 'audit-004',
      userId: 'user-045',
      userRole: 'consumer',
      action: 'create',
      resourceType: 'order',
      resourceId: 'ORD-5820',
      details: 'Created retail order',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      status: 'success',
      ipAddress: '203.0.113.45',
    ),
    AuditLogEntry(
      id: 'audit-005',
      userId: 'unknown',
      userRole: 'unknown',
      action: 'update',
      resourceType: 'product',
      resourceId: 'SKU-1234',
      details: 'Failed authentication attempt',
      timestamp: DateTime.now().subtract(const Duration(hours: 7)),
      status: 'failed',
      ipAddress: '198.51.100.89',
    ),
  ];
});

/// Admin Audit Log Browser Screen
class AdminAuditLogBrowserScreen extends ConsumerStatefulWidget {
  const AdminAuditLogBrowserScreen({super.key});

  @override
  ConsumerState<AdminAuditLogBrowserScreen> createState() =>
      _AdminAuditLogBrowserScreenState();
}

class _AdminAuditLogBrowserScreenState
    extends ConsumerState<AdminAuditLogBrowserScreen> {
  String searchQuery = '';
  String? selectedAction;
  String? selectedResourceType;
  String? selectedStatus;
  DateTimeRange? selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log Browser'),
        elevation: 0,
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading audit logs: $error'),
            ],
          ),
        ),
        data: (logs) => Column(
          children: [
            // Filter panel
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by user, resource ID, or IP address',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                  ),
                  const SizedBox(height: 12),

                  // Filters row 1
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: selectedAction,
                          hint: const Text('All Actions'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Actions'),
                            ),
                            const DropdownMenuItem(
                              value: 'create',
                              child: Text('Create'),
                            ),
                            const DropdownMenuItem(
                              value: 'update',
                              child: Text('Update'),
                            ),
                            const DropdownMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                            const DropdownMenuItem(
                              value: 'approve',
                              child: Text('Approve'),
                            ),
                            const DropdownMenuItem(
                              value: 'reject',
                              child: Text('Reject'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => selectedAction = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: selectedResourceType,
                          hint: const Text('All Resources'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Resources'),
                            ),
                            const DropdownMenuItem(
                              value: 'user',
                              child: Text('User'),
                            ),
                            const DropdownMenuItem(
                              value: 'order',
                              child: Text('Order'),
                            ),
                            const DropdownMenuItem(
                              value: 'product',
                              child: Text('Product'),
                            ),
                            const DropdownMenuItem(
                              value: 'price',
                              child: Text('Price'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => selectedResourceType = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filters row 2
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: selectedStatus,
                          hint: const Text('All Status'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Status'),
                            ),
                            const DropdownMenuItem(
                              value: 'success',
                              child: Text('Success'),
                            ),
                            const DropdownMenuItem(
                              value: 'failed',
                              child: Text('Failed'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => selectedStatus = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showDateRangePicker(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: Text(
                            selectedDateRange == null
                                ? 'Select Date'
                                : '${selectedDateRange!.start.day}/${selectedDateRange!.start.month} - ${selectedDateRange!.end.day}/${selectedDateRange!.end.month}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Logs list
            Expanded(
              child: _buildLogsList(logs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList(List<AuditLogEntry> logs) {
    // Filter logs
    var filtered = logs.where((log) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        if (!log.userId.toLowerCase().contains(searchQuery) &&
            !log.resourceId.toLowerCase().contains(searchQuery) &&
            !log.ipAddress.toLowerCase().contains(searchQuery)) {
          return false;
        }
      }

      // Action filter
      if (selectedAction != null && log.action != selectedAction) {
        return false;
      }

      // Resource type filter
      if (selectedResourceType != null &&
          log.resourceType != selectedResourceType) {
        return false;
      }

      // Status filter
      if (selectedStatus != null && log.status != selectedStatus) {
        return false;
      }

      // Date range filter
      if (selectedDateRange != null) {
        if (log.timestamp.isBefore(selectedDateRange!.start) ||
            log.timestamp.isAfter(selectedDateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No audit logs found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _AuditLogCard(log: filtered[index]),
    );
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDateRange = picked);
    }
  }
}

/// Audit Log Card Widget
class _AuditLogCard extends StatelessWidget {
  final AuditLogEntry log;

  const _AuditLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getActionIcon(),
                            size: 18,
                            color: _getActionColor(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${log.action.toUpperCase()} ${log.resourceType}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.resourceId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: log.status == 'success'
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: log.status == 'success'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            if (log.details != null) ...[
              Text(
                log.details!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${log.userId} (${log.userRole})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            log.ipAddress,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(log.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTime(log.timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon() {
    switch (log.action) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'approve':
        return Icons.check_circle;
      case 'reject':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor() {
    switch (log.action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
