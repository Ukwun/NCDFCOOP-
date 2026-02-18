/// All user roles in the NCDFCOOP system
enum UserRole {
  consumer,
  coopMember,
  franchiseOwner,
  storeManager,
  storeStaff,
  institutionalBuyer,
  institutionalApprover,
  warehouseStaff,
  deliveryDriver,
  admin,
  superAdmin,
}

extension UserRoleX on UserRole {
  /// Display name for UI
  String get displayName {
    return switch (this) {
      UserRole.consumer => 'Consumer',
      UserRole.coopMember => 'Co-op Member',
      UserRole.franchiseOwner => 'Franchise Owner',
      UserRole.storeManager => 'Store Manager',
      UserRole.storeStaff => 'Store Staff',
      UserRole.institutionalBuyer => 'Institutional Buyer',
      UserRole.institutionalApprover => 'Institutional Approver',
      UserRole.warehouseStaff => 'Warehouse Staff',
      UserRole.deliveryDriver => 'Delivery Driver',
      UserRole.admin => 'Admin',
      UserRole.superAdmin => 'Super Admin',
    };
  }

  /// Color code for badges
  String get colorCode {
    return switch (this) {
      UserRole.consumer => '#1E7F4E',
      UserRole.coopMember => '#C9A227',
      UserRole.franchiseOwner => '#F3951A',
      UserRole.storeManager => '#F3951A',
      UserRole.storeStaff => '#F3951A',
      UserRole.institutionalBuyer => '#8B5CF6',
      UserRole.institutionalApprover => '#8B5CF6',
      UserRole.warehouseStaff => '#EC4899',
      UserRole.deliveryDriver => '#06B6D4',
      UserRole.admin => '#EF4444',
      UserRole.superAdmin => '#DC2626',
    };
  }

  /// Whether this role requires approval workflows
  bool get requiresApproval {
    return this == UserRole.institutionalApprover;
  }

  /// Whether this is a wholesale-related role
  bool get isWholesale {
    return [
      UserRole.franchiseOwner,
      UserRole.storeManager,
      UserRole.storeStaff,
    ].contains(this);
  }

  /// Whether this is an institutional role
  bool get isInstitutional {
    return [
      UserRole.institutionalBuyer,
      UserRole.institutionalApprover,
    ].contains(this);
  }

  /// Whether this is a logistics role
  bool get isLogistics {
    return [
      UserRole.warehouseStaff,
      UserRole.deliveryDriver,
    ].contains(this);
  }

  /// Whether this is an admin role
  bool get isAdmin {
    return [
      UserRole.admin,
      UserRole.superAdmin,
    ].contains(this);
  }
}
