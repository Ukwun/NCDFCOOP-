import 'role.dart';

/// Organization context for a user in a specific role
class UserContext {
  final String userId;
  final UserRole role;
  final String? franchiseId;
  final String? storeId;
  final String? institutionId;
  final String? warehouseId;
  final DateTime? startDate;

  const UserContext({
    required this.userId,
    required this.role,
    this.franchiseId,
    this.storeId,
    this.institutionId,
    this.warehouseId,
    this.startDate,
  });

  factory UserContext.fromJson(Map<String, dynamic> json) {
    return UserContext(
      userId: json['userId'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.consumer,
      ),
      franchiseId: json['franchiseId'],
      storeId: json['storeId'],
      institutionId: json['institutionId'],
      warehouseId: json['warehouseId'],
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'role': role.name,
        'franchiseId': franchiseId,
        'storeId': storeId,
        'institutionId': institutionId,
        'warehouseId': warehouseId,
        'startDate': startDate?.toIso8601String(),
      };

  UserContext copyWith({
    String? userId,
    UserRole? role,
    String? franchiseId,
    String? storeId,
    String? institutionId,
    String? warehouseId,
    DateTime? startDate,
  }) {
    return UserContext(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      franchiseId: franchiseId ?? this.franchiseId,
      storeId: storeId ?? this.storeId,
      institutionId: institutionId ?? this.institutionId,
      warehouseId: warehouseId ?? this.warehouseId,
      startDate: startDate ?? this.startDate,
    );
  }

  @override
  String toString() {
    return 'UserContext(userId: $userId, role: ${role.displayName}, '
        'franchiseId: $franchiseId, storeId: $storeId, institutionId: $institutionId)';
  }
}
