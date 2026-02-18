/// Base payment exception
class PaymentException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  PaymentException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() =>
      'PaymentException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Thrown when payment initialization fails
class PaymentInitializationException extends PaymentException {
  PaymentInitializationException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Thrown when payment verification fails
class PaymentVerificationException extends PaymentException {
  PaymentVerificationException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Thrown when webhook verification fails
class WebhookVerificationException extends PaymentException {
  WebhookVerificationException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Thrown when payment refund fails
class PaymentRefundException extends PaymentException {
  PaymentRefundException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Thrown when authentication fails with payment provider
class PaymentAuthenticationException extends PaymentException {
  PaymentAuthenticationException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Thrown when payment timeout occurs
class PaymentTimeoutException extends PaymentException {
  PaymentTimeoutException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Thrown when validation fails
class PaymentValidationException extends PaymentException {
  final List<String>? errors;

  PaymentValidationException({
    required super.message,
    super.code,
    this.errors,
    super.originalException,
    super.stackTrace,
  });
}

/// Thrown when network error occurs
class PaymentNetworkException extends PaymentException {
  PaymentNetworkException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

/// Thrown when bank transfer fails
class BankTransferException extends PaymentException {
  BankTransferException(
    String message, {
    super.code,
    super.originalException,
    super.stackTrace,
  }) : super(
          message: message,
        );
}

/// Thrown when card processing fails
class CardProcessingException extends PaymentException {
  CardProcessingException(
    String message, {
    super.code,
    super.originalException,
    super.stackTrace,
  }) : super(
          message: message,
        );
}

/// Thrown when card validation fails
class CardValidationException extends PaymentException {
  CardValidationException(
    String message, {
    super.code,
    super.originalException,
    super.stackTrace,
  }) : super(
          message: message,
        );
}

/// Thrown when USSD processing fails
class USSDException extends PaymentException {
  USSDException(
    String message, {
    super.code,
    super.originalException,
    super.stackTrace,
  }) : super(
          message: message,
        );
}

/// Thrown when payment storage fails
class PaymentStorageException extends PaymentException {
  PaymentStorageException(
    String message, {
    super.code,
    super.originalException,
    super.stackTrace,
  }) : super(
          message: message,
        );
}
