import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'payment_models.dart';

/// Webhook verification service
class WebhookService {
  final String paystackSecret;
  final String flutterwaveSecret;
  final WebhookEventHandler eventHandler = WebhookEventHandler();

  WebhookService({
    required this.paystackSecret,
    required this.flutterwaveSecret,
  });

  /// Verify Paystack webhook
  bool verifyPaystackWebhook(String body, String signature) {
    final hash = sha512.convert(utf8.encode(body + paystackSecret));
    return hash.toString() == signature;
  }

  /// Verify Flutterwave webhook
  bool verifyFlutterwaveWebhook(String body, String signature) {
    final hash = sha256.convert(utf8.encode(body + flutterwaveSecret));
    return hash.toString() == signature;
  }

  /// Process Paystack webhook event
  WebhookEvent processPaystackEvent(Map<String, dynamic> payload) {
    final event = payload['event'] ?? 'charge.complete';
    final data = payload['data'] ?? {};

    return WebhookEvent(
      id: data['reference'] ?? '',
      event: event,
      provider: 'paystack',
      data: data,
      timestamp: DateTime.now(),
      verified: true,
    );
  }

  /// Process Flutterwave webhook event
  WebhookEvent processFlutterwaveEvent(Map<String, dynamic> payload) {
    final event = payload['event'] ?? 'charge.completed';
    final data = payload['data'] ?? {};

    return WebhookEvent(
      id: data['id']?.toString() ?? '',
      event: event,
      provider: 'flutterwave',
      data: data,
      timestamp: DateTime.now(),
      verified: true,
    );
  }

  /// Extract payment response from webhook event
  PaymentResponse extractPaymentResponse(WebhookEvent event) {
    if (event.provider == 'paystack') {
      return _extractPaystackResponse(event.data);
    } else if (event.provider == 'flutterwave') {
      return _extractFlutterwaveResponse(event.data);
    }

    return PaymentResponse(
      transactionId: '',
      status: PaymentStatus.failed,
      amount: 0,
      currency: 'NGN',
      provider: PaymentProvider.paystack,
      timestamp: DateTime.now(),
      message: 'Unknown provider',
    );
  }

  PaymentResponse _extractPaystackResponse(Map<String, dynamic> data) {
    return PaymentResponse(
      transactionId: data['metadata']['transaction_id'] ?? '',
      paymentId: data['reference'],
      status: data['status'] == 'success'
          ? PaymentStatus.success
          : PaymentStatus.failed,
      amount: (data['amount'] / 100).toDouble(),
      currency: data['currency'],
      provider: PaymentProvider.paystack,
      timestamp: DateTime.parse(data['created_at']),
      message: data['gateway_response'],
    );
  }

  PaymentResponse _extractFlutterwaveResponse(Map<String, dynamic> data) {
    return PaymentResponse(
      transactionId: data['tx_ref'] ?? '',
      paymentId: data['id'].toString(),
      status: data['status'] == 'successful'
          ? PaymentStatus.success
          : PaymentStatus.failed,
      amount: (data['amount']).toDouble(),
      currency: data['currency'],
      provider: PaymentProvider.flutterwave,
      timestamp: DateTime.parse(data['created_at']),
      message: data['processor_response'],
    );
  }

  /// Validate webhook signature and event type
  Map<String, dynamic> validateWebhook(
    String provider,
    String body,
    String signature,
  ) {
    final isValid = provider == 'paystack'
        ? verifyPaystackWebhook(body, signature)
        : verifyFlutterwaveWebhook(body, signature);

    if (!isValid) {
      return {'valid': false, 'error': 'Invalid webhook signature'};
    }

    try {
      final payload = jsonDecode(body);
      final event = provider == 'paystack'
          ? processPaystackEvent(payload)
          : processFlutterwaveEvent(payload);

      return {'valid': true, 'event': event};
    } catch (e) {
      return {'valid': false, 'error': 'Failed to parse webhook event: $e'};
    }
  }
}

/// Webhook event handler
class WebhookEventHandler {
  final Map<String, Function(WebhookEvent)> _handlers = {};

  /// Register event handler
  void on(String eventType, Function(WebhookEvent) handler) {
    _handlers[eventType] = handler;
  }

  /// Handle webhook event
  Future<void> handle(WebhookEvent event) async {
    final handler = _handlers[event.event];
    if (handler != null) {
      await Future.value(handler(event));
    }
  }

  /// Register default handlers
  void registerDefaultHandlers({
    required Function(WebhookEvent) onSuccess,
    required Function(WebhookEvent) onFailed,
    required Function(WebhookEvent) onPending,
  }) {
    on('charge.success', onSuccess);
    on('charge.complete', onSuccess);
    on('charge.failed', onFailed);
    on('charge.pending', onPending);
    on('charge.updated', onPending);
  }
}
