import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/pricing/pricing_models.dart';

/// Pricing Engine Service - Core pricing calculation system
///
/// Handles all pricing modes:
/// - Retail pricing (base price by store)
/// - Wholesale pricing (quantity-based discounts)
/// - Contract pricing (institution-specific prices)
/// - Promotions (time-limited discounts)
/// - Essential basket ceilings (price caps on essentials)
/// - Price overrides (approval-based manual overrides)
///
/// Maintains comprehensive audit trail of all pricing changes.
class PricingEngineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _pricingRulesCollection = 'pricing_rules';
  static const String _contractPricingCollection = 'contract_pricing';
  static const String _promotionsCollection = 'promotions';
  static const String _essentialBasketCollection = 'essential_basket_items';
  static const String _priceOverridesCollection = 'price_overrides';
  static const String _priceAuditLogCollection = 'price_audit_log';

  // Cache for frequently accessed data
  final Map<String, PricingRule> _pricingRuleCache = {};
  final Map<String, Promotion> _promotionCache = {};

  /// Calculate retail price for a product in a specific store
  ///
  /// Returns: PriceCalculationResult with breakdown
  ///
  /// Process:
  /// 1. Get base price for store
  /// 2. Apply active promotions
  /// 3. Check essential basket ceiling
  /// 4. Check for active price overrides
  /// 5. Return calculation with components
  Future<PriceCalculationResult> calculateRetailPrice({
    required String productId,
    required String storeId,
    required String customerId,
    String? customerRole, // for role-based promotions
  }) async {
    try {
      final components = <PriceComponent>[];

      // 1. Get base price for this store
      final basePriceQuery = await _firestore
          .collection(_pricingRulesCollection)
          .where('productId', isEqualTo: productId)
          .where('storeId', isEqualTo: storeId)
          .where('mode', isEqualTo: 'retail')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      double basePrice = 0.0;
      if (basePriceQuery.docs.isNotEmpty) {
        basePrice =
            (basePriceQuery.docs.first.data()['basePrice'] ?? 0.0).toDouble();
      } else {
        // Fall back to system-wide price
        final systemPrice = await _firestore
            .collection(_pricingRulesCollection)
            .where('productId', isEqualTo: productId)
            .where('mode', isEqualTo: 'retail')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (systemPrice.docs.isNotEmpty) {
          basePrice =
              (systemPrice.docs.first.data()['basePrice'] ?? 0.0).toDouble();
        }
      }

      components.add(PriceComponent(
          name: 'Base Price ($storeId)',
          value: '\$${basePrice.toStringAsFixed(2)}'));

      // 2. Apply promotions
      double discountAmount = 0.0;
      double discountPercentage = 0.0;

      final activePromotions = await _getActivePromotions();
      for (final promo in activePromotions) {
        if (promo.appliesToProduct(productId) &&
            (customerRole == null || promo.appliesToRole(customerRole))) {
          final promoDiscount = basePrice * (promo.discountPercentage / 100);
          if (promoDiscount > discountAmount) {
            discountAmount = promoDiscount;
            discountPercentage = promo.discountPercentage;
            components.add(PriceComponent(
              name: 'Promotion',
              value:
                  '${promo.name} (-${promo.discountPercentage.toStringAsFixed(1)}%)',
            ));
          }
        }
      }

      var finalPrice = basePrice - discountAmount;

      // 3. Check essential basket ceiling
      var hadEssentialBasketCap = false;
      final essentialCeiling = await _getEssentialBasketCeiling(productId);
      if (essentialCeiling != null && finalPrice > essentialCeiling) {
        finalPrice = essentialCeiling;
        hadEssentialBasketCap = true;
        components.add(PriceComponent(
          name: 'Essential Basket Cap',
          value: 'Capped at \$${essentialCeiling.toStringAsFixed(2)}',
        ));
      }

      // 4. Check for active price overrides (customer-specific)
      var hadPriceOverride = false;
      final override = await _getValidPriceOverride(productId, customerId);
      if (override != null) {
        finalPrice = override.requestedPrice;
        hadPriceOverride = true;
        components.add(PriceComponent(
          name: 'Price Override',
          value:
              'Manual override: \$${override.requestedPrice.toStringAsFixed(2)}',
        ));
      }

      return PriceCalculationResult(
        basePrice: basePrice,
        discountAmount: discountAmount,
        discountPercentage: discountPercentage,
        finalPrice: finalPrice,
        components: components,
        hadEssentialBasketCap: hadEssentialBasketCap,
        hadPriceOverride: hadPriceOverride,
      );
    } catch (e) {
      print('Error calculating retail price: $e');
      rethrow;
    }
  }

  /// Calculate wholesale price for a product
  ///
  /// Applies quantity-based discount tiers:
  /// - 1-99 units: 10% discount
  /// - 100-499 units: 20% discount
  /// - 500+ units: 30% discount
  ///
  /// Returns: PriceCalculationResult with tier breakdown
  Future<PriceCalculationResult> calculateWholesalePrice({
    required String productId,
    required String franchiseId,
    required int quantity,
  }) async {
    try {
      final components = <PriceComponent>[];

      // Get base price
      final basePriceQuery = await _firestore
          .collection(_pricingRulesCollection)
          .where('productId', isEqualTo: productId)
          .where('mode', isEqualTo: 'wholesale')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      double basePrice = 0.0;
      if (basePriceQuery.docs.isNotEmpty) {
        basePrice =
            (basePriceQuery.docs.first.data()['basePrice'] ?? 0.0).toDouble();
      }

      components.add(PriceComponent(
        name: 'Base Price (Wholesale)',
        value: '\$${basePrice.toStringAsFixed(2)}',
      ));

      // Apply quantity-based tier discount
      double discountPercentage = _getWholesaleDiscountTier(quantity);
      double discountAmount = basePrice * (discountPercentage / 100);
      double finalPrice = basePrice - discountAmount;

      components.add(PriceComponent(
        name: 'Wholesale Tier',
        value:
            'Qty: $quantity units (-${discountPercentage.toStringAsFixed(1)}%)',
      ));

      return PriceCalculationResult(
        basePrice: basePrice,
        discountAmount: discountAmount,
        discountPercentage: discountPercentage,
        finalPrice: finalPrice,
        components: components,
      );
    } catch (e) {
      print('Error calculating wholesale price: $e');
      rethrow;
    }
  }

  /// Calculate contract price for an institution
  ///
  /// Returns: Negotiated price from contract agreement
  /// Returns: PriceCalculationResult with contract details
  Future<PriceCalculationResult> calculateContractPrice({
    required String productId,
    required String institutionId,
  }) async {
    try {
      final components = <PriceComponent>[];

      // Get contract pricing
      final contractQuery = await _firestore
          .collection(_contractPricingCollection)
          .where('productId', isEqualTo: productId)
          .where('institutionId', isEqualTo: institutionId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (contractQuery.docs.isEmpty) {
        throw Exception(
            'No active contract found for institution $institutionId');
      }

      final contractData = contractQuery.docs.first.data();
      final contractPrice = (contractData['contractPrice'] ?? 0.0).toDouble();

      components.add(PriceComponent(
        name: 'Contract Price',
        value: '\$${contractPrice.toStringAsFixed(2)}',
      ));

      if (contractData['casePackSize'] != null) {
        components.add(PriceComponent(
          name: 'Case Pack Size',
          value: '${contractData['casePackSize']} units per case',
        ));
      }

      if (contractData['minimumOrderQuantity'] != null) {
        components.add(PriceComponent(
          name: 'Minimum Order Quantity',
          value: '${contractData['minimumOrderQuantity']} units',
        ));
      }

      return PriceCalculationResult(
        basePrice: contractPrice,
        discountAmount: 0.0,
        discountPercentage: 0.0,
        finalPrice: contractPrice,
        components: components,
      );
    } catch (e) {
      print('Error calculating contract price: $e');
      rethrow;
    }
  }

  /// Request a price override (requires approval)
  ///
  /// Use case: Store manager needs special pricing for VIP customer
  Future<PriceOverride> requestPriceOverride({
    required String productId,
    required String requestedPrice,
    required String reason,
    required String requestedBy,
    String? customerId,
    DateTime? expiryDate,
  }) async {
    try {
      final override = PriceOverride(
        id: const Uuid().v4(),
        productId: productId,
        customerId: customerId,
        requestedPrice: double.parse(requestedPrice),
        reason: reason,
        status: PriceOverrideStatus.pending,
        requestedBy: requestedBy,
        requestedAt: DateTime.now(),
        expiryDate: expiryDate,
      );

      await _firestore
          .collection(_priceOverridesCollection)
          .doc(override.id)
          .set(override.toMap());

      return override;
    } catch (e) {
      print('Error requesting price override: $e');
      rethrow;
    }
  }

  /// Approve a pending price override
  Future<void> approvePriceOverride({
    required String overrideId,
    required String approvedBy,
  }) async {
    try {
      await _firestore
          .collection(_priceOverridesCollection)
          .doc(overrideId)
          .update({
        'status': PriceOverrideStatus.approved.name,
        'approvedBy': approvedBy,
        'approvedAt': DateTime.now(),
      });
    } catch (e) {
      print('Error approving price override: $e');
      rethrow;
    }
  }

  /// Reject a pending price override
  Future<void> rejectPriceOverride({
    required String overrideId,
    required String rejectionReason,
  }) async {
    try {
      await _firestore
          .collection(_priceOverridesCollection)
          .doc(overrideId)
          .update({
        'status': PriceOverrideStatus.rejected.name,
        'rejectionReason': rejectionReason,
      });
    } catch (e) {
      print('Error rejecting price override: $e');
      rethrow;
    }
  }

  /// Create or update a pricing rule
  ///
  /// Logs audit trail of price change
  Future<void> setPricingRule({
    required String productId,
    required double basePrice,
    required PricingMode mode,
    required String changedBy,
    String? storeId,
    required String changeReason,
  }) async {
    try {
      // Get previous price for audit
      double previousPrice = 0.0;
      final query = await _firestore
          .collection(_pricingRulesCollection)
          .where('productId', isEqualTo: productId)
          .where('mode', isEqualTo: mode.name)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        previousPrice =
            (query.docs.first.data()['basePrice'] ?? 0.0).toDouble();
      }

      // Create new pricing rule
      final rule = PricingRule(
        id: const Uuid().v4(),
        productId: productId,
        storeId: storeId,
        basePrice: basePrice,
        mode: mode,
        effectiveDate: DateTime.now(),
        isActive: true,
        createdBy: changedBy,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_pricingRulesCollection)
          .doc(rule.id)
          .set(rule.toMap());

      // Log audit trail
      await _logPriceAudit(
        productId: productId,
        previousPrice: previousPrice,
        newPrice: basePrice,
        changeReason: changeReason,
        changedBy: changedBy,
        pricingMode: mode,
        storeId: storeId,
      );
    } catch (e) {
      print('Error setting pricing rule: $e');
      rethrow;
    }
  }

  /// Create a promotion
  Future<void> createPromotion({
    required String name,
    required double discountPercentage,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    List<String>? applicableProductIds,
    List<String>? applicableRoles,
    required String createdBy,
    int? maxRedemptions,
  }) async {
    try {
      final promotion = Promotion(
        id: const Uuid().v4(),
        name: name,
        description: description,
        discountPercentage: discountPercentage,
        applicableProductIds: applicableProductIds,
        applicableRoles: applicableRoles,
        startDate: startDate,
        endDate: endDate,
        maxRedemptions: maxRedemptions,
        isActive: true,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_promotionsCollection)
          .doc(promotion.id)
          .set(promotion.toMap());

      _promotionCache.clear(); // Invalidate cache
    } catch (e) {
      print('Error creating promotion: $e');
      rethrow;
    }
  }

  /// Set an essential basket item (price ceiling)
  Future<void> setEssentialBasketItem({
    required String productId,
    required double maximumPrice,
    required String category,
  }) async {
    try {
      final item = EssentialBasketItem(
        id: const Uuid().v4(),
        productId: productId,
        maximumPrice: maximumPrice,
        category: category,
        effectiveDate: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_essentialBasketCollection)
          .doc(item.id)
          .set(item.toMap());
    } catch (e) {
      print('Error setting essential basket item: $e');
      rethrow;
    }
  }

  /// Get pending price override requests (for approval)
  Future<List<PriceOverride>> getPendingPriceOverrides() async {
    try {
      final query = await _firestore
          .collection(_priceOverridesCollection)
          .where('status', isEqualTo: PriceOverrideStatus.pending.name)
          .orderBy('requestedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => PriceOverride.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting pending price overrides: $e');
      rethrow;
    }
  }

  /// Get price audit log for a product
  Future<List<PriceAuditLog>> getPriceAuditLog(String productId) async {
    try {
      final query = await _firestore
          .collection(_priceAuditLogCollection)
          .where('productId', isEqualTo: productId)
          .orderBy('changedAt', descending: true)
          .limit(50) // Last 50 changes
          .get();

      return query.docs
          .map((doc) => PriceAuditLog.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting price audit log: $e');
      rethrow;
    }
  }

  // ==================== PRIVATE HELPERS ====================

  /// Get wholesale discount percentage based on quantity tier
  double _getWholesaleDiscountTier(int quantity) {
    if (quantity >= 500) return 30.0; // 30% discount for bulk orders
    if (quantity >= 100) return 20.0; // 20% discount for large orders
    if (quantity >= 50) return 15.0; // 15% discount for medium orders
    return 10.0; // 10% base wholesale discount
  }

  /// Get active promotions from cache or Firestore
  Future<List<Promotion>> _getActivePromotions() async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection(_promotionsCollection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .get();

      List<Promotion> promotions = query.docs
          .map((doc) => Promotion.fromMap(doc.data()))
          .where((p) => p.endDate == null || p.endDate!.isAfter(now))
          .toList();

      return promotions;
    } catch (e) {
      print('Error getting active promotions: $e');
      return [];
    }
  }

  /// Get essential basket ceiling for a product
  Future<double?> _getEssentialBasketCeiling(String productId) async {
    try {
      final query = await _firestore
          .collection(_essentialBasketCollection)
          .where('productId', isEqualTo: productId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final item = EssentialBasketItem.fromMap(query.docs.first.data());
        if (item.isValid()) {
          return item.maximumPrice;
        }
      }
      return null;
    } catch (e) {
      print('Error getting essential basket ceiling: $e');
      return null;
    }
  }

  /// Get a valid price override for a customer
  Future<PriceOverride?> _getValidPriceOverride(
      String productId, String customerId) async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection(_priceOverridesCollection)
          .where('productId', isEqualTo: productId)
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: PriceOverrideStatus.approved.name)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final override = PriceOverride.fromMap(query.docs.first.data());
        if (override.isValidAndApproved()) {
          return override;
        }
      }
      return null;
    } catch (e) {
      print('Error getting price override: $e');
      return null;
    }
  }

  /// Log a price change to audit trail
  Future<void> _logPriceAudit({
    required String productId,
    required double previousPrice,
    required double newPrice,
    required String changeReason,
    required String changedBy,
    required PricingMode pricingMode,
    String? storeId,
  }) async {
    try {
      final log = PriceAuditLog(
        id: const Uuid().v4(),
        productId: productId,
        previousPrice: previousPrice,
        newPrice: newPrice,
        changeReason: changeReason,
        changedBy: changedBy,
        pricingMode: pricingMode,
        storeId: storeId,
        changedAt: DateTime.now(),
      );

      await _firestore
          .collection(_priceAuditLogCollection)
          .doc(log.id)
          .set(log.toMap());
    } catch (e) {
      print('Error logging price audit: $e');
      // Don't rethrow - audit logging failure shouldn't fail price change
    }
  }

  /// Log price calculation for audit trail (non-critical logging)
  Future<void> logPriceCalculation({
    required String productId,
    required String
        calculationType, // 'retail_add_to_cart', 'checkout_summary', etc.
    required double basePrice,
    required double finalPrice,
    Map<String, dynamic>? context, // Additional context data
  }) async {
    try {
      await _firestore.collection('price_calculations').add({
        'productId': productId,
        'calculationType': calculationType,
        'basePrice': basePrice,
        'finalPrice': finalPrice,
        'discount': basePrice - finalPrice,
        'discountPercent': ((basePrice - finalPrice) / basePrice * 100),
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging price calculation: $e');
      // Silently fail - this is informational logging
    }
  }
}
