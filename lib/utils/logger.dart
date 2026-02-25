import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _defaultTag = 'CoopCommerce';

  static void debug(String message,
      {String tag = _defaultTag, dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[$tag] 🔵 DEBUG: $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  static void info(String message,
      {String tag = _defaultTag, dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[$tag] ℹ️ INFO: $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  static void warning(String message,
      {String tag = _defaultTag, dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[$tag] ⚠️ WARNING: $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  static void error(String message,
      {String tag = _defaultTag, dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[$tag] ❌ ERROR: $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  static void success(String message, {String tag = _defaultTag}) {
    if (kDebugMode) {
      print('[$tag] ✅ SUCCESS: $message');
    }
  }

  static void verbose(String message, {String tag = _defaultTag}) {
    if (kDebugMode) {
      print('[$tag] 📝 VERBOSE: $message');
    }
  }

  static void logMethodCall(String methodName,
      {String tag = _defaultTag, Map<String, dynamic>? params}) {
    if (kDebugMode) {
      String message = '→ $methodName()';
      if (params != null && params.isNotEmpty) {
        message += ' - Params: $params';
      }
      print('[$tag] 📞 $message');
    }
  }

  static void logMethodReturn(String methodName,
      {String tag = _defaultTag, dynamic result}) {
    if (kDebugMode) {
      String message = '← $methodName()';
      if (result != null) {
        message += ' - Result: $result';
      }
      print('[$tag] 📤 $message');
    }
  }

  static void logNetworkRequest(
    String method,
    String endpoint, {
    String tag = _defaultTag,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (kDebugMode) {
      print('[$tag] 🌐 $method $endpoint');
      if (headers != null) {
        print('  Headers: $headers');
      }
      if (body != null) {
        print('  Body: $body');
      }
    }
  }

  static void logNetworkResponse(
    String method,
    String endpoint, {
    String tag = _defaultTag,
    int? statusCode,
    dynamic body,
    Duration? duration,
  }) {
    if (kDebugMode) {
      String durationStr =
          duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      print('[$tag] 📥 $method $endpoint - $statusCode$durationStr');
      if (body != null) {
        print('  Response: $body');
      }
    }
  }

  static void logException(
    dynamic exception, {
    String tag = _defaultTag,
    StackTrace? stackTrace,
    String? message,
  }) {
    if (kDebugMode) {
      print('[$tag] 💥 EXCEPTION${message != null ? ': $message' : ''}');
      print('Exception: $exception');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  static void logFirestoreOperation(
    String operation, {
    String tag = _defaultTag,
    String? collection,
    String? documentId,
    dynamic data,
  }) {
    if (kDebugMode) {
      String message = operation;
      if (collection != null) {
        message += ' - Collection: $collection';
      }
      if (documentId != null) {
        message += ' - Document: $documentId';
      }
      print('[$tag] 🔥 Firestore - $message');
      if (data != null) {
        print('  Data: $data');
      }
    }
  }

  static void logAuthEvent(String event,
      {String tag = _defaultTag, String? userId, dynamic details}) {
    if (kDebugMode) {
      String message = event;
      if (userId != null) {
        message += ' - User: $userId';
      }
      print('[$tag] 🔐 Auth - $message');
      if (details != null) {
        print('  Details: $details');
      }
    }
  }

  static void logFormSubmission(
    String formName, {
    String tag = _defaultTag,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      print('[$tag] 📝 Form Submission - $formName');
      if (data != null && data.isNotEmpty) {
        print('  Data: $data');
      }
    }
  }

  static void logPageNavigation(String fromPage, String toPage,
      {String tag = _defaultTag}) {
    if (kDebugMode) {
      print('[$tag] 🔀 Navigation: $fromPage → $toPage');
    }
  }

  static void logPerformance(String operation, Duration duration,
      {String tag = _defaultTag}) {
    if (kDebugMode) {
      final ms = duration.inMilliseconds;
      String status = '✅';
      if (ms > 1000) status = '🐌';
      if (ms > 5000) status = '🔴';
      print('[$tag] $status Performance: $operation took ${ms}ms');
    }
  }

  static void divider({String tag = _defaultTag, String char = '─'}) {
    if (kDebugMode) {
      print('[$tag] ${char * 50}');
    }
  }
}
