import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_models.dart';
import 'payment_service.dart';
import 'webhook_service.dart';

/// Payment service instance provider
final paystackServiceProvider = Provider<PaystackPaymentService>((ref) {
  return PaystackPaymentService();
});

final flutterwaveServiceProvider = Provider<FlutterwavePaymentService>((ref) {
  return FlutterwavePaymentService();
});

/// Payment provider selector
final selectedPaymentProviderProvider =
    NotifierProvider<PaymentProviderNotifier, PaymentProvider>(
      PaymentProviderNotifier.new,
    );

class PaymentProviderNotifier extends Notifier<PaymentProvider> {
  @override
  PaymentProvider build() => PaymentProvider.paystack;

  void setProvider(PaymentProvider provider) => state = provider;
}

/// Active payment service provider
final activePaymentServiceProvider = Provider<PaymentService>((ref) {
  final provider = ref.watch(selectedPaymentProviderProvider);

  if (provider == PaymentProvider.paystack) {
    return ref.watch(paystackServiceProvider);
  } else {
    return ref.watch(flutterwaveServiceProvider);
  }
});

/// Payment loading state
final paymentProcessingProvider =
    NotifierProvider<PaymentProcessingNotifier, bool>(
      PaymentProcessingNotifier.new,
    );

class PaymentProcessingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setLoading(bool loading) => state = loading;
}

/// Current payment response
final currentPaymentResponseProvider =
    NotifierProvider<CurrentPaymentResponseNotifier, PaymentResponse?>(
      CurrentPaymentResponseNotifier.new,
    );

class CurrentPaymentResponseNotifier extends Notifier<PaymentResponse?> {
  @override
  PaymentResponse? build() => null;
  void setResponse(PaymentResponse? response) => state = response;
}

/// Payment history provider
final paymentHistoryProvider = FutureProvider<List<PaymentTransaction>>((ref) {
  final service = ref.watch(activePaymentServiceProvider);
  return service.getTransactionHistory();
});

/// Available payment methods provider
final availablePaymentMethodsProvider = FutureProvider<List<PaymentMethod>>((
  ref,
) {
  final service = ref.watch(activePaymentServiceProvider);
  return service.getAvailableMethods();
});

/// Webhook service provider
final webhookServiceProvider = Provider<WebhookService>((ref) {
  return WebhookService(
    paystackSecret: const String.fromEnvironment(
      'PAYSTACK_SECRET_KEY',
      defaultValue: 'pk_test_xxxxx',
    ),
    flutterwaveSecret: const String.fromEnvironment(
      'FLUTTERWAVE_SECRET_KEY',
      defaultValue: 'FLWSECK_TEST_xxxxx',
    ),
  );
});

/// Webhook event handler provider
final webhookEventHandlerProvider = Provider<WebhookEventHandler>((ref) {
  final handler = WebhookEventHandler();

  // Register default handlers
  handler.registerDefaultHandlers(
    onSuccess: (event) {
      // Handle successful payment
      debugPrint('Payment successful: ${event.data['reference']}');
    },
    onFailed: (event) {
      // Handle failed payment
      debugPrint('Payment failed: ${event.data['reference']}');
    },
    onPending: (event) {
      // Handle pending payment
      debugPrint('Payment pending: ${event.data['reference']}');
    },
  );

  return handler;
});

/// Payment controller for business logic
class PaymentController extends AsyncNotifier<PaymentResponse?> {
  @override
  Future<PaymentResponse?> build() async => null;

  PaymentService get _paymentService => ref.read(activePaymentServiceProvider);

  /// Initialize payment services
  Future<void> initializeServices({
    required String paystackPublicKey,
    required String paystackSecretKey,
    required String flutterwavePublicKey,
    required String flutterwaveSecretKey,
    bool testMode = true,
  }) async {
    if (_paymentService is PaystackPaymentService) {
      await (_paymentService as PaystackPaymentService).initialize(
        publicKey: paystackPublicKey,
        secretKey: paystackSecretKey,
        testMode: testMode,
      );
    }
  }

  /// Process payment
  Future<void> processPayment(PaymentRequest request) async {
    state = const AsyncValue.loading();

    try {
      final response = await _paymentService.initiatePayment(request);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Verify payment status
  Future<void> verifyPayment(String reference) async {
    state = const AsyncValue.loading();

    try {
      final response = await _paymentService.verifyPayment(reference);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Process refund
  Future<bool> refund(String reference, double amount) async {
    return await _paymentService.processRefund(reference, amount);
  }
}

/// Payment controller provider
final paymentControllerProvider =
    AsyncNotifierProvider<PaymentController, PaymentResponse?>(
      PaymentController.new,
    );

/// Verify payment provider
final verifyPaymentProvider = FutureProvider.family<PaymentResponse, String>((
  ref,
  reference,
) async {
  final service = ref.watch(activePaymentServiceProvider);
  return await service.verifyPayment(reference);
});

/// Get transaction history provider
final transactionHistoryProvider =
    FutureProvider.family<List<PaymentTransaction>, int>((ref, page) async {
      final service = ref.watch(activePaymentServiceProvider);
      return await service.getTransactionHistory(page: page);
    });

/// Payment success state
final paymentSuccessProvider = NotifierProvider<PaymentSuccessNotifier, bool>(
  PaymentSuccessNotifier.new,
);

class PaymentSuccessNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setSuccess(bool success) => state = success;
}

/// Payment error message provider
final paymentErrorProvider = NotifierProvider<PaymentErrorNotifier, String?>(
  PaymentErrorNotifier.new,
);

class PaymentErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setError(String? error) => state = error;
}
