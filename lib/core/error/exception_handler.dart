import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Global exception handler for production environments
class ExceptionHandler {
  static bool _crashReportingReady = false;

  static Future<void> initializeCrashReporting() async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    _crashReportingReady = true;
  }

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
    if (_crashReportingReady && !kIsWeb) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: type,
        fatal: false,
      );
    }
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
