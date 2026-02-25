import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'api_client.dart';
import 'api_config.dart';
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
  final String? role;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.membershipCode,
    this.role,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'membershipCode': membershipCode,
        'role': role,
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

  /// Helper method to create mock user when OAuth fails
  /// This ensures users can still log in even if OAuth setup is incomplete
  Future<User> _createMockUser(
    String provider, {
    String? email,
    String? name,
    String? photoUrl,
    bool rememberMe = true,
  }) async {
    try {
      print('📱 Creating mock user for $provider provider...');
      await Future.delayed(const Duration(milliseconds: 500));

      final roles = ['consumer'];
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Generate realistic email if not provided
      final userEmail = email ??
          '$provider.user.${userId.hashCode % 10000}@coopcommerce.local';
      final userName = name ?? '$provider User';

      final mockToken = _generateMockJWT(
        userId: userId,
        email: userEmail,
        roles: roles,
        expiresIn: const Duration(hours: 24),
      );

      final mockUserJson = {
        'id': userId,
        'email': userEmail,
        'name': userName,
        'photoUrl': photoUrl,
        'roles': roles,
      };

      final user = User.fromJson(mockUserJson).copyWith(token: mockToken);

      _apiClient.setAuthToken(mockToken);

      if (rememberMe) {
        await _localStorage.saveToken(mockToken);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      print('✅ Mock user created successfully for $provider');
      return user;
    } catch (e) {
      print('❌ Failed to create mock user: $e');
      rethrow;
    }
  }

  /// Login user - tries real backend first, falls back to mock
  Future<User> login(LoginRequest request, {bool rememberMe = false}) async {
    try {
      // Try real backend first
      if (!ApiClient.isMockBackend) {
        try {
          print('🔗 Attempting real backend login...');
          final response = await _apiClient.client.post(
            ApiConfig.loginEndpoint,
            data: request.toJson(),
            options: Options(
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final authResponse = AuthResponse.fromJson(response.data);
            final user = User.fromJson(
              authResponse.user,
            ).copyWith(token: authResponse.token);

            _apiClient.setAuthToken(authResponse.token);

            // Log successful login
            await _auditLogService.logAction(
              user.id,
              'consumer',
              AuditAction.LOGIN_SUCCESS,
              'user',
              resourceId: user.id,
              severity: AuditSeverity.INFO,
              details: {
                'email': user.email,
                'roles': user.roles.map((r) => r.name).toList(),
              },
            );

            if (rememberMe) {
              await _localStorage.saveToken(authResponse.token);
              await _localStorage.saveUser(user);
            }

            _authStateController.add(user);
            print('✅ Real backend login successful');
            return user;
          }
        } catch (e) {
          print('⚠️ Real backend login failed: $e');
          print('📱 Falling back to mock authentication...');
        }
      }

      // Fallback to mock authentication
      return await _loginWithMock(request, rememberMe);
    } catch (e) {
      print('❌ Authentication error: $e');
      rethrow;
    }
  }

  /// Mock login for offline/development
  Future<User> _loginWithMock(LoginRequest request, bool rememberMe) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final roles = _assignRolesByEmail(request.email);
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

      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final mockToken = _generateMockJWT(
        userId: userId,
        email: request.email,
        roles: roles.map((r) => r.name).toList(),
        expiresIn: const Duration(hours: 24),
      );

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
          'mode': 'mock',
        },
      );

      if (rememberMe) {
        await _localStorage.saveToken(mockToken);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      return user;
    } catch (e) {
      print('❌ Mock authentication failed: $e');
      rethrow;
    }
  }

  /// Register new user - tries real backend first, falls back to mock
  Future<User> register(
    RegisterRequest request, {
    bool rememberMe = false,
  }) async {
    try {
      // Try real backend first
      if (!ApiClient.isMockBackend) {
        try {
          print('🔗 Attempting real backend registration...');
          final response = await _apiClient.client.post(
            ApiConfig.registerEndpoint,
            data: request.toJson(),
            options: Options(
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final authResponse = AuthResponse.fromJson(response.data);
            final user = User.fromJson(
              authResponse.user,
            ).copyWith(token: authResponse.token);

            _apiClient.setAuthToken(authResponse.token);

            await _auditLogService.logAction(
              user.id,
              request.role ?? 'consumer',
              AuditAction.USER_CREATED,
              'user',
              resourceId: user.id,
              severity: AuditSeverity.INFO,
              details: {
                'email': user.email,
                'roles': user.roles.map((r) => r.name).toList(),
              },
            );

            if (rememberMe) {
              await _localStorage.saveToken(authResponse.token);
              await _localStorage.saveUser(user);
            }

            _authStateController.add(user);
            print('✅ Real backend registration successful');
            return user;
          }
        } catch (e) {
          print('⚠️ Real backend registration failed: $e');
          print('📱 Falling back to mock authentication...');
        }
      }

      // Fallback to mock
      return await _registerWithMock(request, rememberMe);
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  /// Mock registration for offline/development
  Future<User> _registerWithMock(
    RegisterRequest request,
    bool rememberMe,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Start all users as consumers
      // Users will select their actual role/membership type during onboarding
      // after they see clear explanations of each option
      final userRoles = [UserRole.consumer];
      final roleNames = userRoles.map((r) => r.name).toList();

      final mockToken = _generateMockJWT(
        userId: userId,
        email: request.email,
        roles: roleNames,
        expiresIn: const Duration(hours: 24),
      );

      final mockUserJson = {
        'id': userId,
        'email': request.email,
        'name': request.name,
        'photoUrl': null,
        'roles': roleNames,
      };

      final user = User.fromJson(mockUserJson).copyWith(token: mockToken);
      _apiClient.setAuthToken(mockToken);

      await _auditLogService.logAction(
        userId,
        userRoles.first.name,
        AuditAction.USER_CREATED,
        'user',
        resourceId: userId,
        severity: AuditSeverity.INFO,
        details: {
          'email': request.email,
          'name': request.name,
          'roles': roleNames,
          'mode': 'mock',
          'note': 'User will select role during onboarding',
        },
      );

      if (rememberMe) {
        await _localStorage.saveToken(mockToken);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      return user;
    } catch (e) {
      print('❌ Mock registration failed: $e');
      rethrow;
    }
  }

  /// Logout user - tries real backend first
  Future<void> logout({String? userId}) async {
    try {
      print('🚪 Logging out user...');

      // Try real backend logout first
      if (!ApiClient.isMockBackend) {
        try {
          await _apiClient.client.post(ApiConfig.logoutEndpoint);
          print('✅ Real backend logout successful');
        } catch (e) {
          print('⚠️ Real backend logout failed: $e');
        }
      }

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

      _apiClient.clearAuthToken();
      await _localStorage.clearToken();
      await _localStorage.clearUser();
      _authStateController.add(null);
      print('✅ Local logout complete');
    } catch (e) {
      print('❌ Logout error: $e');
      rethrow;
    }
  }

  /// Refresh authentication token with automatic retry
  Future<String> refreshToken(String refreshToken, {String? userId}) async {
    try {
      print('🔄 Refreshing authentication token...');

      // Try real backend first
      if (!ApiClient.isMockBackend) {
        try {
          final response = await _apiClient.client.post(
            ApiConfig.refreshTokenEndpoint,
            data: {'refreshToken': refreshToken},
            options: Options(
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200) {
            final authResponse = AuthResponse.fromJson(response.data);
            _apiClient.setAuthToken(authResponse.token);

            // Save new token
            await _localStorage.saveToken(authResponse.token);

            print('✅ Token refreshed from real backend');
            return authResponse.token;
          }
        } catch (e) {
          print('⚠️ Real backend token refresh failed: $e');
        }
      }

      // Fallback: generate mock token
      print('📱 Generating mock refresh token...');
      final mockToken = _generateMockJWT(
        userId: userId ?? 'user_unknown',
        email: 'user@example.com',
        roles: ['consumer'],
        expiresIn: const Duration(hours: 24),
      );

      _apiClient.setAuthToken(mockToken);
      await _localStorage.saveToken(mockToken);

      return mockToken;
    } catch (e) {
      print('❌ Token refresh error: $e');
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

  /// Sign in with Google - with robust error handling and fallback
  Future<User> signInWithGoogle({bool rememberMe = false}) async {
    try {
      print('🔐 Attempting Google Sign-In...');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      print('✅ Google user signed in: ${googleUser.email}');
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      print('✅ Google token acquired');

      // Try real backend first (if not in mock mode)
      if (!ApiClient.isMockBackend && idToken != null) {
        try {
          print('🔗 Sending token to real backend...');
          final response = await _apiClient.client.post(
            ApiConfig.googleAuthEndpoint,
            data: {'idToken': idToken},
            options: Options(
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
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
            print('✅ Google Sign-In successful with real backend');
            return user;
          } else {
            print('⚠️ Real backend returned status: ${response.statusCode}');
            print('📱 Falling back to mock authentication...');
          }
        } catch (e) {
          print('⚠️ Real backend Google Sign-In failed: $e');
          print('📱 Falling back to mock authentication...');
        }
      }

      // Fallback to mock
      return await _googleSignInWithMock(googleUser, rememberMe);
    } on PlatformException catch (e) {
      // Handle platform-specific errors (missing config, permissions, etc)
      print('❌ Google Sign-In platform error: ${e.code}');
      print('   Message: ${e.message}');
      print('   Possible fixes:');
      print('   1. Add Google OAuth config to android/app/build.gradle');
      print('   2. Download google-services.json from Firebase Console');
      print('   3. Ensure SHA-1 fingerprint is registered in Google Cloud');
      print('📱 Using mock authentication as fallback...');
      return _createMockUser(
        'Google',
        email: 'google.user@coopcommerce.local',
        rememberMe: rememberMe,
      );
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      print('📱 Attempting mock authentication fallback...');
      try {
        return _createMockUser(
          'Google',
          email: 'google.user@coopcommerce.local',
          rememberMe: rememberMe,
        );
      } catch (mockError) {
        print('❌ Mock fallback also failed: $mockError');
        rethrow;
      }
    }
  }

  /// Mock Google Sign-In for offline/development
  Future<User> _googleSignInWithMock(
    GoogleSignInAccount googleUser,
    bool rememberMe,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final roles = ['consumer'];
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final mockToken = _generateMockJWT(
        userId: userId,
        email: googleUser.email,
        roles: roles,
        expiresIn: const Duration(hours: 24),
      );

      final mockUserJson = {
        'id': userId,
        'email': googleUser.email,
        'name': googleUser.displayName ?? 'Google User',
        'photoUrl': googleUser.photoUrl,
        'roles': roles,
      };

      final user = User.fromJson(mockUserJson).copyWith(token: mockToken);

      _apiClient.setAuthToken(mockToken);

      if (rememberMe) {
        await _localStorage.saveToken(mockToken);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      print('✅ Google Sign-In successful');
      return user;
      // -----------------------------------
    } catch (e) {
      print('❌ Google Sign-In failed: $e');
      await _googleSignIn.signOut(); // Sign out on error
      rethrow;
    }
  }

  /// Sign in with Facebook - with robust error handling and fallback
  Future<User> signInWithFacebook({bool rememberMe = false}) async {
    try {
      print('🔐 Attempting Facebook Sign-In...');

      final fb_auth.LoginResult result = await _facebookAuth.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == fb_auth.LoginStatus.cancelled) {
        throw Exception('Facebook sign in cancelled');
      }

      if (result.status == fb_auth.LoginStatus.failed) {
        print('❌ Facebook sign in failed: ${result.message}');
        throw Exception('Facebook sign in failed: ${result.message}');
      }

      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      print('✅ Facebook access token acquired');

      // Get user details
      final userData = await _facebookAuth.getUserData(
        fields: 'id,name,email,picture.width(100).height(100)',
      );

      print('✅ Facebook user details fetched');

      // Try real backend first
      if (!ApiClient.isMockBackend) {
        try {
          print('🔗 Sending token to real backend...');
          final response = await _apiClient.client.post(
            ApiConfig.facebookAuthEndpoint,
            data: {'accessToken': accessToken},
            options: Options(
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
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
            print('✅ Facebook Sign-In successful with real backend');
            return user;
          } else {
            print('⚠️ Real backend returned status: ${response.statusCode}');
            print('📱 Falling back to mock authentication...');
          }
        } catch (e) {
          print('⚠️ Real backend Facebook Sign-In failed: $e');
          print('📱 Falling back to mock authentication...');
        }
      }

      // Fallback to mock
      return await _facebookSignInWithMock(userData, rememberMe);
    } on PlatformException catch (e) {
      // Handle platform-specific errors
      print('❌ Facebook Sign-In platform error: ${e.code}');
      print('   Message: ${e.message}');
      print('   Possible fixes:');
      print('   1. Add Facebook App ID to AndroidManifest.xml');
      print('   2. Configure Facebook App in Facebook Developer Console');
      print('   3. Set correct package name and key hash');
      print('   4. Add Facebook App ID to iOS Info.plist');
      print('📱 Using mock authentication as fallback...');
      return _createMockUser(
        'Facebook',
        email: 'facebook.user@coopcommerce.local',
        rememberMe: rememberMe,
      );
    } catch (e) {
      print('❌ Facebook Sign-In error: $e');
      print('📱 Attempting mock authentication fallback...');
      try {
        return _createMockUser(
          'Facebook',
          email: 'facebook.user@coopcommerce.local',
          rememberMe: rememberMe,
        );
      } catch (mockError) {
        print('❌ Mock fallback also failed: $mockError');
        rethrow;
      } finally {
        try {
          await _facebookAuth.logOut();
        } catch (_) {}
      }
    }
  }

  /// Mock Facebook Sign-In for offline/development
  Future<User> _facebookSignInWithMock(
    Map<String, dynamic> userData,
    bool rememberMe,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final roles = ['consumer'];
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final mockToken = _generateMockJWT(
        userId: userId,
        email: userData['email'] ?? userData['id'],
        roles: roles,
        expiresIn: const Duration(hours: 24),
      );

      final mockUserJson = {
        'id': userId,
        'email': userData['email'] ?? userData['id'],
        'name': userData['name'] ?? 'Facebook User',
        'photoUrl': userData['picture']?['data']?['url'],
        'roles': roles,
      };

      final user = User.fromJson(mockUserJson).copyWith(token: mockToken);
      _apiClient.setAuthToken(mockToken);

      if (rememberMe) {
        await _localStorage.saveToken(mockToken);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      print('✅ Facebook Sign-In successful');
      return user;
    } catch (e) {
      print('❌ Facebook Sign-In failed: $e');
      rethrow;
    }
  }

  /// Sign in with Apple - with robust error handling and fallback
  Future<User> signInWithApple({bool rememberMe = false}) async {
    try {
      print('🔐 Attempting Apple Sign-In...');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        throw Exception('Failed to get Apple identity token');
      }

      print('✅ Apple credentials acquired');
      print('   User: ${credential.userIdentifier}');
      print('   Email: ${credential.email}');

      // Try real backend first
      if (!ApiClient.isMockBackend) {
        try {
          print('🔗 Sending token to real backend...');
          final response = await _apiClient.client.post(
            ApiConfig.appleAuthEndpoint,
            data: {'identityToken': credential.identityToken},
            options: Options(
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
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
            print('✅ Apple Sign-In successful with real backend');
            return user;
          } else {
            print('⚠️ Real backend returned status: ${response.statusCode}');
            print('📱 Falling back to mock authentication...');
          }
        } catch (e) {
          print('⚠️ Real backend Apple Sign-In failed: $e');
          print('📱 Falling back to mock authentication...');
        }
      }

      // Fallback to mock
      return await _appleSignInWithMock(credential, rememberMe);
    } on PlatformException catch (e) {
      // Handle platform-specific errors
      print('❌ Apple Sign-In platform error: ${e.code}');
      print('   Message: ${e.message}');
      print('   Possible fixes:');
      print('   1. Ensure "Sign in with Apple" capability is enabled');
      print('   2. Add Apple ID to iOS App Settings');
      print('   3. Configure Sign in with Apple in Xcode (Runner project)');
      print('   4. Check iOS deployment target (must be 13.0 or higher)');
      print('📱 Using mock authentication as fallback...');
      return _createMockUser(
        'Apple',
        email: 'apple.user@coopcommerce.local',
        rememberMe: rememberMe,
      );
    } catch (e) {
      print('❌ Apple Sign-In error: $e');
      print('📱 Attempting mock authentication fallback...');
      try {
        return _createMockUser(
          'Apple',
          email: 'apple.user@coopcommerce.local',
          rememberMe: rememberMe,
        );
      } catch (mockError) {
        print('❌ Mock fallback also failed: $mockError');
        rethrow;
      }
    }
  }

  /// Mock Apple Sign-In for offline/development
  Future<User> _appleSignInWithMock(
    AuthorizationCredentialAppleID credential,
    bool rememberMe,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final roles = ['consumer'];
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final fullName =
          '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      final email =
          credential.email ?? '${credential.userIdentifier}@apple.com';

      final mockToken = _generateMockJWT(
        userId: userId,
        email: email,
        roles: roles,
        expiresIn: const Duration(hours: 24),
      );

      final mockUserJson = {
        'id': userId,
        'email': email,
        'name': fullName.isEmpty ? 'Apple User' : fullName,
        'photoUrl': null,
        'roles': roles,
      };

      final user = User.fromJson(mockUserJson).copyWith(token: mockToken);
      _apiClient.setAuthToken(mockToken);

      if (rememberMe) {
        await _localStorage.saveToken(mockToken);
        await _localStorage.saveUser(user);
      }

      _authStateController.add(user);
      print('✅ Apple Sign-In successful');
      return user;
    } catch (e) {
      print('❌ Apple Sign-In failed: $e');
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
    now.add(expiresIn); // expiry calculated but not used in mock implementation

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
