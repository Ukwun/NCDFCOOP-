import 'payment_models.dart';
import 'payment_service.dart';
import 'webhook_service.dart';

/// Repository for managing payment operations
class PaymentRepository {
  final PaymentService paymentService;
  final WebhookService webhookService;
  final String provider;

  PaymentRepository({
    required this.paymentService,
    required this.webhookService,
    required this.provider,
  });

  /// Initialize payment for order
  Future<PaymentResponse> initiatePayment({
    required String transactionId,
    required int amount,
    required String currency,
    required String paymentMethod,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
    Map<String, dynamic>? metadata,
  }) async {
    final request = PaymentRequest(
      transactionId: transactionId,
      amount: amount.toDouble(),
      currency: currency,
      provider: PaymentProvider.values.firstWhere(
        (e) => e.name == provider,
        orElse: () => PaymentProvider.paystack,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == paymentMethod,
        orElse: () => PaymentMethod.card,
      ),
      customerEmail: customerEmail,
      customerName: customerName,
      customerPhone: customerPhone,
      metadata: metadata,
    );

    return await paymentService.initiatePayment(request);
  }

  /// Verify payment
  Future<PaymentResponse> verifyPayment({required String reference}) async {
    return await paymentService.verifyPayment(reference);
  }

  /// Process refund
  Future<PaymentResponse> refundPayment({
    required String transactionId,
    required int amount,
  }) async {
    final success = await paymentService.processRefund(
      transactionId,
      amount.toDouble(),
    );
    return PaymentResponse(
      transactionId: transactionId,
      status: success ? 'success' : 'failed',
      amount: amount.toDouble(),
      currency: 'NGN',
      provider: provider,
      timestamp: DateTime.now(),
      message: success ? 'Refund successful' : 'Refund failed',
    );
  }

  /// Get transaction history
  Future<List<PaymentTransaction>> getTransactionHistory({
    required int page,
    required int limit,
    String? startDate,
    String? endDate,
  }) async {
    return await paymentService.getTransactionHistory(page: page, limit: limit);
  }

  /// Get available payment methods
  Future<List<String>> getAvailableMethods() async {
    final methods = await paymentService.getAvailableMethods();
    return methods.map((m) => m.name).toList();
  }

  /// Verify webhook
  bool verifyWebhook({required String body, required String signature}) {
    return webhookService.verifyPaystackWebhook(body, signature) ||
        webhookService.verifyFlutterwaveWebhook(body, signature);
  }

  /// Process webhook event
  Future<void> processWebhookEvent({
    required Map<String, dynamic> eventData,
    required String signature,
  }) async {
    if (provider == 'paystack') {
      final event = webhookService.processPaystackEvent(eventData);
      await webhookService.eventHandler.handle(event);
    } else if (provider == 'flutterwave') {
      final event = webhookService.processFlutterwaveEvent(eventData);
      await webhookService.eventHandler.handle(event);
    }
  }

  /// Register webhook event handler
  void registerWebhookHandler({
    required String eventType,
    required Function(WebhookEvent) handler,
  }) {
    webhookService.eventHandler.on(eventType, handler);
  }

  /// Register default handlers
  void registerDefaultHandlers({
    required Function(PaymentResponse) onSuccess,
    required Function(PaymentResponse) onFailed,
    required Function(PaymentResponse) onPending,
  }) {
    webhookService.eventHandler.registerDefaultHandlers(
      onSuccess: (event) =>
          onSuccess(webhookService.extractPaymentResponse(event)),
      onFailed: (event) =>
          onFailed(webhookService.extractPaymentResponse(event)),
      onPending: (event) =>
          onPending(webhookService.extractPaymentResponse(event)),
    );
  }
}
