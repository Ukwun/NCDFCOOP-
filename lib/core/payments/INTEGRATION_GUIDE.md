# Payment System Integration Guide

## Quick Start

### 1. Setup Environment Variables

Create `.env` file or set system environment variables:

```bash
# Paystack Configuration
export PAYSTACK_PUBLIC_KEY="pk_live_your_key_here"
export PAYSTACK_SECRET_KEY="sk_live_your_key_here"

# Flutterwave Configuration
export FLUTTERWAVE_PUBLIC_KEY="pk_live_your_key_here"
export FLUTTERWAVE_SECRET_KEY="sk_live_your_key_here"

# Environment
export PAYMENT_ENV="production"  # or "development"
```

### 2. Add Dependencies to pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.2.0
  dio: ^5.0.0
  crypto: ^3.0.0
  go_router: ^14.0.0
```

### 3. Initialize Payment System

```dart
// In main.dart or initialization code
import 'package:coop_commerce/core/payments/payment_config.dart';

void main() {
  // Verify payment configuration is valid
  assert(PaymentConfig.paystackSecretKey != 'sk_test_your_secret_key',
    'Set PAYSTACK_SECRET_KEY environment variable');
  assert(PaymentConfig.flutterwaveSecretKey != 'sk_test_your_secret_key',
    'Set FLUTTERWAVE_SECRET_KEY environment variable');
  
  runApp(const MyApp());
}
```

## Integration Steps

### Step 1: Create Payment Request Model

```dart
// In your order/checkout model
final paymentRequest = PaymentRequest(
  transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
  amount: orderTotal * 100, // Convert to kobo/cents
  currency: 'NGN',
  provider: PaymentProvider.paystack,
  method: PaymentMethod.card,
  customerId: userId,
  customerEmail: userEmail,
  customerName: userName,
  customerPhone: userPhone,
  metadata: {
    'orderId': orderId,
    'productIds': productIds,
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

### Step 2: Implement Payment UI

```dart
// lib/features/checkout/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/payments/payment_provider.dart';
import 'package:coop_commerce/core/payments/payment_models.dart';

class PaymentScreen extends ConsumerWidget {
  final PaymentRequest paymentRequest;

  const PaymentScreen({
    Key? key,
    required this.paymentRequest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(
      paymentControllerProvider(PaymentProvider.paystack)
    );

    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Center(
        child: paymentState.when(
          loading: () => CircularProgressIndicator(),
          data: (response) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Payment Status: ${response?.status ?? 'Pending'}'),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _processPayment(context, ref),
                child: Text('Pay Now'),
              ),
            ],
          ),
          error: (error, stack) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => _processPayment(context, ref),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(
      paymentControllerProvider(PaymentProvider.paystack)
    );

    try {
      await controller.processPayment(paymentRequest);
      // Redirect to payment gateway
      // Handle response
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }
}
```

### Step 3: Create Webhook Handler (Backend)

```dart
// Example with Shelf (Dart backend framework)
import 'package:shelf/shelf.dart' as shelf;
import 'package:coop_commerce/core/payments/payment_repository.dart';

Future<shelf.Response> handlePaymentWebhook(shelf.Request request) async {
  try {
    // Get webhook body and signature
    final body = await request.readAsString();
    final signature = request.headers['X-Paystack-Signature'] ?? '';

    // Create repository with configured services
    final repository = PaymentRepository(
      paymentService: paystackService,
      webhookService: webhookService,
      provider: 'paystack',
    );

    // Verify and process webhook
    if (!repository.verifyWebhook(body: body, signature: signature)) {
      return shelf.Response.forbidden('Invalid signature');
    }

    // Parse event
    final event = jsonDecode(body) as Map<String, dynamic>;

    // Process event
    await repository.processWebhookEvent(
      eventData: event,
      signature: signature,
    );

    return shelf.Response.ok('Webhook processed');
  } catch (e) {
    print('Webhook error: $e');
    return shelf.Response.internalServerError(body: 'Error processing webhook');
  }
}
```

### Step 4: Handle Payment Callback

```dart
// In your callback/return URL handler
class PaymentCallbackScreen extends ConsumerWidget {
  final String? reference;

  const PaymentCallbackScreen({Key? key, this.reference}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reference == null) {
      return _buildCancelledScreen();
    }

    // Watch verification state
    final verifyState = ref.watch(verifyPaymentProvider(reference!));

    return Scaffold(
      body: verifyState.when(
        loading: () => _buildLoadingScreen(),
        data: (response) {
          if (response.status == 'success') {
            // Payment successful - update order
            _updateOrderStatus(ref, 'paid');
            return _buildSuccessScreen(response);
          } else if (response.status == 'pending') {
            return _buildPendingScreen(response);
          } else {
            return _buildFailureScreen(response);
          }
        },
        error: (error, stack) => _buildErrorScreen(error),
      ),
    );
  }

  Widget _buildLoadingScreen() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Verifying payment...'),
      ],
    ),
  );

  Widget _buildSuccessScreen(PaymentResponse response) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 64, color: Colors.green),
        SizedBox(height: 16),
        Text('Payment Successful!'),
        SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            // Navigate to order confirmation
            GoRouter.of(navigatorKey.currentContext!).go('/order-confirmation');
          },
          child: Text('Continue'),
        ),
      ],
    ),
  );

  Widget _buildFailureScreen(PaymentResponse response) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text('Payment Failed'),
        SizedBox(height: 8),
        Text(response.failureReason ?? 'Please try again'),
        SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            GoRouter.of(navigatorKey.currentContext!).go('/checkout');
          },
          child: Text('Try Again'),
        ),
      ],
    ),
  );

  Widget _buildPendingScreen(PaymentResponse response) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Payment Pending'),
        SizedBox(height: 8),
        Text('We are awaiting confirmation'),
      ],
    ),
  );

  Widget _buildCancelledScreen() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cancel, size: 64, color: Colors.orange),
        SizedBox(height: 16),
        Text('Payment Cancelled'),
        SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            GoRouter.of(navigatorKey.currentContext!).go('/checkout');
          },
          child: Text('Go Back'),
        ),
      ],
    ),
  );

  Widget _buildErrorScreen(Object error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text('Error'),
        SizedBox(height: 8),
        Text(error.toString()),
      ],
    ),
  );

  void _updateOrderStatus(WidgetRef ref, String status) {
    // Update order in database
    // Update UI state
  }
}
```

### Step 5: Add Logging

```dart
// In your payment operations
import 'package:coop_commerce/core/payments/payment_logger.dart';

class PaymentService {
  final logger = PaymentTransactionLogger();

  Future<void> processPayment(PaymentRequest request) async {
    try {
      logger.logPaymentInitiation(
        transactionId: request.transactionId,
        amount: request.amount,
        provider: request.provider.toString(),
        method: request.method.toString(),
      );

      // Process payment...

      logger.logPaymentVerification(
        transactionId: request.transactionId,
        provider: request.provider.toString(),
        status: 'success',
      );
    } catch (e, stack) {
      logger.logError(
        transactionId: request.transactionId,
        provider: request.provider.toString(),
        errorMessage: e.toString(),
        exception: e as Exception?,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // Export logs for debugging
  void exportLogs() {
    final logs = logger.exportAsJson();
    print(jsonEncode(logs));
  }
}
```

### Step 6: Add Error Handling

```dart
// lib/features/checkout/payment_error_handler.dart
import 'package:coop_commerce/core/payments/payment_exceptions.dart';

class PaymentErrorHandler {
  static String getDisplayMessage(Object error) {
    if (error is PaymentValidationException) {
      return 'Please check your details: ${error.errors?.join(", ") ?? error.message}';
    } else if (error is PaymentTimeoutException) {
      return 'Payment request timed out. Please try again.';
    } else if (error is PaymentNetworkException) {
      return 'Network error. Please check your connection.';
    } else if (error is PaymentAuthenticationException) {
      return 'Authentication failed. Please try again.';
    } else if (error is PaymentException) {
      return 'Payment failed: ${error.message}';
    }
    return 'An unexpected error occurred';
  }

  static bool isRetryable(Object error) {
    return error is PaymentTimeoutException ||
        error is PaymentNetworkException ||
        (error is PaymentException && error.code != 'AUTH_FAILED');
  }
}
```

## Testing

### Test Environment Setup

```dart
// lib/core/payments/payment_config.dart - for testing
class PaymentConfig {
  static bool isTestMode() {
    return Platform.environment['PAYMENT_ENV'] != 'production';
  }

  static String getTestApiUrl() {
    return isTestMode()
        ? 'https://api.test.paystack.co'
        : 'https://api.paystack.co';
  }
}
```

### Test Payment Cards

**Paystack:**
- Visa: 4111 1111 1111 1111
- Mastercard: 5399 8343 1234 5678
- Test OTP: 123456

**Flutterwave:**
- Visa: 5399 8343 1234 5678
- Mastercard: 5531 8866 5214 2950
- Test OTP: 12345

### Example Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coop_commerce/core/payments/payment_helper.dart';

void main() {
  group('PaymentHelper Tests', () {
    test('validateCardNumber - valid card', () {
      const validCard = '4111111111111111';
      expect(PaymentHelper.validateCardNumber(validCard), isTrue);
    });

    test('validateCardNumber - invalid card', () {
      const invalidCard = '4111111111111112';
      expect(PaymentHelper.validateCardNumber(invalidCard), isFalse);
    });

    test('validateCVV - valid CVV', () {
      expect(PaymentHelper.validateCVV('123'), isTrue);
      expect(PaymentHelper.validateCVV('1234'), isTrue);
    });

    test('validateCVV - invalid CVV', () {
      expect(PaymentHelper.validateCVV('12'), isFalse);
      expect(PaymentHelper.validateCVV('12345'), isFalse);
    });

    test('calculateFee - percentage only', () {
      final fee = PaymentHelper.calculateFee(50000, 1.5);
      expect(fee, 750); // 1.5% of 50000
    });

    test('calculateTotalWithFee', () {
      final total = PaymentHelper.calculateTotalWithFee(50000, 1.5);
      expect(total, 50750);
    });

    test('maskCardNumber', () {
      final masked = PaymentHelper.maskCardNumber('4111111111111111');
      expect(masked, '**** **** **** 1111');
    });

    test('getCardType', () {
      expect(PaymentHelper.getCardType('4111111111111111'), 'Visa');
      expect(PaymentHelper.getCardType('5399834312345678'), 'Mastercard');
    });
  });
}
```

## Deployment Checklist

- [ ] Environment variables set in production
- [ ] Webhook URL configured in payment provider dashboard
- [ ] SSL/HTTPS enabled for all endpoints
- [ ] Error logs configured and monitored
- [ ] Database migrations for payment tables
- [ ] Payment idempotency keys implemented
- [ ] Rate limiting configured
- [ ] Monitoring and alerting setup
- [ ] Fallback payment provider configured
- [ ] Customer support playbook for payment issues
- [ ] Terms and conditions updated
- [ ] Privacy policy updated

## Monitoring & Analytics

### Key Metrics to Track

```dart
// Payment Success Rate
totalSuccessfulPayments / totalPaymentAttempts

// Average Payment Time
averageTimeFromInitToCompletion

// Failed Payment Reasons
failuresByReason = {
  'insufficient_funds': count,
  'card_declined': count,
  'timeout': count,
  'network_error': count,
}

// Payment Method Distribution
{
  'card': count,
  'bank_transfer': count,
  'mobile_wallet': count,
  'ussd': count,
}
```

### Export Logs for Analysis

```dart
final logger = PaymentTransactionLogger();
final logsJson = logger.exportAsJson();

// Send to analytics service
analyticsService.sendPaymentLogs(logsJson);
```

## Troubleshooting

### Common Issues

**Issue: "Invalid API Key"**
```
Solution: Verify environment variables are set correctly
$ echo $PAYSTACK_SECRET_KEY
$ echo $FLUTTERWAVE_SECRET_KEY
```

**Issue: "Webhook signature verification failed"**
```
Solution: Ensure webhook secret matches provider config
Check: PaymentConfig.getWebhookSecret(provider)
```

**Issue: "Card validation fails"**
```
Solution: Use test cards from provider documentation
Ensure: Card number passes Luhn algorithm
Check: Expiry is in future date
```

**Issue: "Amount out of range"**
```
Solution: Check PaymentConfig limits
Verify: minAmount <= amount <= maxAmount
```

## Support

For issues or questions:
1. Check error logs: `logger.getLogsByLevel(LogLevel.error)`
2. Review payment provider documentation
3. Check payment provider's status page
4. Contact support with transaction ID
