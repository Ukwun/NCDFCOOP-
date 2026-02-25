import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/services/inventory_management_service.dart';
import 'package:coop_commerce/models/inventory_models.dart';

// ==================== Providers ====================

/// Inventory Management Service Provider
final inventoryServiceProvider = Provider((ref) {
  return InventoryManagementService();
});

/// Warehouse Locations Provider
final warehouseLocationsProvider = FutureProvider((ref) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getActiveLocations();
});

/// Inventory Item Provider
/// Watch specific inventory by ID
final inventoryItemProvider =
    FutureProvider.family<InventoryItem?, String>((ref, inventoryId) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getInventoryItem(inventoryId);
});

/// Product Inventory Provider
/// Get all inventory for a specific product across locations
final productInventoryProvider =
    FutureProvider.family<Map<String, InventoryItem>, String>(
        (ref, productId) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getProductInventory(productId);
});

/// Location Inventory Summary Provider
final locationSummaryProvider =
    FutureProvider.family<InventorySummary?, String>((ref, locationId) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getLocationSummary(locationId);
});

/// Transaction History Provider
final transactionHistoryProvider = FutureProvider.family<List<StockTransaction>,
    ({String inventoryId, int limit})>((ref, params) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getTransactionHistory(params.inventoryId, limit: params.limit);
});

/// Location Alerts Provider
final locationAlertsProvider = FutureProvider.family<
    List<InventoryAlert>,
    ({
      String locationId,
      String? severity,
    })>((ref, params) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getLocationAlerts(params.locationId,
      severity: params.severity);
});

/// Critical Alerts Only Provider
final criticalAlertsProvider =
    FutureProvider.family<List<InventoryAlert>, String>(
        (ref, locationId) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getLocationAlerts(locationId, severity: 'critical');
});

/// Reorder Suggestions Provider
final reorderSuggestionsProvider =
    FutureProvider.family<List<ReorderSuggestion>, String>((
  ref,
  locationId,
) async {
  final service = ref.watch(inventoryServiceProvider);
  return service.getLocationReorderSuggestions(locationId);
});

// ==================== Actions Provider ====================

/// Inventory Actions Notifier
class InventoryActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Record a stock inbound transaction
  Future<void> recordInbound(
    String inventoryId,
    String productId,
    String locationId,
    int quantity,
    String reason,
    String? poNumber,
    String createdBy, {
    String? notes,
  }) async {
    final service = ref.read(inventoryServiceProvider);
    await service.recordTransaction(
      inventoryId,
      productId,
      locationId,
      'inbound',
      quantity,
      reason,
      'purchase_order',
      poNumber,
      createdBy,
      notes,
    );
    // Refresh affected providers
    ref.invalidate(productInventoryProvider(productId));
    ref.invalidate(locationSummaryProvider(locationId));
    ref.invalidate(transactionHistoryProvider(
      (inventoryId: inventoryId, limit: 100),
    ));
    ref.invalidate(
        locationAlertsProvider((locationId: locationId, severity: null)));
  }

  /// Record a stock outbound transaction
  Future<void> recordOutbound(
    String inventoryId,
    String productId,
    String locationId,
    int quantity,
    String reason,
    String? orderId,
    String createdBy, {
    String? notes,
  }) async {
    final service = ref.read(inventoryServiceProvider);
    await service.recordTransaction(
      inventoryId,
      productId,
      locationId,
      'outbound',
      quantity,
      reason,
      'sales_order',
      orderId,
      createdBy,
      notes,
    );
    // Refresh affected providers
    ref.invalidate(productInventoryProvider(productId));
    ref.invalidate(locationSummaryProvider(locationId));
    ref.invalidate(transactionHistoryProvider(
      (inventoryId: inventoryId, limit: 100),
    ));
  }

  /// Record a stock adjustment
  Future<void> recordAdjustment(
    String inventoryId,
    String productId,
    String locationId,
    int adjustmentQuantity,
    String reason,
    String createdBy, {
    String? notes,
  }) async {
    final service = ref.read(inventoryServiceProvider);
    await service.recordTransaction(
      inventoryId,
      productId,
      locationId,
      'adjustment',
      adjustmentQuantity.abs(),
      reason,
      'inventory_adjustment',
      null,
      createdBy,
      notes,
    );
    // Refresh affected providers
    ref.invalidate(productInventoryProvider(productId));
    ref.invalidate(locationSummaryProvider(locationId));
    ref.invalidate(transactionHistoryProvider(
      (inventoryId: inventoryId, limit: 100),
    ));
  }

  /// Record a damage/loss
  Future<void> recordDamage(
    String inventoryId,
    String productId,
    String locationId,
    int quantity,
    String reason,
    String createdBy, {
    String? notes,
  }) async {
    final service = ref.read(inventoryServiceProvider);
    await service.recordTransaction(
      inventoryId,
      productId,
      locationId,
      'damage',
      quantity,
      reason,
      'damage_report',
      null,
      createdBy,
      notes,
    );
    // Refresh affected providers
    ref.invalidate(productInventoryProvider(productId));
    ref.invalidate(locationSummaryProvider(locationId));
  }

  /// Resolve an inventory alert
  Future<void> resolveAlert(String alertId, String resolvedBy) async {
    final service = ref.read(inventoryServiceProvider);
    await service.resolveAlert(alertId, resolvedBy);
    // Refresh alerts
    ref.invalidate(locationAlertsProvider(
      (locationId: '', severity: null),
    ));
  }

  /// Create reorder suggestion
  Future<void> createReorderSuggestion(
    String inventoryId,
    String productId,
    String locationId,
    int currentStock,
    int forecastedDemand,
    double forecastedDemandWeekly,
    int daysToStockout,
  ) async {
    final service = ref.read(inventoryServiceProvider);
    await service.createReorderSuggestion(
      inventoryId,
      productId,
      locationId,
      currentStock,
      forecastedDemand,
      forecastedDemandWeekly,
      daysToStockout,
    );
    // Refresh suggestions
    ref.invalidate(reorderSuggestionsProvider(locationId));
  }

  /// Accept a reorder suggestion
  Future<void> acceptReorderSuggestion(String suggestionId) async {
    final service = ref.read(inventoryServiceProvider);
    await service.acceptReorderSuggestion(suggestionId);
    // Refresh suggestions
    ref.invalidate(reorderSuggestionsProvider(''));
  }
}

final inventoryActionsProvider =
    NotifierProvider<InventoryActionsNotifier, void>(
  () => InventoryActionsNotifier(),
);

// ==================== Computed Providers ====================

/// Get all low stock items across locations
final lowStockItemsProvider = FutureProvider((ref) async {
  // This would typically query all inventory items with low stock status
  // Implementation depends on your specific needs
  return <InventoryItem>[];
});

/// Get dashboard statistics
final inventoryDashboardStatsProvider = FutureProvider((ref) async {
  final locations = await ref.watch(warehouseLocationsProvider.future);

  double totalInventoryValue = 0;
  int totalItems = 0;
  int lowStockCount = 0;
  int criticalAlertCount = 0;

  for (var location in locations) {
    final summary = await ref.read(
      locationSummaryProvider(location.locationId).future,
    );
    if (summary != null) {
      totalInventoryValue += summary.totalValue;
      totalItems += summary.totalItems;
      lowStockCount += summary.lowStockItems;
    }

    final alerts = await ref.read(
      criticalAlertsProvider(location.locationId).future,
    );
    criticalAlertCount += alerts.length;
  }

  return InventoryDashboardStats(
    totalValue: totalInventoryValue,
    totalItems: totalItems,
    lowStockItems: lowStockCount,
    criticalAlerts: criticalAlertCount,
  );
});

/// Dashboard Statistics Model
class InventoryDashboardStats {
  final double totalValue;
  final int totalItems;
  final int lowStockItems;
  final int criticalAlerts;

  InventoryDashboardStats({
    required this.totalValue,
    required this.totalItems,
    required this.lowStockItems,
    required this.criticalAlerts,
  });
}
