import 'package:cloud_firestore/cloud_firestore.dart';

/// Inventory Location Model
/// Represents a warehouse or store location with stock
class InventoryLocation {
  final String locationId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type; // warehouse, store, distribution_center
  final bool isActive;

  InventoryLocation({
    required this.locationId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.isActive,
  });

  factory InventoryLocation.fromFirestore(Map<String, dynamic> data, String docId) {
    return InventoryLocation(
      locationId: docId,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'warehouse',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'isActive': isActive,
    };
  }
}

/// Inventory Item Model
/// Represents stock level at a specific location
class InventoryItem {
  final String inventoryId;
  final String productId;
  final String locationId;
  final int currentStock;
  final int reservedStock;
  final int safetyStockLevel;
  final int reorderPoint;
  final int reorderQuantity;
  final double costPerUnit;
  final DateTime lastCountDate;
  final DateTime lastRestockDate;
  final String status; // in_stock, low_stock, out_of_stock, discontinued
  final bool isTracked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
    required this.inventoryId,
    required this.productId,
    required this.locationId,
    required this.currentStock,
    required this.reservedStock,
    required this.safetyStockLevel,
    required this.reorderPoint,
    required this.reorderQuantity,
    required this.costPerUnit,
    required this.lastCountDate,
    required this.lastRestockDate,
    required this.status,
    required this.isTracked,
    required this.createdAt,
    required this.updatedAt,
  });

  int get availableStock => currentStock - reservedStock;

  bool get isLowStock => currentStock <= reorderPoint;

  bool get needsReorder => currentStock <= reorderPoint;

  factory InventoryItem.fromFirestore(Map<String, dynamic> data, String docId) {
    return InventoryItem(
      inventoryId: docId,
      productId: data['productId'] ?? '',
      locationId: data['locationId'] ?? '',
      currentStock: data['currentStock'] ?? 0,
      reservedStock: data['reservedStock'] ?? 0,
      safetyStockLevel: data['safetyStockLevel'] ?? 10,
      reorderPoint: data['reorderPoint'] ?? 20,
      reorderQuantity: data['reorderQuantity'] ?? 50,
      costPerUnit: (data['costPerUnit'] ?? 0.0).toDouble(),
      lastCountDate: (data['lastCountDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastRestockDate: (data['lastRestockDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'in_stock',
      isTracked: data['isTracked'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'locationId': locationId,
      'currentStock': currentStock,
      'reservedStock': reservedStock,
      'safetyStockLevel': safetyStockLevel,
      'reorderPoint': reorderPoint,
      'reorderQuantity': reorderQuantity,
      'costPerUnit': costPerUnit,
      'lastCountDate': lastCountDate,
      'lastRestockDate': lastRestockDate,
      'status': status,
      'isTracked': isTracked,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  InventoryItem copyWith({
    String? inventoryId,
    String? productId,
    String? locationId,
    int? currentStock,
    int? reservedStock,
    int? safetyStockLevel,
    int? reorderPoint,
    int? reorderQuantity,
    double? costPerUnit,
    DateTime? lastCountDate,
    DateTime? lastRestockDate,
    String? status,
    bool? isTracked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      inventoryId: inventoryId ?? this.inventoryId,
      productId: productId ?? this.productId,
      locationId: locationId ?? this.locationId,
      currentStock: currentStock ?? this.currentStock,
      reservedStock: reservedStock ?? this.reservedStock,
      safetyStockLevel: safetyStockLevel ?? this.safetyStockLevel,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      lastCountDate: lastCountDate ?? this.lastCountDate,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
      status: status ?? this.status,
      isTracked: isTracked ?? this.isTracked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Stock Transaction Model
/// Represents a stock movement (in/out)
class StockTransaction {
  final String transactionId;
  final String inventoryId;
  final String productId;
  final String locationId;
  final String type; // inbound, outbound, adjustment, return, damage
  final int quantity;
  final String reason;
  final String referenceType; // purchase_order, sales_order, internal_transfer, etc.
  final String? referenceId;
  final String createdBy;
  final DateTime createdAt;
  final String? notes;
  final bool isVerified;

  const StockTransaction({
    required this.transactionId,
    required this.inventoryId,
    required this.productId,
    required this.locationId,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.referenceType,
    this.referenceId,
    required this.createdBy,
    required this.createdAt,
    this.notes,
    required this.isVerified,
  });

  factory StockTransaction.fromFirestore(Map<String, dynamic> data, String docId) {
    return StockTransaction(
      transactionId: docId,
      inventoryId: data['inventoryId'] ?? '',
      productId: data['productId'] ?? '',
      locationId: data['locationId'] ?? '',
      type: data['type'] ?? '',
      quantity: data['quantity'] ?? 0,
      reason: data['reason'] ?? '',
      referenceType: data['referenceType'] ?? '',
      referenceId: data['referenceId'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inventoryId': inventoryId,
      'productId': productId,
      'locationId': locationId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'notes': notes,
      'isVerified': isVerified,
    };
  }
}

/// Inventory Alert Model
/// Represents alerts for low stock, excessive stock, etc.
class InventoryAlert {
  final String alertId;
  final String inventoryId;
  final String productId;
  final String locationId;
  final String alertType; // low_stock, overstock, reorder_needed, stockout
  final String severity; // info, warning, critical
  final String message;
  final int? currentStock;
  final int? threshold;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String status; // active, resolved
  final String? resolvedBy;

  const InventoryAlert({
    required this.alertId,
    required this.inventoryId,
    required this.productId,
    required this.locationId,
    required this.alertType,
    required this.severity,
    required this.message,
    this.currentStock,
    this.threshold,
    required this.createdAt,
    this.resolvedAt,
    required this.status,
    this.resolvedBy,
  });

  factory InventoryAlert.fromFirestore(Map<String, dynamic> data, String docId) {
    return InventoryAlert(
      alertId: docId,
      inventoryId: data['inventoryId'] ?? '',
      productId: data['productId'] ?? '',
      locationId: data['locationId'] ?? '',
      alertType: data['alertType'] ?? '',
      severity: data['severity'] ?? 'info',
      message: data['message'] ?? '',
      currentStock: data['currentStock'],
      threshold: data['threshold'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      resolvedBy: data['resolvedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inventoryId': inventoryId,
      'productId': productId,
      'locationId': locationId,
      'alertType': alertType,
      'severity': severity,
      'message': message,
      'currentStock': currentStock,
      'threshold': threshold,
      'createdAt': createdAt,
      'resolvedAt': resolvedAt,
      'status': status,
      'resolvedBy': resolvedBy,
    };
  }
}

/// Inventory Summary Model
/// Aggregate statistics for inventory
class InventorySummary {
  final String locationId;
  final int totalItems;
  final int totalStock;
  final int totalReserved;
  final int lowStockItems;
  final int outOfStockItems;
  final double totalValue;
  final DateTime lastUpdated;
  final Map<String, int> stockByCategory;

  const InventorySummary({
    required this.locationId,
    required this.totalItems,
    required this.totalStock,
    required this.totalReserved,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.totalValue,
    required this.lastUpdated,
    required this.stockByCategory,
  });

  factory InventorySummary.fromFirestore(Map<String, dynamic> data, String docId) {
    return InventorySummary(
      locationId: docId,
      totalItems: data['totalItems'] ?? 0,
      totalStock: data['totalStock'] ?? 0,
      totalReserved: data['totalReserved'] ?? 0,
      lowStockItems: data['lowStockItems'] ?? 0,
      outOfStockItems: data['outOfStockItems'] ?? 0,
      totalValue: (data['totalValue'] ?? 0.0).toDouble(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stockByCategory: Map<String, int>.from(data['stockByCategory'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalItems': totalItems,
      'totalStock': totalStock,
      'totalReserved': totalReserved,
      'lowStockItems': lowStockItems,
      'outOfStockItems': outOfStockItems,
      'totalValue': totalValue,
      'lastUpdated': lastUpdated,
      'stockByCategory': stockByCategory,
    };
  }
}

/// Reorder Suggestion Model
/// AI-generated reorder suggestions based on demand forecasting
class ReorderSuggestion {
  final String suggestionId;
  final String inventoryId;
  final String productId;
  final String locationId;
  final int suggestedQuantity;
  final int currentStock;
  final int forecastedDemand;
  final double forecastedDemandWeekly;
  final int daysToStockout;
  final String priority; // low, medium, high, urgent
  final double confidence;
  final String reason;
  final DateTime generatedAt;
  final bool isAccepted;

  const ReorderSuggestion({
    required this.suggestionId,
    required this.inventoryId,
    required this.productId,
    required this.locationId,
    required this.suggestedQuantity,
    required this.currentStock,
    required this.forecastedDemand,
    required this.forecastedDemandWeekly,
    required this.daysToStockout,
    required this.priority,
    required this.confidence,
    required this.reason,
    required this.generatedAt,
    required this.isAccepted,
  });

  factory ReorderSuggestion.fromFirestore(Map<String, dynamic> data, String docId) {
    return ReorderSuggestion(
      suggestionId: docId,
      inventoryId: data['inventoryId'] ?? '',
      productId: data['productId'] ?? '',
      locationId: data['locationId'] ?? '',
      suggestedQuantity: data['suggestedQuantity'] ?? 0,
      currentStock: data['currentStock'] ?? 0,
      forecastedDemand: data['forecastedDemand'] ?? 0,
      forecastedDemandWeekly: (data['forecastedDemandWeekly'] ?? 0.0).toDouble(),
      daysToStockout: data['daysToStockout'] ?? 999,
      priority: data['priority'] ?? 'low',
      confidence: (data['confidence'] ?? 0.5).toDouble(),
      reason: data['reason'] ?? '',
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAccepted: data['isAccepted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inventoryId': inventoryId,
      'productId': productId,
      'locationId': locationId,
      'suggestedQuantity': suggestedQuantity,
      'currentStock': currentStock,
      'forecastedDemand': forecastedDemand,
      'forecastedDemandWeekly': forecastedDemandWeekly,
      'daysToStockout': daysToStockout,
      'priority': priority,
      'confidence': confidence,
      'reason': reason,
      'generatedAt': generatedAt,
      'isAccepted': isAccepted,
    };
  }
}
