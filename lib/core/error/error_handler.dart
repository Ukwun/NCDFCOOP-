import 'dart:math' as math;

/// Error handling utility for managing app-wide errors
///
/// Provides consistent error handling and user-friendly messages
/// for network errors, payment failures, validation errors, etc.

class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({
    super.message =
        'Network connection error. Please check your internet connection.',
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

class PaymentException extends AppException {
  final double? amount;
  final String? paymentMethod;
  final String? transactionId;

  PaymentException({
    required super.message,
    super.code,
    this.amount,
    this.paymentMethod,
    this.transactionId,
    super.originalException,
    super.stackTrace,
  });
}

class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;

  ValidationException({
    required super.message,
    required this.fieldErrors,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

class TimeoutException extends AppException {
  final Duration timeout;

  TimeoutException({
    required super.message,
    required this.timeout,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

class AuthenticationException extends AppException {
  AuthenticationException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

class AuthorizationException extends AppException {
  AuthorizationException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required super.message,
    this.statusCode,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Error handler for providing user-friendly error messages
class ErrorHandler {
  static String getUserMessage(Exception exception) {
    if (exception is AppException) {
      return exception.message;
    } else if (exception is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else if (exception is NetworkException) {
      return 'Network error. Please check your connection.';
    } else if (exception is PaymentException) {
      return exception.message;
    } else if (exception is ValidationException) {
      return exception.message;
    } else if (exception is AuthenticationException) {
      return 'Authentication failed. Please log in again.';
    } else if (exception is AuthorizationException) {
      return 'You do not have permission to perform this action.';
    } else if (exception is ServerException) {
      if (exception.statusCode == 500) {
        return 'Server error. Please try again later.';
      } else if (exception.statusCode == 503) {
        return 'Service temporarily unavailable. Please try again later.';
      }
      return exception.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Log error for debugging/monitoring
  static void logError(Exception exception, {String? context}) {
    final errorMsg = exception.toString();
    final timestamp = DateTime.now();

    print('=== ERROR LOG ===');
    print('Timestamp: $timestamp');
    if (context != null) print('Context: $context');
    print('Error: $errorMsg');

    if (exception is AppException && exception.stackTrace != null) {
      print('Stack Trace: ${exception.stackTrace}');
    }

    print('================');

    // TODO: Send to error tracking service (Sentry, Firebase Crashlytics, etc.)
  }

  /// Determine if error is retryable
  static bool isRetryable(Exception exception) {
    if (exception is NetworkException) return true;
    if (exception is TimeoutException) return true;
    if (exception is ServerException) {
      // Retry on 5xx errors but not 4xx
      if (exception.statusCode == null) return true;
      return exception.statusCode! >= 500;
    }
    return false;
  }

  /// Determine if error is user-caused (input validation)
  static bool isUserError(Exception exception) {
    return exception is ValidationException;
  }

  /// Determine if user should be logged out
  static bool shouldLogout(Exception exception) {
    return exception is AuthenticationException;
  }
}

/// Retry logic for network and transient failures
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  });

  /// Calculate delay for retry attempt
  Duration getDelay(int attemptNumber) {
    final exponentialDelay =
        initialDelay * math.pow(backoffMultiplier, attemptNumber).toInt();
    return exponentialDelay > maxDelay ? maxDelay : exponentialDelay;
  }
}

/// Fluent API for handling errors
class ErrorBuilder {
  final Exception exception;
  String? _userMessage;
  String? _debugMessage;
  VoidCallback? _onRetry;
  VoidCallback? _onDismiss;
  bool _isRetryable = false;
  bool _isUserError = false;

  ErrorBuilder(this.exception);

  ErrorBuilder withUserMessage(String message) {
    _userMessage = message;
    return this;
  }

  ErrorBuilder withDebugMessage(String message) {
    _debugMessage = message;
    return this;
  }

  ErrorBuilder onRetry(VoidCallback callback) {
    _onRetry = callback;
    _isRetryable = true;
    return this;
  }

  ErrorBuilder onDismiss(VoidCallback callback) {
    _onDismiss = callback;
    return this;
  }

  ErrorBuilder markAsUserError() {
    _isUserError = true;
    return this;
  }

  /// Build error context
  ErrorContext build() {
    return ErrorContext(
      exception: exception,
      userMessage: _userMessage ?? ErrorHandler.getUserMessage(exception),
      debugMessage: _debugMessage,
      onRetry: _onRetry,
      onDismiss: _onDismiss,
      isRetryable: _isRetryable || ErrorHandler.isRetryable(exception),
      isUserError: _isUserError || ErrorHandler.isUserError(exception),
      shouldLogout: ErrorHandler.shouldLogout(exception),
    );
  }
}

/// Error context for UI presentation
class ErrorContext {
  final Exception exception;
  final String userMessage;
  final String? debugMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool isRetryable;
  final bool isUserError;
  final bool shouldLogout;

  ErrorContext({
    required this.exception,
    required this.userMessage,
    this.debugMessage,
    this.onRetry,
    this.onDismiss,
    required this.isRetryable,
    required this.isUserError,
    required this.shouldLogout,
  });

  String get emoji => isUserError
      ? '⚠️'
      : isRetryable
          ? '🔄'
          : '❌';

  String get title => isUserError
      ? 'Invalid Input'
      : isRetryable
          ? 'Something went wrong'
          : 'Error';
}

typedef VoidCallback = void Function();
