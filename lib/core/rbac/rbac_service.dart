import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/auth/role.dart';

/// Permission levels enum
enum PermissionLevel { none, view, create, edit, delete, admin }

/// Role-Based Access Control (RBAC) Service
/// Manages permissions, features, and capabilities per role
class RBACService {
  static final RBACService _instance = RBACService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory RBACService() {
    return _instance;
  }

  RBACService._internal();

  /// Feature access map per role
  static const Map<UserRole, Set<String>> roleFeatures = {
    UserRole.consumer: {
      'browse_products',
      'manage_cart',
      'place_orders',
      'track_orders',
      'view_profile',
      'update_profile',
      'manage_addresses',
      'view_membership_benefits',
      'rate_products',
      'customer_support',
    },
    UserRole.coopMember: {
      'browse_products',
      'manage_cart',
      'place_orders',
      'track_orders',
      'view_profile',
      'update_profile',
      'manage_addresses',
      'view_membership_benefits',
      'rate_products',
      'customer_support',
      'view_rewards',
      'redeem_rewards',
      'view_member_pricing',
      'member_exclusive_deals',
    },
    UserRole.franchiseOwner: {
      'manage_franchise',
      'view_sales',
      'manage_inventory',
      'manage_staff',
      'wholesale_pricing_view',
      'place_orders',
      'manage_franchise_profile',
      'view_analytics',
      'manage_returns',
      'communicate_with_coop',
    },
    UserRole.institutionalBuyer: {
      'bulk_ordering',
      'manage_contracts',
      'view_pricing_tiers',
      'view_order_history',
      'manage_approvers',
      'export_reports',
      'schedule_delivery',
      'view_invoices',
      'manage_budget_codes',
    },
    UserRole.warehouseStaff: {
      'view_orders',
      'manage_inventory',
      'pack_orders',
      'generate_labels',
      'update_order_status',
      'view_warehouse_dashboard',
      'manage_stock_levels',
      'process_returns',
    },
    UserRole.deliveryDriver: {
      'view_deliveries',
      'update_delivery_status',
      'view_route',
      'confirm_delivery',
      'view_instructions',
      'report_issues',
      'view_customer_info',
    },
    UserRole.admin: {
      'manage_users',
      'manage_roles',
      'view_analytics',
      'manage_content',
      'manage_pricing',
      'manage_franchises',
      'manage_institutions',
      'view_system_health',
      'manage_support_tickets',
      'manage_compliance',
      'export_data',
      'system_settings',
      'view_audit_logs',
    },
    UserRole.superAdmin: {
      'manage_system',
      'manage_admin_users',
      'access_all_resources',
      'view_all_analytics',
      'manage_super_settings',
    },
    UserRole.storeManager: {
      'manage_store',
      'manage_inventory',
      'manage_staff',
      'view_sales',
      'manage_returns',
    },
    UserRole.storeStaff: {
      'manage_inventory',
      'process_orders',
      'view_orders',
      'assist_customers',
    },
    UserRole.institutionalApprover: {
      'approve_orders',
      'view_order_history',
      'manage_budget',
      'view_analytics',
      'export_reports',
    },
  };

  /// Check if user has permission for a feature (checking any role)
  bool hasFeatureAccess(List<UserRole> roles, String feature) {
    for (final role in roles) {
      final features = roleFeatures[role] ?? {};
      if (features.contains(feature)) {
        return true;
      }
    }
    return false;
  }

  /// Get all features for a user's roles (union of all features)
  Set<String> getFeaturesForRoles(List<UserRole> roles) {
    final allFeatures = <String>{};
    for (final role in roles) {
      allFeatures.addAll(roleFeatures[role] ?? {});
    }
    return allFeatures;
  }

  /// Check multiple permissions (all must be in at least one role)
  bool hasAllPermissions(List<UserRole> roles, List<String> features) {
    final userFeatures = getFeaturesForRoles(roles);
    return features.every((feature) => userFeatures.contains(feature));
  }

  /// Check if user has any of the permissions
  bool hasAnyPermission(List<UserRole> roles, List<String> features) {
    final userFeatures = getFeaturesForRoles(roles);
    return features.any((feature) => userFeatures.contains(feature));
  }

  /// Check if role can access dashboard
  bool canAccessDashboard(List<UserRole> roles) {
    return hasFeatureAccess(roles, 'view_analytics') ||
        roles.contains(UserRole.franchiseOwner) ||
        roles.contains(UserRole.warehouseStaff) ||
        roles.contains(UserRole.deliveryDriver) ||
        roles.contains(UserRole.admin) ||
        roles.contains(UserRole.superAdmin);
  }

  /// Check if role can manage users
  bool canManageUsers(List<UserRole> roles) {
    return roles.contains(UserRole.admin) ||
        roles.contains(UserRole.superAdmin) ||
        (roles.contains(UserRole.franchiseOwner) &&
            hasFeatureAccess(roles, 'manage_staff'));
  }

  /// Check if role can view pricing
  bool canViewPricing(List<UserRole> roles) {
    return roles.contains(UserRole.franchiseOwner) ||
        roles.contains(UserRole.institutionalBuyer) ||
        roles.contains(UserRole.admin) ||
        roles.contains(UserRole.superAdmin);
  }

  /// Check if role can place orders
  bool canPlaceOrders(List<UserRole> roles) {
    return roles.contains(UserRole.consumer) ||
        roles.contains(UserRole.coopMember) ||
        roles.contains(UserRole.franchiseOwner) ||
        roles.contains(UserRole.institutionalBuyer) ||
        roles.contains(UserRole.institutionalApprover);
  }

  /// Get permission level for a resource
  Future<PermissionLevel> getResourcePermission(
    List<UserRole> userRoles,
    String resourceType,
    String resourceId,
  ) async {
    try {
      // Check role-based permissions first
      if (!hasFeatureAccess(userRoles, resourceType)) {
        return PermissionLevel.none;
      }

      // For now, return based on role
      // Can be extended to check document-level permissions
      if (userRoles.contains(UserRole.admin) ||
          userRoles.contains(UserRole.superAdmin)) {
        return PermissionLevel.admin;
      }

      if (userRoles.contains(UserRole.franchiseOwner) &&
          resourceType == 'franchise') {
        return PermissionLevel.edit;
      }

      return PermissionLevel.view;
    } catch (e) {
      return PermissionLevel.none;
    }
  }

  /// Log access for audit trail
  Future<void> logAccess({
    required String userId,
    required List<UserRole> userRoles,
    required String feature,
    required bool allowed,
    String? reason,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'userId': userId,
        'userRoles': userRoles.map((r) => r.name).toList(),
        'feature': feature,
        'allowed': allowed,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log locally if Firestore fails
      // In production, would use proper logger
    }
  }

  /// Validate role transition
  bool canTransitionToRole(List<UserRole> currentRoles, UserRole targetRole) {
    // Admins can change anyone's role
    if (currentRoles.contains(UserRole.admin) ||
        currentRoles.contains(UserRole.superAdmin)) {
      return true;
    }

    // Users cannot escalate their own roles
    if (currentRoles.contains(targetRole)) {
      return true; // Reassigning same role is allowed
    }

    return false;
  }

  /// Get role hierarchy (for admin purposes)
  static const Map<UserRole, int> roleHierarchy = {
    UserRole.consumer: 1,
    UserRole.coopMember: 2,
    UserRole.deliveryDriver: 3,
    UserRole.storeStaff: 3,
    UserRole.warehouseStaff: 4,
    UserRole.storeManager: 5,
    UserRole.franchiseOwner: 5,
    UserRole.institutionalBuyer: 5,
    UserRole.institutionalApprover: 6,
    UserRole.admin: 10,
    UserRole.superAdmin: 20,
  };

  /// Check if role1 outranks role2
  static bool outranks(UserRole role1, UserRole role2) {
    return (roleHierarchy[role1] ?? 0) > (roleHierarchy[role2] ?? 0);
  }

  /// Get highest role in list
  static UserRole getHighestRole(List<UserRole> roles) {
    if (roles.isEmpty) return UserRole.consumer;
    return roles.reduce(
        (a, b) => (roleHierarchy[a] ?? 0) >= (roleHierarchy[b] ?? 0) ? a : b);
  }
}
