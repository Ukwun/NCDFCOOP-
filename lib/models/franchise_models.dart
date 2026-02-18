import 'package:cloud_firestore/cloud_firestore.dart';

/// Franchise store information
class FranchiseStore {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final String email;
  final DateTime establishedDate;
  final double salesTarget;
  final String status; // active, inactive, suspended
  final bool acceptsUnionCard;
  final int employeeCount;
  final List<String> operatingDays; // Monday-Sunday
  final String operatingHours; // "9AM-9PM"

  FranchiseStore({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    required this.email,
    required this.establishedDate,
    required this.salesTarget,
    required this.status,
    required this.acceptsUnionCard,
    required this.employeeCount,
    required this.operatingDays,
    required this.operatingHours,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'email': email,
      'establishedDate': Timestamp.fromDate(establishedDate),
      'salesTarget': salesTarget,
      'status': status,
      'acceptsUnionCard': acceptsUnionCard,
      'employeeCount': employeeCount,
      'operatingDays': operatingDays,
      'operatingHours': operatingHours,
    };
  }

  factory FranchiseStore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FranchiseStore(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      establishedDate:
          (data['establishedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      salesTarget: (data['salesTarget'] as num?)?.toDouble() ?? 0,
      status: data['status'] ?? 'active',
      acceptsUnionCard: data['acceptsUnionCard'] ?? false,
      employeeCount: data['employeeCount'] ?? 0,
      operatingDays: List<String>.from(data['operatingDays'] ?? []),
      operatingHours: data['operatingHours'] ?? '9AM-9PM',
    );
  }
}

/// Daily sales metrics
class SalesMetric {
  final String id;
  final String storeId;
  final DateTime date;
  final double dailySales;
  final int transactionCount;
  final double avgTransactionValue;
  final double estimatedCogs; // Cost of goods sold
  final double estimatedGrossProfit;
  final double profitMargin;
  final String notes;
  final DateTime recordedAt;

  SalesMetric({
    required this.id,
    required this.storeId,
    required this.date,
    required this.dailySales,
    required this.transactionCount,
    required this.avgTransactionValue,
    required this.estimatedCogs,
    required this.estimatedGrossProfit,
    required this.profitMargin,
    required this.notes,
    required this.recordedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'date': Timestamp.fromDate(date),
      'dailySales': dailySales,
      'transactionCount': transactionCount,
      'avgTransactionValue': avgTransactionValue,
      'estimatedCogs': estimatedCogs,
      'estimatedGrossProfit': estimatedGrossProfit,
      'profitMargin': profitMargin,
      'notes': notes,
      'recordedAt': Timestamp.fromDate(recordedAt),
    };
  }

  factory SalesMetric.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesMetric(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dailySales: (data['dailySales'] as num?)?.toDouble() ?? 0,
      transactionCount: data['transactionCount'] ?? 0,
      avgTransactionValue:
          (data['avgTransactionValue'] as num?)?.toDouble() ?? 0,
      estimatedCogs: (data['estimatedCogs'] as num?)?.toDouble() ?? 0,
      estimatedGrossProfit:
          (data['estimatedGrossProfit'] as num?)?.toDouble() ?? 0,
      profitMargin: (data['profitMargin'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] ?? '',
      recordedAt:
          (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Franchise inventory item (stock tracking)
class FranchiseInventoryItem {
  final String id;
  final String storeId;
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final int safetyStock; // Minimum quantity to maintain
  final int averageDailyUsage;
  final double unitCost;
  final DateTime lastRestockDate;
  final DateTime lastCountDate;
  final String shelf;
  final String binLocation;

  FranchiseInventoryItem({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.safetyStock,
    required this.averageDailyUsage,
    required this.unitCost,
    required this.lastRestockDate,
    required this.lastCountDate,
    required this.shelf,
    required this.binLocation,
  });

  /// Calculate days of cover (how many days until stock runs out)
  int getDaysOfCover() {
    if (averageDailyUsage == 0) return 999;
    return (quantity / averageDailyUsage).ceil();
  }

  /// Check if stock is low
  bool isLowStock() {
    return quantity <= safetyStock;
  }

  /// Calculate reorder quantity
  int getReorderQuantity() {
    final daysToReorder = 7; // Reorder for 7 days
    return (averageDailyUsage * daysToReorder) + safetyStock;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'quantity': quantity,
      'safetyStock': safetyStock,
      'averageDailyUsage': averageDailyUsage,
      'unitCost': unitCost,
      'lastRestockDate': Timestamp.fromDate(lastRestockDate),
      'lastCountDate': Timestamp.fromDate(lastCountDate),
      'shelf': shelf,
      'binLocation': binLocation,
    };
  }

  factory FranchiseInventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FranchiseInventoryItem(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      sku: data['sku'] ?? '',
      quantity: data['quantity'] ?? 0,
      safetyStock: data['safetyStock'] ?? 10,
      averageDailyUsage: data['averageDailyUsage'] ?? 5,
      unitCost: (data['unitCost'] as num?)?.toDouble() ?? 0,
      lastRestockDate:
          (data['lastRestockDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastCountDate:
          (data['lastCountDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shelf: data['shelf'] ?? '',
      binLocation: data['binLocation'] ?? '',
    );
  }
}

/// Daily compliance checklist
class ComplianceChecklist {
  final String id;
  final String storeId;
  final DateTime date;
  final List<ComplianceItem> items;
  final int completedCount;
  final int totalCount;
  final double completionPercentage;
  final String status; // pending, in_progress, completed
  final String notes;
  final DateTime? submittedAt;
  final String? submittedBy;

  ComplianceChecklist({
    required this.id,
    required this.storeId,
    required this.date,
    required this.items,
    required this.completedCount,
    required this.totalCount,
    required this.completionPercentage,
    required this.status,
    required this.notes,
    this.submittedAt,
    this.submittedBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'date': Timestamp.fromDate(date),
      'items': items.map((item) => item.toFirestore()).toList(),
      'completedCount': completedCount,
      'totalCount': totalCount,
      'completionPercentage': completionPercentage,
      'status': status,
      'notes': notes,
      'submittedAt':
          submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'submittedBy': submittedBy,
    };
  }

  factory ComplianceChecklist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsData = data['items'] as List<dynamic>? ?? [];
    return ComplianceChecklist(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: itemsData
          .map((item) => ComplianceItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      completedCount: data['completedCount'] ?? 0,
      totalCount: data['totalCount'] ?? 0,
      completionPercentage:
          (data['completionPercentage'] as num?)?.toDouble() ?? 0,
      status: data['status'] ?? 'pending',
      notes: data['notes'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      submittedBy: data['submittedBy'],
    );
  }
}

/// Individual compliance item
class ComplianceItem {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final String? photoUrl;
  final String? notes;
  final DateTime? completedAt;
  final String? completedBy;
  final String
      category; // shelves, displays, cleanliness, pricing, union_card, etc.

  ComplianceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.photoUrl,
    this.notes,
    this.completedAt,
    this.completedBy,
    required this.category,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'photoUrl': photoUrl,
      'notes': notes,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'category': category,
    };
  }

  factory ComplianceItem.fromMap(Map<String, dynamic> data) {
    return ComplianceItem(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      photoUrl: data['photoUrl'],
      notes: data['notes'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedBy: data['completedBy'],
      category: data['category'] ?? 'general',
    );
  }
}

/// Compliance score (daily/weekly/monthly)
class ComplianceScore {
  final String id;
  final String storeId;
  final DateTime dateStart;
  final DateTime dateEnd;
  final String period; // daily, weekly, monthly
  final int totalChecklistsCompleted;
  final int totalChecklistsRequired;
  final double completionRate;
  final double complianceScore; // 0-100
  final List<String> violations; // Failed items
  final String trend; // up, down, stable
  final DateTime calculatedAt;

  ComplianceScore({
    required this.id,
    required this.storeId,
    required this.dateStart,
    required this.dateEnd,
    required this.period,
    required this.totalChecklistsCompleted,
    required this.totalChecklistsRequired,
    required this.completionRate,
    required this.complianceScore,
    required this.violations,
    required this.trend,
    required this.calculatedAt,
  });

  // Grade: A, B, C, D, F
  String getGrade() {
    if (complianceScore >= 90) return 'A';
    if (complianceScore >= 80) return 'B';
    if (complianceScore >= 70) return 'C';
    if (complianceScore >= 60) return 'D';
    return 'F';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'dateStart': Timestamp.fromDate(dateStart),
      'dateEnd': Timestamp.fromDate(dateEnd),
      'period': period,
      'totalChecklistsCompleted': totalChecklistsCompleted,
      'totalChecklistsRequired': totalChecklistsRequired,
      'completionRate': completionRate,
      'complianceScore': complianceScore,
      'violations': violations,
      'trend': trend,
      'calculatedAt': Timestamp.fromDate(calculatedAt),
    };
  }

  factory ComplianceScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplianceScore(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      dateStart: (data['dateStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateEnd: (data['dateEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      period: data['period'] ?? 'daily',
      totalChecklistsCompleted: data['totalChecklistsCompleted'] ?? 0,
      totalChecklistsRequired: data['totalChecklistsRequired'] ?? 0,
      completionRate: (data['completionRate'] as num?)?.toDouble() ?? 0,
      complianceScore: (data['complianceScore'] as num?)?.toDouble() ?? 0,
      violations: List<String>.from(data['violations'] ?? []),
      trend: data['trend'] ?? 'stable',
      calculatedAt:
          (data['calculatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
