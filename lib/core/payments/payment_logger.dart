import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// Payment log entry
class PaymentLog {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? provider;
  final String? transactionId;
  final Map<String, dynamic>? metadata;
  final Exception? exception;
  final StackTrace? stackTrace;

  PaymentLog({
    required this.timestamp,
    required this.level,
    required this.message,
    this.provider,
    this.transactionId,
    this.metadata,
    this.exception,
    this.stackTrace,
  });

  @override
  String toString() =>
      '$level: $message (Provider: $provider, TXN: $transactionId)';
}

/// Payment transaction logger for debugging and monitoring
class PaymentTransactionLogger {
  static final PaymentTransactionLogger _instance =
      PaymentTransactionLogger._internal();

  factory PaymentTransactionLogger() {
    return _instance;
  }

  PaymentTransactionLogger._internal();

  final List<PaymentLog> _logs = [];
  int maxLogs = 500;
  LogLevel logLevel = LogLevel.debug;

  /// Log payment event
  void log({
    required String message,
    required LogLevel level,
    String? provider,
    String? transactionId,
    Map<String, dynamic>? metadata,
    Exception? exception,
    StackTrace? stackTrace,
  }) {
    if (level.index < logLevel.index) return;

    final log = PaymentLog(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      provider: provider,
      transactionId: transactionId,
      metadata: metadata,
      exception: exception,
      stackTrace: stackTrace,
    );

    _logs.add(log);

    // Keep only recent logs
    if (_logs.length > maxLogs) {
      _logs.removeRange(0, _logs.length - maxLogs);
    }

    _printLog(log);
  }

  void debug(
    String message, {
    String? provider,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    log(
      message: message,
      level: LogLevel.debug,
      provider: provider,
      transactionId: transactionId,
      metadata: metadata,
    );
  }

  void info(
    String message, {
    String? provider,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    log(
      message: message,
      level: LogLevel.info,
      provider: provider,
      transactionId: transactionId,
      metadata: metadata,
    );
  }

  void warning(
    String message, {
    String? provider,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    log(
      message: message,
      level: LogLevel.warning,
      provider: provider,
      transactionId: transactionId,
      metadata: metadata,
    );
  }

  void error(
    String message, {
    String? provider,
    String? transactionId,
    Exception? exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    log(
      message: message,
      level: LogLevel.error,
      provider: provider,
      transactionId: transactionId,
      exception: exception,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  void logPaymentInitiation({
    required String transactionId,
    required int amount,
    required String provider,
    required String method,
  }) {
    info(
      'Payment initiated',
      provider: provider,
      transactionId: transactionId,
      metadata: {'amount': amount, 'method': method},
    );
  }

  void logPaymentVerification({
    required String transactionId,
    required String provider,
    required String status,
  }) {
    info(
      'Payment verified',
      provider: provider,
      transactionId: transactionId,
      metadata: {'status': status},
    );
  }

  void logWebhookReceived({
    required String provider,
    required String event,
    required String transactionId,
  }) {
    info(
      'Webhook received',
      provider: provider,
      transactionId: transactionId,
      metadata: {'event': event},
    );
  }

  void logWebhookVerificationFailed({
    required String provider,
    required String reason,
  }) {
    warning(
      'Webhook verification failed',
      provider: provider,
      metadata: {'reason': reason},
    );
  }

  void logRefund({
    required String transactionId,
    required int amount,
    required String provider,
    required String status,
  }) {
    info(
      'Refund processed',
      provider: provider,
      transactionId: transactionId,
      metadata: {'amount': amount, 'status': status},
    );
  }

  void logError({
    required String transactionId,
    required String provider,
    required String errorMessage,
    Exception? exception,
    StackTrace? stackTrace,
  }) {
    error(
      errorMessage,
      provider: provider,
      transactionId: transactionId,
      exception: exception,
      stackTrace: stackTrace,
    );
  }

  /// Get all logs
  List<PaymentLog> getLogs() => List.unmodifiable(_logs);

  /// Get logs for transaction
  List<PaymentLog> getLogsForTransaction(String transactionId) {
    return _logs.where((log) => log.transactionId == transactionId).toList();
  }

  /// Get logs for provider
  List<PaymentLog> getLogsForProvider(String provider) {
    return _logs.where((log) => log.provider == provider).toList();
  }

  /// Get logs by level
  List<PaymentLog> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Export logs as JSON
  List<Map<String, dynamic>> exportAsJson() {
    return _logs
        .map(
          (log) => {
            'timestamp': log.timestamp.toIso8601String(),
            'level': log.level.toString(),
            'message': log.message,
            'provider': log.provider,
            'transactionId': log.transactionId,
            'metadata': log.metadata,
            'exception': log.exception?.toString(),
          },
        )
        .toList();
  }

  /// Clear logs
  void clearLogs() => _logs.clear();

  /// Clear logs for transaction
  void clearLogsForTransaction(String transactionId) {
    _logs.removeWhere((log) => log.transactionId == transactionId);
  }

  void _printLog(PaymentLog log) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.write('[${log.timestamp.toIso8601String()}] ');
    buffer.write('[${log.level.name.toUpperCase()}] ');

    if (log.provider != null) {
      buffer.write('[${log.provider}] ');
    }

    if (log.transactionId != null) {
      buffer.write('[TXN: ${log.transactionId}] ');
    }

    buffer.write(log.message);

    if (log.metadata != null && log.metadata!.isNotEmpty) {
      buffer.write('\nMetadata: ${log.metadata}');
    }

    if (log.exception != null) {
      buffer.write('\nException: ${log.exception}');
    }

    debugPrint(buffer.toString());

    if (log.stackTrace != null) {
      debugPrintStack(stackTrace: log.stackTrace);
    }
  }
}
