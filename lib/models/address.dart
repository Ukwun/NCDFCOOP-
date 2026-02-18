/// Address model for shipping and billing addresses
class Address {
  final String id;
  final String userId;
  final String type; // 'home', 'work', 'other'
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String phoneNumber;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.userId,
    required this.type,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phoneNumber,
    this.addressLine2,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Get full address string
  String get fullAddress {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
      country,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'address_line_1': addressLine1,
        'address_line_2': addressLine2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'phone_number': phoneNumber,
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Create from Firestore document
  factory Address.fromMap(Map<String, dynamic> map, String docId) {
    return Address(
      id: docId,
      userId: map['user_id'] ?? '',
      type: map['type'] ?? 'other',
      addressLine1: map['address_line_1'] ?? '',
      addressLine2: map['address_line_2'],
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postal_code'] ?? '',
      country: map['country'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      isDefault: map['is_default'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Create a copy with modified fields
  Address copyWith({
    String? type,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phoneNumber,
    bool? isDefault,
  }) {
    return Address(
      id: id,
      userId: userId,
      type: type ?? this.type,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() => 'Address($id, $addressLine1, $city)';
}
