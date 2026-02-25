import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/api/auth_service.dart';
import '../../core/api/service_locator.dart';
import '../../core/auth/user_persistence.dart';
import '../../core/auth/role.dart';
import '../../providers/auth_provider.dart' as global_auth;
import '../../providers/user_activity_providers.dart';
import 'user_model.dart';

/// Provider for the Auth Service
final authServiceProvider = Provider<AuthService>((ref) {
  // Ensure service locator is initialized in main.dart
  return serviceLocator.authService;
});

/// Stream provider to listen to real-time auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Controller for Auth UI logic
class AuthController extends AsyncNotifier<void> {
  AuthService get _authService => ref.read(authServiceProvider);

  @override
  Future<void> build() async {
    // Check for persisted session on startup
    try {
      print('🔄 AuthController initializing...');
      await _authService.initialize();
      print('✅ AuthController initialized successfully');
    } catch (e) {
      print('❌ AuthController initialization error: $e');
      rethrow;
    }
  }

  Future<void> signIn(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.login(
        LoginRequest(email: email, password: password),
        rememberMe: rememberMe,
      );
      // Save user to persistent secure storage
      await UserPersistence.saveUser(user);
      // Log login activity
      await ref.read(activityLoggerProvider.notifier).logLogin(email);
      // Update the global current user provider
      ref.read(global_auth.currentUserProvider.notifier).setUser(user);
      return;
    });
  }

  Future<void> signUp(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.register(
        RegisterRequest(name: '', email: email, password: password),
        rememberMe: rememberMe,
      );
      // Save user to persistent secure storage
      await UserPersistence.saveUser(user);
      // Log signup/login activity
      await ref.read(activityLoggerProvider.notifier).logLogin(email);
      // Update the global current user provider
      ref.read(global_auth.currentUserProvider.notifier).setUser(user);
      return;
    });
  }

  Future<void> signUpWithMembership(
    String email,
    String password, {
    required String membershipType,
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.register(
        RegisterRequest(
          name: '',
          email: email,
          password: password,
          role: membershipType,
        ),
        rememberMe: rememberMe,
      );
      // Save user to persistent secure storage
      await UserPersistence.saveUser(user);
      // Log signup and membership purchase
      await ref.read(activityLoggerProvider.notifier).logLogin(email);
      await ref
          .read(activityLoggerProvider.notifier)
          .logMembershipPurchase(membershipType, 5000);
      // Update the global current user provider
      ref.read(global_auth.currentUserProvider.notifier).setUser(user);
      return;
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.signInWithGoogle(rememberMe: true);
      // Save user to persistent secure storage
      await UserPersistence.saveUser(user);
      // Log login activity
      await ref.read(activityLoggerProvider.notifier).logLogin(user.email);
      ref.read(global_auth.currentUserProvider.notifier).setUser(user);
      return;
    });
  }

  Future<void> signInWithFacebook() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.signInWithFacebook(rememberMe: true);
      // Save user to persistent secure storage
      await UserPersistence.saveUser(user);
      // Log login activity
      await ref.read(activityLoggerProvider.notifier).logLogin(user.email);
      ref.read(global_auth.currentUserProvider.notifier).setUser(user);
      return;
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _authService.signInWithApple(rememberMe: true);
      // Save user to persistent secure storage
      await UserPersistence.saveUser(user);
      // Log login activity
      await ref.read(activityLoggerProvider.notifier).logLogin(user.email);
      ref.read(global_auth.currentUserProvider.notifier).setUser(user);
      return;
    });
  }

  Future<void> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.forgotPassword(email));
  }

  Future<void> forgotPasswordWithPhone(String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.forgotPassword(phone));
  }

  Future<void> resetPassword(
    String newPassword, {
    required String token,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.resetPassword(token: token, newPassword: newPassword),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Log logout activity before clearing
      await ref.read(activityLoggerProvider.notifier).logLogout();
      // Logout from service
      await _authService.logout();
      // Clear persisted user data
      await UserPersistence.clearUser();
      // Clear the global current user provider
      ref.read(global_auth.currentUserProvider.notifier).clearUser();
      return;
    });
  }

  /// Update user's selected role during onboarding
  Future<void> selectUserRole(UserRole selectedRole) async {
    print('🔷 selectUserRole called with: ${selectedRole.name}');

    // Get current user
    final currentUser = ref.read(global_auth.currentUserProvider);
    print('🔷 Current user: ${currentUser?.email}');

    if (currentUser == null) {
      print('❌ No user logged in');
      throw Exception('No user logged in');
    }

    // Update user's roles to include the selected role + mark role selection as completed
    final updatedUser = currentUser.copyWith(
      roles: [selectedRole], // Override with selected role
      roleSelectionCompleted:
          true, // Mark that user has explicitly selected a role
    );
    print(
        '🔷 Updated user roles: ${updatedUser.roles}, completed: ${updatedUser.roleSelectionCompleted}');

    // Step 1: Update in memory (SYNCHRONOUS - must complete instantly)
    ref.read(global_auth.currentUserProvider.notifier).setUser(updatedUser);
    print('✅ User updated in memory');

    // Step 2: Save to persistent storage (background task - don't block)
    Future.microtask(() {
      UserPersistence.saveUser(updatedUser).catchError((e) {
        print('⚠️ Warning: Failed to save to persistent storage: $e');
      });
    });
    print('✅ Persistence save scheduled (non-blocking)');

    // Step 3: Create Firestore profiles based on role
    // AWAIT these with timeout so profile exists when user navigates
    if (selectedRole == UserRole.coopMember) {
      try {
        await _createMemberProfile(
                currentUser.id, currentUser.email, currentUser.name)
            .timeout(const Duration(seconds: 8));
        print('✅ Member profile created');
      } catch (e) {
        print('⚠️ Warning: Member profile creation failed or timed out: $e');
        // Don't rethrow - allow role selection to continue even if profile creation fails
      }
    } else if (selectedRole == UserRole.institutionalBuyer) {
      try {
        await _createInstitutionalBuyerProfile(
                currentUser.id, currentUser.email, currentUser.name)
            .timeout(const Duration(seconds: 8));
        print('✅ Institutional buyer profile created');
      } catch (e) {
        print(
            '⚠️ Warning: Institutional buyer profile creation failed or timed out: $e');
        // Don't rethrow - allow role selection to continue
      }
    }

    print('✅ Role selection completed: ${selectedRole.name}');
    // Function now returns after profile is created (or timeout)
  }

  /// Create member profile in Firestore when user selects Member role
  Future<void> _createMemberProfile(
      String userId, String email, String name) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Create member document with initial data
      await firestore.collection('members').doc(userId).set({
        'userId': userId,
        'email': email,
        'name': name,
        'tier': 'bronze', // Start at bronze tier
        'loyaltyPoints': 0,
        'totalSpent': 0.0,
        'joiningDate': Timestamp.now(),
        'membershipStatus': 'active',
        'isFree': false,
        'isBasic': false,
        'isGold': false,
        'isPlatinum': false,
      });

      print('✅ Member profile created for $email');
    } catch (e) {
      print('⚠️ Warning: Failed to create member profile: $e');
      // Don't rethrow - let the role selection succeed even if member profile creation fails
    }
  }

  /// Create institutional buyer profile when user selects that role
  Future<void> _createInstitutionalBuyerProfile(
      String userId, String email, String name) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Create institutional buyer document
      await firestore.collection('institutional_buyers').doc(userId).set({
        'userId': userId,
        'email': email,
        'name': name,
        'organizationName': '', // To be filled in onboarding
        'organizationType': '', // School, Hospital, Company, etc
        'registrationDate': Timestamp.now(),
        'status':
            'pending_verification', // Will be activated after verification
        'creditLimit': 0.0,
        'creditUsed': 0.0,
        'paymentTerms': 'net_30',
        'deliveryLocations': [],
        'totalOrders': 0,
        'totalSpent': 0.0,
      });

      print('✅ Institutional buyer profile created for $email');
    } catch (e) {
      print('⚠️ Warning: Failed to create institutional buyer profile: $e');
      // Don't rethrow - let the role selection succeed
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

/// Initialize persisted user on app startup
final initializePersistedUserProvider = FutureProvider<void>((ref) async {
  try {
    final persistedUser = await UserPersistence.getUser();
    if (persistedUser != null) {
      print('🔄 Restored user from persistent storage: ${persistedUser.name}');
      ref.read(global_auth.currentUserProvider.notifier).setUser(persistedUser);
    }
  } catch (e) {
    print('⚠️ Failed to restore persisted user: $e');
  }
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});
