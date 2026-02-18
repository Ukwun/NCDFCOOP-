import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/features/warehouse/models/warehouse_models.dart';
import 'package:coop_commerce/core/audit/audit_service.dart';
import 'package:coop_commerce/core/auth/role.dart';

/// Complete warehouse management service handling pick, pack, and QC workflows
class WarehouseService {
  static final WarehouseService _instance = WarehouseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();

  factory WarehouseService() {
    return _instance;
  }

  WarehouseService._internal();

  // ==================== PICK WORKFLOWS ====================

  /// Create pick jobs for an order
  Future<String> createPickJob({
    required String orderId,
    required String warehouseId,
    required String pickerId,
    required String pickerName,
    required List<PickLine> pickLines,
    String? notes,
    double? priorityScore,
  }) async {
    try {
      final pickJobRef = _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pick_jobs')
          .doc();

      final pickJob = PickJob(
        id: pickJobRef.id,
        orderId: orderId,
        warehouseId: warehouseId,
        pickerId: pickerId,
        pickerName: pickerName,
        pickLines: pickLines,
        status: PickStatus.pending,
        createdAt: DateTime.now(),
        notes: notes,
        priorityScore: priorityScore,
      );

      await pickJobRef.set(pickJob.toFirestore());

      // Log to audit
      await _auditService.logAction(
        userId: pickerId,
        userName: pickerName,
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.pickStarted,
        resource: 'pick_job',
        resourceId: pickJob.id,
        action: 'create_pick_job',
        result: 'success',
        details: {
          'orderId': orderId,
          'warehouseId': warehouseId,
          'lineCount': pickLines.length,
        },
      );

      return pickJob.id;
    } catch (e) {
      await _auditService.logAction(
        userId: pickerId,
        userName: pickerName,
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.pickStarted,
        resource: 'pick_job',
        resourceId: 'unknown',
        action: 'create_pick_job',
        result: 'failure',
        details: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Start pick job
  Future<void> startPickJob(
      String warehouseId, String pickJobId, String pickerId) async {
    try {
      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pick_jobs')
          .doc(pickJobId)
          .update({
        'status': PickStatus.inProgress.name,
        'startedAt': FieldValue.serverTimestamp(),
      });

      await _auditService.logAction(
        userId: pickerId,
        userName: 'Picker',
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.pickStarted,
        resource: 'pick_job',
        resourceId: pickJobId,
        action: 'start_pick_job',
        result: 'success',
      );
    } catch (e) {
      await _auditService.logAction(
        userId: pickerId,
        userName: 'Picker',
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.pickStarted,
        resource: 'pick_job',
        resourceId: pickJobId,
        action: 'start_pick_job',
        result: 'failure',
        details: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Update pick line quantity
  Future<void> updatePickLineQuantity(
    String warehouseId,
    String pickJobId,
    String pickLineId,
    int pickedQuantity,
    String pickerId,
  ) async {
    try {
      final jobDoc = await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pick_jobs')
          .doc(pickJobId)
          .get();

      final job = PickJob.fromFirestore(jobDoc);
      final updatedLines = job.pickLines.map((line) {
        if (line.id == pickLineId) {
          return PickLine(
            id: line.id,
            sku: line.sku,
            productName: line.productName,
            binLocation: line.binLocation,
            quantity: line.quantity,
            pickedQuantity: pickedQuantity,
            notes: line.notes,
          );
        }
        return line;
      }).toList();

      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pick_jobs')
          .doc(pickJobId)
          .update({
        'pickLines': updatedLines.map((l) => l.toMap()).toList(),
      });

      await _auditService.logAction(
        userId: pickerId,
        userName: 'Picker',
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.pickStarted,
        resource: 'pick_line',
        resourceId: pickLineId,
        action: 'update_pick_quantity',
        result: 'success',
        newValue: {'pickedQuantity': pickedQuantity},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Complete pick job
  Future<void> completePickJob(
    String warehouseId,
    String pickJobId,
    String pickerId,
    String? notes,
  ) async {
    try {
      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pick_jobs')
          .doc(pickJobId)
          .update({
        'status': PickStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
        'notes': notes,
      });

      await _auditService.logAction(
        userId: pickerId,
        userName: 'Picker',
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.pickCompleted,
        resource: 'pick_job',
        resourceId: pickJobId,
        action: 'complete_pick_job',
        result: 'success',
        details: {'notes': notes},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get pick jobs for a warehouse
  Future<List<PickJob>> getPickJobs(
    String warehouseId, {
    PickStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pick_jobs');

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs.map((doc) => PickJob.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== PACK WORKFLOWS ====================

  /// Create pack job
  Future<String> createPackJob({
    required String orderId,
    required String warehouseId,
    required String packerId,
    required String packerName,
    required List<PackLine> packLines,
    String? notes,
  }) async {
    try {
      final packJobRef = _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pack_jobs')
          .doc();

      final packJob = PackJob(
        id: packJobRef.id,
        orderId: orderId,
        warehouseId: warehouseId,
        packerId: packerId,
        packerName: packerName,
        packLines: packLines,
        status: PackStatus.pending,
        createdAt: DateTime.now(),
        notes: notes,
      );

      await packJobRef.set(packJob.toFirestore());

      await _auditService.logAction(
        userId: packerId,
        userName: packerName,
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.packStarted,
        resource: 'pack_job',
        resourceId: packJob.id,
        action: 'create_pack_job',
        result: 'success',
        details: {'orderId': orderId, 'lineCount': packLines.length},
      );

      return packJob.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Start pack job
  Future<void> startPackJob(
      String warehouseId, String packJobId, String packerId) async {
    try {
      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pack_jobs')
          .doc(packJobId)
          .update({
        'status': PackStatus.inProgress.name,
        'startedAt': FieldValue.serverTimestamp(),
      });

      await _auditService.logAction(
        userId: packerId,
        userName: 'Packer',
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.packStarted,
        resource: 'pack_job',
        resourceId: packJobId,
        action: 'start_pack_job',
        result: 'success',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update pack line
  Future<void> updatePackLineQuantity(
    String warehouseId,
    String packJobId,
    String packLineId,
    int packedQuantity,
    String boxNumber,
    String packerId,
  ) async {
    try {
      final jobDoc = await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pack_jobs')
          .doc(packJobId)
          .get();

      final job = PackJob.fromFirestore(jobDoc);
      final updatedLines = job.packLines.map((line) {
        if (line.id == packLineId) {
          return PackLine(
            id: line.id,
            sku: line.sku,
            productName: line.productName,
            quantity: line.quantity,
            packedQuantity: packedQuantity,
            boxNumber: boxNumber,
            notes: line.notes,
          );
        }
        return line;
      }).toList();

      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pack_jobs')
          .doc(packJobId)
          .update({
        'packLines': updatedLines.map((l) => l.toMap()).toList(),
      });

      await _auditService.logAction(
        userId: packerId,
        userName: 'Packer',
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.packStarted,
        resource: 'pack_line',
        resourceId: packLineId,
        action: 'update_pack_quantity',
        result: 'success',
        newValue: {'packedQuantity': packedQuantity, 'boxNumber': boxNumber},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Complete pack job
  Future<void> completePackJob(
    String warehouseId,
    String packJobId,
    String packerId,
    double? weight,
    String? dimensions,
    String? notes,
  ) async {
    try {
      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pack_jobs')
          .doc(packJobId)
          .update({
        'status': PackStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
        'weight': weight,
        'dimensions': dimensions,
        'notes': notes,
      });

      await _auditService.logAction(
        userId: packerId,
        userName: 'Packer',
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.packCompleted,
        resource: 'pack_job',
        resourceId: packJobId,
        action: 'complete_pack_job',
        result: 'success',
        details: {'weight': weight, 'dimensions': dimensions},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get pack jobs for warehouse
  Future<List<PackJob>> getPackJobs(
    String warehouseId, {
    PackStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('pack_jobs');

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs.map((doc) => PackJob.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== QC WORKFLOWS ====================

  /// Create QC job
  Future<String> createQCJob({
    required String orderId,
    required String warehouseId,
    required String qcPersonId,
    required String qcPersonName,
    required List<QCLine> qcLines,
    String? shipmentId,
    String? notes,
  }) async {
    try {
      final qcJobRef = _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('qc_jobs')
          .doc();

      final qcJob = QCJob(
        id: qcJobRef.id,
        orderId: orderId,
        shipmentId: shipmentId,
        warehouseId: warehouseId,
        qcPersonId: qcPersonId,
        qcPersonName: qcPersonName,
        qcLines: qcLines,
        status: QCStatus.pending,
        createdAt: DateTime.now(),
        notes: notes,
        issues: [],
      );

      await qcJobRef.set(qcJob.toFirestore());

      await _auditService.logAction(
        userId: qcPersonId,
        userName: qcPersonName,
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.qcPassed,
        resource: 'qc_job',
        resourceId: qcJob.id,
        action: 'create_qc_job',
        result: 'success',
        details: {'orderId': orderId, 'lineCount': qcLines.length},
      );

      return qcJob.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Start QC job
  Future<void> startQCJob(
      String warehouseId, String qcJobId, String qcPersonId) async {
    try {
      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('qc_jobs')
          .doc(qcJobId)
          .update({
        'status': QCStatus.inProgress.name,
        'startedAt': FieldValue.serverTimestamp(),
      });

      await _auditService.logAction(
        userId: qcPersonId,
        userName: 'QC Officer',
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.qcPassed,
        resource: 'qc_job',
        resourceId: qcJobId,
        action: 'start_qc_job',
        result: 'success',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check QC line
  Future<void> checkQCLine(
    String warehouseId,
    String qcJobId,
    String qcLineId,
    bool passed,
    String? failureReason,
    String qcPersonId,
  ) async {
    try {
      final jobDoc = await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('qc_jobs')
          .doc(qcJobId)
          .get();

      final job = QCJob.fromFirestore(jobDoc);
      final updatedLines = job.qcLines.map((line) {
        if (line.id == qcLineId) {
          return QCLine(
            id: line.id,
            sku: line.sku,
            productName: line.productName,
            quantity: line.quantity,
            passed: passed,
            failureReason: failureReason,
            isChecked: true,
          );
        }
        return line;
      }).toList();

      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('qc_jobs')
          .doc(qcJobId)
          .update({
        'qcLines': updatedLines.map((l) => l.toMap()).toList(),
      });

      final eventType =
          passed ? AuditEventType.qcPassed : AuditEventType.qcFailed;
      await _auditService.logAction(
        userId: qcPersonId,
        userName: 'QC Officer',
        userRoles: [UserRole.warehouseStaff],
        eventType: eventType,
        resource: 'qc_line',
        resourceId: qcLineId,
        action: passed ? 'qc_passed' : 'qc_failed',
        result: 'success',
        details: {'failureReason': failureReason},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Report QC issue
  Future<void> reportQCIssue(
    String warehouseId,
    String qcJobId,
    QCIssue issue,
    String qcPersonId,
  ) async {
    try {
      final jobDoc = await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('qc_jobs')
          .doc(qcJobId)
          .get();

      final job = QCJob.fromFirestore(jobDoc);
      final updatedIssues = [...job.issues, issue];

      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('qc_jobs')
          .doc(qcJobId)
          .update({
        'issues': updatedIssues.map((i) => i.toMap()).toList(),
      });

      await _auditService.logAction(
        userId: qcPersonId,
        userName: 'QC Officer',
        userRoles: [UserRole.warehouseStaff],
        eventType: AuditEventType.qcFailed,
        resource: 'qc_issue',
        resourceId: issue.id,
        action: 'report_qc_issue',
        result: 'success',
        details: {
          'issueType': issue.issueType,
          'severity': issue.severity,
          'description': issue.description,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Complete QC job
  Future<void> completeQCJob(
    String warehouseId,
    String qcJobId,
    QCStatus finalStatus,
    String qcPersonId,
    String? notes,
  ) async {
    try {
      await _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('qc_jobs')
          .doc(qcJobId)
          .update({
        'status': finalStatus.name,
        'completedAt': FieldValue.serverTimestamp(),
        'notes': notes,
      });

      final eventType = finalStatus == QCStatus.passed
          ? AuditEventType.qcPassed
          : AuditEventType.qcFailed;
      await _auditService.logAction(
        userId: qcPersonId,
        userName: 'QC Officer',
        userRoles: [UserRole.warehouseStaff],
        eventType: eventType,
        resource: 'qc_job',
        resourceId: qcJobId,
        action: 'complete_qc_job',
        result: 'success',
        details: {'status': finalStatus.name, 'notes': notes},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get QC jobs
  Future<List<QCJob>> getQCJobs(
    String warehouseId, {
    QCStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('warehouses')
          .doc(warehouseId)
          .collection('qc_jobs');

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs.map((doc) => QCJob.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== SHIPMENT WORKFLOWS ====================

  /// Create warehouse shipment
  Future<String> createShipment({
    required String orderId,
    required String warehouseId,
    required List<String> pickJobIds,
    required List<String> packJobIds,
    String? qcJobId,
  }) async {
    try {
      final shipmentRef = _firestore.collection('warehouse_shipments').doc();

      final shipment = WarehouseShipment(
        id: shipmentRef.id,
        orderId: orderId,
        warehouseId: warehouseId,
        pickJobIds: pickJobIds,
        packJobIds: packJobIds,
        qcJobId: qcJobId,
        status: ShipmentStatus.created,
        createdAt: DateTime.now(),
      );

      await shipmentRef.set(shipment.toFirestore());

      return shipment.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update shipment status
  Future<void> updateShipmentStatus(
    String shipmentId,
    ShipmentStatus status, {
    String? trackingNumber,
    String? carrier,
  }) async {
    try {
      final updateData = {'status': status.name} as Map<String, dynamic>;

      if (status == ShipmentStatus.ready) {
        updateData['readyAt'] = FieldValue.serverTimestamp();
      } else if (status == ShipmentStatus.shipped) {
        updateData['shippedAt'] = FieldValue.serverTimestamp();
        if (trackingNumber != null) {
          updateData['trackingNumber'] = trackingNumber;
        }
        if (carrier != null) updateData['carrier'] = carrier;
      }

      await _firestore
          .collection('warehouse_shipments')
          .doc(shipmentId)
          .update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  /// Get shipment
  Future<WarehouseShipment?> getShipment(String shipmentId) async {
    try {
      final doc = await _firestore
          .collection('warehouse_shipments')
          .doc(shipmentId)
          .get();
      if (doc.exists) {
        return WarehouseShipment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get shipments for order
  Future<List<WarehouseShipment>> getOrderShipments(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('warehouse_shipments')
          .where('orderId', isEqualTo: orderId)
          .get();

      return snapshot.docs
          .map((doc) => WarehouseShipment.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

final warehouseServiceProvider = Provider<WarehouseService>((ref) {
  return WarehouseService();
});
