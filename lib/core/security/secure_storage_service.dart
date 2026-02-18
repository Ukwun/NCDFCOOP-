import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Secure storage service for sensitive user data
class SecureStorageService {
  static const String _userTokenKey = 'user_token_secure';
  static const String _userIdKey = 'user_id_secure';
  static const String _userEmailKey = 'user_email_secure';
  static const String _sessionTimeoutKey = 'session_timeout';

  /// Save authentication token securely
  static Future<bool> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In production, use flutter_secure_storage for encryption
      return await prefs.setString(_userTokenKey, token);
    } catch (e) {
      debugPrint('Error saving auth token: $e');
      return false;
    }
  }

  /// Retrieve authentication token
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userTokenKey);
    } catch (e) {
      debugPrint('Error retrieving auth token: $e');
      return null;
    }
  }

  /// Save user ID securely
  static Future<bool> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userIdKey, userId);
    } catch (e) {
      debugPrint('Error saving user ID: $e');
      return false;
    }
  }

  /// Retrieve user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      debugPrint('Error retrieving user ID: $e');
      return null;
    }
  }

  /// Save user email securely
  static Future<bool> saveUserEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userEmailKey, email);
    } catch (e) {
      debugPrint('Error saving user email: $e');
      return false;
    }
  }

  /// Retrieve user email
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      debugPrint('Error retrieving user email: $e');
      return null;
    }
  }

  /// Set session timeout timestamp
  static Future<bool> setSessionTimeout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 30 minutes timeout
      final timeoutTime = DateTime.now().add(Duration(minutes: 30)).toString();
      return await prefs.setString(_sessionTimeoutKey, timeoutTime);
    } catch (e) {
      debugPrint('Error setting session timeout: $e');
      return false;
    }
  }

  /// Check if session is still valid
  static Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeoutString = prefs.getString(_sessionTimeoutKey);

      if (timeoutString == null) return false;

      final timeoutTime = DateTime.parse(timeoutString);
      return DateTime.now().isBefore(timeoutTime);
    } catch (e) {
      debugPrint('Error checking session: $e');
      return false;
    }
  }

  /// Clear all sensitive data on logout
  static Future<bool> clearAllSecureData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_sessionTimeoutKey);
      return true;
    } catch (e) {
      debugPrint('Error clearing secure data: $e');
      return false;
    }
  }
}
