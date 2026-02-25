import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Improved error handling and user-friendly messages
class ErrorHandler {
  /// Convert Firebase Auth errors to user-friendly messages
  static String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up instead.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Login is currently disabled. Please try again later.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'timeout':
        return 'Connection timeout. Please try again.';
      case 'provider-already-linked':
        return 'This account is already linked to another provider.';
      case 'credential-already-in-use':
        return 'These credentials are already associated with another account.';
      default:
        return 'Login failed: ${e.message ?? 'Unknown error'}. Please try again.';
    }
  }

  /// Convert Firestore errors to user-friendly messages
  static String getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to access this resource. Please try logging out and back in.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This item already exists. Please try a different one.';
      case 'failed-precondition':
        return 'Operation failed due to system constraints. Please try again later.';
      case 'aborted':
        return 'Operation was cancelled. Please try again.';
      case 'out-of-range':
        return 'Invalid range specified. Please check your input.';
      case 'unauthenticated':
        return 'You need to be logged in to perform this action.';
      case 'invalid-argument':
        return 'Invalid data provided. Please check your input.';
      case 'resource-exhausted':
        return 'Service quota exceeded. Please try again later.';
      case 'unavailable':
        return 'Service is currently unavailable. Please try again later.';
      case 'internal':
        return 'Internal server error. Please try again later.';
      case 'data-loss':
        return 'Unexpected data loss occurred. Please refresh and try again.';
      case 'deadline-exceeded':
        return 'Request took too long. Please check your connection and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred: ${e.message ?? 'Unknown error'}. Please try again.';
    }
  }

  /// Generic error message converter
  static String getErrorMessage(dynamic error) {
    debugPrint('❌ Error: $error');

    if (error == null) {
      return 'An unknown error occurred. Please try again.';
    }

    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else if (error is String) {
      // Already a string message
      return error;
    } else if (error is Exception) {
      final message = error.toString();
      if (message.contains('socket')) {
        return 'Network connection error. Please check your internet.';
      } else if (message.contains('timeout')) {
        return 'Request timed out. Please try again.';
      }
      return message;
    }

    return 'An unexpected error occurred: $error';
  }

  /// Parse and improve error message
  static String parseError(dynamic error) {
    return getErrorMessage(error);
  }

  /// Log error with context
  static void logError({
    required String context,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    debugPrint('''
╔═══════════════════════════════════════════════════════════════════════════╗
║ ❌ ERROR in $context
║ Message: ${getErrorMessage(error)}
║ Type: ${error.runtimeType}
║ Details: $error
${stackTrace != null ? '║ Stack: $stackTrace' : ''}
╚═══════════════════════════════════════════════════════════════════════════╝
''');
  }

  /// Categorize errors by severity
  static ErrorSeverity getErrorSeverity(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
        case 'timeout':
          return ErrorSeverity.warning;
        case 'too-many-requests':
          return ErrorSeverity.warning;
        default:
          return ErrorSeverity.error;
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
        case 'resource-exhausted':
          return ErrorSeverity.warning;
        case 'permission-denied':
        case 'unauthenticated':
          return ErrorSeverity.critical;
        default:
          return ErrorSeverity.error;
      }
    }

    return ErrorSeverity.error;
  }

  /// Get user-appropriate action for error
  static String getErrorAction(dynamic error) {
    final severity = getErrorSeverity(error);

    switch (severity) {
      case ErrorSeverity.critical:
        return 'Please logout and login again';
      case ErrorSeverity.error:
        return 'Please try again';
      case ErrorSeverity.warning:
        return 'Please check your connection and try again';
    }
  }
}

/// Error severity levels
enum ErrorSeverity {
  warning, // Non-critical, recoverable
  error, // Standard error, user action needed
  critical, // Critical error, needs immediate action
}

/// Extension for better error handling in widgets
extension ErrorHandling on BuildContext {
  /// Show error snackbar with improved message
  void showErrorSnackBar(
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = ErrorHandler.getErrorMessage(error);
    final action = ErrorHandler.getErrorAction(error);

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Error',
              style: Theme.of(this).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(this).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              action,
              style: Theme.of(this).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(this).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show info snackbar
  void showInfoSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(this).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show warning snackbar
  void showWarningSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(this).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Custom exceptions for the app
class AppException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({String? message, dynamic error, StackTrace? stackTrace})
      : super(
          message: message ?? 'Network error occurred',
          originalError: error,
          stackTrace: stackTrace,
        );
}

class AuthException extends AppException {
  AuthException({String? message, dynamic error, StackTrace? stackTrace})
      : super(
          message: message ?? 'Authentication error occurred',
          originalError: error,
          stackTrace: stackTrace,
        );
}

class DataException extends AppException {
  DataException({String? message, dynamic error, StackTrace? stackTrace})
      : super(
          message: message ?? 'Data error occurred',
          originalError: error,
          stackTrace: stackTrace,
        );
}

class ValidationException extends AppException {
  ValidationException({String? message, dynamic error, StackTrace? stackTrace})
      : super(
          message: message ?? 'Validation error occurred',
          originalError: error,
          stackTrace: stackTrace,
        );
}
