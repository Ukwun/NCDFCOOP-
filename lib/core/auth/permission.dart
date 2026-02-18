import 'role.dart';

/// All permissions in the system
enum Permission {
  // Retail permissions
  viewRetailProducts,
  viewRetailPrices,
  createRetailOrder,
  trackRetailOrder,
  viewSavings,

  // Member permissions
  viewMemberBenefits,
  viewVotingItems,
  participateInVoting,
  viewMemberReports,

  // Wholesale permissions
  viewWholesaleProducts,
  viewWholesalePrices,
  createWholesaleOrder,
  viewWholesaleOrders,
  updateFranchiseInventory,
  viewFranchiseInventory,
  viewFranchiseSales,

  // Institutional permissions
  viewInstitutionalProducts,
  viewContractPricing,
  createPurchaseOrder,
  approvePurchaseOrder,
  viewInvoices,

  // Compliance & Operations
  submitComplianceEvidence,
  reportIncident,

  // Logistics permissions
  viewDeliveryRoutes,
  assignDeliveryRoute,
  updateDeliveryStatus,
  captureProofOfDelivery,

  // Admin permissions
  manageUsers,
  assignUserRoles,
  viewAuditLog,
  overridePricing,
  viewKPIs,
  handleExceptions,
}

/// Maps each role to its permissions
final rolePermissions = <UserRole, Set<Permission>>{
  UserRole.consumer: {
    Permission.viewRetailProducts,
    Permission.viewRetailPrices,
    Permission.createRetailOrder,
    Permission.trackRetailOrder,
  },
  UserRole.coopMember: {
    Permission.viewRetailProducts,
    Permission.viewRetailPrices,
    Permission.createRetailOrder,
    Permission.trackRetailOrder,
    Permission.viewSavings,
    Permission.viewMemberBenefits,
    Permission.viewVotingItems,
    Permission.participateInVoting,
    Permission.viewMemberReports,
  },
  UserRole.franchiseOwner: {
    Permission.viewWholesaleProducts,
    Permission.viewWholesalePrices,
    Permission.createWholesaleOrder,
    Permission.viewWholesaleOrders,
    Permission.viewFranchiseInventory,
    Permission.updateFranchiseInventory,
    Permission.viewFranchiseSales,
    Permission.submitComplianceEvidence,
    Permission.reportIncident,
  },
  UserRole.storeManager: {
    Permission.viewWholesaleProducts,
    Permission.viewWholesalePrices,
    Permission.viewWholesaleOrders,
    Permission.viewFranchiseInventory,
    Permission.updateFranchiseInventory,
    Permission.viewFranchiseSales,
    Permission.submitComplianceEvidence,
    Permission.reportIncident,
  },
  UserRole.storeStaff: {
    Permission.viewWholesaleProducts,
    Permission.viewWholesalePrices,
    Permission.viewFranchiseInventory,
    Permission.viewFranchiseSales,
  },
  UserRole.institutionalBuyer: {
    Permission.viewInstitutionalProducts,
    Permission.viewContractPricing,
    Permission.createPurchaseOrder,
    Permission.viewInvoices,
  },
  UserRole.institutionalApprover: {
    Permission.viewInstitutionalProducts,
    Permission.viewContractPricing,
    Permission.viewInvoices,
    Permission.approvePurchaseOrder,
  },
  UserRole.warehouseStaff: {
    Permission.viewDeliveryRoutes,
    Permission.updateDeliveryStatus,
  },
  UserRole.deliveryDriver: {
    Permission.viewDeliveryRoutes,
    Permission.updateDeliveryStatus,
    Permission.captureProofOfDelivery,
  },
  UserRole.admin: {
    Permission.viewRetailProducts,
    Permission.viewRetailPrices,
    Permission.viewWholesaleProducts,
    Permission.viewWholesalePrices,
    Permission.viewInstitutionalProducts,
    Permission.viewContractPricing,
    Permission.manageUsers,
    Permission.assignUserRoles,
    Permission.viewAuditLog,
    Permission.overridePricing,
    Permission.viewKPIs,
    Permission.handleExceptions,
  },
  UserRole.superAdmin: {
    // Super admin has all permissions
    ...Permission.values.toSet(),
  },
};

extension PermissionX on Permission {
  /// Description of what this permission allows
  String get description {
    return switch (this) {
      Permission.viewRetailProducts => 'View retail products in catalog',
      Permission.viewRetailPrices => 'View retail pricing',
      Permission.createRetailOrder => 'Create retail orders',
      Permission.trackRetailOrder => 'Track retail orders',
      Permission.viewSavings => 'View personal savings',
      Permission.viewMemberBenefits => 'View membership benefits',
      Permission.viewVotingItems => 'View voting items',
      Permission.participateInVoting => 'Participate in voting',
      Permission.viewMemberReports => 'View member reports',
      Permission.viewWholesaleProducts => 'View wholesale products',
      Permission.viewWholesalePrices => 'View wholesale pricing',
      Permission.createWholesaleOrder => 'Create wholesale orders',
      Permission.viewWholesaleOrders => 'View wholesale orders',
      Permission.updateFranchiseInventory => 'Update franchise inventory',
      Permission.viewFranchiseInventory => 'View franchise inventory',
      Permission.viewFranchiseSales => 'View franchise sales',
      Permission.viewInstitutionalProducts => 'View institutional products',
      Permission.viewContractPricing => 'View contract pricing',
      Permission.createPurchaseOrder => 'Create purchase orders',
      Permission.approvePurchaseOrder => 'Approve purchase orders',
      Permission.viewInvoices => 'View invoices',
      Permission.submitComplianceEvidence => 'Submit compliance evidence',
      Permission.reportIncident => 'Report incidents',
      Permission.viewDeliveryRoutes => 'View delivery routes',
      Permission.assignDeliveryRoute => 'Assign delivery routes',
      Permission.updateDeliveryStatus => 'Update delivery status',
      Permission.captureProofOfDelivery => 'Capture proof of delivery',
      Permission.manageUsers => 'Manage users',
      Permission.assignUserRoles => 'Assign user roles',
      Permission.viewAuditLog => 'View audit logs',
      Permission.overridePricing => 'Override pricing',
      Permission.viewKPIs => 'View KPIs',
      Permission.handleExceptions => 'Handle exceptions',
    };
  }
}
