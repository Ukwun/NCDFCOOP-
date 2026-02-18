import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';
import 'package:coop_commerce/models/product.dart';

class VisibilityService {
  /// Check if user can view a product
  bool canViewProduct({
    required Product product,
    required User user,
    required UserRole role,
  }) {
    // Admin can view everything
    if (role.isAdmin) return true;

    // Check role-based visibility
    return switch (role) {
      UserRole.consumer => product.visibleToRetail,
      UserRole.coopMember => product.visibleToRetail,
      UserRole.franchiseOwner => product.visibleToWholesale,
      UserRole.storeManager => product.visibleToWholesale,
      UserRole.storeStaff => product.visibleToWholesale,
      UserRole.institutionalBuyer => product.visibleToInstitutions,
      UserRole.institutionalApprover => product.visibleToInstitutions,
      UserRole.warehouseStaff => false,
      UserRole.deliveryDriver => false,
      _ => false,
    };
  }

  /// Check if user can view pricing for a product
  bool canViewPrice({
    required Product product,
    required User user,
    required UserRole role,
  }) {
    // Can only see price if can see product
    return canViewProduct(product: product, user: user, role: role);
  }

  /// Check if user can access franchise-specific data
  bool canViewFranchiseData({
    required String franchiseId,
    required User user,
  }) {
    // Only franchise owners/staff of that franchise
    if (!user.hasRole(UserRole.franchiseOwner) &&
        !user.hasRole(UserRole.storeManager) &&
        !user.hasRole(UserRole.storeStaff)) {
      return false;
    }

    final context = user.getContext(UserRole.franchiseOwner);
    if (context != null) {
      return context.franchiseId == franchiseId;
    }

    return false;
  }

  /// Check if user can access institutional data
  bool canViewInstitutionData({
    required String institutionId,
    required User user,
  }) {
    // Only institutional buyers/approvers of that institution
    if (!user.hasRole(UserRole.institutionalBuyer) &&
        !user.hasRole(UserRole.institutionalApprover)) {
      return false;
    }

    final context = user.getContext(UserRole.institutionalBuyer);
    if (context != null) {
      return context.institutionId == institutionId;
    }

    return false;
  }

  /// Check if user can access warehouse data
  bool canViewWarehouseData({
    required String warehouseId,
    required User user,
  }) {
    // Only warehouse staff
    if (!user.hasRole(UserRole.warehouseStaff) &&
        !user.hasRole(UserRole.deliveryDriver)) {
      return false;
    }

    final context = user.getContext(UserRole.warehouseStaff);
    if (context != null) {
      return context.warehouseId == warehouseId;
    }

    return false;
  }

  /// Get filtered product list based on user visibility
  List<Product> filterProductsForUser({
    required List<Product> products,
    required User user,
    required UserRole role,
  }) {
    return products
        .where((p) => canViewProduct(product: p, user: user, role: role))
        .toList();
  }
}

final visibilityServiceProvider = Provider<VisibilityService>((ref) {
  return VisibilityService();
});
