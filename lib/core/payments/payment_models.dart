/// Payment models and enums
enum PaymentProvider { paystack, flutterwave }

enum PaymentMethod { card, bankTransfer, mobileWallet, ussd }

enum PaymentStatus { pending, processing, success, failed, cancelled }

/// Payment request model
class PaymentRequest {
  final String transactionId;
  final double amount;
  final String currency;
  final PaymentProvider provider;
  final PaymentMethod method;
  final String customerEmail;
  final String customerName;
  final String? customerPhone;
  final Map<String, dynamic>? metadata;

  PaymentRequest({
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.method,
    required this.customerEmail,
    required this.customerName,
    this.customerPhone,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'amount': amount,
    'currency': currency,
    'provider': provider.name,
    'method': method.name,
    'customerEmail': customerEmail,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'metadata': metadata,
  };
}

/// Payment response model
class PaymentResponse {
  final String transactionId;
  final String? paymentId;
  final PaymentStatus status;
  final double amount;
  final String currency;
  final PaymentProvider provider;
  final DateTime timestamp;
  final String? message;
  final String? authorizationUrl;
  final Map<String, dynamic>? rawResponse;

  PaymentResponse({
    required this.transactionId,
    this.paymentId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.timestamp,
    this.message,
    this.authorizationUrl,
    this.rawResponse,
  });

  factory PaymentResponse.fromJson(
    Map<String, dynamic> json,
    PaymentProvider provider,
  ) {
    return PaymentResponse(
      transactionId: json['transactionId'] ?? '',
      paymentId: json['paymentId'],
      status: _parseStatus(json['status']),
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'NGN',
      provider: provider,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
      message: json['message'],
      authorizationUrl: json['authorizationUrl'],
      rawResponse: json,
    );
  }

  static PaymentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
      case 'completed':
        return PaymentStatus.success;
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'failed':
      case 'error':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
    'transactionId': transactionId,
    'paymentId': paymentId,
    'status': status.name,
    'amount': amount,
    'currency': currency,
    'provider': provider.name,
    'timestamp': timestamp.toIso8601String(),
    'message': message,
    'authorizationUrl': authorizationUrl,
  };
}

/// Webhook event model
class WebhookEvent {
  final String id;
  final String event;
  final String provider;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? signature;
  final bool verified;

  WebhookEvent({
    required this.id,
    required this.event,
    required this.provider,
    required this.data,
    required this.timestamp,
    this.signature,
    this.verified = false,
  });

  factory WebhookEvent.fromJson(Map<String, dynamic> json) {
    return WebhookEvent(
      id: json['id'] ?? '',
      event: json['event'] ?? '',
      provider: json['provider'] ?? '',
      data: json['data'] ?? {},
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toString()),
      signature: json['signature'],
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'event': event,
    'provider': provider,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'signature': signature,
    'verified': verified,
  };
}

/// Card payment model
class CardPaymentDetails {
  final String cardNumber;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;
  final String cardholderName;

  CardPaymentDetails({
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.cardholderName,
  });

  Map<String, dynamic> toJson() => {
    'cardNumber': cardNumber,
    'expiryMonth': expiryMonth,
    'expiryYear': expiryYear,
    'cvv': cvv,
    'cardholderName': cardholderName,
  };
}

/// Bank transfer details
class BankTransferDetails {
  final String? bankCode;
  final String? accountNumber;
  final String? accountName;
  final String bankName;

  BankTransferDetails({
    this.bankCode,
    this.accountNumber,
    this.accountName,
    required this.bankName,
  });

  Map<String, dynamic> toJson() => {
    'bankCode': bankCode,
    'accountNumber': accountNumber,
    'accountName': accountName,
    'bankName': bankName,
  };
}

/// Payment transaction history
class PaymentTransaction {
  final String id;
  final String orderId;
  final double amount;
  final String currency;
  final PaymentProvider provider;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final String? reference;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.method,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    this.reference,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'NGN',
      provider: PaymentProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => PaymentProvider.paystack,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.card,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      failureReason: json['failureReason'],
      reference: json['reference'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'amount': amount,
    'currency': currency,
    'provider': provider.name,
    'method': method.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'failureReason': failureReason,
    'reference': reference,
  };
}
