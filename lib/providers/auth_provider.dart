import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:coop_commerce/features/welcome/user_model.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/core/auth/permission.dart';
import 'package:coop_commerce/core/auth/user_context.dart';
import 'package:coop_commerce/services/auth/firebase_auth_service.dart';

// ============================================================================
// STATE NOTIFIER FOR MANAGING CURRENT USER
// ============================================================================

/// Notifier that manages the currently authenticated user
class UserNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null;
  }

  /// Update the current user (called when login/signup completes)
  void setUser(User? user) {
    state = user;
  }

  /// Clear the user (called on logout)
  void clearUser() {
    state = null;
  }
}

// ============================================================================
// USER AND ROLE PROVIDERS
// ============================================================================

/// Current authenticated user - synchronous, managed state
final currentUserProvider = NotifierProvider<UserNotifier, User?>(() {
  return UserNotifier();
});

/// Currently active role (for multi-role users)
final currentRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.roles.isNotEmpty == true ? user!.roles.first : UserRole.consumer;
});

/// Current context for the active role
final currentContextProvider = Provider<UserContext?>((ref) {
  final user = ref.watch(currentUserProvider);
  final role = ref.watch(currentRoleProvider);

  if (user == null) return null;
  return user.getContext(role);
});

/// Permissions available in the current role
final currentPermissionsProvider = Provider<Set<Permission>>((ref) {
  final user = ref.watch(currentUserProvider);
  final role = ref.watch(currentRoleProvider);

  if (user == null) return {};
  return user.getPermissions(role);
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// List of all user's roles
final userRolesProvider = Provider<List<UserRole>>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.roles ?? [];
});

// ============================================================================
// PERMISSION & ROLE CHECKS
// ============================================================================

/// Check if user has a specific permission
final hasPermissionProvider = Provider.family<bool, Permission>(
  (ref, permission) {
    final permissions = ref.watch(currentPermissionsProvider);
    return permissions.contains(permission);
  },
);

/// Check if user has a specific role
final hasRoleProvider = Provider.family<bool, UserRole>(
  (ref, role) {
    final user = ref.watch(currentUserProvider);
    return user?.hasRole(role) ?? false;
  },
);

/// Check if user can perform an action in current role
final canPerformActionProvider = Provider.family<bool, Permission>(
  (ref, permission) {
    return ref.watch(hasPermissionProvider(permission));
  },
);

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

/// Get current user's available roles
final availableRolesProvider = Provider<List<UserRole>>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.roles ?? [UserRole.consumer];
});

/// Get context for a specific role
final getContextForRoleProvider = Provider.family<UserContext?, UserRole>(
  (ref, role) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return user.getContext(role);
  },
);

/// Get permissions for a specific role
final getPermissionsForRoleProvider =
    Provider.family<Set<Permission>, UserRole>(
  (ref, role) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return {};
    return user.getPermissions(role);
  },
);

/// Check if user is admin
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.roles.contains(UserRole.admin) == true ||
      user?.roles.contains(UserRole.superAdmin) == true;
});

/// Check if user is super admin
final isSuperAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.roles.contains(UserRole.superAdmin) == true;
});

// ============================================================================
// FIREBASE AUTH SERVICE PROVIDERS
// ============================================================================

/// Firebase auth service provider
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Firebase auth state stream
final firebaseAuthStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  return ref.watch(firebaseAuthServiceProvider).authStateChanges;
});

/// Firebase current user provider
final firebaseCurrentUserProvider = Provider<firebase_auth.User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.currentUser;
});

/// Firebase user ID provider
final firebaseUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.currentUserId;
});

/// Firebase user email provider
final firebaseUserEmailProvider = Provider<String?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.currentUserEmail;
});
