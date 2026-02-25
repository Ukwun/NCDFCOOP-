import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Role-based permission definitions
/// Maps role → list of allowed actions
enum UserRole {
  SUPER_ADMIN, // Full system access
  ADMIN, // Regional/operational admin
  COMPLIANCE_OFFICER, // Audit & compliance oversight
  FINANCE_MANAGER, // Payment & billing oversight
  WAREHOUSE_MANAGER, // Warehouse operations
  WAREHOUSE_STAFF, // Warehouse execution
  DRIVER, // Delivery operations
  FRANCHISE_OWNER, // Franchise management
  FRANCHISE_STAFF, // Franchise store operations
  INSTITUTION_ADMIN, // Institutional account admin
  INSTITUTION_BUYER, // Institutional buyer
  CONSUMER, // Individual consumer
  SUPPORT_AGENT, // Customer support
}

/// Permission types (actions that can be granted/denied)
enum Permission {
  // Order management
  create_order,
  view_order,
  approve_order,
  cancel_order,
  change_order_status,

  // Pricing management
  view_cost_price,
  modify_pricing,
  approve_price_override,
  view_contract_pricing,

  // Warehouse operations
  assign_task,
  view_queue,
  perform_qc,
  view_warehouse_data,
  manage_inventory,

  // Payment operations
  process_payment,
  process_refund,
  void_payment,
  view_payment_details,

  // User & franchise management
  manage_users,
  manage_franchises,
  manage_institutions,

  // Reporting & audit
  access_audit_log,
  export_data,
  view_analytics,
  generate_reports,

  // System admin
  modify_system_settings,
  manage_roles_and_permissions,
  access_admin_dashboard,

  // Institution management
  create_institutional_order,
  manage_institution_account,
  approve_institutional_order,
  manage_contracts,
}

/// Role-to-permissions mapping
final rolePermissionsMap = {
  UserRole.SUPER_ADMIN: Permission.values.toSet(), // All permissions
  UserRole.ADMIN: {
    Permission.view_order,
    Permission.approve_order,
    Permission.change_order_status,
    Permission.view_cost_price,
    Permission.modify_pricing,
    Permission.approve_price_override,
    Permission.process_refund,
    Permission.manage_users,
    Permission.manage_franchises,
    Permission.manage_institutions,
    Permission.access_audit_log,
    Permission.export_data,
    Permission.view_analytics,
    Permission.generate_reports,
    Permission.access_admin_dashboard,
    Permission.manage_roles_and_permissions,
  },
  UserRole.COMPLIANCE_OFFICER: {
    Permission.access_audit_log,
    Permission.view_analytics,
    Permission.generate_reports,
    Permission.export_data,
    Permission.view_order,
    Permission.view_payment_details,
  },
  UserRole.FINANCE_MANAGER: {
    Permission.view_order,
    Permission.view_payment_details,
    Permission.process_refund,
    Permission.view_analytics,
    Permission.generate_reports,
    Permission.access_audit_log,
  },
  UserRole.WAREHOUSE_MANAGER: {
    Permission.view_queue,
    Permission.assign_task,
    Permission.perform_qc,
    Permission.view_warehouse_data,
    Permission.manage_inventory,
    Permission.change_order_status,
    Permission.view_order,
  },
  UserRole.WAREHOUSE_STAFF: {
    Permission.view_queue,
    Permission.perform_qc,
    Permission.change_order_status,
    Permission.view_order,
  },
  UserRole.DRIVER: {
    Permission.view_order,
    Permission.change_order_status,
  },
  UserRole.FRANCHISE_OWNER: {
    Permission.create_order,
    Permission.view_order,
    Permission.cancel_order,
    Permission.view_cost_price, // See wholesale pricing
    Permission.manage_users,
    Permission.view_analytics,
    Permission.generate_reports,
    Permission.manage_franchises,
  },
  UserRole.FRANCHISE_STAFF: {
    Permission.create_order,
    Permission.view_order,
    Permission.cancel_order,
    Permission.view_cost_price,
  },
  UserRole.INSTITUTION_ADMIN: {
    Permission.create_institutional_order,
    Permission.view_order,
    Permission.approve_institutional_order,
    Permission.manage_institution_account,
    Permission.manage_contracts,
    Permission.manage_users,
    Permission.view_analytics,
    Permission.generate_reports,
  },
  UserRole.INSTITUTION_BUYER: {
    Permission.create_institutional_order,
    Permission.view_order,
    Permission.view_contract_pricing,
  },
  UserRole.CONSUMER: {
    Permission.create_order,
    Permission.view_order,
    Permission.cancel_order,
  },
  UserRole.SUPPORT_AGENT: {
    Permission.view_order,
    Permission.view_payment_details,
    Permission.generate_reports,
  },
};

/// User permission context (extracted from JWT or database)
class UserContext {
  final String userId;
  final UserRole role;
  final String? franchiseId; // If franchise-scoped
  final String? institutionId; // If institution-scoped
  final String? warehouseId; // If warehouse-scoped
  final Set<Permission> permissions;

  UserContext({
    required this.userId,
    required this.role,
    this.franchiseId,
    this.institutionId,
    this.warehouseId,
    Set<Permission>? permissions,
  }) : permissions = permissions ?? rolePermissionsMap[role] ?? {};

  factory UserContext.fromMap(Map<String, dynamic> data) {
    final roleStr = data['role'] as String;
    final role = UserRole.values.firstWhere(
      (r) => r.toString().split('.')[1] == roleStr,
      orElse: () => UserRole.CONSUMER,
    );

    return UserContext(
      userId: data['user_id'] as String,
      role: role,
      franchiseId: data['franchise_id'] as String?,
      institutionId: data['institution_id'] as String?,
      warehouseId: data['warehouse_id'] as String?,
      permissions: rolePermissionsMap[role],
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'role': role.toString().split('.')[1],
        'franchise_id': franchiseId,
        'institution_id': institutionId,
        'warehouse_id': warehouseId,
      };

  /// Check if user has specific permission
  bool hasPermission(Permission permission) => permissions.contains(permission);

  /// Get human-readable role name
  String getRoleName() {
    final parts = role.toString().split('.');
    return parts.last.replaceAllMapped(
      RegExp(r'_+'),
      (match) => ' ',
    );
  }
}

/// Permission Service - Core RBAC logic
/// Handles all permission checking across the application
class PermissionService {
  /// Check if user has permission to perform action
  Future<bool> hasPermission(UserContext user, Permission permission) async {
    try {
      // Fast path: check in-memory permissions
      if (user.hasPermission(permission)) {
        return true;
      }

      // If permission not in standard set, deny
      return false;
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  /// Check multiple permissions (user must have ALL)
  Future<bool> hasAllPermissions(
    UserContext user,
    List<Permission> permissions,
  ) async {
    for (final permission in permissions) {
      if (!await hasPermission(user, permission)) {
        return false;
      }
    }
    return true;
  }

  /// Check multiple permissions (user must have ANY)
  Future<bool> hasAnyPermission(
    UserContext user,
    List<Permission> permissions,
  ) async {
    for (final permission in permissions) {
      if (await hasPermission(user, permission)) {
        return true;
      }
    }
    return false;
  }

  /// Get all permissions for a role
  Set<Permission> getPermissionsForRole(UserRole role) {
    return rolePermissionsMap[role] ?? {};
  }

  /// Check if user can create order
  Future<bool> canCreateOrder(UserContext user) async {
    return hasPermission(user, Permission.create_order);
  }

  /// Check if user can approve order
  Future<bool> canApproveOrder(UserContext user) async {
    return hasPermission(user, Permission.approve_order);
  }

  /// Check if user can change order status
  Future<bool> canChangeOrderStatus(UserContext user) async {
    return hasPermission(user, Permission.change_order_status);
  }

  /// Check if user can view order
  Future<bool> canViewOrder(UserContext user) async {
    return hasPermission(user, Permission.view_order);
  }

  /// Check if user can cancel order
  Future<bool> canCancelOrder(UserContext user) async {
    return hasPermission(user, Permission.cancel_order);
  }

  /// Check if user can view cost pricing
  Future<bool> canViewCostPrice(UserContext user) async {
    return hasPermission(user, Permission.view_cost_price);
  }

  /// Check if user can modify pricing
  Future<bool> canModifyPricing(UserContext user) async {
    return hasPermission(user, Permission.modify_pricing);
  }

  /// Check if user can approve price override
  Future<bool> canApprovePriceOverride(UserContext user) async {
    return hasPermission(user, Permission.approve_price_override);
  }

  /// Check if user can assign warehouse task
  Future<bool> canAssignTask(UserContext user) async {
    return hasPermission(user, Permission.assign_task);
  }

  /// Check if user can view warehouse queue
  Future<bool> canViewQueue(UserContext user) async {
    return hasPermission(user, Permission.view_queue);
  }

  /// Check if user can perform QC check
  Future<bool> canPerformQC(UserContext user) async {
    return hasPermission(user, Permission.perform_qc);
  }

  /// Check if user can view warehouse data
  Future<bool> canViewWarehouseData(UserContext user) async {
    return hasPermission(user, Permission.view_warehouse_data);
  }

  /// Check if user can process payment
  Future<bool> canProcessPayment(UserContext user) async {
    return hasPermission(user, Permission.process_payment);
  }

  /// Check if user can process refund
  Future<bool> canProcessRefund(UserContext user) async {
    return hasPermission(user, Permission.process_refund);
  }

  /// Check if user can void payment
  Future<bool> canVoidPayment(UserContext user) async {
    return hasPermission(user, Permission.void_payment);
  }

  /// Check if user can access audit log
  Future<bool> canAccessAuditLog(UserContext user) async {
    return hasPermission(user, Permission.access_audit_log);
  }

  /// Check if user can export data
  Future<bool> canExportData(UserContext user) async {
    return hasPermission(user, Permission.export_data);
  }

  /// Check if user can manage franchises
  Future<bool> canManageFranchises(UserContext user) async {
    return hasPermission(user, Permission.manage_franchises);
  }

  /// Check if user can manage institutions
  Future<bool> canManageInstitutions(UserContext user) async {
    return hasPermission(user, Permission.manage_institutions);
  }

  /// Check if user can create institutional order
  Future<bool> canCreateInstitutionalOrder(UserContext user) async {
    return hasPermission(user, Permission.create_institutional_order);
  }

  /// Check if user can approve institutional order
  Future<bool> canApproveInstitutionalOrder(UserContext user) async {
    return hasPermission(user, Permission.approve_institutional_order);
  }

  /// Check if user can manage contracts
  Future<bool> canManageContracts(UserContext user) async {
    return hasPermission(user, Permission.manage_contracts);
  }

  /// Check if user can access admin dashboard
  Future<bool> canAccessAdminDashboard(UserContext user) async {
    return hasPermission(user, Permission.access_admin_dashboard);
  }

  /// Get permission description
  String getPermissionDescription(Permission permission) {
    const descriptions = {
      Permission.create_order: 'Create new orders',
      Permission.view_order: 'View order details',
      Permission.approve_order: 'Approve pending orders',
      Permission.cancel_order: 'Cancel orders',
      Permission.change_order_status: 'Change order status',
      Permission.view_cost_price: 'View cost/wholesale prices',
      Permission.modify_pricing: 'Modify product pricing',
      Permission.approve_price_override: 'Approve price overrides',
      Permission.view_contract_pricing: 'View contract pricing',
      Permission.assign_task: 'Assign warehouse tasks',
      Permission.view_queue: 'View warehouse queue',
      Permission.perform_qc: 'Perform quality checks',
      Permission.view_warehouse_data: 'View warehouse data',
      Permission.manage_inventory: 'Manage inventory',
      Permission.process_payment: 'Process payments',
      Permission.process_refund: 'Process refunds',
      Permission.void_payment: 'Void payments',
      Permission.view_payment_details: 'View payment details',
      Permission.manage_users: 'Manage users',
      Permission.manage_franchises: 'Manage franchises',
      Permission.manage_institutions: 'Manage institutions',
      Permission.access_audit_log: 'Access audit logs',
      Permission.export_data: 'Export data',
      Permission.view_analytics: 'View analytics',
      Permission.generate_reports: 'Generate reports',
      Permission.modify_system_settings: 'Modify system settings',
      Permission.manage_roles_and_permissions: 'Manage roles and permissions',
      Permission.access_admin_dashboard: 'Access admin dashboard',
      Permission.create_institutional_order: 'Create institutional orders',
      Permission.manage_institution_account: 'Manage institution account',
      Permission.approve_institutional_order: 'Approve institutional orders',
      Permission.manage_contracts: 'Manage contracts',
    };
    return descriptions[permission] ?? 'Unknown permission';
  }
}

/// Riverpod provider for PermissionService
final permissionServiceProvider = Provider((ref) => PermissionService());

/// Provider for current user context (to be filled during auth)
final userContextProvider = Provider<UserContext?>((ref) => null);
