import 'dart:async';
import 'api_client.dart';
import 'local_storage.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/core/auth/user_context.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fb_auth;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:coop_commerce/core/security/audit_log_service.dart';

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
  final AuditLogService _auditLogService;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final fb_auth.FacebookAuth _facebookAuth = fb_auth.FacebookAuth.instance;

  // Stream controller for real-time auth state
  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  AuthService(
    this._apiClient,
    this._localStorage, {
    AuditLogService? auditLogService,
  }) : _auditLogService = auditLogService ?? AuditLogService();

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

  /// Login user with JWT token generation and audit logging
  Future<User> login(LoginRequest request, {bool rememberMe = false}) async {
    try {
      // --- SIMULATED API CALL FOR TESTING ---
      await Future.delayed(const Duration(seconds: 2));

      // Assign roles based on email (for testing/demo)
      final roles = _assignRolesByEmail(request.email);

      // Create contexts for each role
      final contexts = <UserRole, UserContext>{};
      for (final role in roles) {
        contexts[role] = UserContext(
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
          role: role,
          franchiseId: role.isWholesale ? 'franchise_ng_001' : null,
          storeId: role.isWholesale ? 'store_ng_001' : null,
          institutionId: role.isInstitutional ? 'inst_ng_001' : null,
          warehouseId: role.isLogistics ? 'warehouse_ng_001' : null,
        );
      }

      // Generate JWT token with claims
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final mockToken = _generateMockJWT(
        userId: userId,
        email: request.email,
        roles: roles.map((r) => r.name).toList(),
        expiresIn: const Duration(hours: 24),
      );

      // Mock successful response
      final mockUserJson = {
        'id': userId,
        'email': request.email,
        'name': 'Test User',
        'photoUrl': null,
        'roles': roles.map((r) => r.name).toList(),
        'contexts': {
          for (final entry in contexts.entries)
            entry.key.name: entry.value.toJson(),
        },
      };

      final user = User.fromJson(mockUserJson).copyWith(token: mockToken);

      _apiClient.setAuthToken(mockToken);

      // Log successful login
      await _auditLogService.logAction(
        userId,
        'consumer',
        AuditAction.LOGIN_SUCCESS,
        'user',
        resourceId: userId,
        severity: AuditSeverity.INFO,
        details: {
          'email': request.email,
          'roles': roles.map((r) => r.name).toList(),
          'token_expires_at':
              DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        },
      );

      if (rememberMe) {
        await _localStorage.saveToken(mockToken);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      return user;
      // -------------------------------------

      /* REAL IMPLEMENTATION (Uncomment when backend is ready)
      final response = await _apiClient.client.post('/auth/login', data: request.toJson());
      final authResponse = AuthResponse.fromJson(response.data);
      final user = User.fromJson(authResponse.user).copyWith(token: authResponse.token);
      
      // Log successful login
      await _auditLogService.logAction(
        user_id: user.id,
        user_role: UserRole.CONSUMER,
        action: AuditAction.USER_LOGIN,
        severity: AuditSeverity.INFO,
        resource_type: 'user',
        resource_id: user.id,
        details: {
          'email': user.email,
          'roles': user.roles.map((r) => r.name).toList(),
        },
      );
      
      _apiClient.setAuthToken(authResponse.token);
      if (rememberMe) {
        await _localStorage.saveToken(authResponse.token);
        await _localStorage.saveUser(user);
      }
      _authStateController.add(user);
      return user;
      */
    } catch (e) {
      // Log failed login attempt
      await _auditLogService.logAction(
        request.email,
        'consumer',
        AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT,
        'user',
        severity: AuditSeverity.WARNING,
        details: {'reason': 'Login failed: ${e.toString()}'},
      );
      rethrow;
    }
  }

  /// Register new user with audit logging
  Future<User> register(
    RegisterRequest request, {
    bool rememberMe = false,
  }) async {
    try {
      // --- SIMULATED API CALL FOR TESTING ---
      await Future.delayed(const Duration(seconds: 2));

      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final mockToken = _generateMockJWT(
        userId: userId,
        email: request.email,
        roles: ['consumer'],
        expiresIn: const Duration(hours: 24),
      );

      final mockUserJson = {
        'id': userId,
        'email': request.email,
        'name': request.name,
        'photoUrl': null,
      };

      final user = User.fromJson(mockUserJson).copyWith(token: mockToken);

      _apiClient.setAuthToken(mockToken);

      // Log successful registration
      await _auditLogService.logAction(
        userId,
        'consumer',
        AuditAction.USER_CREATED,
        'user',
        resourceId: userId,
        severity: AuditSeverity.INFO,
        details: {
          'email': request.email,
          'name': request.name,
          'membership_code': request.membershipCode,
        },
      );

      if (rememberMe) {
        await _localStorage.saveToken(mockToken);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      return user;
      // -------------------------------------
    } catch (e) {
      // Log failed registration
      await _auditLogService.logAction(
        request.email,
        'consumer',
        AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT,
        'user',
        resourceId: 'new',
        severity: AuditSeverity.ERROR,
        details: {
          'attempted_email': request.email,
          'reason': 'Registration failed: ${e.toString()}',
        },
      );
      rethrow;
    }
  }

  /// Logout user with audit logging
  Future<void> logout({String? userId}) async {
    try {
      // Log logout action
      if (userId != null) {
        await _auditLogService.logAction(
          userId,
          'consumer',
          AuditAction.LOGOUT,
          'user',
          resourceId: userId,
          severity: AuditSeverity.INFO,
          details: {'action': 'user_logout'},
        );
      }

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

  /// Refresh authentication token with audit logging
  Future<AuthResponse> refreshToken(String refreshToken,
      {String? userId}) async {
    try {
      final response = await _apiClient.client.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      _apiClient.setAuthToken(authResponse.token);

      // Log token refresh
      if (userId != null) {
        await _auditLogService.logAction(
          userId,
          'consumer',
          AuditAction.TOKEN_REFRESHED,
          'auth_token',
          resourceId: userId,
          severity: AuditSeverity.INFO,
          details: {
            'old_token_expires': DateTime.now().toIso8601String(),
            'new_token_expires':
                DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          },
        );
      }

      return authResponse;
    } catch (e) {
      // Log token refresh failure
      if (userId != null) {
        await _auditLogService.logAction(
          userId,
          'consumer',
          AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT,
          'auth_token',
          resourceId: userId,
          severity: AuditSeverity.ERROR,
          details: {'reason': 'Token refresh failed: ${e.toString()}'},
        );
      }
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

  /// Sign in with Google
  Future<User> signInWithGoogle({bool rememberMe = false}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in cancelled');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw Exception('Failed to get Google ID token');

      // Call backend API to authenticate with Google token
      final response = await _apiClient.client.post(
        '/auth/google',
        data: {
          'idToken': idToken,
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'Google User',
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      final user = User.fromJson(
        authResponse.user,
      ).copyWith(token: authResponse.token, photoUrl: googleUser.photoUrl);

      _apiClient.setAuthToken(authResponse.token);

      if (rememberMe) {
        await _localStorage.saveToken(authResponse.token);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      return user;
    } catch (e) {
      await _googleSignIn.signOut(); // Sign out on error
      rethrow;
    }
  }

  /// Sign in with Facebook
  Future<User> signInWithFacebook({bool rememberMe = false}) async {
    try {
      final fb_auth.LoginResult result = await _facebookAuth.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == fb_auth.LoginStatus.cancelled) {
        throw Exception('Facebook sign in cancelled');
      }

      if (result.status == fb_auth.LoginStatus.failed) {
        throw Exception('Facebook sign in failed: ${result.message}');
      }

      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      // Get user details
      final userData = await _facebookAuth.getUserData(
        fields: 'id,name,email,picture.width(100).height(100)',
      );

      // Call backend API to authenticate with Facebook token
      final response = await _apiClient.client.post(
        '/auth/facebook',
        data: {
          'accessToken': accessToken,
          'email': userData['email'] ?? userData['id'],
          'name': userData['name'] ?? 'Facebook User',
          'photoUrl': userData['picture']?['data']?['url'],
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      final user = User.fromJson(authResponse.user).copyWith(
        token: authResponse.token,
        photoUrl: userData['picture']?['data']?['url'],
      );

      _apiClient.setAuthToken(authResponse.token);

      if (rememberMe) {
        await _localStorage.saveToken(authResponse.token);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      return user;
    } catch (e) {
      await _facebookAuth.logOut(); // Log out on error
      rethrow;
    }
  }

  /// Sign in with Apple
  Future<User> signInWithApple({bool rememberMe = false}) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        throw Exception('Failed to get Apple identity token');
      }

      // Call backend API to authenticate with Apple token
      final response = await _apiClient.client.post(
        '/auth/apple',
        data: {
          'identityToken': credential.identityToken,
          'email': credential.email,
          'name': '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
              .trim(),
          'userId': credential.userIdentifier,
        },
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

  /// Sign out from all OAuth providers
  Future<void> signOutFromOAuth() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _facebookAuth.logOut();
    } catch (_) {}
  }

  /// Generate mock JWT token with claims (for demo/testing)
  /// In production, this would be generated by the backend
  String _generateMockJWT({
    required String userId,
    required String email,
    required List<String> roles,
    required Duration expiresIn,
  }) {
    // Create JWT header and payload manually for demo
    // In production, use a proper JWT library
    final now = DateTime.now();
    final expiry = now.add(expiresIn);

    // Mock JWT format: header.payload.signature
    // This is NOT a real JWT - only for demo purposes
    // Base64 encode the payload (demo purposes only)
    return 'mock_jwt_${userId}_${now.millisecondsSinceEpoch}';
  }

  /// Validate JWT token expiry
  Future<bool> isTokenValid(String token) async {
    try {
      // In real implementation, use jwt_decoder to check expiry
      // For now, assume token is valid if it exists
      return token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Assign roles based on email (for testing/demo purposes)
  /// In production, this would come from the backend
  List<UserRole> _assignRolesByEmail(String email) {
    final lowerEmail = email.toLowerCase();

    // Demo: Assign roles based on email keywords
    final roles = <UserRole>[UserRole.consumer]; // Everyone starts as consumer

    if (lowerEmail.contains('member')) {
      roles.add(UserRole.coopMember);
    }
    if (lowerEmail.contains('franchise')) {
      roles.add(UserRole.franchiseOwner);
    }
    if (lowerEmail.contains('store')) {
      roles.add(UserRole.storeManager);
    }
    if (lowerEmail.contains('institution') || lowerEmail.contains('buyer')) {
      roles.add(UserRole.institutionalBuyer);
    }
    if (lowerEmail.contains('approver')) {
      roles.add(UserRole.institutionalApprover);
    }
    if (lowerEmail.contains('warehouse')) {
      roles.add(UserRole.warehouseStaff);
    }
    if (lowerEmail.contains('driver')) {
      roles.add(UserRole.deliveryDriver);
    }
    if (lowerEmail.contains('admin')) {
      return [UserRole.admin]; // Admin overrides other roles
    }
    if (lowerEmail.contains('superadmin')) {
      return [UserRole.superAdmin]; // Super admin overrides everything
    }

    return roles;
  }
}
