import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../features/welcome/user_model.dart';

/// Activity log entry for tracking user interactions
class ActivityLog {
  final String id;
  final String type; // 'view', 'purchase', 'cart_add', 'wishlist', 'login', 'logout'
  final String? productId;
  final String? productName;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityLog({
    required this.id,
    required this.type,
    this.productId,
    this.productName,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'productId': productId,
    'productName': productName,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    id: json['id'],
    type: json['type'],
    productId: json['productId'],
    productName: json['productName'],
    timestamp: DateTime.parse(json['timestamp']),
    metadata: json['metadata'],
  );
}

/// Handles user data persistence across app sessions
class UserPersistence {
  static const String _userKey = 'coop_commerce_user';
  static const String _authTokenKey = 'coop_commerce_auth_token';
  static const String _membershipKey = 'coop_commerce_membership';
  static const String _activityLogKey = 'coop_commerce_activity_log';
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Save user data locally
  static Future<void> saveUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _secureStorage.write(key: _userKey, value: userJson);
      debugPrint('✅ User persisted: ${user.email}');
    } catch (e) {
      debugPrint('❌ Error saving user: $e');
    }
  }

  /// Save membership tier
  static Future<void> saveMembership(String tier, DateTime expiryDate) async {
    try {
      final membershipData = {
        'tier': tier,
        'expiryDate': expiryDate.toIso8601String(),
        'purchaseDate': DateTime.now().toIso8601String(),
      };
      final json = jsonEncode(membershipData);
      await _secureStorage.write(key: _membershipKey, value: json);
      debugPrint('✅ Membership saved: $tier');
    } catch (e) {
      debugPrint('❌ Error saving membership: $e');
    }
  }

  /// Get saved user
  static Future<User?> getUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson == null) return null;
      
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      final user = User.fromJson(userData);
      debugPrint('✅ User retrieved: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('❌ Error retrieving user: $e');
      return null;
    }
  }

  /// Get saved membership
  static Future<Map<String, dynamic>?> getMembership() async {
    try {
      final membershipJson = await _secureStorage.read(key: _membershipKey);
      if (membershipJson == null) return null;
      
      final membership = jsonDecode(membershipJson) as Map<String, dynamic>;
      final expiryDate = DateTime.parse(membership['expiryDate'] as String);
      
      // Check if membership is still active
      if (expiryDate.isBefore(DateTime.now())) {
        debugPrint('⏰ Membership expired on ${membership['expiryDate']}');
        return null;
      }
      
      debugPrint('✅ Membership retrieved: ${membership['tier']}');
      return membership;
    } catch (e) {
      debugPrint('❌ Error retrieving membership: $e');
      return null;
    }
  }

  /// Save authentication token
  static Future<void> saveAuthToken(String token) async {
    try {
      await _secureStorage.write(key: _authTokenKey, value: token);
      debugPrint('✅ Auth token saved');
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
    }
  }

  /// Get authentication token
  static Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: _authTokenKey);
    } catch (e) {
      debugPrint('❌ Error retrieving token: $e');
      return null;
    }
  }

  /// Log user activity (view, purchase, etc)
  static Future<void> logActivity({
    required String type,
    String? productId,
    String? productName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activity = ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        productId: productId,
        productName: productName,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      // Get existing activity log
      final activityLog = await getActivityLog();
      
      // Add new activity
      activityLog.add(activity);
      
      // Keep only last 100 activities to avoid excessive storage
      if (activityLog.length > 100) {
        activityLog.removeRange(0, activityLog.length - 100);
      }

      // Save updated log
      final jsonList = activityLog.map((a) => a.toJson()).toList();
      await _secureStorage.write(
        key: _activityLogKey,
        value: jsonEncode(jsonList),
      );
      
      debugPrint('✅ Activity logged: $type${productName != null ? ' - $productName' : ''}');
    } catch (e) {
      debugPrint('⚠️ Error logging activity: $e');
      // Don't throw - activity logging should not crash the app
    }
  }

  /// Get activity history
  static Future<List<ActivityLog>> getActivityLog() async {
    try {
      final json = await _secureStorage.read(key: _activityLogKey);
      if (json == null) return [];
      
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => ActivityLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('⚠️ Error reading activity log: $e');
      return [];
    }
  }

  /// Get recent activities (last N entries)
  static Future<List<ActivityLog>> getRecentActivities({int limit = 10}) async {
    final allActivities = await getActivityLog();
    final recentStart = allActivities.length > limit ? allActivities.length - limit : 0;
    return allActivities.sublist(recentStart).toList().reversed.toList();
  }

  /// Clear all user data (logout)
  static Future<void> clearUser() async {
    try {
      await _secureStorage.delete(key: _userKey);
      await _secureStorage.delete(key: _authTokenKey);
      await _secureStorage.delete(key: _membershipKey);
      // Keep activity log even after logout (for future data analysis)
      debugPrint('✅ User data cleared (logout)');
    } catch (e) {
      debugPrint('❌ Error clearing user: $e');
    }
  }

  /// Clear everything including activity log (full reset)
  static Future<void> clearAll() async {
    try {
      await _secureStorage.delete(key: _userKey);
      await _secureStorage.delete(key: _authTokenKey);
      await _secureStorage.delete(key: _membershipKey);
      await _secureStorage.delete(key: _activityLogKey);
      debugPrint('✅ All user data cleared (full reset)');
    } catch (e) {
      debugPrint('❌ Error clearing all data: $e');
    }
  }
}
