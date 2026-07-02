/// All user roles in the NCDFCOOP system
enum UserRole {
  wholesaleBuyer,
  coopMember,
  premiumMember,
  seller,
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
  /// The only marketplace identities that may be assigned or activated.
  static const Set<UserRole> supportedRoles = {
    UserRole.seller,
    UserRole.coopMember,
    UserRole.wholesaleBuyer,
  };

  /// The public onboarding flow exposes these three roles in a consistent order.
  static const List<UserRole> visibleRoles = [
    UserRole.seller,
    UserRole.coopMember,
    UserRole.wholesaleBuyer,
  ];

  bool get isSupported => supportedRoles.contains(this);

  /// Display name for UI
  String get displayName {
    return switch (this) {
      UserRole.wholesaleBuyer => 'Wholesale Buyer',
      UserRole.coopMember => 'Member',
      UserRole.premiumMember => 'Premium Member',
      UserRole.seller => 'Seller',
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
      UserRole.wholesaleBuyer => '#1E7F4E',
      UserRole.coopMember => '#C9A227',
      UserRole.premiumMember => '#FFD700',
      UserRole.seller => '#0B6B3A',
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
    return this == UserRole.wholesaleBuyer;
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
