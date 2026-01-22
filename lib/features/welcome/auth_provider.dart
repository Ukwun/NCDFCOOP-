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
    // TODO: Implement actual Google Sign In
    state = const AsyncValue.loading();
    // state = await AsyncValue.guard(() => _authService.signInWithGoogle());
  }

  Future<void> signInWithFacebook() async {
    // TODO: Implement actual Facebook Sign In
    state = const AsyncValue.loading();
  }

  Future<void> signInWithApple() async {
    // TODO: Implement actual Apple Sign In
    state = const AsyncValue.loading();
  }

  Future<void> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.forgotPassword(email));
  }

  Future<void> forgotPasswordWithPhone(String phone) async {
    state = const AsyncValue.loading();
    // TODO: Implement phone reset in backend
  }

  Future<void> resetPassword(String newPassword) async {
    state = const AsyncValue.loading();
    // TODO: Need token from deep link
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.logout());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
