import 'package:flutter/foundation.dart';

/// Global exception handler for production environments
class ExceptionHandler {
  static void setupGlobalExceptionHandler() {
    // Catch all uncaught exceptions in the main isolate
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Catch all unhandled errors in async code
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleAsyncError(error, stack);
      return true; // Indicates error was handled
    };
  }

  /// Handle Flutter framework errors
  static void _handleFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, show the full error
      FlutterError.presentError(details);
    } else {
      // In production, log the error silently
      _logError(
        'Flutter Error',
        details.exception,
        details.stack ?? StackTrace.current,
      );
    }
  }

  /// Handle async errors
  static void _handleAsyncError(Object error, StackTrace stack) {
    _logError(
      'Async Error',
      error,
      stack,
    );
  }

  /// Log errors securely (without exposing sensitive info)
  static void _logError(
    String type,
    Object error,
    StackTrace stack,
  ) {
    // In production, you would send this to a logging service
    // For now, we'll log to console in debug mode only
    if (kDebugMode) {
      debugPrint('═' * 80);
      debugPrint('[$type]');
      debugPrint('Error: $error');
      debugPrint('Stack Trace:');
      debugPrint(stack.toString());
      debugPrint('═' * 80);
    }
  }
}
