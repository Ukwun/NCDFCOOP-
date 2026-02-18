/// User-friendly error messages for different error types
class AppErrorMessages {
  // Network errors
  static const String noInternet =
      'Please check your internet connection and try again.';
  static const String timeout = 'The request took too long. Please try again.';
  static const String connectionFailed =
      'Failed to connect to the server. Please try again.';

  // Authentication errors
  static const String invalidCredentials = 'Invalid email or password.';
  static const String accountNotFound =
      'Account not found. Please check your email.';
  static const String accountDisabled = 'This account has been disabled.';
  static const String unauthorizedAccess =
      'You do not have permission to access this.';
  static const String sessionExpired =
      'Your session has expired. Please log in again.';

  // Validation errors
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String invalidPassword =
      'Password must be at least 8 characters.';
  static const String passwordsDoNotMatch = 'Passwords do not match.';
  static const String requiredField = 'This field is required.';
  static const String invalidPhoneNumber = 'Please enter a valid phone number.';

  // Business logic errors
  static const String insufficientInventory = 'This item is out of stock.';
  static const String minimumOrderQuantity =
      'Quantity is below the minimum order amount.';
  static const String maximumOrderQuantity =
      'Quantity exceeds the maximum allowed.';
  static const String productNotFound = 'This product is no longer available.';
  static const String cartEmpty = 'Your cart is empty.';
  static const String paymentFailed =
      'Payment failed. Please try another payment method.';
  static const String orderFailed = 'Failed to create order. Please try again.';

  // Permission errors
  static const String locationPermissionDenied =
      'Location permission is required for this feature.';
  static const String cameraPermissionDenied =
      'Camera permission is required to take photos.';
  static const String photoPermissionDenied =
      'Photo library permission is required.';

  // Generic errors
  static const String somethingWentWrong =
      'Something went wrong. Please try again.';
  static const String pageNotFound = 'This page could not be found.';
  static const String dataNotFound = 'No data available.';

  /// Get user-friendly message from exception
  static String fromException(Exception e) {
    final message = e.toString().toLowerCase();

    if (message.contains('network') || message.contains('socket')) {
      return noInternet;
    }
    if (message.contains('timeout')) {
      return timeout;
    }
    if (message.contains('unauthorized') || message.contains('403')) {
      return unauthorizedAccess;
    }
    if (message.contains('not found') || message.contains('404')) {
      return pageNotFound;
    }
    if (message.contains('invalid')) {
      return invalidCredentials;
    }

    return somethingWentWrong;
  }

  /// Get user-friendly message from error code
  static String fromErrorCode(String? code) {
    switch (code) {
      case 'NETWORK_ERROR':
        return noInternet;
      case 'TIMEOUT':
        return timeout;
      case 'UNAUTHORIZED':
        return unauthorizedAccess;
      case 'NOT_FOUND':
        return pageNotFound;
      case 'INVALID_CREDENTIALS':
        return invalidCredentials;
      case 'SESSION_EXPIRED':
        return sessionExpired;
      case 'INSUFFICIENT_INVENTORY':
        return insufficientInventory;
      case 'MINIMUM_ORDER_QUANTITY':
        return minimumOrderQuantity;
      case 'PAYMENT_FAILED':
        return paymentFailed;
      default:
        return somethingWentWrong;
    }
  }
}

/// Exception classes for different error types
class AppException implements Exception {
  final String message;
  final String? code;
  final String? stackTrace;
  final Exception? originalException;

  AppException({
    required this.message,
    this.code,
    this.stackTrace,
    this.originalException,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({
    super.message = AppErrorMessages.noInternet,
    super.originalException,
  }) : super(
          code: 'NETWORK_ERROR',
        );
}

class TimeoutException extends AppException {
  TimeoutException({
    super.message = AppErrorMessages.timeout,
    super.originalException,
  }) : super(
          code: 'TIMEOUT',
        );
}

class AuthenticationException extends AppException {
  AuthenticationException({
    required super.message,
    String super.code = 'AUTH_ERROR',
    super.originalException,
  });
}

class PermissionException extends AppException {
  PermissionException({
    required String permission,
    super.originalException,
  }) : super(
          message: 'Permission required: $permission',
          code: 'PERMISSION_DENIED',
        );
}

class ValidationException extends AppException {
  ValidationException({
    required super.message,
    super.originalException,
  }) : super(
          code: 'VALIDATION_ERROR',
        );
}

class BusinessLogicException extends AppException {
  BusinessLogicException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(
          code: code ?? 'BUSINESS_LOGIC_ERROR',
        );
}

/// Error handler utility
class ErrorHandler {
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is Exception) {
      return AppErrorMessages.fromException(error);
    }

    return AppErrorMessages.somethingWentWrong;
  }

  static String getErrorCode(dynamic error) {
    if (error is AppException) {
      return error.code ?? 'UNKNOWN_ERROR';
    }
    return 'UNKNOWN_ERROR';
  }

  static Future<void> logError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) async {
    // TODO: Implement logging to Firebase Crashlytics or similar
    // This will be crucial for debugging production issues
    print('ERROR in $context: $error');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }

  static Future<void> logErrorAndReport(
    dynamic error, {
    required String context,
    StackTrace? stackTrace,
    bool reportToServer = true,
  }) async {
    await logError(error, context: context, stackTrace: stackTrace);

    if (reportToServer) {
      // TODO: Send to server for monitoring
    }
  }
}
