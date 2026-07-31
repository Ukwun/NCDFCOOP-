import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'local_storage.dart';
import 'package:coop_commerce/features/welcome/user_model.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/core/auth/user_context.dart';
import 'package:coop_commerce/core/config/social_auth_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  static const bool _mockAuthRequested = bool.fromEnvironment(
    'ENABLE_MOCK_AUTH',
    defaultValue: false,
  );

  /// Mock identities are deliberately opt-in and debug-only. A production
  /// outage must never authenticate a fabricated user or infer permissions
  /// from an email address.
  bool get _allowMockAuth => kDebugMode && _mockAuthRequested;

  void _requireMockAuthEnabled() {
    if (!_allowMockAuth) {
      throw StateError(
        'Authentication service is unavailable. Please try again shortly.',
      );
    }
  }

  Future<User> _firebaseUserToAppUser(
    firebase_auth.User firebaseUser, {
    String? fallbackName,
  }) async {
    final profileRef =
        FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
    Map<String, dynamic>? existing;
    var profileExists = false;
    try {
      final snapshot = await profileRef.get();
      existing = snapshot.data();
      profileExists = snapshot.exists;
    } on FirebaseException catch (error) {
      // Authentication is authoritative. App Check, an offline Firestore
      // client, or a transient rules propagation delay must not invalidate a
      // credential Firebase Auth has already created. The trusted role
      // provisioning function creates/merges this profile in the next step.
      debugPrint(
        'Deferred Firestore profile read (${error.code}): ${error.message}',
      );
    }
    final idToken = await firebaseUser.getIdToken();
    final profile = <String, dynamic>{
      ...?existing,
      'id': firebaseUser.uid,
      'email': firebaseUser.email ?? existing?['email'] ?? '',
      'name': firebaseUser.displayName ??
          existing?['name'] ??
          fallbackName ??
          'NCDFCOOP User',
      'photoUrl': firebaseUser.photoURL ?? existing?['photoUrl'],
      'token': idToken,
      if (existing?['marketplaceRole'] != null)
        'marketplaceRole': existing!['marketplaceRole'],
    };

    if (!profileExists) {
      try {
        await profileRef.set({
          'id': profile['id'],
          'email': profile['email'],
          'name': profile['name'],
          'photoUrl': profile['photoUrl'],
          'roleSelectionCompleted': false,
          'onboardingCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (error) {
        debugPrint(
          'Deferred Firestore profile creation (${error.code}): ${error.message}',
        );
      }
    }

    final user = User.fromJson(profile).copyWith(token: idToken);
    _apiClient.setAuthToken(idToken ?? '');
    await _localStorage.saveToken(idToken ?? '');
    await _localStorage.saveUser(user);
    _latestUser = user;
    _authStateController.add(user);
    return user;
  }

  Future<User> _loginWithFirebase(LoginRequest request) async {
    final credential =
        await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
      email: request.email.trim(),
      password: request.password,
    );
    return _firebaseUserToAppUser(credential.user!);
  }

  Future<User> _registerWithFirebase(RegisterRequest request) async {
    firebase_auth.User? createdUser;
    try {
      final credential = await firebase_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: request.email.trim().toLowerCase(),
            password: request.password,
          )
          .timeout(const Duration(seconds: 25));
      createdUser = credential.user!;
      await createdUser
          .updateDisplayName(request.name)
          .timeout(const Duration(seconds: 8));
      return await _firebaseUserToAppUser(
        createdUser,
        fallbackName: request.name,
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw StateError(_friendlyRegistrationError(error));
    } catch (error) {
      // Do not leave an unusable, half-created Auth account when profile
      // provisioning fails. That otherwise turns the next attempt into an
      // incorrect "email already in use" failure.
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      if (error is TimeoutException) {
        throw StateError(
          'Account creation timed out. Check your internet connection and try again.',
        );
      }
      if (error is FirebaseException) {
        throw StateError(
          'Your account could not be completed. Please check your connection and try again.',
        );
      }
      rethrow;
    }
  }

  String _friendlyRegistrationError(
    firebase_auth.FirebaseAuthException error,
  ) {
    return switch (error.code) {
      'email-already-in-use' =>
        'An account already exists for this email. Sign in instead, or reset your password.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' =>
        'Choose a stronger password with at least 8 characters.',
      'operation-not-allowed' =>
        'Email registration is temporarily unavailable. Please contact support.',
      'network-request-failed' =>
        'Firebase could not be reached. Check your internet connection and try again.',
      'too-many-requests' =>
        'Too many attempts were made. Wait a moment and try again.',
      _ => 'Account creation failed. Please try again.',
    };
  }

  // Stream controller for real-time auth state
  final _authStateController = StreamController<User?>.broadcast();
  User? _latestUser;
  Stream<User?> get authStateChanges async* {
    yield _latestUser;
    yield* _authStateController.stream;
  }

  AuthService(
    this._apiClient,
    this._localStorage, {
    AuditLogService? auditLogService,
  }) : _auditLogService = auditLogService ?? AuditLogService() {
    unawaited(initialize());
  }

  /// Initialize auth state from storage
  Future<void> initialize() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await _firebaseUserToAppUser(firebaseUser);
      return;
    }
    // Firebase is authoritative. Never resurrect a signed-out identity from
    // legacy local tokens or cached profile data.
    await _localStorage.clearToken();
    await _localStorage.clearUser();
    _latestUser = null;
    _apiClient.setAuthToken('');
    _authStateController.add(null);
  }

  String _normalizeIdentity(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  String _stableMockUserId({String? email, required String provider}) {
    final base = email?.trim().isNotEmpty == true
        ? _normalizeIdentity(email!)
        : _normalizeIdentity(provider);
    return 'user_$base';
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
    _requireMockAuthEnabled();
    try {
      print('📱 Creating mock user for $provider provider...');
      await Future.delayed(const Duration(milliseconds: 500));

      final roles = ['consumer'];
      final userId = _stableMockUserId(email: email, provider: provider);

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
    if (!_allowMockAuth) {
      return _loginWithFirebase(request);
    }
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
    _requireMockAuthEnabled();
    try {
      await Future.delayed(const Duration(seconds: 1));

      final roles = _assignRolesByEmail(request.email);
      final userId =
          _stableMockUserId(email: request.email, provider: 'credentials');
      final contexts = <UserRole, UserContext>{};
      for (final role in roles) {
        contexts[role] = UserContext(
          userId: userId,
          role: role,
          franchiseId: role.isWholesale ? 'franchise_ng_001' : null,
          storeId: role.isWholesale ? 'store_ng_001' : null,
          institutionId: role.isInstitutional ? 'inst_ng_001' : null,
          warehouseId: role.isLogistics ? 'warehouse_ng_001' : null,
        );
      }

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
    if (!_allowMockAuth) {
      return _registerWithFirebase(request);
    }
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
    _requireMockAuthEnabled();
    try {
      await Future.delayed(const Duration(seconds: 1));

      final userId =
          _stableMockUserId(email: request.email, provider: 'credentials');

      // Start all users as wholesale buyers
      // Users will select their actual role/membership type during onboarding
      // They can choose between Wholesale Buyer or Member (with Premium upgrade option)
      final userRoles = [UserRole.wholesaleBuyer];
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
      await firebase_auth.FirebaseAuth.instance.signOut();
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

      // Never fabricate an authenticated identity in production when refresh
      // fails. Mock tokens are available only for explicitly enabled debug
      // sessions.
      _requireMockAuthEnabled();

      // Debug-only fallback: generate a mock token.
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
    await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
      email: email.trim(),
      actionCodeSettings: firebase_auth.ActionCodeSettings(
        url: 'https://coop-commerce-8d43f.web.app/signin',
        handleCodeInApp: false,
        androidPackageName: 'com.example.coop_commerce',
      ),
    );
  }

  /// Reset password
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await firebase_auth.FirebaseAuth.instance.confirmPasswordReset(
      code: token,
      newPassword: newPassword,
    );
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
    if (!_allowMockAuth) {
      firebase_auth.UserCredential credential;
      if (kIsWeb) {
        final provider = firebase_auth.GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        credential =
            await firebase_auth.FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw StateError('Google sign-in was cancelled.');
        }
        final googleAuth = await googleUser.authentication;
        credential =
            await firebase_auth.FirebaseAuth.instance.signInWithCredential(
          firebase_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          ),
        );
      }
      return _firebaseUserToAppUser(credential.user!);
    }
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
      final userId =
          _stableMockUserId(email: googleUser.email, provider: 'google');
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
    if (!_allowMockAuth) {
      final provider = firebase_auth.FacebookAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'display': 'popup'});
      final credential = kIsWeb
          ? await firebase_auth.FirebaseAuth.instance.signInWithPopup(provider)
          : await firebase_auth.FirebaseAuth.instance
              .signInWithProvider(provider);
      return _firebaseUserToAppUser(credential.user!);
    }
    // Guard: keep Facebook button functional without the native Facebook plugin path.
    if (!SocialAuthConfig.isFacebookConfigured) {
      print(
          '⚠️ Facebook native auth is not configured. Using realistic fallback login.');
    }
    return _createMockUser(
      'Facebook',
      email: 'facebook.user@coopcommerce.local',
      rememberMe: rememberMe,
    );
  }

  /// Mock Facebook Sign-In for offline/development
  // ignore: unused_element
  Future<User> _facebookSignInWithMock(
    Map<String, dynamic> userData,
    bool rememberMe,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final roles = ['consumer'];
      final userId = _stableMockUserId(
        email: userData['email'] as String?,
        provider: 'facebook',
      );
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
    if (!_allowMockAuth) {
      final provider = firebase_auth.AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      final credential = kIsWeb
          ? await firebase_auth.FirebaseAuth.instance.signInWithPopup(provider)
          : await firebase_auth.FirebaseAuth.instance
              .signInWithProvider(provider);
      return _firebaseUserToAppUser(credential.user!);
    }
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
      final email =
          credential.email ?? '${credential.userIdentifier}@apple.com';
      final userId = _stableMockUserId(email: email, provider: 'apple');
      final fullName =
          '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();

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
    final roles = <UserRole>[
      UserRole.wholesaleBuyer
    ]; // Everyone starts as wholesale buyer

    if (lowerEmail.contains('member')) {
      roles.add(UserRole.coopMember);
    }
    if (lowerEmail.contains('premium')) {
      roles.add(UserRole.premiumMember);
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
