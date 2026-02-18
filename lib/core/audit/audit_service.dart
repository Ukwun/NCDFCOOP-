import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/auth/role.dart';

/// Audit Log Event Types for comprehensive tracking
enum AuditEventType {
  userLogin,
  userLogout,
  userRoleChange,
  orderCreated,
  orderUpdated,
  orderCancelled,
  paymentProcessed,
  paymentFailed,
  inventoryAdjusted,
  pickStarted,
  pickCompleted,
  packStarted,
  packCompleted,
  qcPassed,
  qcFailed,
  shipmentCreated,
  deliveryStarted,
  deliveryCompleted,
  accessDenied,
  suspiciousActivity,
  dataExported,
  settingsChanged,
}

/// Complete Audit Log with Firestore integration
class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final List<UserRole> userRoles;
  final AuditEventType eventType;
  final String resource;
  final String resourceId;
  final String action;
  final String result; // 'success', 'failure', 'partial'
  final String? denialReason;
  final Map<String, dynamic>? previousValue;
  final Map<String, dynamic>? newValue;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final int durationMs;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRoles,
    required this.eventType,
    required this.resource,
    required this.resourceId,
    required this.action,
    required this.result,
    this.denialReason,
    this.previousValue,
    this.newValue,
    this.details,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    required this.durationMs,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userRoles: (data['userRoles'] as List?)
              ?.map((r) => UserRole.values.firstWhere(
                    (role) => role.name == r,
                    orElse: () => UserRole.consumer,
                  ))
              .toList() ??
          [UserRole.consumer],
      eventType: AuditEventType.values.firstWhere(
        (e) => e.name == data['eventType'],
        orElse: () => AuditEventType.suspiciousActivity,
      ),
      resource: data['resource'] ?? '',
      resourceId: data['resourceId'] ?? '',
      action: data['action'] ?? '',
      result: data['result'] ?? 'unknown',
      denialReason: data['denialReason'],
      previousValue: data['previousValue'],
      newValue: data['newValue'],
      details: data['details'],
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      durationMs: data['durationMs'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'userRoles': userRoles.map((r) => r.name).toList(),
        'eventType': eventType.name,
        'resource': resource,
        'resourceId': resourceId,
        'action': action,
        'result': result,
        'denialReason': denialReason,
        'previousValue': previousValue,
        'newValue': newValue,
        'details': details,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'timestamp': FieldValue.serverTimestamp(),
        'durationMs': durationMs,
      };

  @override
  String toString() {
    return '[AUDIT] $timestamp - $userName ($userId) - $eventType on $resource#$resourceId - $result';
  }

  /// Check if this log indicates a critical security event
  bool isCriticalEvent() {
    return eventType == AuditEventType.accessDenied ||
        eventType == AuditEventType.suspiciousActivity ||
        eventType == AuditEventType.userRoleChange ||
        result == 'failure' && eventType == AuditEventType.paymentProcessed;
  }

  /// Get severity level for display
  String getSeverity() {
    if (isCriticalEvent()) return 'CRITICAL';
    if (eventType == AuditEventType.dataExported) return 'HIGH';
    if (result == 'failure') return 'MEDIUM';
    return 'LOW';
  }
}

/// Comprehensive Audit Service with Firestore integration
class AuditService {
  static final AuditService _instance = AuditService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<AuditLog> _localCache = [];

  factory AuditService() {
    return _instance;
  }

  AuditService._internal();

  /// Log an action with comprehensive details
  Future<void> logAction({
    required String userId,
    required String userName,
    required List<UserRole> userRoles,
    required AuditEventType eventType,
    required String resource,
    required String resourceId,
    required String action,
    required String result,
    String? denialReason,
    Map<String, dynamic>? previousValue,
    Map<String, dynamic>? newValue,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
    int durationMs = 0,
  }) async {
    try {
      final auditLog = AuditLog(
        id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        userRoles: userRoles,
        eventType: eventType,
        resource: resource,
        resourceId: resourceId,
        action: action,
        result: result,
        denialReason: denialReason,
        previousValue: previousValue,
        newValue: newValue,
        details: details,
        ipAddress: ipAddress,
        userAgent: userAgent,
        timestamp: DateTime.now(),
        durationMs: durationMs,
      );

      // Add to local cache
      _localCache.add(auditLog);

      // Send to Firestore
      try {
        await _firestore.collection('audit_logs').doc(auditLog.id).set(
              auditLog.toFirestore(),
            );

        // Also add to user-specific audit trail
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('audit_logs')
            .add(auditLog.toFirestore());
      } catch (e) {
        // Firestore error - continue with local caching
      }

      // Log critical events
      if (auditLog.isCriticalEvent()) {
        await _logCriticalEvent(auditLog);
      }
    } catch (e) {
      // Fail silently but audit logging should not break app
    }
  }

  /// Log critical security events separately
  Future<void> _logCriticalEvent(AuditLog log) async {
    try {
      await _firestore.collection('critical_events').add({
        ...log.toFirestore(),
        'alertLevel': log.getSeverity(),
        'reviewed': false,
      });
    } catch (e) {
      // Silent fail
    }
  }

  /// Get audit logs for a specific user
  Future<List<AuditLog>> getUserAuditLogs(String userId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all audit logs with filters
  Future<List<AuditLog>> getAuditLogs({
    AuditEventType? eventType,
    String? userId,
    String? resource,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('audit_logs');

      if (eventType != null) {
        query = query.where('eventType', isEqualTo: eventType.name);
      }
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (resource != null) {
        query = query.where('resource', isEqualTo: resource);
      }
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get critical security events
  Future<List<AuditLog>> getCriticalEvents({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('critical_events')
          .where('reviewed', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Mark critical event as reviewed
  Future<void> markEventReviewed(String eventId) async {
    try {
      await _firestore.collection('critical_events').doc(eventId).update({
        'reviewed': true,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail
    }
  }

  /// Get audit statistics for compliance reporting
  Future<Map<String, dynamic>> getAuditStats(
      DateTime startDate, DateTime endDate) async {
    try {
      final allLogs = await getAuditLogs(
          startDate: startDate, endDate: endDate, limit: 1000);

      final stats = {
        'totalEvents': allLogs.length,
        'successCount': allLogs.where((l) => l.result == 'success').length,
        'failureCount': allLogs.where((l) => l.result == 'failure').length,
        'criticalEvents': allLogs.where((l) => l.isCriticalEvent()).length,
        'uniqueUsers': allLogs.map((l) => l.userId).toSet().length,
        'eventBreakdown': _getEventBreakdown(allLogs),
        'resourceBreakdown': _getResourceBreakdown(allLogs),
      };

      return stats;
    } catch (e) {
      return {};
    }
  }

  Map<String, int> _getEventBreakdown(List<AuditLog> logs) {
    final breakdown = <String, int>{};
    for (final log in logs) {
      breakdown[log.eventType.name] = (breakdown[log.eventType.name] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, int> _getResourceBreakdown(List<AuditLog> logs) {
    final breakdown = <String, int>{};
    for (final log in logs) {
      breakdown[log.resource] = (breakdown[log.resource] ?? 0) + 1;
    }
    return breakdown;
  }

  /// Export audit logs for compliance reporting
  Future<String> exportAuditLogs(DateTime startDate, DateTime endDate,
      {String format = 'csv'}) async {
    try {
      final logs = await getAuditLogs(
          startDate: startDate, endDate: endDate, limit: 10000);

      if (format == 'csv') {
        return _generateCSV(logs);
      } else if (format == 'json') {
        return _generateJSON(logs);
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  String _generateCSV(List<AuditLog> logs) {
    final buffer = StringBuffer();
    buffer.writeln(
        'ID,Timestamp,User,Roles,Event,Resource,ResourceID,Action,Result,Duration(ms),IP,Severity');

    for (final log in logs) {
      buffer.writeln(
        '${log.id},'
        '${log.timestamp.toIso8601String()},'
        '${log.userName},'
        '${log.userRoles.map((r) => r.name).join(";")},'
        '${log.eventType.name},'
        '${log.resource},'
        '${log.resourceId},'
        '${log.action},'
        '${log.result},'
        '${log.durationMs},'
        '${log.ipAddress},'
        '${log.getSeverity()}',
      );
    }

    return buffer.toString();
  }

  String _generateJSON(List<AuditLog> logs) {
    return '[${logs.map((l) => l.toFirestore().toString()).join(',')}]';
  }

  /// Get local audit cache (for offline support)
  List<AuditLog> getLocalCache() => List.from(_localCache);

  /// Clear local cache
  void clearLocalCache() => _localCache.clear();
}

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService();
});
