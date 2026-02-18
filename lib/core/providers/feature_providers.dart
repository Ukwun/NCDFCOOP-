import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/services/saved_items_service.dart';
import 'package:coop_commerce/core/services/franchise_inventory_service.dart';
import 'package:coop_commerce/core/services/compliance_scoring_service.dart';

// ===================== SERVICE PROVIDERS =====================

final savedItemsServiceProvider = Provider((ref) => SavedItemsService());

final franchiseInventoryServiceProvider =
    Provider((ref) => FranchiseInventoryService());

final complienceScoringServiceProvider =
    Provider((ref) => ComplianceScoringService());

// ===================== SAVED ITEMS PROVIDERS =====================

/// Stream of saved items for current user
final userSavedItemsProvider = StreamProvider.family<List<SavedItem>, String>(
  (ref, userId) {
    final service = ref.watch(savedItemsServiceProvider);
    return service.getSavedItemsStream(userId);
  },
);

/// Check if specific item is saved
final isItemSavedProvider =
    FutureProvider.family<bool, ({String userId, String productId})>(
  (ref, params) async {
    final service = ref.watch(savedItemsServiceProvider);
    return service.isItemSaved(
      userId: params.userId,
      productId: params.productId,
    );
  },
);

/// Count of saved items for user
final savedItemsCountProvider = FutureProvider.family<int, String>(
  (ref, userId) async {
    final service = ref.watch(savedItemsServiceProvider);
    return service.getSavedItemsCount(userId);
  },
);

/// Get saved items with pagination
final paginatedSavedItemsProvider = FutureProvider.family<SavedItemsPage,
    ({String userId, int page, int pageSize})>(
  (ref, params) async {
    final service = ref.watch(savedItemsServiceProvider);
    return service.getSavedItemsPaginated(
      userId: params.userId,
      page: params.page,
      pageSize: params.pageSize,
    );
  },
);

/// Get all saved collections for user
final userSavedCollectionsProvider =
    FutureProvider.family<List<SavedCollection>, String>(
  (ref, userId) async {
    final service = ref.watch(savedItemsServiceProvider);
    return service.getUserCollections(userId);
  },
);

// ===================== FRANCHISE INVENTORY PROVIDERS =====================

/// Stream of current inventory for a franchise store
final franchiseStoreInventoryProvider = FutureProvider.family<
    Map<String, InventoryItem>, ({String franchiseId, String storeId})>(
  (ref, params) async {
    final service = ref.watch(franchiseInventoryServiceProvider);
    return service.getCurrentInventory(params.franchiseId, params.storeId);
  },
);

/// Days-of-cover calculation
final franchiseDaysOfCoverProvider = FutureProvider.family<Map<String, int>,
    ({String franchiseId, String storeId, int lookbackDays})>(
  (ref, params) async {
    final service = ref.watch(franchiseInventoryServiceProvider);
    return service.calculateDaysOfCover(
      franchiseId: params.franchiseId,
      storeId: params.storeId,
      lookbackDays: params.lookbackDays,
    );
  },
);

/// Critical stock alerts for a franchise
final franchiseCriticalStockProvider = FutureProvider.family<
    List<CriticalStockAlert>,
    ({String franchiseId, String storeId, int threshold})>(
  (ref, params) async {
    final service = ref.watch(franchiseInventoryServiceProvider);
    return service.getCriticalStockAlerts(
      franchiseId: params.franchiseId,
      storeId: params.storeId,
      criticalThresholdDays: params.threshold,
    );
  },
);

/// Auto reorder suggestions
final franchiseReorderSuggestionsProvider = FutureProvider.family<
    List<AutoReorderSuggestion>, ({String franchiseId, String storeId})>(
  (ref, params) async {
    final service = ref.watch(franchiseInventoryServiceProvider);
    return service.getReorderSuggestions(
      franchiseId: params.franchiseId,
      storeId: params.storeId,
    );
  },
);

// ===================== COMPLIANCE SCORING PROVIDERS =====================

/// Current compliance score for a franchise
final franchiseComplianceScoreProvider =
    FutureProvider.family<ComplianceScore?, String>(
  (ref, franchiseId) async {
    final service = ref.watch(complienceScoringServiceProvider);
    return service.getComplianceScore(franchiseId);
  },
);

/// Compliance score history for a franchise
final franchiseComplianceHistoryProvider = FutureProvider.family<
    List<ComplianceScore>, ({String franchiseId, int limit})>(
  (ref, params) async {
    final service = ref.watch(complienceScoringServiceProvider);
    return service.getComplianceHistory(
      params.franchiseId,
      limit: params.limit,
    );
  },
);

/// Trigger compliance score calculation
final triggerComplianceCalculationProvider =
    FutureProvider.family<ComplianceScore?, String>(
  (ref, franchiseId) async {
    final service = ref.watch(complienceScoringServiceProvider);
    return service.calculateComplianceScore(franchiseId);
  },
);
