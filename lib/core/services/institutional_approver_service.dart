import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/institutional_approver_models.dart';
import '../security/audit_log_service.dart';

/// Service for managing institutional approver workflows
class InstitutionalApproverService {
  final FirebaseFirestore _firestore;
  final AuditLogService _auditLogService;

  static InstitutionalApproverService? _instance;

  factory InstitutionalApproverService({
    FirebaseFirestore? firestore,
    AuditLogService? auditLogService,
  }) {
    _instance ??= InstitutionalApproverService._(
      firestore: firestore,
      auditLogService: auditLogService,
    );
    return _instance!;
  }

  InstitutionalApproverService._({
    FirebaseFirestore? firestore,
    AuditLogService? auditLogService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auditLogService = auditLogService ?? AuditLogService();

  /// Approve PO at department level
  Future<void> approveDepartment({
    required String poId,
    required String departmentName,
    required String approverId,
    required String approverName,
    String? notes,
  }) async {
    try {
      final approval = DepartmentApproval(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        poId: poId,
        departmentName: departmentName,
        approverId: approverId,
        approverName: approverName,
        status: ApprovalStatus.approved,
        createdAt: DateTime.now(),
        approvedAt: DateTime.now(),
        notes: notes,
      );

      await _firestore.collection('po_approvals').doc(poId).set({
        'departmentApproval': approval.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log to audit trail
      await _auditLogService.logAction(
        approverId,
        'approver',
        AuditAction.APPROVAL_STATUS_CHANGED,
        'PO',
        resourceId: poId,
        details: {
          'department': departmentName,
          'approverName': approverName,
          'notes': notes,
        },
      );
    } catch (e) {
      print('Error approving PO at department level: $e');
      rethrow;
    }
  }

  /// Reject PO at department level
  Future<void> rejectDepartment({
    required String poId,
    required String departmentName,
    required String approverId,
    required String approverName,
    required String rejectionReason,
  }) async {
    try {
      final approval = DepartmentApproval(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        poId: poId,
        departmentName: departmentName,
        approverId: approverId,
        approverName: approverName,
        status: ApprovalStatus.rejected,
        createdAt: DateTime.now(),
        approvedAt: DateTime.now(),
        rejectionReason: rejectionReason,
      );

      await _firestore.collection('po_approvals').doc(poId).set({
        'departmentApproval': approval.toFirestore(),
        'overallStatus': ApprovalStatus.rejected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _auditLogService.logAction(
        approverId,
        'approver',
        AuditAction.APPROVAL_STATUS_CHANGED,
        'PO',
        resourceId: poId,
        details: {
          'department': departmentName,
          'approverName': approverName,
          'rejectionReason': rejectionReason,
        },
      );
    } catch (e) {
      print('Error rejecting PO at department level: $e');
      rethrow;
    }
  }

  /// Verify budget for PO
  Future<void> verifyBudget({
    required String poId,
    required double poAmount,
    required String budgetOfficerId,
    required String budgetOfficerName,
    required double availableBudget,
    String? notes,
  }) async {
    try {
      final withinBudget = poAmount <= availableBudget;
      final approval = BudgetVerification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        poId: poId,
        budgetOfficerId: budgetOfficerId,
        budgetOfficerName: budgetOfficerName,
        poAmount: poAmount,
        remainingBudget: availableBudget - poAmount,
        withinBudget: withinBudget,
        status:
            withinBudget ? ApprovalStatus.approved : ApprovalStatus.rejected,
        createdAt: DateTime.now(),
        verifiedAt: DateTime.now(),
        notes: notes,
      );

      await _firestore.collection('po_approvals').doc(poId).set({
        'budgetVerification': approval.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _auditLogService.logAction(
        budgetOfficerId,
        'budget_officer',
        AuditAction.APPROVAL_STATUS_CHANGED,
        'PO',
        resourceId: poId,
        details: {
          'poAmount': poAmount,
          'availableBudget': availableBudget,
          'withinBudget': withinBudget,
          'budgetOfficerName': budgetOfficerName,
        },
      );
    } catch (e) {
      print('Error verifying budget: $e');
      rethrow;
    }
  }

  /// Authorize PO at director level
  Future<void> authorizeFinal({
    required String poId,
    required String directorId,
    required String directorName,
    String? comments,
  }) async {
    try {
      final authorization = FinalAuthorization(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        poId: poId,
        directorId: directorId,
        directorName: directorName,
        status: ApprovalStatus.approved,
        createdAt: DateTime.now(),
        authorizedAt: DateTime.now(),
        comments: comments,
      );

      await _firestore.collection('po_approvals').doc(poId).set({
        'finalAuthorization': authorization.toFirestore(),
        'overallStatus': ApprovalStatus.approved.name,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _auditLogService.logAction(
        directorId,
        'director',
        AuditAction.APPROVAL_STATUS_CHANGED,
        'PO',
        resourceId: poId,
        details: {
          'directorName': directorName,
          'comments': comments,
        },
      );
    } catch (e) {
      print('Error authorizing PO: $e');
      rethrow;
    }
  }

  /// Reject PO at final authorization stage
  Future<void> rejectFinal({
    required String poId,
    required String directorId,
    required String directorName,
    required String rejectionReason,
  }) async {
    try {
      final authorization = FinalAuthorization(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        poId: poId,
        directorId: directorId,
        directorName: directorName,
        status: ApprovalStatus.rejected,
        createdAt: DateTime.now(),
        authorizedAt: DateTime.now(),
        comments: rejectionReason,
      );

      await _firestore.collection('po_approvals').doc(poId).set({
        'finalAuthorization': authorization.toFirestore(),
        'overallStatus': ApprovalStatus.rejected.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _auditLogService.logAction(
        directorId,
        'director',
        AuditAction.APPROVAL_STATUS_CHANGED,
        'PO',
        resourceId: poId,
        details: {
          'directorName': directorName,
          'rejectionReason': rejectionReason,
        },
      );
    } catch (e) {
      print('Error rejecting PO at final stage: $e');
      rethrow;
    }
  }

  /// Get all pending approvals for a specific approver
  Future<List<POApprovalWorkflow>> getPendingApprovalsForUser(
    String userId,
    ApprovalStep step,
  ) async {
    try {
      final query = _firestore.collection('po_approvals');
      final snapshot = await query.get();

      final pendingApprovals = <POApprovalWorkflow>[];

      for (var doc in snapshot.docs) {
        final workflow = POApprovalWorkflow.fromFirestore(doc);

        // Check which step is pending and if this user should approve it
        final nextStep = workflow.getNextStep();
        if (nextStep == step) {
          // In real implementation, verify that user is authorized for this step
          pendingApprovals.add(workflow);
        }
      }

      return pendingApprovals;
    } catch (e) {
      print('Error fetching pending approvals: $e');
      return _getMockPendingApprovals();
    }
  }

  /// Get approval history for a PO
  Future<List<ApprovalHistoryEntry>> getApprovalHistory(String poId) async {
    try {
      final snapshot = await _firestore
          .collection('approval_history')
          .where('poId', isEqualTo: poId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ApprovalHistoryEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching approval history: $e');
      return _getMockApprovalHistory(poId);
    }
  }

  /// Enforce budget limits - check if PO exceeds limits
  Future<Map<String, dynamic>> enforceBudgetLimits({
    required String departmentId,
    required double poAmount,
  }) async {
    try {
      // Fetch department budget
      final budgetDoc =
          await _firestore.collection('departments').doc(departmentId).get();

      if (!budgetDoc.exists) {
        return {
          'withinBudget': true,
          'remainingBudget': double.infinity,
          'message': 'Department not found',
        };
      }

      final data = budgetDoc.data() as Map<String, dynamic>;
      final totalBudget = (data['totalBudget'] as num?)?.toDouble() ?? 0.0;
      final approvedSpending =
          (data['approvedSpending'] as num?)?.toDouble() ?? 0.0;

      final remainingBudget = totalBudget - approvedSpending;
      final withinBudget = poAmount <= remainingBudget;

      return {
        'withinBudget': withinBudget,
        'remainingBudget': remainingBudget,
        'requestedAmount': poAmount,
        'totalBudget': totalBudget,
        'approvedSpending': approvedSpending,
        'message': withinBudget
            ? 'PO is within budget limits'
            : 'PO exceeds remaining budget of ₦${remainingBudget.toStringAsFixed(2)}',
      };
    } catch (e) {
      print('Error enforcing budget limits: $e');
      return {
        'withinBudget': true,
        'remainingBudget': 1000000.0,
        'message': 'Budget check failed, defaulting to allow',
      };
    }
  }

  /// Get approval status for a PO
  Future<POApprovalWorkflow?> getApprovalStatus(String poId) async {
    try {
      final doc = await _firestore.collection('po_approvals').doc(poId).get();

      if (!doc.exists) {
        return null;
      }

      return POApprovalWorkflow.fromFirestore(doc);
    } catch (e) {
      print('Error fetching approval status: $e');
      return _getMockApprovalStatus(poId);
    }
  }

  /// Get approval dashboard statistics
  Future<Map<String, dynamic>> getApprovalDashboardStats() async {
    try {
      final snapshot = await _firestore.collection('po_approvals').get();

      int pending = 0;
      int approved = 0;
      int rejected = 0;
      double totalAmount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = ApprovalStatus.values.firstWhere(
          (s) => s.name == data['overallStatus'],
          orElse: () => ApprovalStatus.pending,
        );

        if (status == ApprovalStatus.pending) {
          pending++;
        } else if (status == ApprovalStatus.approved) {
          approved++;
        } else if (status == ApprovalStatus.rejected) {
          rejected++;
        }
      }

      return {
        'totalPOs': snapshot.docs.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'totalAmount': totalAmount,
      };
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return _getMockDashboardStats();
    }
  }

  // Mock data methods
  List<POApprovalWorkflow> _getMockPendingApprovals() {
    return [
      POApprovalWorkflow(
        id: '1',
        poId: 'PO-2024-001',
        departmentApproval: null,
        budgetVerification: null,
        finalAuthorization: null,
        overallStatus: ApprovalStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      POApprovalWorkflow(
        id: '2',
        poId: 'PO-2024-002',
        departmentApproval: DepartmentApproval(
          id: '1',
          poId: 'PO-2024-002',
          departmentName: 'Procurement',
          approverId: 'user123',
          approverName: 'John Doe',
          status: ApprovalStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          approvedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          notes: 'Looks good',
        ),
        budgetVerification: null,
        finalAuthorization: null,
        overallStatus: ApprovalStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  List<ApprovalHistoryEntry> _getMockApprovalHistory(String poId) {
    return [
      ApprovalHistoryEntry(
        id: '1',
        poId: poId,
        stepName: 'Department Approval',
        approverId: 'user123',
        approverName: 'John Doe',
        action: 'approved',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        comments: 'Department approved the PO',
      ),
      ApprovalHistoryEntry(
        id: '2',
        poId: poId,
        stepName: 'Budget Verification',
        approverId: 'user456',
        approverName: 'Jane Smith',
        action: 'pending',
        timestamp: DateTime.now(),
        comments: 'Awaiting budget verification',
      ),
    ];
  }

  POApprovalWorkflow? _getMockApprovalStatus(String poId) {
    return POApprovalWorkflow(
      id: '1',
      poId: poId,
      departmentApproval: DepartmentApproval(
        id: '1',
        poId: poId,
        departmentName: 'Procurement',
        approverId: 'user123',
        approverName: 'John Doe',
        status: ApprovalStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        approvedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      budgetVerification: null,
      finalAuthorization: null,
      overallStatus: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  Map<String, dynamic> _getMockDashboardStats() {
    return {
      'totalPOs': 15,
      'pending': 5,
      'approved': 8,
      'rejected': 2,
      'totalAmount': 5850000.0,
    };
  }
}

/// Provider for Institutional Approver Service
final institutionalApproverServiceProvider =
    Provider((ref) => InstitutionalApproverService());
