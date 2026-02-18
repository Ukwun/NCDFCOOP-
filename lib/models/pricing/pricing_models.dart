import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single price rule in the system
class PricingRule {
  final String id;
  final String productId;
  final String? storeId; // null = applies to all stores
  final double basePrice;
  final PricingMode mode; // retail, wholesale, contract
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  PricingRule({
    required this.id,
    required this.productId,
    this.storeId,
    required this.basePrice,
    required this.mode,
    required this.effectiveDate,
    this.expiryDate,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
  });

  factory PricingRule.fromMap(Map<String, dynamic> map) {
    return PricingRule(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      storeId: map['storeId'],
      basePrice: (map['basePrice'] ?? 0.0).toDouble(),
      mode: PricingMode.values.firstWhere(
        (e) => e.toString() == 'PricingMode.${map['mode'] ?? 'retail'}',
        orElse: () => PricingMode.retail,
      ),
      effectiveDate:
          (map['effectiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'storeId': storeId,
      'basePrice': basePrice,
      'mode': mode.name,
      'effectiveDate': effectiveDate,
      'expiryDate': expiryDate,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}

/// Wholesale pricing tier based on quantity
class WholesaleTier {
  final int minQuantity;
  final int maxQuantity;
  final double discountPercentage; // 0-100

  WholesaleTier({
    required this.minQuantity,
    required this.maxQuantity,
    required this.discountPercentage,
  });

  factory WholesaleTier.fromMap(Map<String, dynamic> map) {
    return WholesaleTier(
      minQuantity: map['minQuantity'] ?? 0,
      maxQuantity: map['maxQuantity'] ?? 999999,
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'discountPercentage': discountPercentage,
    };
  }
}

/// Contract pricing for a specific institution
class ContractPricing {
  final String id;
  final String institutionId;
  final String productId;
  final double contractPrice;
  final int? minimumOrderQuantity; // MOQ
  final int? casePackSize; // must order in multiples of this
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime createdAt;

  ContractPricing({
    required this.id,
    required this.institutionId,
    required this.productId,
    required this.contractPrice,
    this.minimumOrderQuantity,
    this.casePackSize,
    required this.effectiveDate,
    this.expiryDate,
    required this.isActive,
    required this.createdAt,
  });

  factory ContractPricing.fromMap(Map<String, dynamic> map) {
    return ContractPricing(
      id: map['id'] ?? '',
      institutionId: map['institutionId'] ?? '',
      productId: map['productId'] ?? '',
      contractPrice: (map['contractPrice'] ?? 0.0).toDouble(),
      minimumOrderQuantity: map['minimumOrderQuantity'],
      casePackSize: map['casePackSize'],
      effectiveDate:
          (map['effectiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institutionId': institutionId,
      'productId': productId,
      'contractPrice': contractPrice,
      'minimumOrderQuantity': minimumOrderQuantity,
      'casePackSize': casePackSize,
      'effectiveDate': effectiveDate,
      'expiryDate': expiryDate,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}

/// Promotion pricing rule
class Promotion {
  final String id;
  final String name;
  final String? description;
  final double discountPercentage; // 0-100
  final List<String>? applicableProductIds; // null = all products
  final List<String>? applicableRoles; // null = all roles
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxRedemptions; // null = unlimited
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  Promotion({
    required this.id,
    required this.name,
    this.description,
    required this.discountPercentage,
    this.applicableProductIds,
    this.applicableRoles,
    required this.startDate,
    this.endDate,
    this.maxRedemptions,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
  });

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
      applicableProductIds:
          List<String>.from(map['applicableProductIds'] ?? []),
      applicableRoles: List<String>.from(map['applicableRoles'] ?? []),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      maxRedemptions: map['maxRedemptions'],
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'discountPercentage': discountPercentage,
      'applicableProductIds': applicableProductIds,
      'applicableRoles': applicableRoles,
      'startDate': startDate,
      'endDate': endDate,
      'maxRedemptions': maxRedemptions,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  /// Check if promotion is currently valid
  bool isValid() {
    final now = DateTime.now();
    if (!isActive) return false;
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Check if promotion applies to a product
  bool appliesToProduct(String productId) {
    if (applicableProductIds == null || applicableProductIds!.isEmpty) {
      return true; // applies to all
    }
    return applicableProductIds!.contains(productId);
  }

  /// Check if promotion applies to a role
  bool appliesToRole(String role) {
    if (applicableRoles == null || applicableRoles!.isEmpty) {
      return true; // applies to all
    }
    return applicableRoles!.contains(role);
  }
}

/// Essential basket item (price ceiling)
class EssentialBasketItem {
  final String id;
  final String productId;
  final double maximumPrice; // Price should not exceed this
  final String category; // e.g., "staples", "produce"
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime createdAt;

  EssentialBasketItem({
    required this.id,
    required this.productId,
    required this.maximumPrice,
    required this.category,
    required this.effectiveDate,
    this.expiryDate,
    required this.isActive,
    required this.createdAt,
  });

  factory EssentialBasketItem.fromMap(Map<String, dynamic> map) {
    return EssentialBasketItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      maximumPrice: (map['maximumPrice'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      effectiveDate:
          (map['effectiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'maximumPrice': maximumPrice,
      'category': category,
      'effectiveDate': effectiveDate,
      'expiryDate': expiryDate,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  /// Check if this ceiling is currently valid
  bool isValid() {
    final now = DateTime.now();
    if (!isActive) return false;
    if (now.isBefore(effectiveDate)) return false;
    if (expiryDate != null && now.isAfter(expiryDate!)) return false;
    return true;
  }
}

/// Price override request (requires approval)
class PriceOverride {
  final String id;
  final String productId;
  final String? customerId; // null = system-wide override
  final double requestedPrice;
  final String reason; // why this override is needed
  final PriceOverrideStatus status; // pending, approved, rejected
  final String requestedBy;
  final String? approvedBy;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime? expiryDate; // when override expires

  PriceOverride({
    required this.id,
    required this.productId,
    this.customerId,
    required this.requestedPrice,
    required this.reason,
    required this.status,
    required this.requestedBy,
    this.approvedBy,
    required this.requestedAt,
    this.approvedAt,
    this.rejectionReason,
    this.expiryDate,
  });

  factory PriceOverride.fromMap(Map<String, dynamic> map) {
    return PriceOverride(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      customerId: map['customerId'],
      requestedPrice: (map['requestedPrice'] ?? 0.0).toDouble(),
      reason: map['reason'] ?? '',
      status: PriceOverrideStatus.values.firstWhere(
        (e) =>
            e.toString() == 'PriceOverrideStatus.${map['status'] ?? 'pending'}',
        orElse: () => PriceOverrideStatus.pending,
      ),
      requestedBy: map['requestedBy'] ?? '',
      approvedBy: map['approvedBy'],
      requestedAt:
          (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'],
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'customerId': customerId,
      'requestedPrice': requestedPrice,
      'reason': reason,
      'status': status.name,
      'requestedBy': requestedBy,
      'approvedBy': approvedBy,
      'requestedAt': requestedAt,
      'approvedAt': approvedAt,
      'rejectionReason': rejectionReason,
      'expiryDate': expiryDate,
    };
  }

  /// Check if override is still valid
  bool isValidAndApproved() {
    if (status != PriceOverrideStatus.approved) return false;
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) return false;
    return true;
  }
}

/// Audit log for price changes
class PriceAuditLog {
  final String id;
  final String productId;
  final double previousPrice;
  final double newPrice;
  final String changeReason;
  final String changedBy;
  final PricingMode pricingMode;
  final String? storeId; // null = system-wide
  final DateTime changedAt;

  PriceAuditLog({
    required this.id,
    required this.productId,
    required this.previousPrice,
    required this.newPrice,
    required this.changeReason,
    required this.changedBy,
    required this.pricingMode,
    this.storeId,
    required this.changedAt,
  });

  factory PriceAuditLog.fromMap(Map<String, dynamic> map) {
    return PriceAuditLog(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      previousPrice: (map['previousPrice'] ?? 0.0).toDouble(),
      newPrice: (map['newPrice'] ?? 0.0).toDouble(),
      changeReason: map['changeReason'] ?? '',
      changedBy: map['changedBy'] ?? '',
      pricingMode: PricingMode.values.firstWhere(
        (e) => e.toString() == 'PricingMode.${map['pricingMode'] ?? 'retail'}',
        orElse: () => PricingMode.retail,
      ),
      storeId: map['storeId'],
      changedAt: (map['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'previousPrice': previousPrice,
      'newPrice': newPrice,
      'changeReason': changeReason,
      'changedBy': changedBy,
      'pricingMode': pricingMode.name,
      'storeId': storeId,
      'changedAt': changedAt,
    };
  }
}

/// Result of price calculation with breakdown
class PriceCalculationResult {
  final double basePrice;
  final double discountAmount;
  final double discountPercentage;
  final double finalPrice;
  final List<PriceComponent>
      components; // breakdown of how price was calculated
  final bool hadEssentialBasketCap; // was price capped by essential basket?
  final bool hadPriceOverride; // was price overridden?

  PriceCalculationResult({
    required this.basePrice,
    required this.discountAmount,
    required this.discountPercentage,
    required this.finalPrice,
    required this.components,
    this.hadEssentialBasketCap = false,
    this.hadPriceOverride = false,
  });

  /// Get human-readable breakdown
  String getBreakdown() {
    final buffer = StringBuffer();
    buffer.writeln('Price Calculation Breakdown:');
    buffer.writeln('- Base Price: \$$basePrice');
    for (final component in components) {
      buffer.writeln('- ${component.name}: ${component.value}');
    }
    buffer.writeln(
        '- Discount: -\$${discountAmount.toStringAsFixed(2)} (${discountPercentage.toStringAsFixed(1)}%)');
    buffer.writeln('- Final Price: \$${finalPrice.toStringAsFixed(2)}');
    if (hadEssentialBasketCap) {
      buffer.writeln('(Capped by essential basket rule)');
    }
    if (hadPriceOverride) buffer.writeln('(Applied price override)');
    return buffer.toString();
  }
}

/// A component of the price calculation
class PriceComponent {
  final String name;
  final String value;

  PriceComponent({required this.name, required this.value});
}

// Enums
enum PricingMode { retail, wholesale, contract }

enum PriceOverrideStatus { pending, approved, rejected }
