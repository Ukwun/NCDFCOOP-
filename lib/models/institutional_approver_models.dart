import 'package:cloud_firestore/cloud_firestore.dart';

/// PO Approval Models for Institutional Approver workflow

/// Approval step in PO workflow
enum ApprovalStep { departmentApproval, budgetVerification, finalAuthorization }

/// PO approval status
enum ApprovalStatus { pending, approved, rejected, needsRevision }

/// Department approval record
class DepartmentApproval {
  final String id;
  final String poId;
  final String departmentName;
  final String approverId;
  final String approverName;
  final ApprovalStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? notes;
  final String? rejectionReason;

  DepartmentApproval({
    required this.id,
    required this.poId,
    required this.departmentName,
    required this.approverId,
    required this.approverName,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.notes,
    this.rejectionReason,
  });

  factory DepartmentApproval.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepartmentApproval(
      id: doc.id,
      poId: data['poId'] ?? '',
      departmentName: data['departmentName'] ?? '',
      approverId: data['approverId'] ?? '',
      approverName: data['approverName'] ?? '',
      status: ApprovalStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'poId': poId,
        'departmentName': departmentName,
        'approverId': approverId,
        'approverName': approverName,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': approvedAt,
        'notes': notes,
        'rejectionReason': rejectionReason,
      };
}

/// Budget verification record
class BudgetVerification {
  final String id;
  final String poId;
  final String budgetOfficerId;
  final String budgetOfficerName;
  final double poAmount;
  final double remainingBudget;
  final bool withinBudget;
  final ApprovalStatus status;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? notes;

  BudgetVerification({
    required this.id,
    required this.poId,
    required this.budgetOfficerId,
    required this.budgetOfficerName,
    required this.poAmount,
    required this.remainingBudget,
    required this.withinBudget,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
    this.notes,
  });

  factory BudgetVerification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetVerification(
      id: doc.id,
      poId: data['poId'] ?? '',
      budgetOfficerId: data['budgetOfficerId'] ?? '',
      budgetOfficerName: data['budgetOfficerName'] ?? '',
      poAmount: (data['poAmount'] as num?)?.toDouble() ?? 0.0,
      remainingBudget: (data['remainingBudget'] as num?)?.toDouble() ?? 0.0,
      withinBudget: data['withinBudget'] ?? true,
      status: ApprovalStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'poId': poId,
        'budgetOfficerId': budgetOfficerId,
        'budgetOfficerName': budgetOfficerName,
        'poAmount': poAmount,
        'remainingBudget': remainingBudget,
        'withinBudget': withinBudget,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'verifiedAt': verifiedAt,
        'notes': notes,
      };
}

/// Final authorization approval
class FinalAuthorization {
  final String id;
  final String poId;
  final String directorId;
  final String directorName;
  final ApprovalStatus status;
  final DateTime createdAt;
  final DateTime? authorizedAt;
  final String? comments;

  FinalAuthorization({
    required this.id,
    required this.poId,
    required this.directorId,
    required this.directorName,
    required this.status,
    required this.createdAt,
    this.authorizedAt,
    this.comments,
  });

  factory FinalAuthorization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinalAuthorization(
      id: doc.id,
      poId: data['poId'] ?? '',
      directorId: data['directorId'] ?? '',
      directorName: data['directorName'] ?? '',
      status: ApprovalStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorizedAt: (data['authorizedAt'] as Timestamp?)?.toDate(),
      comments: data['comments'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'poId': poId,
        'directorId': directorId,
        'directorName': directorName,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'authorizedAt': authorizedAt,
        'comments': comments,
      };
}

/// Complete approval workflow status
class POApprovalWorkflow {
  final String id;
  final String poId;
  final DepartmentApproval? departmentApproval;
  final BudgetVerification? budgetVerification;
  final FinalAuthorization? finalAuthorization;
  final ApprovalStatus overallStatus;
  final DateTime createdAt;
  final DateTime? completedAt;

  POApprovalWorkflow({
    required this.id,
    required this.poId,
    this.departmentApproval,
    this.budgetVerification,
    this.finalAuthorization,
    required this.overallStatus,
    required this.createdAt,
    this.completedAt,
  });

  factory POApprovalWorkflow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return POApprovalWorkflow(
      id: doc.id,
      poId: data['poId'] ?? '',
      departmentApproval: data['departmentApproval'] != null
          ? _departmentApprovalFromMap(data['departmentApproval'])
          : null,
      budgetVerification: data['budgetVerification'] != null
          ? _budgetVerificationFromMap(data['budgetVerification'])
          : null,
      finalAuthorization: data['finalAuthorization'] != null
          ? _finalAuthorizationFromMap(data['finalAuthorization'])
          : null,
      overallStatus: ApprovalStatus.values.firstWhere(
        (s) => s.name == data['overallStatus'],
        orElse: () => ApprovalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'poId': poId,
        'overallStatus': overallStatus.name,
        'createdAt': FieldValue.serverTimestamp(),
        'completedAt': completedAt,
      };

  /// Check if all approvals are complete
  bool get isComplete =>
      departmentApproval?.status == ApprovalStatus.approved &&
      budgetVerification?.status == ApprovalStatus.approved &&
      finalAuthorization?.status == ApprovalStatus.approved;

  /// Get next required approval step
  ApprovalStep? getNextStep() {
    if (departmentApproval?.status != ApprovalStatus.approved) {
      return ApprovalStep.departmentApproval;
    }
    if (budgetVerification?.status != ApprovalStatus.approved) {
      return ApprovalStep.budgetVerification;
    }
    if (finalAuthorization?.status != ApprovalStatus.approved) {
      return ApprovalStep.finalAuthorization;
    }
    return null;
  }
}

/// Approval history entry
class ApprovalHistoryEntry {
  final String id;
  final String poId;
  final String stepName;
  final String approverId;
  final String approverName;
  final String action; // approved, rejected, revised
  final DateTime timestamp;
  final String? comments;

  ApprovalHistoryEntry({
    required this.id,
    required this.poId,
    required this.stepName,
    required this.approverId,
    required this.approverName,
    required this.action,
    required this.timestamp,
    this.comments,
  });

  factory ApprovalHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApprovalHistoryEntry(
      id: doc.id,
      poId: data['poId'] ?? '',
      stepName: data['stepName'] ?? '',
      approverId: data['approverId'] ?? '',
      approverName: data['approverName'] ?? '',
      action: data['action'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      comments: data['comments'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'poId': poId,
        'stepName': stepName,
        'approverId': approverId,
        'approverName': approverName,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'comments': comments,
      };
}

// Helper functions to convert maps to model objects
DepartmentApproval _departmentApprovalFromMap(Map<String, dynamic> data) {
  return DepartmentApproval(
    id: data['id'] ?? '',
    poId: data['poId'] ?? '',
    departmentName: data['departmentName'] ?? '',
    approverId: data['approverId'] ?? '',
    approverName: data['approverName'] ?? '',
    status: ApprovalStatus.values.firstWhere(
      (s) => s.name == data['status'],
      orElse: () => ApprovalStatus.pending,
    ),
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
    notes: data['notes'],
    rejectionReason: data['rejectionReason'],
  );
}

BudgetVerification _budgetVerificationFromMap(Map<String, dynamic> data) {
  return BudgetVerification(
    id: data['id'] ?? '',
    poId: data['poId'] ?? '',
    budgetOfficerId: data['budgetOfficerId'] ?? '',
    budgetOfficerName: data['budgetOfficerName'] ?? '',
    poAmount: (data['poAmount'] ?? 0).toDouble(),
    remainingBudget: (data['remainingBudget'] ?? 0).toDouble(),
    withinBudget: data['withinBudget'] ?? true,
    status: ApprovalStatus.values.firstWhere(
      (s) => s.name == data['status'],
      orElse: () => ApprovalStatus.pending,
    ),
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    notes: data['notes'],
  );
}

FinalAuthorization _finalAuthorizationFromMap(Map<String, dynamic> data) {
  return FinalAuthorization(
    id: data['id'] ?? '',
    poId: data['poId'] ?? '',
    directorId: data['directorId'] ?? '',
    directorName: data['directorName'] ?? '',
    status: ApprovalStatus.values.firstWhere(
      (s) => s.name == data['status'],
      orElse: () => ApprovalStatus.pending,
    ),
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    authorizedAt: (data['authorizedAt'] as Timestamp?)?.toDate(),
    comments: data['comments'],
  );
}
