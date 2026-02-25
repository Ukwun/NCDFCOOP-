import 'package:cloud_firestore/cloud_firestore.dart';
import 'audit_log_service.dart';

/// Audit Log Browser Service
/// Enables admin users to query, filter, and export audit logs
/// for compliance and investigation purposes
class AuditLogBrowserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _auditLogsCollection = 'audit_logs';

  AuditLogBrowserService();

  /// Get audit logs with flexible filtering
  Future<List<AuditLogEntry>> getFilteredAuditLogs({
    String? userId,
    String? resourceType,
    String? resourceId,
    AuditAction? action,
    AuditSeverity? severity,
    DateTime? startDate,
    DateTime? endDate,
    String? institutionId,
    String? franchiseId,
    bool? success,
    int limit = 100,
  }) async {
    try {
      var query = _firestore.collection(_auditLogsCollection)
          as Query<Map<String, dynamic>>;

      // Apply filters
      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      if (resourceType != null) {
        query = query.where('resource_type', isEqualTo: resourceType);
      }

      if (resourceId != null) {
        query = query.where('resource_id', isEqualTo: resourceId);
      }

      if (action != null) {
        query =
            query.where('action', isEqualTo: action.toString().split('.').last);
      }

      if (severity != null) {
        query = query.where('severity',
            isEqualTo: severity.toString().split('.').last);
      }

      if (institutionId != null) {
        query = query.where('institution_id', isEqualTo: institutionId);
      }

      if (franchiseId != null) {
        query = query.where('franchise_id', isEqualTo: franchiseId);
      }

      if (success != null) {
        query = query.where('success', isEqualTo: success);
      }

      // Date range filtering
      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      // Get results sorted by timestamp descending
      final snapshot =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => AuditLogEntry.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting filtered audit logs: $e');
      return [];
    }
  }

  /// Search audit logs by text (across multiple fields)
  Future<List<AuditLogEntry>> searchAuditLogs(
    String searchTerm, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = _firestore.collection(_auditLogsCollection)
          as Query<Map<String, dynamic>>;

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.orderBy('timestamp', descending: true).get();

      // Client-side filtering for text search
      final searchLower = searchTerm.toLowerCase();
      final results = snapshot.docs
          .map((doc) => AuditLogEntry.fromMap(doc.data(), doc.id))
          .where((entry) {
            return entry.userId.toLowerCase().contains(searchLower) ||
                (entry.resourceId?.toLowerCase().contains(searchLower) ??
                    false) ||
                entry.action.toString().contains(searchLower) ||
                (entry.failureReason?.toLowerCase().contains(searchLower) ??
                    false);
          })
          .take(limit)
          .toList();

      return results;
    } catch (e) {
      print('Error searching audit logs: $e');
      return [];
    }
  }

  /// Get audit logs for a specific time range
  Future<List<AuditLogEntry>> getAuditLogsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 500,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_auditLogsCollection)
          .where('timestamp',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLogEntry.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting logs by date range: $e');
      return [];
    }
  }

  /// Get suspicious activity (failed attempts, unauthorized access)
  Future<List<AuditLogEntry>> getSuspiciousActivity({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _firestore
          .collection(_auditLogsCollection)
          .where('success', isEqualTo: false);

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => AuditLogEntry.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting suspicious activity: $e');
      return [];
    }
  }

  /// Get critical operations (price changes, approvals, user changes, etc)
  Future<List<AuditLogEntry>> getCriticalOperations({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _firestore.collection(_auditLogsCollection).where('severity',
          isEqualTo: AuditSeverity.WARNING.toString().split('.').last);

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => AuditLogEntry.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting critical operations: $e');
      return [];
    }
  }

  /// Export audit logs to CSV format
  Future<String> exportAsCSV(List<AuditLogEntry> logs) async {
    try {
      final buffer = StringBuffer();

      // Header row
      buffer.writeln(
          'Timestamp,User ID,User Role,Action,Severity,Resource Type,'
          'Resource ID,Institution ID,Franchise ID,IP Address,Success,Failure Reason,Endpoint');

      // Data rows
      for (final log in logs) {
        final row = [
          log.timestamp.toIso8601String(),
          log.userId,
          log.userRole,
          log.action.toString().split('.').last,
          log.severity.toString().split('.').last,
          log.resourceType,
          log.resourceId ?? '',
          log.institutionId ?? '',
          log.franchiseId ?? '',
          log.ipAddress ?? '',
          log.success,
          log.failureReason ?? '',
          log.endpoint ?? '',
        ];

        // Escape and quote CSV fields
        final csvRow = row.map((field) {
          final str = field.toString();
          if (str.contains(',') || str.contains('"')) {
            return '"${str.replaceAll('"', '""')}"';
          }
          return str;
        }).join(',');

        buffer.writeln(csvRow);
      }

      return buffer.toString();
    } catch (e) {
      print('Error exporting to CSV: $e');
      rethrow;
    }
  }

  /// Export audit logs to JSON format
  Future<String> exportAsJSON(List<AuditLogEntry> logs) async {
    try {
      final jsonList = logs.map((log) => log.toMap()).toList();
      return _formatJSON(jsonList);
    } catch (e) {
      print('Error exporting to JSON: $e');
      rethrow;
    }
  }

  /// Format list as pretty-printed JSON
  String _formatJSON(List<Map<String, dynamic>> data) {
    final buffer = StringBuffer();
    buffer.writeln('[');

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      buffer.write('  {');

      final keys = entry.keys.toList();
      for (int j = 0; j < keys.length; j++) {
        final key = keys[j];
        final value = entry[key];

        buffer.write('\n    "$key": ');

        if (value is String) {
          buffer.write('"$value"');
        } else if (value is num || value is bool) {
          buffer.write(value);
        } else if (value is Map || value is List) {
          buffer.write(value);
        } else {
          buffer.write('null');
        }

        if (j < keys.length - 1) {
          buffer.write(',');
        }
      }

      buffer.write('\n  }');

      if (i < data.length - 1) {
        buffer.writeln(',');
      } else {
        buffer.writeln();
      }
    }

    buffer.writeln(']');
    return buffer.toString();
  }

  /// Get compliance report for date range
  Future<ComplianceReport> generateComplianceReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final logs =
          await getAuditLogsByDateRange(startDate, endDate, limit: 5000);

      // Calculate statistics
      final totalActions = logs.length;
      final failedActions = logs.where((l) => !l.success).length;
      final unauthorizedAttempts = logs
          .where((l) => !l.success && l.severity == AuditSeverity.WARNING)
          .length;

      // Group by user
      final actionsByUser = <String, int>{};
      for (final log in logs) {
        actionsByUser[log.userId] = (actionsByUser[log.userId] ?? 0) + 1;
      }

      // Group by resource type
      final actionsByResource = <String, int>{};
      for (final log in logs) {
        actionsByResource[log.resourceType] =
            (actionsByResource[log.resourceType] ?? 0) + 1;
      }

      // Group by action
      final actionsByType = <String, int>{};
      for (final log in logs) {
        final actionName = log.action.toString().split('.').last;
        actionsByType[actionName] = (actionsByType[actionName] ?? 0) + 1;
      }

      return ComplianceReport(
        startDate: startDate,
        endDate: endDate,
        totalActions: totalActions,
        failedActions: failedActions,
        unauthorizedAttempts: unauthorizedAttempts,
        actionsByUser: actionsByUser,
        actionsByResource: actionsByResource,
        actionsByType: actionsByType,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error generating compliance report: $e');
      rethrow;
    }
  }

  /// Watch audit logs for real-time updates (admin dashboard)
  Stream<List<AuditLogEntry>> watchRecentAuditLogs({
    int limit = 50,
    Duration recentness = const Duration(days: 1),
  }) {
    final cutoffTime = DateTime.now().subtract(recentness);

    return _firestore
        .collection(_auditLogsCollection)
        .where('timestamp',
            isGreaterThanOrEqualTo: cutoffTime.toIso8601String())
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLogEntry.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}

/// Compliance Report
/// Summary statistics of audit activity for a time period
class ComplianceReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalActions;
  final int failedActions;
  final int unauthorizedAttempts;
  final Map<String, int> actionsByUser; // user_id -> count
  final Map<String, int> actionsByResource; // resource_type -> count
  final Map<String, int> actionsByType; // action_type -> count
  final DateTime generatedAt;

  ComplianceReport({
    required this.startDate,
    required this.endDate,
    required this.totalActions,
    required this.failedActions,
    required this.unauthorizedAttempts,
    required this.actionsByUser,
    required this.actionsByResource,
    required this.actionsByType,
    required this.generatedAt,
  });

  /// Get success rate percentage
  double get successRate {
    if (totalActions == 0) return 100.0;
    return ((totalActions - failedActions) / totalActions) * 100;
  }

  /// Get top user by action count
  String? get topUser {
    if (actionsByUser.isEmpty) return null;
    return actionsByUser.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Format report as human-readable text
  String toFormattedString() {
    final buffer = StringBuffer();

    buffer.writeln('═' * 60);
    buffer.writeln('COMPLIANCE AUDIT REPORT');
    buffer.writeln('═' * 60);
    buffer.writeln();

    buffer.writeln(
        'Period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    buffer.writeln('Generated: ${generatedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('─ Summary Statistics ─');
    buffer.writeln('Total Actions:      $totalActions');
    buffer.writeln('Failed Actions:     $failedActions');
    buffer.writeln('Unauthorized:       $unauthorizedAttempts');
    buffer.writeln('Success Rate:       ${successRate.toStringAsFixed(1)}%');
    buffer.writeln();

    buffer.writeln('─ Top Users ─');
    final sortedUsers = actionsByUser.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedUsers.take(5)) {
      buffer.writeln(
          '${entry.key.padRight(30)} ${entry.value.toString().padLeft(5)} actions');
    }
    buffer.writeln();

    buffer.writeln('─ By Resource Type ─');
    final sortedResources = actionsByResource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedResources) {
      buffer.writeln(
          '${entry.key.padRight(30)} ${entry.value.toString().padLeft(5)} actions');
    }
    buffer.writeln();

    buffer.writeln('─ Top Action Types ─');
    final sortedActions = actionsByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedActions.take(10)) {
      buffer.writeln(
          '${entry.key.padRight(30)} ${entry.value.toString().padLeft(5)} times');
    }
    buffer.writeln();

    buffer.writeln('═' * 60);

    return buffer.toString();
  }

  /// Export report to CSV
  String toCSV() {
    final buffer = StringBuffer();

    buffer.writeln('Compliance Report');
    buffer.writeln(
        'Period,"${startDate.toIso8601String()} to ${endDate.toIso8601String()}"');
    buffer.writeln('Generated,${generatedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('Summary');
    buffer.writeln('Total Actions,$totalActions');
    buffer.writeln('Failed Actions,$failedActions');
    buffer.writeln('Unauthorized Attempts,$unauthorizedAttempts');
    buffer.writeln('Success Rate,${successRate.toStringAsFixed(1)}%');
    buffer.writeln();

    buffer.writeln('Top Users');
    buffer.writeln('User ID,Action Count');
    final sortedUsers = actionsByUser.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedUsers.take(10)) {
      buffer.writeln('${entry.key},${entry.value}');
    }

    return buffer.toString();
  }
}
