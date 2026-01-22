import 'dart:async';
import 'api_client.dart';
import 'package:coop_commerce/core/storage/local_storage.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';

/// Authentication request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// Register request model
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String? membershipCode;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.membershipCode,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
    'membershipCode': membershipCode,
  };
}

/// Authentication response model
class AuthResponse {
  final String token;
  final String refreshToken;
  final Map<String, dynamic> user;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: json['user'] ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
    'user': user,
  };
}

/// Authentication service for API calls
class AuthService {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  // Stream controller for real-time auth state
  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  AuthService(this._apiClient, this._localStorage);

  /// Initialize auth state from storage
  Future<void> initialize() async {
    final token = await _localStorage.getToken();
    final user = await _localStorage.getUser();

    if (token != null && user != null) {
      _apiClient.setAuthToken(token);
      _authStateController.add(user);
    } else {
      _authStateController.add(null);
    }
  }

  /// Login user
  Future<User> login(LoginRequest request, {bool rememberMe = false}) async {
    try {
      final response = await _apiClient.client.post(
        '/auth/login',
        data: request.toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data);

      // Create user object from response
      final user = User.fromJson(
        authResponse.user,
      ).copyWith(token: authResponse.token);

      _apiClient.setAuthToken(authResponse.token);

      if (rememberMe) {
        await _localStorage.saveToken(authResponse.token);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Register new user
  Future<User> register(
    RegisterRequest request, {
    bool rememberMe = false,
  }) async {
    try {
      final response = await _apiClient.client.post(
        '/auth/register',
        data: request.toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data);

      final user = User.fromJson(
        authResponse.user,
      ).copyWith(token: authResponse.token);

      _apiClient.setAuthToken(authResponse.token);

      if (rememberMe) {
        await _localStorage.saveToken(authResponse.token);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Try to call logout API, but don't block local logout if it fails
      try {
        await _apiClient.client.post('/auth/logout');
      } catch (_) {}

      _apiClient.clearAuthToken();
      await _localStorage.clearToken();
      await _localStorage.clearUser();
      _authStateController.add(null);
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh authentication token
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.client.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      _apiClient.setAuthToken(authResponse.token);
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.client.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiClient.client.post(
        '/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Verify email
  Future<void> verifyEmail(String token) async {
    try {
      await _apiClient.client.post(
        '/auth/verify-email',
        data: {'token': token},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _apiClient.client.get(
        '/auth/check-email',
        queryParameters: {'email': email},
      );
      return response.data['exists'] ?? false;
    } catch (e) {
      rethrow;
    }
  }
}
