import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/auth_service.dart';
import '../../core/api/service_locator.dart';
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
    await _authService.initialize();
  }

  Future<void> signIn(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.login(
        LoginRequest(email: email, password: password),
        rememberMe: rememberMe,
      ),
    );
  }

  Future<void> signUp(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.register(
        RegisterRequest(name: '', email: email, password: password),
        rememberMe: rememberMe,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signInWithGoogle(rememberMe: true),
    );
  }

  Future<void> signInWithFacebook() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signInWithFacebook(rememberMe: true),
    );
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signInWithApple(rememberMe: true),
    );
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
    state = await AsyncValue.guard(() => _authService.logout());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});
