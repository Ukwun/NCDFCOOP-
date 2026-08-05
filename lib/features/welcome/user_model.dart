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
  final bool onboardingCompleted; // Has user seen the onboarding screens?

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.token,
    this.roles = const [],
    this.contexts = const {},
    this.membershipTier = 'free',
    this.membershipExpiryDate,
    this.franchiseId,
    this.roleSelectionCompleted = false,
    this.onboardingCompleted = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawRoles = <dynamic>[
      if (json['roles'] is Iterable) ...(json['roles'] as Iterable),
      json['marketplaceRole'],
      json['selectedRole'],
      json['role'],
      json['userRole'],
      json['userType'],
      json['accountType'],
    ].where((value) => value != null);
    final rolesList = <UserRole>[];
    for (final rawRole in rawRoles) {
      final role = _parseMarketplaceRole(rawRole);
      if (role != null && !rolesList.contains(role)) {
        rolesList.add(role);
      }
    }

    final contextsMap = <UserRole, UserContext>{};
    if (json['contexts'] is Map) {
      for (final entry in (json['contexts'] as Map).entries) {
        try {
          final role = UserRole.values.firstWhere(
            (r) => r.name == entry.key,
          );
          if (role.isSupported) {
            contextsMap[role] = UserContext.fromJson(entry.value);
          }
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
      // A valid role is authoritative even when an older website profile did
      // not write the newer completion flag.
      roleSelectionCompleted:
          json['roleSelectionCompleted'] == true || rolesList.isNotEmpty,
      onboardingCompleted: json['onboardingCompleted'] ?? false,
    );
  }

  static UserRole? _parseMarketplaceRole(dynamic value) {
    final normalized = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return switch (normalized) {
      'seller' || 'vendor' || 'merchant' => UserRole.seller,
      'member' ||
      'coopmember' ||
      'cooperativemember' ||
      'buyer' =>
        UserRole.coopMember,
      'wholesale' || 'wholesalebuyer' || 'bulkbuyer' => UserRole.wholesaleBuyer,
      _ => null,
    };
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
        'onboardingCompleted': onboardingCompleted,
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
    bool? onboardingCompleted,
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
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
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
