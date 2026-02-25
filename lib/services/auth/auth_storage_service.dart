import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';

/// Service for managing authentication state persistence
class AuthStorageService {
  static const String _userKey = 'auth_user';
  static const String _tokenKey = 'auth_token';
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'remembered_email';
  static const String _passwordKey = 'remembered_password';
  static const String _providerKey =
      'auth_provider'; // google, facebook, apple, email

  static final AuthStorageService _instance = AuthStorageService._internal();

  factory AuthStorageService() {
    return _instance;
  }

  AuthStorageService._internal();

  /// Save user credentials with remember me option
  Future<void> saveCredentials({
    required User user,
    required String? token,
    required bool rememberMe,
    String? email,
    String? password,
    String? provider = 'email',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save user data
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);

      // Save token
      if (token != null) {
        await prefs.setString(_tokenKey, token);
      }

      // Save remember me preference
      await prefs.setBool(_rememberMeKey, rememberMe);

      // Save provider
      await prefs.setString(_providerKey, provider ?? 'email');

      // Save credentials if rememberMe is enabled
      if (rememberMe && email != null && password != null) {
        await prefs.setString(_emailKey, email);
        // In production, encrypt password before storing!
        await prefs.setString(_passwordKey, password);
      } else {
        // Clear saved credentials if remember me is disabled
        await prefs.remove(_emailKey);
        await prefs.remove(_passwordKey);
      }
    } catch (e) {
      print('Error saving credentials: $e');
      rethrow;
    }
  }

  /// Load saved user data
  Future<User?> loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson == null) return null;

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userData);
    } catch (e) {
      print('Error loading user: $e');
      return null;
    }
  }

  /// Load saved token
  Future<String?> loadSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error loading token: $e');
      return null;
    }
  }

  /// Check if user has remember me enabled
  Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      print('Error checking remember me: $e');
      return false;
    }
  }

  /// Load remembered credentials
  Future<Map<String, String>?> loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey);
      final password = prefs.getString(_passwordKey);

      if (email == null || password == null) return null;

      return {
        'email': email,
        'password': password,
      };
    } catch (e) {
      print('Error loading credentials: $e');
      return null;
    }
  }

  /// Get auth provider
  Future<String?> getAuthProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_providerKey);
    } catch (e) {
      print('Error getting auth provider: $e');
      return null;
    }
  }

  /// Clear all auth data (logout)
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_userKey),
        prefs.remove(_tokenKey),
        prefs.remove(_rememberMeKey),
        prefs.remove(_emailKey),
        prefs.remove(_passwordKey),
        prefs.remove(_providerKey),
      ]);
    } catch (e) {
      print('Error clearing auth storage: $e');
      rethrow;
    }
  }

  /// Update user profile without clearing credentials
  Future<void> updateUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }
}
