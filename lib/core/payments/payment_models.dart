enum PaymentMethod {
  card,
  bankTransfer,
  mobileMoney,
  mobileWallet,
  ussd,
}

enum PaymentProvider {
  flutterwave,
  paystack,
}

enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
  refunded,
}

class PaymentRequest {
  final String transactionId;
  final double amount;
  final String currency;
  final PaymentProvider provider;
  final PaymentMethod method;
  final String customerEmail;
  final String customerName;
  final String customerPhone;
  final Map<String, dynamic>? metadata;

  PaymentRequest({
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.method,
    required this.customerEmail,
    required this.customerName,
    required this.customerPhone,
    this.metadata,
  });
}

class PaymentResponse {
  final bool success;
  final String? message;
  final String? transactionId;
  final String? reference;
  final dynamic data;
  final String? paymentId;
  final String? status;
  final double? amount;
  final String? currency;
  final String? provider;
  final DateTime? timestamp;
  final String? authorizationUrl;
  final Map<String, dynamic>? rawResponse;

  PaymentResponse({
    this.success = false,
    this.message,
    this.transactionId,
    this.reference,
    this.data,
    this.paymentId,
    this.status,
    this.amount,
    this.currency,
    this.provider,
    this.timestamp,
    this.authorizationUrl,
    this.rawResponse,
  });
}

class PaymentTransaction {
  final String id;
  final String? paymentId;
  final String? orderId;
  final String reference;
  final double amount;
  final String? currency;
  final PaymentProvider provider;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? timestamp;

  PaymentTransaction({
    required this.id,
    this.paymentId,
    this.orderId,
    required this.reference,
    required this.amount,
    this.currency,
    required this.provider,
    required this.method,
    required this.status,
    required this.createdAt,
    this.timestamp,
  });
}

/// Webhook event data structure
class WebhookEvent {
  final String id;
  final String event;
  final String provider;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool verified;

  WebhookEvent({
    required this.id,
    required this.event,
    required this.provider,
    required this.data,
    required this.timestamp,
    required this.verified,
  });

  factory WebhookEvent.fromFirestore(Map<String, dynamic> json) {
    return WebhookEvent(
      id: json['id'] as String,
      event: json['event'] as String,
      provider: json['provider'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      verified: json['verified'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'event': event,
      'provider': provider,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'verified': verified,
    };
  }
}
