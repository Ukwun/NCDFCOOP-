import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/audit/audit_service.dart';

/// Audit and Compliance Reporting Screen
class AuditReportingScreen extends ConsumerStatefulWidget {
  const AuditReportingScreen({super.key});

  @override
  ConsumerState<AuditReportingScreen> createState() =>
      _AuditReportingScreenState();
}

class _AuditReportingScreenState extends ConsumerState<AuditReportingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  AuditEventType? _selectedEventType;
  String _selectedView = 'logs'; // logs, critical, stats

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final auditService = ref.watch(auditServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit & Compliance'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View selector
            _buildViewSelector(),
            const SizedBox(height: 16),

            // Date and filters
            _buildFilters(),
            const SizedBox(height: 16),

            // Content based on selected view
            if (_selectedView == 'logs')
              _buildAuditLogs(auditService)
            else if (_selectedView == 'critical')
              _buildCriticalEvents(auditService)
            else
              _buildStatistics(auditService),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Row(
      children: [
        _buildViewButton('Logs', 'logs'),
        const SizedBox(width: 8),
        _buildViewButton('Critical', 'critical'),
        const SizedBox(width: 8),
        _buildViewButton('Statistics', 'stats'),
      ],
    );
  }

  Widget _buildViewButton(String label, String view) {
    final isSelected = _selectedView == view;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedView = view;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
          foregroundColor: isSelected ? Colors.white : Colors.black,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date range selector
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date', style: TextStyle(fontSize: 12)),
                      Text(_startDate?.toString().split(' ')[0] ??
                          'Select date'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Date', style: TextStyle(fontSize: 12)),
                      Text(_endDate?.toString().split(' ')[0] ?? 'Select date'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Event type filter
        if (_selectedView == 'logs')
          DropdownButton<AuditEventType?>(
            isExpanded: true,
            value: _selectedEventType,
            hint: const Text('Filter by event type'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All event types'),
              ),
              ...AuditEventType.values.map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedEventType = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildAuditLogs(AuditService auditService) {
    return FutureBuilder<List<AuditLog>>(
      future: auditService.getAuditLogs(
        eventType: _selectedEventType,
        startDate: _startDate,
        endDate: _endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No audit logs found'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final log = snapshot.data![index];
            return _buildAuditLogTile(context, log);
          },
        );
      },
    );
  }

  Widget _buildAuditLogTile(BuildContext context, AuditLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${log.userName} - ${log.eventType.name}'),
        subtitle: Text(
          '${log.timestamp} | ${log.resource}#${log.resourceId}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: log.result == 'success' ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            log.result.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          _showLogDetail(context, log);
        },
      ),
    );
  }

  Widget _buildCriticalEvents(AuditService auditService) {
    return FutureBuilder<List<AuditLog>>(
      future: auditService.getCriticalEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No critical events to review'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final log = snapshot.data![index];
            return _buildCriticalEventTile(context, log);
          },
        );
      },
    );
  }

  Widget _buildCriticalEventTile(BuildContext context, AuditLog log) {
    final severity = log.getSeverity();
    final severityColor = severity == 'CRITICAL'
        ? Colors.red
        : severity == 'HIGH'
            ? Colors.orange
            : Colors.yellow;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: severityColor.withValues(alpha: 0.1),
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
                        log.eventType.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                      Text(
                        '${log.userName} on ${log.resource}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    severity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (log.denialReason != null)
              Text('Reason: ${log.denialReason}',
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showLogDetail(context, log);
                    },
                    child: const Text('Review'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(AuditService auditService) {
    return FutureBuilder<Map<String, dynamic>>(
      future: auditService.getAuditStats(_startDate!, _endDate!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        final stats = snapshot.data!;
        final breakdown = stats['eventBreakdown'] as Map<String, int>? ?? {};
        final resourceBreakdown =
            stats['resourceBreakdown'] as Map<String, int>? ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatItem('Total Events',
                    stats['totalEvents']?.toString() ?? '0', Colors.blue),
                _buildStatItem('Success',
                    stats['successCount']?.toString() ?? '0', Colors.green),
                _buildStatItem('Failures',
                    stats['failureCount']?.toString() ?? '0', Colors.red),
                _buildStatItem(
                  'Critical',
                  stats['criticalEvents']?.toString() ?? '0',
                  Colors.orange,
                ),
                _buildStatItem(
                  'Unique Users',
                  stats['uniqueUsers']?.toString() ?? '0',
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Event breakdown
            Text(
              'Event Type Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...breakdown.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Resource breakdown
            Text(
              'Resource Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...resourceBreakdown.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetail(BuildContext context, AuditLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Log Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Event Type', log.eventType.name),
              _buildDetailRow('User', log.userName),
              _buildDetailRow('Resource', '${log.resource}#${log.resourceId}'),
              _buildDetailRow('Action', log.action),
              _buildDetailRow('Result', log.result),
              _buildDetailRow('Timestamp', log.timestamp.toString()),
              _buildDetailRow('Duration', '${log.durationMs}ms'),
              if (log.denialReason != null)
                _buildDetailRow('Denial Reason', log.denialReason!),
              if (log.ipAddress != null)
                _buildDetailRow('IP Address', log.ipAddress!),
              if (log.details != null)
                _buildDetailRow('Details', log.details.toString()),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate! : _endDate!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }
}
