import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/models/inventory_models.dart';

/// Real-time Inventory Management Service
/// Manages stock levels, transactions, alerts, and forecasting
class InventoryManagementService {
  final FirebaseFirestore _firestore;

  InventoryManagementService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _inventoryCollection = 'inventory';
  static const String _transactionCollection = 'stock_transactions';
  static const String _alertsCollection = 'inventory_alerts';
  static const String _locationsCollection = 'warehouse_locations';
  static const String _summaryCollection = 'inventory_summary';
  static const String _suggestionsCollection = 'reorder_suggestions';

  // ==================== Location Management ====================

  /// Create a new warehouse/store location
  Future<InventoryLocation> createLocation(
    String name,
    String address,
    double latitude,
    double longitude,
    String type,
  ) async {
    try {
      debugPrint('Creating inventory location: $name');

      final docRef = _firestore.collection(_locationsCollection).doc();
      final location = InventoryLocation(
        locationId: docRef.id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        type: type,
        isActive: true,
      );

      await docRef.set(location.toFirestore());
      debugPrint('✅ Location created: ${location.locationId}');
      return location;
    } catch (e) {
      debugPrint('❌ Failed to create location: $e');
      rethrow;
    }
  }

  /// Get all active warehouse locations
  Future<List<InventoryLocation>> getActiveLocations() async {
    try {
      final snapshot = await _firestore
          .collection(_locationsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => InventoryLocation.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch locations: $e');
      return [];
    }
  }

  // ==================== Inventory Management ====================

  /// Add inventory for a product at a location
  Future<InventoryItem> addInventory(
    String productId,
    String locationId,
    int initialStock,
    int safetyStockLevel,
    int reorderPoint,
    int reorderQuantity,
    double costPerUnit,
  ) async {
    try {
      debugPrint(
        'Adding inventory: product=$productId, location=$locationId, stock=$initialStock',
      );

      final docRef = _firestore.collection(_inventoryCollection).doc();
      final now = DateTime.now();
      final inventory = InventoryItem(
        inventoryId: docRef.id,
        productId: productId,
        locationId: locationId,
        currentStock: initialStock,
        reservedStock: 0,
        safetyStockLevel: safetyStockLevel,
        reorderPoint: reorderPoint,
        reorderQuantity: reorderQuantity,
        costPerUnit: costPerUnit,
        lastCountDate: now,
        lastRestockDate: now,
        status: initialStock > reorderPoint ? 'in_stock' : 'low_stock',
        isTracked: true,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(inventory.toFirestore());
      await _createAlert(
        inventory.inventoryId,
        inventory.productId,
        inventory.locationId,
        'inventory_created',
        'info',
        'Inventory initialized',
        initialStock,
        safetyStockLevel,
      );

      debugPrint('✅ Inventory created: ${inventory.inventoryId}');
      return inventory;
    } catch (e) {
      debugPrint('❌ Failed to add inventory: $e');
      rethrow;
    }
  }

  /// Get inventory item by ID
  Future<InventoryItem?> getInventoryItem(String inventoryId) async {
    try {
      final doc = await _firestore
          .collection(_inventoryCollection)
          .doc(inventoryId)
          .get();

      if (!doc.exists) return null;
      return InventoryItem.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('❌ Failed to fetch inventory: $e');
      return null;
    }
  }

  /// Get all inventory for a product across locations
  Future<Map<String, InventoryItem>> getProductInventory(String productId) async {
    try {
      final snapshot = await _firestore
          .collection(_inventoryCollection)
          .where('productId', isEqualTo: productId)
          .get();

      final Map<String, InventoryItem> inventory = {};
      for (var doc in snapshot.docs) {
        final item = InventoryItem.fromFirestore(doc.data(), doc.id);
        inventory[doc.id] = item;
      }
      return inventory;
    } catch (e) {
      debugPrint('❌ Failed to fetch product inventory: $e');
      return {};
    }
  }

  /// Get inventory summary for a location
  Future<InventorySummary?> getLocationSummary(String locationId) async {
    try {
      final doc = await _firestore
          .collection(_summaryCollection)
          .doc(locationId)
          .get();

      if (!doc.exists) return null;
      return InventorySummary.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('❌ Failed to fetch location summary: $e');
      return null;
    }
  }

  // ==================== Stock Transactions ====================

  /// Record a stock transaction (inbound/outbound)
  Future<StockTransaction> recordTransaction(
    String inventoryId,
    String productId,
    String locationId,
    String type,
    int quantity,
    String reason,
    String referenceType,
    String? referenceId,
    String createdBy,
    String? notes,
  ) async {
    try {
      debugPrint(
        'Recording transaction: type=$type, product=$productId, qty=$quantity',
      );

      final inventory = await getInventoryItem(inventoryId);
      if (inventory == null) {
        throw Exception('Inventory item not found');
      }

      // Validate transaction
      if (type == 'outbound' && inventory.availableStock < quantity) {
        debugPrint(
          '⚠️ Insufficient stock: available=${inventory.availableStock}, requested=$quantity',
        );
        throw Exception('Insufficient stock available');
      }

      // Create transaction record
      final docRef = _firestore.collection(_transactionCollection).doc();
      final transaction = StockTransaction(
        transactionId: docRef.id,
        inventoryId: inventoryId,
        productId: productId,
        locationId: locationId,
        type: type,
        quantity: quantity,
        reason: reason,
        referenceType: referenceType,
        referenceId: referenceId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        notes: notes,
        isVerified: false,
      );

      await docRef.set(transaction.toFirestore());

      // Update inventory
      final newCurrentStock = type == 'inbound'
          ? inventory.currentStock + quantity
          : inventory.currentStock - quantity;

      final newStatus = newCurrentStock == 0
          ? 'out_of_stock'
          : newCurrentStock <= inventory.reorderPoint
              ? 'low_stock'
              : 'in_stock';

      await _firestore.collection(_inventoryCollection).doc(inventoryId).update({
        'currentStock': newCurrentStock,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (type == 'inbound') 'lastRestockDate': FieldValue.serverTimestamp(),
      });

      // Check for alerts
      if (newStatus == 'low_stock' || newStatus == 'out_of_stock') {
        await _createAlert(
          inventoryId,
          productId,
          locationId,
          newStatus == 'out_of_stock' ? 'stockout' : 'low_stock',
          newStatus == 'out_of_stock' ? 'critical' : 'warning',
          'Stock level changed: $newCurrentStock units',
          newCurrentStock,
          inventory.reorderPoint,
        );
      }

      debugPrint('✅ Transaction recorded: ${transaction.transactionId}');
      return transaction;
    } catch (e) {
      debugPrint('❌ Failed to record transaction: $e');
      rethrow;
    }
  }

  /// Get transaction history for an inventory item
  Future<List<StockTransaction>> getTransactionHistory(
    String inventoryId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionCollection)
          .where('inventoryId', isEqualTo: inventoryId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => StockTransaction.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch transaction history: $e');
      return [];
    }
  }

  // ==================== Alerts ====================

  /// Create an inventory alert
  Future<InventoryAlert> _createAlert(
    String inventoryId,
    String productId,
    String locationId,
    String alertType,
    String severity,
    String message,
    int? currentStock,
    int? threshold,
  ) async {
    try {
      final docRef = _firestore.collection(_alertsCollection).doc();
      final alert = InventoryAlert(
        alertId: docRef.id,
        inventoryId: inventoryId,
        productId: productId,
        locationId: locationId,
        alertType: alertType,
        severity: severity,
        message: message,
        currentStock: currentStock,
        threshold: threshold,
        createdAt: DateTime.now(),
        status: 'active',
      );

      await docRef.set(alert.toFirestore());
      debugPrint('✅ Alert created: ${alert.alertId} ($alertType)');
      return alert;
    } catch (e) {
      debugPrint('❌ Failed to create alert: $e');
      rethrow;
    }
  }

  /// Get active alerts for a location
  Future<List<InventoryAlert>> getLocationAlerts(
    String locationId, {
    String? severity,
  }) async {
    try {
      var query = _firestore
          .collection(_alertsCollection)
          .where('locationId', isEqualTo: locationId)
          .where('status', isEqualTo: 'active');

      if (severity != null) {
        query = query.where('severity', isEqualTo: severity);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => InventoryAlert.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch location alerts: $e');
      return [];
    }
  }

  /// Resolve an alert
  Future<void> resolveAlert(
    String alertId,
    String resolvedBy,
  ) async {
    try {
      debugPrint('Resolving alert: $alertId');
      await _firestore.collection(_alertsCollection).doc(alertId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': resolvedBy,
      });
      debugPrint('✅ Alert resolved: $alertId');
    } catch (e) {
      debugPrint('❌ Failed to resolve alert: $e');
      rethrow;
    }
  }

  // ==================== Reorder Management ====================

  /// Create a reorder suggestion based on demand forecasting
  Future<ReorderSuggestion> createReorderSuggestion(
    String inventoryId,
    String productId,
    String locationId,
    int currentStock,
    int forecastedDemand,
    double forecastedDemandWeekly,
    int daysToStockout,
  ) async {
    try {
      debugPrint(
        'Creating reorder suggestion: product=$productId, daysToStockout=$daysToStockout',
      );

      final inventory = await getInventoryItem(inventoryId);
      if (inventory == null) {
        throw Exception('Inventory item not found');
      }

      // Calculate suggested quantity
      final weeklyDemand = forecastedDemandWeekly.toInt();
      final leadTimeDays = 7; // Assume 7-day lead time
      final leadTimeStock = weeklyDemand * (leadTimeDays ~/ 7);
      final suggestedQuantity = max(
        inventory.reorderQuantity,
        max(leadTimeStock, forecastedDemand) - currentStock,
      );

      // Determine priority
      late String priority;
      if (daysToStockout <= 3) {
        priority = 'urgent';
      } else if (daysToStockout <= 7) {
        priority = 'high';
      } else if (daysToStockout <= 14) {
        priority = 'medium';
      } else {
        priority = 'low';
      }

      final docRef = _firestore.collection(_suggestionsCollection).doc();
      final suggestion = ReorderSuggestion(
        suggestionId: docRef.id,
        inventoryId: inventoryId,
        productId: productId,
        locationId: locationId,
        suggestedQuantity: suggestedQuantity,
        currentStock: currentStock,
        forecastedDemand: forecastedDemand,
        forecastedDemandWeekly: forecastedDemandWeekly,
        daysToStockout: daysToStockout,
        priority: priority,
        confidence: _calculateConfidence(forecastedDemand),
        reason:
            'Forecasted demand: $forecastedDemand units, $daysToStockout days to stockout',
        generatedAt: DateTime.now(),
        isAccepted: false,
      );

      await docRef.set(suggestion.toFirestore());
      debugPrint('✅ Reorder suggestion created: ${suggestion.suggestionId}');
      return suggestion;
    } catch (e) {
      debugPrint('❌ Failed to create reorder suggestion: $e');
      rethrow;
    }
  }

  /// Get pending reorder suggestions for a location
  Future<List<ReorderSuggestion>> getLocationReorderSuggestions(
    String locationId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_suggestionsCollection)
          .where('locationId', isEqualTo: locationId)
          .where('isAccepted', isEqualTo: false)
          .orderBy('generatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReorderSuggestion.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch reorder suggestions: $e');
      return [];
    }
  }

  /// Accept a reorder suggestion and create PO
  Future<void> acceptReorderSuggestion(String suggestionId) async {
    try {
      debugPrint('Accepting reorder suggestion: $suggestionId');
      await _firestore
          .collection(_suggestionsCollection)
          .doc(suggestionId)
          .update({
        'isAccepted': true,
      });
      debugPrint('✅ Reorder suggestion accepted: $suggestionId');
    } catch (e) {
      debugPrint('❌ Failed to accept reorder suggestion: $e');
      rethrow;
    }
  }

  // ==================== Helpers ====================

  double _calculateConfidence(int forecastedDemand) {
    // Simple confidence calculation based on recent accuracy
    // In production, this would use machine learning models
    return (forecastedDemand > 0 ? 0.8 : 0.5).clamp(0.0, 1.0);
  }

  int max(int a, int b) => a > b ? a : b;
}
