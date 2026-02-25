import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException({required this.message, this.code});

  @override
  String toString() => message;
}

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();

  factory FirebaseAuthService() {
    return _instance;
  }

  FirebaseAuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  bool get isUserLoggedIn => currentUser != null;

  String? get currentUserId => currentUser?.uid;

  String? get currentUserEmail => currentUser?.email;

  String? get currentUserDisplayName => currentUser?.displayName;

  String? get currentUserPhotoUrl => currentUser?.photoURL;

  // Email & Password Authentication
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
        return _firebaseAuth.currentUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException(message: 'Google sign-in cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Facebook Sign In
  Future<User?> signInWithFacebook() async {
    try {
      final loginResult = await _facebookAuth.login();

      if (loginResult.status == LoginStatus.cancelled) {
        throw AuthException(message: 'Facebook sign-in cancelled by user');
      }

      if (loginResult.status == LoginStatus.failed) {
        throw AuthException(
          message: 'Facebook sign-in failed: ${loginResult.message}',
        );
      }

      final token = loginResult.accessToken?.tokenString;
      if (token == null) {
        throw AuthException(message: 'Failed to get Facebook access token');
      }

      final credential = FacebookAuthProvider.credential(token);
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Apple Sign In
  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // Update User Profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  Future<void> updateEmail({required String newEmail}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail.trim());
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
        _facebookAuth.logOut(),
      ]);
    } catch (e) {
      throw AuthException(message: 'Failed to sign out: $e');
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          message:
              'This operation requires recent authentication. Please sign in again.',
          code: 'requires-recent-login',
        );
      }
      throw _handleFirebaseException(e);
    }
  }

  // Re-authenticate User
  Future<void> reauthenticateWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Get ID Token
  Future<String?> getIDToken({bool forceRefresh = false}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        return await user.getIdToken(forceRefresh);
      }
      throw AuthException(message: 'No user is currently logged in');
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Helper method to handle Firebase exceptions
  AuthException _handleFirebaseException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'weak-password' => 'The password provided is too weak.',
      'email-already-in-use' =>
        'An account already exists with that email address.',
      'invalid-email' => 'The email address is not valid.',
      'operation-not-allowed' =>
        'Email/password accounts are not enabled for this Firebase project.',
      'user-disabled' =>
        'The user account has been disabled by an administrator.',
      'user-not-found' => 'No user account found with this email address.',
      'wrong-password' => 'The password is incorrect. Please try again.',
      'invalid-credential' =>
        'Invalid credentials. Please check your email and password.',
      'missing-email' => 'An email address is required.',
      'missing-password' => 'A password is required.',
      'network-request-failed' =>
        'A network error occurred. Please check your connection.',
      'account-exists-with-different-credential' =>
        'An account already exists with a different sign-in method.',
      'cancelled-popup-request' => 'The popup sign-in flow was cancelled.',
      _ => 'Authentication failed: ${e.message}',
    };

    return AuthException(message: message, code: e.code);
  }
}
