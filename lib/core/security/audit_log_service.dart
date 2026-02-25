import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Audit action types
enum AuditAction {
  // Order operations
  ORDER_CREATED,
  ORDER_UPDATED,
  ORDER_APPROVED,
  ORDER_REJECTED,
  ORDER_CANCELLED,
  ORDER_STATUS_CHANGED,

  // Pricing operations
  PRICE_CHANGED,
  PRICE_OVERRIDE_REQUESTED,
  PRICE_OVERRIDE_APPROVED,
  PRICE_OVERRIDE_REJECTED,

  // Payment operations
  PAYMENT_PROCESSED,
  PAYMENT_REFUNDED,
  PAYMENT_VOIDED,
  PAYMENT_FAILED,

  // Authorization operations
  UNAUTHORIZED_ACCESS_ATTEMPT,
  PERMISSION_CHECK_FAILED,
  RESOURCE_ACCESS_DENIED,
  APPROVAL_STATUS_CHANGED,

  // User operations
  USER_CREATED,
  USER_UPDATED,
  USER_DELETED,
  USER_PASSWORD_CHANGED,
  USER_ROLE_CHANGED,

  // Warehouse operations
  TASK_ASSIGNED,
  TASK_COMPLETED,
  QC_PASSED,
  QC_FAILED,
  PACKING_COMPLETED,
  INVENTORY_ADJUSTED,

  // Transaction operations
  TRANSACTION_RECORDED,
  DATA_ACCESSED,
  DATA_EXPORTED,
  DATA_DELETED,

  // System operations
  SYSTEM_SETTING_CHANGED,
  CONFIG_UPDATED,

  // Compliance operations
  COMPLIANCE_AUDIT_REQUESTED,
  COMPLIANCE_REPORT_GENERATED,

  // Contract operations
  CONTRACT_CREATED,
  CONTRACT_UPDATED,
  CONTRACT_EXPIRED,

  // Delivery operations
  DELIVERY_ASSIGNED,
  DELIVERY_STARTED,
  DELIVERY_COMPLETED,
  DELIVERY_FAILED,

  // Authentication operations
  LOGIN_SUCCESS,
  LOGIN_FAILED,
  LOGOUT,
  TOKEN_REFRESHED,
}

/// Severity levels for audit entries
enum AuditSeverity {
  INFO, // Normal operation
  WARNING, // Unusual but allowed operation
  ERROR, // Operation failed
  CRITICAL, // Security or compliance issue
}

/// Audit log entry
/// Immutable record of system actions
class AuditLogEntry {
  final String id; // Unique ID
  final DateTime timestamp;
  final String userId; // Who performed the action
  final String userRole; // Role of user
  final AuditAction action; // What action was performed
  final AuditSeverity severity; // Severity level
  final String
      resourceType; // What resource was affected (order, user, payment, etc)
  final String? resourceId; // ID of affected resource
  final String? institutionId; // For institutional scoping
  final String? franchiseId; // For franchise scoping
  final String? ipAddress; // IP address of request
  final String? userAgent; // User agent of request
  final Map<String, dynamic>? oldValue; // Previous value (for updates)
  final Map<String, dynamic>? newValue; // New value (for updates/creates)
  final Map<String, dynamic>? details; // Additional details
  final bool success; // Whether operation succeeded
  final String? failureReason; // Why it failed (if applicable)
  final String? endpoint; // API endpoint accessed

  AuditLogEntry({
    String? id,
    required this.timestamp,
    required this.userId,
    required this.userRole,
    required this.action,
    required this.severity,
    required this.resourceType,
    this.resourceId,
    this.institutionId,
    this.franchiseId,
    this.ipAddress,
    this.userAgent,
    this.oldValue,
    this.newValue,
    this.details,
    required this.success,
    this.failureReason,
    this.endpoint,
  }) : id = id ?? const Uuid().v4();

  factory AuditLogEntry.fromMap(Map<String, dynamic> map, String docId) {
    return AuditLogEntry(
      id: docId,
      timestamp: DateTime.parse(map['timestamp'] as String),
      userId: map['user_id'] as String,
      userRole: map['user_role'] as String,
      action: AuditAction.values.firstWhere(
        (a) => a.toString() == 'AuditAction.${map['action']}',
        orElse: () => AuditAction.DATA_ACCESSED,
      ),
      severity: AuditSeverity.values.firstWhere(
        (s) => s.toString() == 'AuditSeverity.${map['severity']}',
        orElse: () => AuditSeverity.INFO,
      ),
      resourceType: map['resource_type'] as String,
      resourceId: map['resource_id'] as String?,
      institutionId: map['institution_id'] as String?,
      franchiseId: map['franchise_id'] as String?,
      ipAddress: map['ip_address'] as String?,
      userAgent: map['user_agent'] as String?,
      oldValue: map['old_value'] as Map<String, dynamic>?,
      newValue: map['new_value'] as Map<String, dynamic>?,
      details: map['details'] as Map<String, dynamic>?,
      success: map['success'] as bool? ?? true,
      failureReason: map['failure_reason'] as String?,
      endpoint: map['endpoint'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'user_id': userId,
        'user_role': userRole,
        'action': action.toString().split('.').last,
        'severity': severity.toString().split('.').last,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'institution_id': institutionId,
        'franchise_id': franchiseId,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'old_value': oldValue,
        'new_value': newValue,
        'details': details,
        'success': success,
        'failure_reason': failureReason,
        'endpoint': endpoint,
      };

  @override
  String toString() =>
      'AuditEntry($action by $userId at $timestamp - $resourceType:$resourceId)';
}

/// Audit Log Service
/// Manages immutable audit trail for compliance and security
class AuditLogService {
  late final FirebaseFirestore _firestore;

  static const String _auditLogsCollection = 'audit_logs';
  static const String _archiveCollection = 'audit_logs_archive';

  /// Get Firestore instance, initializing lazy on first access
  FirebaseFirestore _getFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('⚠️ Firestore not available: $e');
      rethrow;
    }
  }

  /// Log a system action
  Future<String> logAction(
    String userId,
    String userRole,
    AuditAction action,
    String resourceType, {
    String? resourceId,
    AuditSeverity severity = AuditSeverity.INFO,
    String? institutionId,
    String? franchiseId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? details,
    bool success = true,
    String? failureReason,
    String? endpoint,
  }) async {
    try {
      final entry = AuditLogEntry(
        timestamp: DateTime.now(),
        userId: userId,
        userRole: userRole,
        action: action,
        severity: severity,
        resourceType: resourceType,
        resourceId: resourceId,
        institutionId: institutionId,
        franchiseId: franchiseId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        details: details,
        success: success,
        failureReason: failureReason,
        endpoint: endpoint,
      );

      await _getFirestore()
          .collection(_auditLogsCollection)
          .doc(entry.id)
          .set(entry.toMap());

      return entry.id;
    } catch (e) {
      // Log to console but don't crash the app if Firebase is unavailable
      debugPrint(
          '⚠️ Audit logging failed (Firebase may not be initialized): $e');
      // Return a dummy ID so the calling code can continue
      return 'audit_log_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Log order-related action
  Future<String> logOrderAction(
    String userId,
    String userRole,
    AuditAction action,
    String orderId, {
    String? institutionId,
    String? franchiseId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? ipAddress,
    String? userAgent,
    String? endpoint,
  }) async {
    try {
      final entry = AuditLogEntry(
        timestamp: DateTime.now(),
        userId: userId,
        userRole: userRole,
        action: action,
        severity: _getSeverityForAction(action),
        resourceType: 'order',
        resourceId: orderId,
        institutionId: institutionId,
        franchiseId: franchiseId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        oldValue: oldValue,
        newValue: newValue,
        endpoint: endpoint,
        success: true,
      );

      await _firestore
          .collection(_auditLogsCollection)
          .doc(entry.id)
          .set(entry.toMap());

      return entry.id;
    } catch (e) {
      print('⚠️ Audit logging failed (Firebase may not be initialized): $e');
      return 'audit_log_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Log price change
  Future<String> logPriceChange(
    String userId,
    String userRole,
    String productId,
    double oldPrice,
    double newPrice, {
    String? reason,
    String? ipAddress,
    String? userAgent,
    String? endpoint,
  }) async {
    try {
      final entry = AuditLogEntry(
        timestamp: DateTime.now(),
        userId: userId,
        userRole: userRole,
        action: AuditAction.PRICE_CHANGED,
        severity: AuditSeverity.WARNING, // Price changes are important
        resourceType: 'product',
        resourceId: productId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        oldValue: {'price': oldPrice},
        newValue: {'price': newPrice},
        details: {'reason': reason},
        endpoint: endpoint,
        success: true,
      );

      await _firestore
          .collection(_auditLogsCollection)
          .doc(entry.id)
          .set(entry.toMap());

      return entry.id;
    } catch (e) {
      print('⚠️ Audit logging failed (Firebase may not be initialized): $e');
      return 'audit_log_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Log approval action
  Future<String> logApproval(
    String userId,
    String userRole,
    AuditAction action,
    String resourceId, {
    String? decision,
    String? reason,
    String? ipAddress,
    String? userAgent,
    String? endpoint,
  }) async {
    try {
      final entry = AuditLogEntry(
        timestamp: DateTime.now(),
        userId: userId,
        userRole: userRole,
        action: action,
        severity: AuditSeverity.INFO,
        resourceType: 'approval',
        resourceId: resourceId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        details: {'decision': decision, 'reason': reason},
        endpoint: endpoint,
        success: true,
      );

      await _firestore
          .collection(_auditLogsCollection)
          .doc(entry.id)
          .set(entry.toMap());

      return entry.id;
    } catch (e) {
      print('⚠️ Audit logging failed (Firebase may not be initialized): $e');
      return 'audit_log_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Log data access (for compliance)
  Future<String> logDataAccess(
    String userId,
    String userRole,
    String resourceType,
    String resourceId, {
    String? details,
    String? ipAddress,
    String? userAgent,
    String? endpoint,
  }) async {
    try {
      final entry = AuditLogEntry(
        timestamp: DateTime.now(),
        userId: userId,
        userRole: userRole,
        action: AuditAction.DATA_ACCESSED,
        severity: AuditSeverity.INFO,
        resourceType: resourceType,
        resourceId: resourceId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        details: {'details': details},
        endpoint: endpoint,
        success: true,
      );

      await _firestore
          .collection(_auditLogsCollection)
          .doc(entry.id)
          .set(entry.toMap());

      return entry.id;
    } catch (e) {
      print('⚠️ Audit logging failed (Firebase may not be initialized): $e');
      return 'audit_log_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Log failed authentication attempt
  Future<String> logFailedAuth(
    String email,
    String reason, {
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final entry = AuditLogEntry(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        userId: 'unknown:$email',
        userRole: 'unknown',
        action: AuditAction.LOGIN_FAILED,
        severity: AuditSeverity.WARNING,
        resourceType: 'authentication',
        resourceId: email,
        ipAddress: ipAddress,
        userAgent: userAgent,
        success: false,
        failureReason: reason,
      );

      await _firestore
          .collection(_auditLogsCollection)
          .doc(entry.id)
          .set(entry.toMap());

      return entry.id;
    } catch (e) {
      print('⚠️ Audit logging failed (Firebase may not be initialized): $e');
      return 'audit_log_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get audit trail for a specific resource
  Future<List<AuditLogEntry>> getAuditTrail(
    String resourceType,
    String resourceId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_auditLogsCollection)
          .where('resource_type', isEqualTo: resourceType)
          .where('resource_id', isEqualTo: resourceId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLogEntry.fromMap(
                doc.data(),
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Error getting audit trail: $e');
      return [];
    }
  }

  /// Get audit entries by user
  Future<List<AuditLogEntry>> getActionsByUser(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _firestore
          .collection(_auditLogsCollection)
          .where('user_id', isEqualTo: userId);

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
      print('Error getting user actions: $e');
      return [];
    }
  }

  /// Get audit entries by action type
  Future<List<AuditLogEntry>> getActionsByType(
    AuditAction action, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _firestore
          .collection(_auditLogsCollection)
          .where('action', isEqualTo: action.toString().split('.').last);

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
      print('Error getting actions by type: $e');
      return [];
    }
  }

  /// Archive old audit logs (older than 30 days but keep for 7 years)
  Future<void> archiveOldLogs({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _firestore
          .collection(_auditLogsCollection)
          .where('timestamp', isLessThan: cutoffDate.toIso8601String())
          .get();

      for (final doc in snapshot.docs) {
        // Copy to archive
        await _firestore
            .collection(_archiveCollection)
            .doc(doc.id)
            .set(doc.data());

        // Delete from active
        await _firestore.collection(_auditLogsCollection).doc(doc.id).delete();
      }

      print('Archived ${snapshot.docs.length} audit logs');
    } catch (e) {
      print('Error archiving logs: $e');
    }
  }

  /// Get severity for action (some actions are more important)
  AuditSeverity _getSeverityForAction(AuditAction action) {
    switch (action) {
      case AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT:
      case AuditAction.PERMISSION_CHECK_FAILED:
      case AuditAction.PAYMENT_FAILED:
      case AuditAction.LOGIN_FAILED:
        return AuditSeverity.WARNING;

      case AuditAction.PRICE_CHANGED:
      case AuditAction.PRICE_OVERRIDE_APPROVED:
      case AuditAction.USER_ROLE_CHANGED:
      case AuditAction.SYSTEM_SETTING_CHANGED:
        return AuditSeverity.WARNING;

      case AuditAction.ORDER_REJECTED:
      case AuditAction.CONTRACT_EXPIRED:
        return AuditSeverity.INFO;

      default:
        return AuditSeverity.INFO;
    }
  }
}
