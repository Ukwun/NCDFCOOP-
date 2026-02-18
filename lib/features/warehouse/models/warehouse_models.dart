import 'package:cloud_firestore/cloud_firestore.dart';

/// Warehouse models for pick, pack, and QC workflows

enum PickStatus { pending, inProgress, completed, cancelled, failed }

enum PackStatus { pending, inProgress, completed, cancelled }

enum QCStatus { pending, inProgress, passed, failed, needsReview }

enum ShipmentStatus { created, ready, shipped, delivered, cancelled }

/// Pick Job - retrieving items from inventory bins
class PickJob {
  final String id;
  final String orderId;
  final String warehouseId;
  final String pickerId;
  final String? pickerName;
  final List<PickLine> pickLines;
  final PickStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final double? priorityScore;

  PickJob({
    required this.id,
    required this.orderId,
    required this.warehouseId,
    required this.pickerId,
    this.pickerName,
    required this.pickLines,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.priorityScore,
  });

  factory PickJob.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PickJob(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      warehouseId: data['warehouseId'] ?? '',
      pickerId: data['pickerId'] ?? '',
      pickerName: data['pickerName'],
      pickLines: (data['pickLines'] as List?)
              ?.map((item) => PickLine.fromMap(item))
              .toList() ??
          [],
      status: PickStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => PickStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      priorityScore: (data['priorityScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'warehouseId': warehouseId,
        'pickerId': pickerId,
        'pickerName': pickerName,
        'pickLines': pickLines.map((l) => l.toMap()).toList(),
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'startedAt': startedAt,
        'completedAt': completedAt,
        'notes': notes,
        'priorityScore': priorityScore,
      };

  int get totalLines => pickLines.length;
  int get completedLines => pickLines.where((l) => l.pickedQuantity > 0).length;
  double get completionPercentage =>
      totalLines > 0 ? (completedLines / totalLines) * 100 : 0;
  int get totalQuantity =>
      pickLines.fold<int>(0, (prev, l) => prev + l.quantity);
  int get pickedQuantity =>
      pickLines.fold<int>(0, (prev, l) => prev + l.pickedQuantity);
}

/// Individual pick line item
class PickLine {
  final String id;
  final String sku;
  final String productName;
  final String binLocation;
  final int quantity;
  final int pickedQuantity;
  final String? notes;

  PickLine({
    required this.id,
    required this.sku,
    required this.productName,
    required this.binLocation,
    required this.quantity,
    required this.pickedQuantity,
    this.notes,
  });

  factory PickLine.fromMap(Map<String, dynamic> data) {
    return PickLine(
      id: data['id'] ?? '',
      sku: data['sku'] ?? '',
      productName: data['productName'] ?? '',
      binLocation: data['binLocation'] ?? '',
      quantity: data['quantity'] ?? 0,
      pickedQuantity: data['pickedQuantity'] ?? 0,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sku': sku,
        'productName': productName,
        'binLocation': binLocation,
        'quantity': quantity,
        'pickedQuantity': pickedQuantity,
        'notes': notes,
      };

  bool get isCompleted => pickedQuantity >= quantity;
  bool get isPartial => pickedQuantity > 0 && pickedQuantity < quantity;
  bool get isNotPicked => pickedQuantity == 0;
}

/// Pack Job - consolidating picked items into shipment boxes
class PackJob {
  final String id;
  final String orderId;
  final String warehouseId;
  final String packerId;
  final String? packerName;
  final List<PackLine> packLines;
  final PackStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? shipmentId;
  final String? notes;
  final double? weight;
  final String? dimensions;

  PackJob({
    required this.id,
    required this.orderId,
    required this.warehouseId,
    required this.packerId,
    this.packerName,
    required this.packLines,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.shipmentId,
    this.notes,
    this.weight,
    this.dimensions,
  });

  factory PackJob.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackJob(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      warehouseId: data['warehouseId'] ?? '',
      packerId: data['packerId'] ?? '',
      packerName: data['packerName'],
      packLines: (data['packLines'] as List?)
              ?.map((item) => PackLine.fromMap(item))
              .toList() ??
          [],
      status: PackStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => PackStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      shipmentId: data['shipmentId'],
      notes: data['notes'],
      weight: (data['weight'] as num?)?.toDouble(),
      dimensions: data['dimensions'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'warehouseId': warehouseId,
        'packerId': packerId,
        'packerName': packerName,
        'packLines': packLines.map((l) => l.toMap()).toList(),
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'startedAt': startedAt,
        'completedAt': completedAt,
        'shipmentId': shipmentId,
        'notes': notes,
        'weight': weight,
        'dimensions': dimensions,
      };

  int get totalLines => packLines.length;
  int get completedLines => packLines.where((l) => l.packedQuantity > 0).length;
  double get completionPercentage =>
      totalLines > 0 ? (completedLines / totalLines) * 100 : 0;
}

/// Individual pack line item
class PackLine {
  final String id;
  final String sku;
  final String productName;
  final int quantity;
  final int packedQuantity;
  final String? boxNumber;
  final String? notes;

  PackLine({
    required this.id,
    required this.sku,
    required this.productName,
    required this.quantity,
    required this.packedQuantity,
    this.boxNumber,
    this.notes,
  });

  factory PackLine.fromMap(Map<String, dynamic> data) {
    return PackLine(
      id: data['id'] ?? '',
      sku: data['sku'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      packedQuantity: data['packedQuantity'] ?? 0,
      boxNumber: data['boxNumber'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sku': sku,
        'productName': productName,
        'quantity': quantity,
        'packedQuantity': packedQuantity,
        'boxNumber': boxNumber,
        'notes': notes,
      };

  bool get isCompleted => packedQuantity >= quantity;
  bool get isPartial => packedQuantity > 0 && packedQuantity < quantity;
}

/// QC (Quality Check) Job - verifying items before shipment
class QCJob {
  final String id;
  final String orderId;
  final String? shipmentId;
  final String warehouseId;
  final String qcPersonId;
  final String? qcPersonName;
  final List<QCLine> qcLines;
  final QCStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final List<QCIssue> issues;

  QCJob({
    required this.id,
    required this.orderId,
    this.shipmentId,
    required this.warehouseId,
    required this.qcPersonId,
    this.qcPersonName,
    required this.qcLines,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.notes,
    required this.issues,
  });

  factory QCJob.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QCJob(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      shipmentId: data['shipmentId'],
      warehouseId: data['warehouseId'] ?? '',
      qcPersonId: data['qcPersonId'] ?? '',
      qcPersonName: data['qcPersonName'],
      qcLines: (data['qcLines'] as List?)
              ?.map((item) => QCLine.fromMap(item))
              .toList() ??
          [],
      status: QCStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => QCStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      issues: (data['issues'] as List?)
              ?.map((item) => QCIssue.fromMap(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'shipmentId': shipmentId,
        'warehouseId': warehouseId,
        'qcPersonId': qcPersonId,
        'qcPersonName': qcPersonName,
        'qcLines': qcLines.map((l) => l.toMap()).toList(),
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'startedAt': startedAt,
        'completedAt': completedAt,
        'notes': notes,
        'issues': issues.map((i) => i.toMap()).toList(),
      };

  int get totalLines => qcLines.length;
  int get checkedLines => qcLines.where((l) => l.isChecked).length;
  int get passedLines => qcLines.where((l) => l.passed == true).length;
  int get failedLines => qcLines.where((l) => l.passed == false).length;
  double get checkProgress =>
      totalLines > 0 ? (checkedLines / totalLines) * 100 : 0;
}

/// Individual QC line item
class QCLine {
  final String id;
  final String sku;
  final String productName;
  final int quantity;
  final bool? passed;
  final String? failureReason;
  final bool isChecked;

  QCLine({
    required this.id,
    required this.sku,
    required this.productName,
    required this.quantity,
    this.passed,
    this.failureReason,
    required this.isChecked,
  });

  factory QCLine.fromMap(Map<String, dynamic> data) {
    return QCLine(
      id: data['id'] ?? '',
      sku: data['sku'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      passed: data['passed'],
      failureReason: data['failureReason'],
      isChecked: data['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sku': sku,
        'productName': productName,
        'quantity': quantity,
        'passed': passed,
        'failureReason': failureReason,
        'isChecked': isChecked,
      };
}

/// QC Issue - problems found during quality check
class QCIssue {
  final String id;
  final String pickLineId;
  final String issueType; // damage, quantity_mismatch, wrong_item, expired, etc
  final String severity; // low, medium, high
  final String description;
  final DateTime reportedAt;
  final String reportedBy;
  final String? resolution;

  QCIssue({
    required this.id,
    required this.pickLineId,
    required this.issueType,
    required this.severity,
    required this.description,
    required this.reportedAt,
    required this.reportedBy,
    this.resolution,
  });

  factory QCIssue.fromMap(Map<String, dynamic> data) {
    return QCIssue(
      id: data['id'] ?? '',
      pickLineId: data['pickLineId'] ?? '',
      issueType: data['issueType'] ?? '',
      severity: data['severity'] ?? 'medium',
      description: data['description'] ?? '',
      reportedAt:
          (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportedBy: data['reportedBy'] ?? '',
      resolution: data['resolution'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'pickLineId': pickLineId,
        'issueType': issueType,
        'severity': severity,
        'description': description,
        'reportedAt': reportedAt,
        'reportedBy': reportedBy,
        'resolution': resolution,
      };
}

/// Warehouse Shipment - tracking the final package
class WarehouseShipment {
  final String id;
  final String orderId;
  final String warehouseId;
  final List<String> pickJobIds;
  final List<String> packJobIds;
  final String? qcJobId;
  final ShipmentStatus status;
  final DateTime createdAt;
  final DateTime? readyAt;
  final DateTime? shippedAt;
  final String? trackingNumber;
  final double? weight;
  final String? dimensions;
  final String? carrier;
  final String? shippingLabel;

  WarehouseShipment({
    required this.id,
    required this.orderId,
    required this.warehouseId,
    required this.pickJobIds,
    required this.packJobIds,
    this.qcJobId,
    required this.status,
    required this.createdAt,
    this.readyAt,
    this.shippedAt,
    this.trackingNumber,
    this.weight,
    this.dimensions,
    this.carrier,
    this.shippingLabel,
  });

  factory WarehouseShipment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WarehouseShipment(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      warehouseId: data['warehouseId'] ?? '',
      pickJobIds: List<String>.from(data['pickJobIds'] ?? []),
      packJobIds: List<String>.from(data['packJobIds'] ?? []),
      qcJobId: data['qcJobId'],
      status: ShipmentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ShipmentStatus.created,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readyAt: (data['readyAt'] as Timestamp?)?.toDate(),
      shippedAt: (data['shippedAt'] as Timestamp?)?.toDate(),
      trackingNumber: data['trackingNumber'],
      weight: (data['weight'] as num?)?.toDouble(),
      dimensions: data['dimensions'],
      carrier: data['carrier'],
      shippingLabel: data['shippingLabel'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'warehouseId': warehouseId,
        'pickJobIds': pickJobIds,
        'packJobIds': packJobIds,
        'qcJobId': qcJobId,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'readyAt': readyAt,
        'shippedAt': shippedAt,
        'trackingNumber': trackingNumber,
        'weight': weight,
        'dimensions': dimensions,
        'carrier': carrier,
        'shippingLabel': shippingLabel,
      };
}
