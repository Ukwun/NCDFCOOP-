import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pricing/pricing_models.dart';
import '../services/pricing_engine_service.dart';

// ==================== SERVICE PROVIDERS ====================

/// Provider for PricingEngineService singleton
final pricingEngineServiceProvider = Provider<PricingEngineService>((ref) {
  return PricingEngineService();
});

// ==================== RETAIL PRICING PROVIDERS ====================

/// Calculate retail price for a product
///
/// Input:
/// - productId: Product identifier
/// - storeId: Store where customer is shopping
/// - customerId: Customer identifier (for customer-specific overrides)
/// - customerRole: Customer role (for role-based promotions)
///
/// Output: PriceCalculationResult with full breakdown
final retailPriceProvider = FutureProvider.family<
    PriceCalculationResult,
    ({
      String productId,
      String storeId,
      String customerId,
      String? customerRole,
    })>((ref, params) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.calculateRetailPrice(
    productId: params.productId,
    storeId: params.storeId,
    customerId: params.customerId,
    customerRole: params.customerRole,
  );
});

// ==================== WHOLESALE PRICING PROVIDERS ====================

/// Calculate wholesale price for a product
///
/// Input:
/// - productId: Product identifier
/// - franchiseId: Franchise/wholesale buyer identifier
/// - quantity: Order quantity (determines discount tier)
///
/// Output: PriceCalculationResult with tier breakdown
final wholesalePriceProvider = FutureProvider.family<
    PriceCalculationResult,
    ({
      String productId,
      String franchiseId,
      int quantity,
    })>((ref, params) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.calculateWholesalePrice(
    productId: params.productId,
    franchiseId: params.franchiseId,
    quantity: params.quantity,
  );
});

// ==================== CONTRACT PRICING PROVIDERS ====================

/// Calculate contract price for an institution
///
/// Input:
/// - productId: Product identifier
/// - institutionId: Institution customer identifier
///
/// Output: PriceCalculationResult with contract details
final contractPriceProvider = FutureProvider.family<PriceCalculationResult,
    ({String productId, String institutionId})>((ref, params) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.calculateContractPrice(
    productId: params.productId,
    institutionId: params.institutionId,
  );
});

// ==================== PRICE OVERRIDE PROVIDERS ====================

/// Get pending price override requests
///
/// Useful for admin dashboard to review and approve/reject overrides
final pendingPriceOverridesProvider =
    FutureProvider<List<PriceOverride>>((ref) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.getPendingPriceOverrides();
});

/// Get price audit log for a product
///
/// Useful for compliance reporting and price history tracking
final priceAuditLogProvider =
    FutureProvider.family<List<PriceAuditLog>, String>((ref, productId) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.getPriceAuditLog(productId);
});

// ==================== ASYNC ACTION HELPERS ====================

/// Async function to request a price override
final requestPriceOverrideFunctionProvider = FutureProvider.family<
    PriceOverride,
    ({
      String productId,
      String requestedPrice,
      String reason,
      String requestedBy,
      String? customerId,
      DateTime? expiryDate,
    })>((ref, params) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.requestPriceOverride(
    productId: params.productId,
    requestedPrice: params.requestedPrice,
    reason: params.reason,
    requestedBy: params.requestedBy,
    customerId: params.customerId,
    expiryDate: params.expiryDate,
  );
});

/// Async function to approve a price override
final approvePriceOverrideFunctionProvider = FutureProvider.family<
    void,
    ({
      String overrideId,
      String approvedBy,
    })>((ref, params) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.approvePriceOverride(
    overrideId: params.overrideId,
    approvedBy: params.approvedBy,
  );
});

/// Async function to reject a price override
final rejectPriceOverrideFunctionProvider = FutureProvider.family<
    void,
    ({
      String overrideId,
      String rejectionReason,
    })>((ref, params) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.rejectPriceOverride(
    overrideId: params.overrideId,
    rejectionReason: params.rejectionReason,
  );
});

/// Async function to set pricing rule
final setPricingRuleFunctionProvider = FutureProvider.family<
    void,
    ({
      String productId,
      double basePrice,
      PricingMode mode,
      String changedBy,
      String? storeId,
      String changeReason,
    })>((ref, params) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.setPricingRule(
    productId: params.productId,
    basePrice: params.basePrice,
    mode: params.mode,
    changedBy: params.changedBy,
    storeId: params.storeId,
    changeReason: params.changeReason,
  );
});

/// Async function to create promotion
final createPromotionFunctionProvider = FutureProvider.family<
    void,
    ({
      String name,
      double discountPercentage,
      DateTime startDate,
      DateTime? endDate,
      String? description,
      List<String>? applicableProductIds,
      List<String>? applicableRoles,
      String createdBy,
      int? maxRedemptions,
    })>((ref, params) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.createPromotion(
    name: params.name,
    discountPercentage: params.discountPercentage,
    startDate: params.startDate,
    endDate: params.endDate,
    description: params.description,
    applicableProductIds: params.applicableProductIds,
    applicableRoles: params.applicableRoles,
    createdBy: params.createdBy,
    maxRedemptions: params.maxRedemptions,
  );
});

/// Async function to set essential basket item
final setEssentialBasketItemFunctionProvider = FutureProvider.family<
    void,
    ({
      String productId,
      double maximumPrice,
      String category,
    })>((ref, params) async {
  final service = ref.watch(pricingEngineServiceProvider);
  return await service.setEssentialBasketItem(
    productId: params.productId,
    maximumPrice: params.maximumPrice,
    category: params.category,
  );
});
