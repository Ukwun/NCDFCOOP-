import 'api_client.dart';

/// Member model
class Member {
  final String id;
  final String name;
  final String email;
  final String membershipNumber;
  final String membershipTier;
  final double totalSavings;
  final int pointsBalance;
  final DateTime memberSince;
  final DateTime? lastPurchaseDate;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.membershipNumber,
    required this.membershipTier,
    required this.totalSavings,
    required this.pointsBalance,
    required this.memberSince,
    this.lastPurchaseDate,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      membershipNumber: json['membershipNumber'] ?? '',
      membershipTier: json['membershipTier'] ?? 'basic',
      totalSavings: (json['totalSavings'] ?? 0).toDouble(),
      pointsBalance: json['pointsBalance'] ?? 0,
      memberSince: DateTime.parse(
        json['memberSince'] ?? DateTime.now().toString(),
      ),
      lastPurchaseDate: json['lastPurchaseDate'] != null
          ? DateTime.parse(json['lastPurchaseDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'membershipNumber': membershipNumber,
    'membershipTier': membershipTier,
    'totalSavings': totalSavings,
    'pointsBalance': pointsBalance,
    'memberSince': memberSince.toIso8601String(),
    'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
  };
}

/// Member savings summary
class SavingsSummary {
  final double totalSavings;
  final double savingsThisMonth;
  final double savingsThisYear;
  final int itemsSaved;
  final double savingsPercentage;

  SavingsSummary({
    required this.totalSavings,
    required this.savingsThisMonth,
    required this.savingsThisYear,
    required this.itemsSaved,
    required this.savingsPercentage,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> json) {
    return SavingsSummary(
      totalSavings: (json['totalSavings'] ?? 0).toDouble(),
      savingsThisMonth: (json['savingsThisMonth'] ?? 0).toDouble(),
      savingsThisYear: (json['savingsThisYear'] ?? 0).toDouble(),
      itemsSaved: json['itemsSaved'] ?? 0,
      savingsPercentage: (json['savingsPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalSavings': totalSavings,
    'savingsThisMonth': savingsThisMonth,
    'savingsThisYear': savingsThisYear,
    'itemsSaved': itemsSaved,
    'savingsPercentage': savingsPercentage,
  };
}

/// Member service for API calls
class MemberService {
  final ApiClient _apiClient;

  MemberService(this._apiClient);

  /// Get current member profile
  Future<Member> getMemberProfile() async {
    try {
      final response = await _apiClient.client.get('/members/profile');
      return Member.fromJson(response.data['member']);
    } catch (e) {
      rethrow;
    }
  }

  /// Update member profile
  Future<Member> updateMemberProfile({String? name, String? email}) async {
    try {
      final data = {};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;

      final response = await _apiClient.client.put(
        '/members/profile',
        data: data,
      );
      return Member.fromJson(response.data['member']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get member savings summary
  Future<SavingsSummary> getSavingsSummary() async {
    try {
      final response = await _apiClient.client.get('/members/savings');
      return SavingsSummary.fromJson(response.data['savings']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get member savings history
  Future<List<Map<String, dynamic>>> getSavingsHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.client.get(
        '/members/savings/history',
        queryParameters: {'page': page, 'limit': limit},
      );
      return (response.data['history'] as List?)
              ?.cast<Map<String, dynamic>>()
              .toList() ??
          [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get membership benefits
  Future<List<Map<String, dynamic>>> getMembershipBenefits() async {
    try {
      final response = await _apiClient.client.get('/members/benefits');
      return (response.data['benefits'] as List?)
              ?.cast<Map<String, dynamic>>()
              .toList() ??
          [];
    } catch (e) {
      rethrow;
    }
  }

  /// Redeem points
  Future<void> redeemPoints(int points) async {
    try {
      await _apiClient.client.post(
        '/members/points/redeem',
        data: {'points': points},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get member tier benefits
  Future<Map<String, dynamic>> getTierBenefits(String tier) async {
    try {
      final response = await _apiClient.client.get(
        '/members/tiers/$tier/benefits',
      );
      return response.data['benefits'] ?? {};
    } catch (e) {
      rethrow;
    }
  }
}
