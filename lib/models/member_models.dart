import 'package:cloud_firestore/cloud_firestore.dart';

/// Member user model - extends regular user with member-specific data
class Member {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? profilePictureUrl;
  final String memberTier; // BASIC, SILVER, GOLD, PLATINUM
  final int loyaltyPoints;
  final int totalPointsEarned;
  final DateTime memberSince;
  final DateTime? lastPurchaseDate;
  final int totalOrders;
  final double totalSpent;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.profilePictureUrl,
    required this.memberTier,
    required this.loyaltyPoints,
    required this.totalPointsEarned,
    required this.memberSince,
    this.lastPurchaseDate,
    required this.totalOrders,
    required this.totalSpent,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      profilePictureUrl: data['profilePictureUrl'] as String?,
      memberTier: data['memberTier'] as String? ?? 'BASIC',
      loyaltyPoints: data['loyaltyPoints'] as int? ?? 0,
      totalPointsEarned: data['totalPointsEarned'] as int? ?? 0,
      memberSince:
          (data['memberSince'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPurchaseDate: (data['lastPurchaseDate'] as Timestamp?)?.toDate(),
      totalOrders: data['totalOrders'] as int? ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
      'memberTier': memberTier,
      'loyaltyPoints': loyaltyPoints,
      'totalPointsEarned': totalPointsEarned,
      'memberSince': Timestamp.fromDate(memberSince),
      'lastPurchaseDate': lastPurchaseDate != null
          ? Timestamp.fromDate(lastPurchaseDate!)
          : null,
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Member copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profilePictureUrl,
    String? memberTier,
    int? loyaltyPoints,
    int? totalPointsEarned,
    DateTime? memberSince,
    DateTime? lastPurchaseDate,
    int? totalOrders,
    double? totalSpent,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      memberTier: memberTier ?? this.memberTier,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      memberSince: memberSince ?? this.memberSince,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Loyalty program tier definition
class MemberLoyalty {
  final String id;
  final String memberId;
  final String currentTier; // BASIC, SILVER, GOLD, PLATINUM
  final int currentPoints;
  final int pointsNeededForNextTier;
  final List<Reward> claimedRewards;
  final List<Reward> availableRewards;
  final DateTime tierUpgradedDate;
  final double discountPercentage; // Varies by tier
  final DateTime createdAt;

  MemberLoyalty({
    required this.id,
    required this.memberId,
    required this.currentTier,
    required this.currentPoints,
    required this.pointsNeededForNextTier,
    required this.claimedRewards,
    required this.availableRewards,
    required this.tierUpgradedDate,
    required this.discountPercentage,
    required this.createdAt,
  });

  factory MemberLoyalty.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberLoyalty(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
      currentTier: data['currentTier'] as String? ?? 'BASIC',
      currentPoints: data['currentPoints'] as int? ?? 0,
      pointsNeededForNextTier: data['pointsNeededForNextTier'] as int? ?? 0,
      claimedRewards: (data['claimedRewards'] as List?)
              ?.map((r) => Reward.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      availableRewards: (data['availableRewards'] as List?)
              ?.map((r) => Reward.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      tierUpgradedDate:
          (data['tierUpgradedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      discountPercentage:
          (data['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'currentTier': currentTier,
      'currentPoints': currentPoints,
      'pointsNeededForNextTier': pointsNeededForNextTier,
      'claimedRewards': claimedRewards.map((r) => r.toMap()).toList(),
      'availableRewards': availableRewards.map((r) => r.toMap()).toList(),
      'tierUpgradedDate': Timestamp.fromDate(tierUpgradedDate),
      'discountPercentage': discountPercentage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double get progressToNextTier {
    if (pointsNeededForNextTier == 0) return 1.0;
    return (currentPoints / pointsNeededForNextTier).clamp(0.0, 1.0);
  }

  String get nextTier {
    switch (currentTier) {
      case 'BASIC':
        return 'SILVER';
      case 'SILVER':
        return 'GOLD';
      case 'GOLD':
        return 'PLATINUM';
      default:
        return 'PLATINUM';
    }
  }
}

/// Reward that can be redeemed
class Reward {
  final String id;
  final String name;
  final String description;
  final int pointsRequired;
  final String rewardType; // discount, freeship, voucher, product
  final dynamic rewardValue; // percentage, amount, or product id
  final bool isClaimed;
  final DateTime? claimedDate;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
    required this.rewardType,
    required this.rewardValue,
    required this.isClaimed,
    this.claimedDate,
  });

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      pointsRequired: map['pointsRequired'] as int? ?? 0,
      rewardType: map['rewardType'] as String? ?? 'discount',
      rewardValue: map['rewardValue'],
      isClaimed: map['isClaimed'] as bool? ?? false,
      claimedDate: (map['claimedDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pointsRequired': pointsRequired,
      'rewardType': rewardType,
      'rewardValue': rewardValue,
      'isClaimed': isClaimed,
      'claimedDate':
          claimedDate != null ? Timestamp.fromDate(claimedDate!) : null,
    };
  }
}

/// Member benefit - what they get for their tier
class MemberBenefit {
  final String id;
  final String name;
  final String description;
  final String icon; // icon name or url
  final String category; // shopping, delivery, support, exclusive
  final List<String> tiers; // which tiers have this benefit
  final String howToUse; // instructions
  final List<String> steps; // step by step guide
  final String? terms; // terms and conditions
  final DateTime createdAt;

  MemberBenefit({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.tiers,
    required this.howToUse,
    required this.steps,
    this.terms,
    required this.createdAt,
  });

  factory MemberBenefit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberBenefit(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'card_giftcard',
      category: data['category'] as String? ?? 'shopping',
      tiers: List<String>.from(data['tiers'] as List? ?? []),
      howToUse: data['howToUse'] as String? ?? '',
      steps: List<String>.from(data['steps'] as List? ?? []),
      terms: data['terms'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'tiers': tiers,
      'howToUse': howToUse,
      'steps': steps,
      'terms': terms,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// App notification
class AppNotification {
  final String id;
  final String memberId;
  final String title;
  final String message;
  final String type; // order, promotion, system, membership
  final String? actionUrl; // where to navigate on tap
  final Map<String, dynamic>? data; // additional data
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.memberId,
    required this.title,
    required this.message,
    required this.type,
    this.actionUrl,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? 'system',
      actionUrl: data['actionUrl'] as String?,
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'title': title,
      'message': message,
      'type': type,
      'actionUrl': actionUrl,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).toStringAsFixed(0)}w ago';
    }
  }
}

/// Order statistics for member
class OrderStats {
  final String memberId;
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final int thisMonthOrders;
  final double thisMonthSpent;
  final String favoriteCategory;
  final DateTime lastOrderDate;
  final DateTime lastUpdated;

  OrderStats({
    required this.memberId,
    required this.totalOrders,
    required this.totalSpent,
    required this.averageOrderValue,
    required this.thisMonthOrders,
    required this.thisMonthSpent,
    required this.favoriteCategory,
    required this.lastOrderDate,
    required this.lastUpdated,
  });

  factory OrderStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderStats(
      memberId: doc.id,
      totalOrders: data['totalOrders'] as int? ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      averageOrderValue: (data['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      thisMonthOrders: data['thisMonthOrders'] as int? ?? 0,
      thisMonthSpent: (data['thisMonthSpent'] as num?)?.toDouble() ?? 0.0,
      favoriteCategory: data['favoriteCategory'] as String? ?? 'N/A',
      lastOrderDate:
          (data['lastOrderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'averageOrderValue': averageOrderValue,
      'thisMonthOrders': thisMonthOrders,
      'thisMonthSpent': thisMonthSpent,
      'favoriteCategory': favoriteCategory,
      'lastOrderDate': Timestamp.fromDate(lastOrderDate),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

/// Saved payment method
class SavedPaymentMethod {
  final String id;
  final String memberId;
  final String cardholderName;
  final String cardType; // visa, mastercard, amex
  final String lastFourDigits;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;
  final DateTime createdAt;

  SavedPaymentMethod({
    required this.id,
    required this.memberId,
    required this.cardholderName,
    required this.cardType,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedPaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedPaymentMethod(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
      cardholderName: data['cardholderName'] as String? ?? '',
      cardType: data['cardType'] as String? ?? 'visa',
      lastFourDigits: data['lastFourDigits'] as String? ?? '',
      expiryMonth: data['expiryMonth'] as int? ?? 0,
      expiryYear: data['expiryYear'] as int? ?? 0,
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'cardholderName': cardholderName,
      'cardType': cardType,
      'lastFourDigits': lastFourDigits,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get displayName => '${cardType.toUpperCase()} •••• $lastFourDigits';
  String get expiryDisplay => '$expiryMonth/$expiryYear';
  bool get isExpired {
    final now = DateTime.now();
    final expiry = DateTime(expiryYear, expiryMonth, 1).add(Duration(days: 30));
    return now.isAfter(expiry);
  }
}
