import 'package:coop_commerce/core/auth/role.dart' as auth_role;
import 'package:coop_commerce/models/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/security/audit_log_service.dart';

class PricingService {
  final AuditLogService _auditLogService;

  PricingService({
    AuditLogService? auditLogService,
  }) : _auditLogService = auditLogService ?? AuditLogService();

  /// Get price for a product based on user role with audit logging
  Future<double> getPrice({
    required Product product,
    required auth_role.UserRole userRole,
    String? userId,
  }) async {
    // Log cost price access attempts (sensitive data)
    if (userId != null && _isCostPriceAccess(userRole)) {
      await _auditLogService.logAction(
        userId,
        _mapUserRoleToString(userRole),
        AuditAction.DATA_ACCESSED,
        'product_pricing',
        resourceId: product.id,
        severity: AuditSeverity.INFO,
      );
    }

    return switch (userRole) {
      auth_role.UserRole.consumer => product.retailPrice,
      auth_role.UserRole.coopMember =>
        product.retailPrice * 0.95, // 5% member discount
      auth_role.UserRole.franchiseOwner => product.wholesalePrice,
      auth_role.UserRole.storeManager => product.wholesalePrice,
      auth_role.UserRole.storeStaff => product.wholesalePrice,
      auth_role.UserRole.institutionalBuyer => product.contractPrice,
      auth_role.UserRole.institutionalApprover => product.contractPrice,
      auth_role.UserRole.warehouseStaff => product.wholesalePrice,
      auth_role.UserRole.deliveryDriver => 0.0, // Drivers don't buy
      auth_role.UserRole.admin => product.retailPrice, // Or negotiable
      auth_role.UserRole.superAdmin => product.retailPrice,
    };
  }

  /// Get price synchronously (for UI rendering, logs separately)
  double getPriceSync({
    required Product product,
    required auth_role.UserRole userRole,
  }) {
    return switch (userRole) {
      auth_role.UserRole.consumer => product.retailPrice,
      auth_role.UserRole.coopMember =>
        product.retailPrice * 0.95, // 5% member discount
      auth_role.UserRole.franchiseOwner => product.wholesalePrice,
      auth_role.UserRole.storeManager => product.wholesalePrice,
      auth_role.UserRole.storeStaff => product.wholesalePrice,
      auth_role.UserRole.institutionalBuyer => product.contractPrice,
      auth_role.UserRole.institutionalApprover => product.contractPrice,
      auth_role.UserRole.warehouseStaff => product.wholesalePrice,
      auth_role.UserRole.deliveryDriver => 0.0, // Drivers don't buy
      auth_role.UserRole.admin => product.retailPrice, // Or negotiable
      auth_role.UserRole.superAdmin => product.retailPrice,
    };
  }

  /// Check if user can order this quantity
  bool canOrder({
    required Product product,
    required auth_role.UserRole userRole,
    required int quantity,
  }) {
    // Wholesale has MOQ requirement
    if (userRole.isWholesale) {
      return quantity >= product.minimumOrderQuantity;
    }
    // Institutional has MOQ requirement
    if (userRole.isInstitutional) {
      return quantity >= product.minimumOrderQuantity;
    }
    // Consumers/members can order 1+
    return quantity >= 1;
  }

  /// Get minimum order quantity for a role
  int getMinimumOrderQuantity({
    required Product product,
    required auth_role.UserRole userRole,
  }) {
    if (userRole.isWholesale || userRole.isInstitutional) {
      return product.minimumOrderQuantity;
    }
    return 1;
  }

  /// Get price label for display
  String getPriceLabel({
    required Product product,
    required auth_role.UserRole userRole,
  }) {
    final price = getPriceSync(product: product, userRole: userRole);

    return switch (userRole) {
      auth_role.UserRole.franchiseOwner =>
        'Wholesale: ₦${price.toStringAsFixed(0)}',
      auth_role.UserRole.storeManager =>
        'Wholesale: ₦${price.toStringAsFixed(0)}',
      auth_role.UserRole.storeStaff =>
        'Wholesale: ₦${price.toStringAsFixed(0)}',
      auth_role.UserRole.institutionalBuyer =>
        'Contract: ₦${price.toStringAsFixed(0)}',
      auth_role.UserRole.institutionalApprover =>
        'Contract: ₦${price.toStringAsFixed(0)}',
      auth_role.UserRole.coopMember => 'Member: ₦${price.toStringAsFixed(0)}',
      _ => '₦${price.toStringAsFixed(0)}',
    };
  }

  /// Calculate total for order
  double calculateTotal({
    required List<MapEntry<Product, int>> items,
    required auth_role.UserRole userRole,
  }) {
    double total = 0;
    for (final entry in items) {
      final product = entry.key;
      final quantity = entry.value;
      final price = getPriceSync(product: product, userRole: userRole);
      total += price * quantity;
    }
    return total;
  }

  /// Check if user can view this pricing tier
  bool canViewPrice({
    required Product product,
    required auth_role.UserRole userRole,
  }) {
    if (userRole.isAdmin) return true;

    return switch (userRole) {
      auth_role.UserRole.consumer => product.visibleToRetail,
      auth_role.UserRole.coopMember => product.visibleToRetail,
      auth_role.UserRole.franchiseOwner => product.visibleToWholesale,
      auth_role.UserRole.storeManager => product.visibleToWholesale,
      auth_role.UserRole.storeStaff => product.visibleToWholesale,
      auth_role.UserRole.institutionalBuyer => product.visibleToInstitutions,
      auth_role.UserRole.institutionalApprover => product.visibleToInstitutions,
      auth_role.UserRole.warehouseStaff => false,
      auth_role.UserRole.deliveryDriver => false,
      _ => false,
    };
  }

  /// Log price change with before/after values
  Future<void> logPriceChange({
    required String userId,
    required String productId,
    required double oldPrice,
    required double newPrice,
    required auth_role.UserRole changerRole,
    String? reason,
  }) async {
    await _auditLogService.logAction(
      userId,
      _mapUserRoleToString(changerRole),
      AuditAction.PRICE_CHANGED,
      'product_pricing',
      resourceId: productId,
      severity: AuditSeverity.WARNING,
      details: {'reason': reason, 'oldPrice': oldPrice, 'newPrice': newPrice},
    );
  }

  /// Helper to determine if this role can access cost price (admin only)
  bool _isCostPriceAccess(auth_role.UserRole role) {
    return role == auth_role.UserRole.admin ||
        role == auth_role.UserRole.superAdmin;
  }

  /// Helper method to map UserRole to string for audit logging
  String _mapUserRoleToString(auth_role.UserRole role) {
    return role.name;
  }
}

final pricingServiceProvider = Provider<PricingService>((ref) {
  return PricingService();
});
