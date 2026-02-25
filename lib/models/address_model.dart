class AddressModel {
  final String id;
  final String userId;
  final String name; // Label like "Home", "Work", etc.
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String? phone;
  final bool isDefault;
  final DateTime createdAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.phone,
    this.isDefault = false,
    required this.createdAt,
  });

  String get fullAddress => '$street, $city, $state $zipCode, $country';

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      zipCode: map['zipCode'] as String? ?? '',
      country: map['country'] as String? ?? '',
      phone: map['phone'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phone,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'AddressModel(id: $id, name: $name, city: $city)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
