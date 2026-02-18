import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling order approval workflows
class ApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit an order for approval
  ///
  /// Returns the approval ID if successful
  Future<String> submitForApproval({
    required String orderId,
    required String submittedBy,
    required double amount,
    required int itemCount,
    required String priority, // Normal, High, Urgent
    required List<String> approverIds,
  }) async {
    try {
      final approval = {
        'orderId': orderId,
        'submittedBy': submittedBy,
        'amount': amount,
        'itemCount': itemCount,
        'priority': priority,
        'status': 'pending', // pending, approved, rejected
        'approverIds': approverIds,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'approvals': {}, // Maps approver ID to {status, timestamp, comments}
        'rejectionReason': null,
      };

      final docRef = await _firestore.collection('approvals').add(approval);

      // Create approval records for each approver
      for (final approverId in approverIds) {
        await _firestore
            .collection('approvals')
            .doc(docRef.id)
            .collection('approver_tasks')
            .doc(approverId)
            .set({
          'approverId': approverId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'viewedAt': null,
        });
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit approval: $e');
    }
  }

  /// Approve an order
  Future<void> approveOrder({
    required String approvalId,
    required String approverId,
    required String comments,
  }) async {
    try {
      // Update main approval document
      await _firestore.collection('approvals').doc(approvalId).update({
        'approvals.$approverId': {
          'status': 'approved',
          'timestamp': FieldValue.serverTimestamp(),
          'comments': comments,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mark approver task as completed
      await _firestore
          .collection('approvals')
          .doc(approvalId)
          .collection('approver_tasks')
          .doc(approverId)
          .update({
        'status': 'approved',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Check if all approvals are complete and update main status
      await _updateApprovalStatus(approvalId);
    } catch (e) {
      throw Exception('Failed to approve order: $e');
    }
  }

  /// Reject an order
  Future<void> rejectOrder({
    required String approvalId,
    required String approverId,
    required String rejectionReason,
  }) async {
    try {
      // Update main approval document
      await _firestore.collection('approvals').doc(approvalId).update({
        'status': 'rejected',
        'rejectionReason': rejectionReason,
        'rejectedBy': approverId,
        'updatedAt': FieldValue.serverTimestamp(),
        'approvals.$approverId': {
          'status': 'rejected',
          'timestamp': FieldValue.serverTimestamp(),
          'comments': rejectionReason,
        },
      });

      // Mark approver task as completed
      await _firestore
          .collection('approvals')
          .doc(approvalId)
          .collection('approver_tasks')
          .doc(approverId)
          .update({
        'status': 'rejected',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject order: $e');
    }
  }

  /// Get pending approvals for a user
  Future<List<ApprovalRecord>> getPendingApprovals(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('approvals')
          .where('approverIds', arrayContains: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ApprovalRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending approvals: $e');
    }
  }

  /// Get approval history
  Future<List<ApprovalRecord>> getApprovalHistory({
    required String userId,
    required int limit,
    DateTime? startDate,
  }) async {
    try {
      Query query = _firestore
          .collection('approvals')
          .where('approverIds', arrayContains: userId);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThan: startDate);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => ApprovalRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch approval history: $e');
    }
  }

  /// Update approval status based on all approver responses
  Future<void> _updateApprovalStatus(String approvalId) async {
    try {
      final approvalDoc =
          await _firestore.collection('approvals').doc(approvalId).get();

      final approvals =
          approvalDoc.data()?['approvals'] as Map<String, dynamic>? ?? {};

      if (approvals.isEmpty) return;

      // Check if all approvers have responded
      final allResponded =
          approvals.values.every((approval) => approval['status'] != 'pending');

      if (!allResponded) return;

      // Check if any rejections
      final hasRejections =
          approvals.values.any((approval) => approval['status'] == 'rejected');

      if (hasRejections) {
        // Already set to rejected in rejectOrder
        return;
      }

      // All approved
      await _firestore.collection('approvals').doc(approvalId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update approval status: $e');
    }
  }
}

/// Model for approval records
class ApprovalRecord {
  final String id;
  final String orderId;
  final String submittedBy;
  final double amount;
  final int itemCount;
  final String priority;
  final String status; // pending, approved, rejected
  final List<String> approverIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, ApproverResponse> approvals;
  final String? rejectionReason;

  ApprovalRecord({
    required this.id,
    required this.orderId,
    required this.submittedBy,
    required this.amount,
    required this.itemCount,
    required this.priority,
    required this.status,
    required this.approverIds,
    required this.createdAt,
    required this.updatedAt,
    required this.approvals,
    this.rejectionReason,
  });

  factory ApprovalRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final approvalsMap = data['approvals'] as Map<String, dynamic>? ?? {};

    return ApprovalRecord(
      id: doc.id,
      orderId: data['orderId'] as String,
      submittedBy: data['submittedBy'] as String,
      amount: (data['amount'] as num).toDouble(),
      itemCount: data['itemCount'] as int,
      priority: data['priority'] as String,
      status: data['status'] as String,
      approverIds: List<String>.from(data['approverIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      approvals: approvalsMap.map((key, value) => MapEntry(
          key, ApproverResponse.fromMap(value as Map<String, dynamic>))),
      rejectionReason: data['rejectionReason'] as String?,
    );
  }
}

/// Model for individual approver response
class ApproverResponse {
  final String status; // pending, approved, rejected
  final DateTime timestamp;
  final String comments;

  ApproverResponse({
    required this.status,
    required this.timestamp,
    required this.comments,
  });

  factory ApproverResponse.fromMap(Map<String, dynamic> data) {
    return ApproverResponse(
      status: data['status'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      comments: data['comments'] as String,
    );
  }
}
