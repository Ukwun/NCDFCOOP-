import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImage;
  final String? bio;
  final String userType; // 'customer', 'vendor', 'admin'
  final List<String> addresses;
  final String? defaultAddressId;
  final bool emailVerified;
  final bool phoneVerified;
  final double? rating;
  final int? reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImage,
    this.bio,
    this.userType = 'customer',
    this.addresses = const [],
    this.defaultAddressId,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.rating,
    this.reviewCount,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      phoneNumber: data['phoneNumber'],
      profileImage: data['profileImage'],
      bio: data['bio'],
      userType: data['userType'] ?? 'customer',
      addresses: List<String>.from(data['addresses'] ?? []),
      defaultAddressId: data['defaultAddressId'],
      emailVerified: data['emailVerified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: data['preferences'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'bio': bio,
      'userType': userType,
      'addresses': addresses,
      'defaultAddressId': defaultAddressId,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImage,
    String? bio,
    String? userType,
    List<String>? addresses,
    String? defaultAddressId,
    bool? emailVerified,
    bool? phoneVerified,
    double? rating,
    int? reviewCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      userType: userType ?? this.userType,
      addresses: addresses ?? this.addresses,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }

  bool get isVendor => userType == 'vendor';
  bool get isAdmin => userType == 'admin';
  bool get isCustomer => userType == 'customer';
  bool get isVerified => emailVerified && phoneVerified;
}
