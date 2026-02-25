import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/core/auth/permission.dart';
import 'package:coop_commerce/core/auth/user_context.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? token;
  final List<UserRole> roles;
  final Map<UserRole, UserContext> contexts;
  final String membershipTier; // 'free', 'basic', 'gold', 'platinum'
  final DateTime? membershipExpiryDate;
  final String? franchiseId;
  final bool roleSelectionCompleted; // Has user gone through role selection?

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.token,
    this.roles = const [UserRole.consumer],
    this.contexts = const {},
    this.membershipTier = 'free',
    this.membershipExpiryDate,
    this.franchiseId,
    this.roleSelectionCompleted = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rolesList = (json['roles'] as List<dynamic>?)
            ?.map((r) => UserRole.values.firstWhere(
                  (role) => role.name == r,
                  orElse: () => UserRole.consumer,
                ))
            .toList() ??
        [UserRole.consumer];

    final contextsMap = <UserRole, UserContext>{};
    if (json['contexts'] is Map) {
      for (final entry in (json['contexts'] as Map).entries) {
        try {
          final role = UserRole.values.firstWhere(
            (r) => r.name == entry.key,
          );
          contextsMap[role] = UserContext.fromJson(entry.value);
        } catch (_) {}
      }
    }

    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
      token: json['token'],
      roles: rolesList,
      contexts: contextsMap,
      membershipTier: json['membershipTier'] ?? 'free',
      membershipExpiryDate: json['membershipExpiryDate'] != null
          ? DateTime.parse(json['membershipExpiryDate'])
          : null,
      franchiseId: json['franchiseId'],
      roleSelectionCompleted: json['roleSelectionCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
        'token': token,
        'roles': roles.map((r) => r.name).toList(),
        'contexts': {
          for (final entry in contexts.entries)
            entry.key.name: entry.value.toJson(),
        },
        'membershipTier': membershipTier,
        'membershipExpiryDate': membershipExpiryDate?.toIso8601String(),
        'franchiseId': franchiseId,
        'roleSelectionCompleted': roleSelectionCompleted,
      };

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? token,
    List<UserRole>? roles,
    Map<UserRole, UserContext>? contexts,
    String? membershipTier,
    DateTime? membershipExpiryDate,
    String? franchiseId,
    bool? roleSelectionCompleted,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      token: token ?? this.token,
      roles: roles ?? this.roles,
      contexts: contexts ?? this.contexts,
      membershipTier: membershipTier ?? this.membershipTier,
      membershipExpiryDate: membershipExpiryDate ?? this.membershipExpiryDate,
      franchiseId: franchiseId ?? this.franchiseId,
      roleSelectionCompleted:
          roleSelectionCompleted ?? this.roleSelectionCompleted,
    );
  }

  /// Alias for phone number (for compatibility)
  String get phoneNumber => '';

  /// Get permissions for a specific role
  Set<Permission> getPermissions(UserRole role) {
    return rolePermissions[role] ?? {};
  }

  /// Check if user has a specific permission in a role
  bool hasPermission(UserRole role, Permission permission) {
    return getPermissions(role).contains(permission);
  }

  /// Get context for a role
  UserContext? getContext(UserRole role) {
    return contexts[role];
  }

  /// Check if user has a specific role
  bool hasRole(UserRole role) {
    return roles.contains(role);
  }
}
