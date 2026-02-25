import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/rbac/rbac_service.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';
import 'package:coop_commerce/providers/auth_provider.dart';

/// RBAC Service Provider
final rbacServiceProvider = Provider<RBACService>((ref) {
  return RBACService();
});

/// Feature access provider - checks if current user can access a feature
final featureAccessProvider =
    FutureProvider.family<bool, String>((ref, feature) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return false;
      final rbac = ref.watch(rbacServiceProvider);
      return rbac.hasFeatureAccess(user.roles, feature);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Get all features for current user's roles
final userFeaturesProvider = FutureProvider<Set<String>>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return {};
      final rbac = ref.watch(rbacServiceProvider);
      return rbac.getFeaturesForRoles(user.roles);
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Check if current user can access dashboard
final canAccessDashboardProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return false;
      final rbac = ref.watch(rbacServiceProvider);
      return rbac.canAccessDashboard(user.roles);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if current user can manage other users
final canManageUsersProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return false;
      final rbac = ref.watch(rbacServiceProvider);
      return rbac.canManageUsers(user.roles);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if current user can view pricing
final canViewPricingProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return false;
      final rbac = ref.watch(rbacServiceProvider);
      return rbac.canViewPricing(user.roles);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if current user can place orders
final canPlaceOrdersProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return false;
      final rbac = ref.watch(rbacServiceProvider);
      return rbac.canPlaceOrders(user.roles);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Get user's role display names
final userRolesDisplayProvider = FutureProvider<List<String>>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return [];
      return user.roles.map((r) => r.displayName).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Check multiple permissions at once
final hasAllPermissionsProvider =
    FutureProvider.family<bool, List<String>>((ref, features) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return false;
      final rbac = ref.watch(rbacServiceProvider);
      return rbac.hasAllPermissions(user.roles, features);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if user has any of the permissions
final hasAnyPermissionProvider =
    FutureProvider.family<bool, List<String>>((ref, features) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return false;
      final rbac = ref.watch(rbacServiceProvider);
      return rbac.hasAnyPermission(user.roles, features);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Get current user's roles for UI decisions
final currentUserRolesProvider = FutureProvider<List<UserRole>>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) => user?.roles ?? [],
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Check resource-level permissions
final resourcePermissionProvider = FutureProvider.family<PermissionLevel,
    ({String resourceType, String resourceId})>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final rbac = ref.watch(rbacServiceProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return PermissionLevel.none;
      return rbac.getResourcePermission(
        user.roles,
        params.resourceType,
        params.resourceId,
      );
    },
    loading: () => PermissionLevel.none,
    error: (_, __) => PermissionLevel.none,
  );
});

/// Get the highest role for the user
/// Uses currentUserProvider which is updated immediately after role selection
final highestUserRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) return UserRole.consumer;
  if (user.roles.isEmpty) return UserRole.consumer;

  return RBACService.getHighestRole(user.roles);
});
