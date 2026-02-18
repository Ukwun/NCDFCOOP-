import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';
import 'package:coop_commerce/models/product.dart';

/// Exception thrown when price validation fails
class PriceValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? details;

  PriceValidationException(this.message, {this.details});

  @override
  String toString() =>
      'PriceValidationException: $message${details != null ? '\nDetails: $details' : ''}';
}

/// Server-side price validation service
/// Prevents client-side price manipulation by recalculating all prices server-side
class PriceValidationService {
  final FirebaseFirestore _firestore;

  PriceValidationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the appropriate price for a product based on user role
  /// This is the SOURCE OF TRUTH for pricing
  Future<double> getValidPrice({
    required String productId,
    required UserRole userRole,
    String? contractId,
    String? franchiseId,
  }) async {
    try {
      // Fetch product from Firestore
      final productDoc =
          await _firestore.collection('products').doc(productId).get();

      if (!productDoc.exists) {
        throw PriceValidationException(
          'Product not found',
          details: {'productId': productId},
        );
      }

      final product = Product.fromJson(productDoc.data() ?? {});

      // Determine base price based on role
      double basePrice = _getPriceForRole(
        product: product,
        userRole: userRole,
      );

      // Check for contract-specific pricing (institutional buyers)
      if (contractId != null && userRole.isInstitutional) {
        final contractPrice = await _getContractPrice(contractId, productId);
        if (contractPrice != null) {
          return contractPrice;
        }
      }

      // Check for franchise-specific pricing (franchise owners)
      if (franchiseId != null && userRole.isFranchise) {
        final franchisePrice = await _getFranchisePrice(franchiseId, productId);
        if (franchisePrice != null) {
          return franchisePrice;
        }
      }

      return basePrice;
    } catch (e) {
      rethrow;
    }
  }

  /// Validate that client-provided prices match server-calculated prices
  /// Returns validation result with any discrepancies
  Future<PriceValidationResult> validateOrderPrices({
    required User user,
    required UserRole userRole,
    required List<OrderItemForValidation> clientItems,
    String? contractId,
    String? franchiseId,
  }) async {
    try {
      final discrepancies = <PriceDiscrepancy>[];
      double serverTotal = 0;
      double clientTotal = 0;

      // Validate each item
      for (final clientItem in clientItems) {
        final serverPrice = await getValidPrice(
          productId: clientItem.productId,
          userRole: userRole,
          contractId: contractId,
          franchiseId: franchiseId,
        );

        final serverSubtotal = serverPrice * clientItem.quantity;
        final clientSubtotal = clientItem.clientPrice * clientItem.quantity;

        serverTotal += serverSubtotal;
        clientTotal += clientSubtotal;

        // Check for price discrepancy (allow small floating-point differences)
        const priceEpsilon = 0.01; // ₦0.01 tolerance
        if ((clientItem.clientPrice - serverPrice).abs() > priceEpsilon) {
          discrepancies.add(
            PriceDiscrepancy(
              productId: clientItem.productId,
              clientPrice: clientItem.clientPrice,
              serverPrice: serverPrice,
              quantity: clientItem.quantity,
              clientSubtotal: clientSubtotal,
              serverSubtotal: serverSubtotal,
              overchargeAmount:
                  (clientSubtotal - serverSubtotal).clamp(0, double.infinity),
            ),
          );
        }
      }

      // Check total mismatch (allow small tolerance for rounding)
      const totalEpsilon = 0.1; // ₦0.10 tolerance for total
      final totalMismatch = (clientTotal - serverTotal).abs() > totalEpsilon;

      return PriceValidationResult(
        isValid: discrepancies.isEmpty && !totalMismatch,
        discrepancies: discrepancies,
        clientTotal: clientTotal,
        serverTotal: serverTotal,
        totalDifference: serverTotal - clientTotal,
        fraudDetected: discrepancies.isNotEmpty &&
            discrepancies
                .any((d) => d.overchargeAmount < 0), // Undercharge = fraud
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get price for a specific role from product data
  double _getPriceForRole({
    required Product product,
    required UserRole userRole,
  }) {
    return switch (userRole) {
      UserRole.consumer => product.retailPrice,
      UserRole.coopMember => product.retailPrice * 0.95, // 5% member discount
      UserRole.franchiseOwner => product.wholesalePrice,
      UserRole.storeManager => product.wholesalePrice,
      UserRole.storeStaff => product.wholesalePrice,
      UserRole.institutionalBuyer => product.contractPrice,
      UserRole.institutionalApprover => product.contractPrice,
      UserRole.warehouseStaff => product.wholesalePrice,
      UserRole.deliveryDriver => 0.0,
      UserRole.admin => product.retailPrice,
      UserRole.superAdmin => product.retailPrice,
    };
  }

  /// Get contract-specific price for institutional buyers
  Future<double?> _getContractPrice(String contractId, String productId) async {
    try {
      final contractDoc = await _firestore
          .collection('institutional_contracts')
          .doc(contractId)
          .get();

      if (!contractDoc.exists) {
        return null;
      }

      final contract = contractDoc.data();
      final pricingTiers = (contract?['pricing_tiers'] as List<dynamic>?) ?? [];

      // Find price for this product
      for (final tier in pricingTiers) {
        if (tier['product_id'] == productId) {
          return (tier['unit_price'] as num?)?.toDouble();
        }
      }

      return null;
    } catch (e) {
      // Log error but don't fail - fall back to default pricing
      print('Error fetching contract price: $e');
      return null;
    }
  }

  /// Get franchise-specific pricing
  Future<double?> _getFranchisePrice(
      String franchiseId, String productId) async {
    try {
      final franchiseDoc = await _firestore
          .collection('franchise_stores')
          .doc(franchiseId)
          .get();

      if (!franchiseDoc.exists) {
        return null;
      }

      final franchise = franchiseDoc.data();
      final wholesalePricing =
          (franchise?['wholesale_pricing'] as Map<String, dynamic>?) ?? {};

      final price = wholesalePricing[productId];
      if (price != null) {
        return (price as num).toDouble();
      }

      return null;
    } catch (e) {
      print('Error fetching franchise price: $e');
      return null;
    }
  }

  /// Check if price override requires approval
  Future<bool> requiresApprovalForPriceOverride({
    required String productId,
    required double clientPrice,
    required double serverPrice,
    required UserRole userRole,
  }) async {
    // Calculate discount percentage
    final discount = ((serverPrice - clientPrice) / serverPrice) * 100;

    // Admin/SuperAdmin can override without approval
    if (userRole.isAdmin) {
      return false;
    }

    // Any price increase (fraud attempt) requires investigation
    if (clientPrice > serverPrice) {
      return true;
    }

    // Discounts > 10% require approval for non-admins
    if (discount > 10) {
      return true;
    }

    return false;
  }

  /// Validate minimum order quantity requirements
  Future<bool> validateMinimumOrderQuantity({
    required String productId,
    required int quantity,
    required UserRole userRole,
  }) async {
    try {
      final productDoc =
          await _firestore.collection('products').doc(productId).get();

      if (!productDoc.exists) {
        throw PriceValidationException('Product not found');
      }

      final product = Product.fromJson(productDoc.data() ?? {});

      // Wholesale/Institutional have MOQ requirements
      if (userRole.isWholesale || userRole.isInstitutional) {
        return quantity >= product.minimumOrderQuantity;
      }

      // Consumers/members can order 1+
      return quantity >= 1;
    } catch (e) {
      rethrow;
    }
  }
}

/// Item for price validation
class OrderItemForValidation {
  final String productId;
  final double clientPrice;
  final int quantity;

  OrderItemForValidation({
    required this.productId,
    required this.clientPrice,
    required this.quantity,
  });

  factory OrderItemForValidation.fromJson(Map<String, dynamic> json) {
    return OrderItemForValidation(
      productId: json['productId'] ?? '',
      clientPrice: (json['clientPrice'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'clientPrice': clientPrice,
        'quantity': quantity,
      };
}

/// Price discrepancy details
class PriceDiscrepancy {
  final String productId;
  final double clientPrice;
  final double serverPrice;
  final int quantity;
  final double clientSubtotal;
  final double serverSubtotal;
  final double
      overchargeAmount; // Positive if client overcharged, negative if undercharged

  PriceDiscrepancy({
    required this.productId,
    required this.clientPrice,
    required this.serverPrice,
    required this.quantity,
    required this.clientSubtotal,
    required this.serverSubtotal,
    required this.overchargeAmount,
  });
}

/// Complete price validation result
class PriceValidationResult {
  final bool isValid;
  final List<PriceDiscrepancy> discrepancies;
  final double clientTotal;
  final double serverTotal;
  final double totalDifference; // serverTotal - clientTotal
  final bool fraudDetected; // Undercharging = fraud attempt

  PriceValidationResult({
    required this.isValid,
    required this.discrepancies,
    required this.clientTotal,
    required this.serverTotal,
    required this.totalDifference,
    required this.fraudDetected,
  });

  /// Get user-friendly error message
  String getErrorMessage() {
    if (fraudDetected) {
      return 'Price validation failed: System detected attempted fraud. Please contact support.';
    }

    if (discrepancies.isNotEmpty) {
      final firstDiscrepancy = discrepancies.first;
      return 'Price mismatch detected. Expected: ₦${firstDiscrepancy.serverPrice.toStringAsFixed(2)}, Got: ₦${firstDiscrepancy.clientPrice.toStringAsFixed(2)}';
    }

    return 'Price validation failed.';
  }
}

/// Extension for checking role types
/// Complements UserRoleX in lib/core/auth/role.dart for price validation specific checks
extension PriceValidationRoleX on UserRole {
  bool get isFranchise =>
      this == UserRole.franchiseOwner ||
      this == UserRole.storeManager ||
      this == UserRole.storeStaff;
}
