# Payment System Documentation

## Overview

The payment system supports multiple payment providers (Paystack and Flutterwave) with secure webhook verification, transaction logging, and comprehensive error handling.

## Architecture

### Core Components

1. **Payment Models** (`payment_models.dart`)
   - Payment request/response data structures
   - WebhookEvent and PaymentTransaction models
   - Enums for PaymentProvider, PaymentMethod, and PaymentStatus

2. **Payment Service** (`payment_service.dart`)
   - Abstract `PaymentService` interface
   - `PaystackPaymentService` implementation
   - `FlutterwavePaymentService` implementation

3. **Webhook Service** (`webhook_service.dart`)
   - Signature verification (SHA-512 for Paystack, SHA-256 for Flutterwave)
   - Event processing and handler management
   - WebhookEventHandler for custom callbacks

4. **Payment Provider** (`payment_provider.dart`)
   - Riverpod integration for state management
   - PaymentController for orchestrating payment flow
   - Multiple providers for different aspects of payment

5. **Payment Repository** (`payment_repository.dart`)
   - High-level API for payment operations
   - Abstraction over payment service and webhook service

6. **Payment Configuration** (`payment_config.dart`)
   - Centralized configuration management
   - API keys, URLs, and business rules
   - Payment method fees and validation rules

7. **Payment Helper** (`payment_helper.dart`)
   - Utility functions for card validation (Luhn algorithm)
   - CVV and card expiry validation
   - Card type detection
   - Amount and fee calculations

8. **Payment Logger** (`payment_logger.dart`)
   - Transaction logging for debugging
   - Error tracking and monitoring
   - JSON export for analytics

9. **Payment Exceptions** (`payment_exceptions.dart`)
   - Custom exception types for different error scenarios
   - Detailed error information for debugging

## Payment Flow

### Initialization

```dart
// Get payment service for provider
final paymentService = ref.watch(activePaymentServiceProvider);

// Or use repository for abstraction
final repository = PaymentRepository(
  paymentService: paymentService,
  webhookService: webhookService,
  provider: 'paystack',
);
```

### Initiating Payment

```dart
// Card Payment
final response = await repository.initiatePayment(
  transactionId: 'TXN_123456',
  amount: 50000, // Amount in kobo for Paystack, currency amount for Flutterwave
  currency: 'NGN',
  paymentMethod: 'card',
  customerId: 'CUST_123',
  customerEmail: 'user@example.com',
  customerName: 'John Doe',
  customerPhone: '+2348012345678',
  metadata: {'orderId': 'ORD_123'},
);

// Redirect to payment URL
// window.location.href = response.authorizationUrl;
```

### Verifying Payment

```dart
// After user redirects back
final verificationResponse = await repository.verifyPayment(
  reference: paymentReference, // From URL parameters
);

if (verificationResponse.status == 'success') {
  // Payment successful
} else {
  // Payment failed or pending
}
```

### Webhook Handling

```dart
// In your backend endpoint
Future<void> handlePaymentWebhook(String body, String signature) async {
  final repository = PaymentRepository(...);
  
  // Verify webhook signature
  if (!repository.verifyWebhook(body: body, signature: signature)) {
    throw WebhookVerificationException(message: 'Invalid signature');
  }
  
  // Parse and process event
  final eventData = jsonDecode(body) as Map<String, dynamic>;
  await repository.processWebhookEvent(
    eventData: eventData,
    signature: signature,
  );
}
```

## Supported Payment Methods

### Paystack
- **Card**: Credit/Debit cards (Visa, Mastercard)
- **Bank Transfer**: Direct bank transfers
- **USSD**: Quick transfer
- **Mobile Wallet**: Mobile money

### Flutterwave
- **Card**: Credit/Debit cards
- **Bank Transfer**: Direct bank transfers
- **Mobile Money**: Mobile money services

## Configuration

### Environment Variables

```bash
export PAYSTACK_PUBLIC_KEY="pk_live_..."
export PAYSTACK_SECRET_KEY="sk_live_..."
export FLUTTERWAVE_PUBLIC_KEY="pk_live_..."
export FLUTTERWAVE_SECRET_KEY="sk_live_..."
export PAYMENT_ENV="production"
```

### Payment Config Constants

```dart
PaymentConfig.defaultCurrency; // 'NGN'
PaymentConfig.minAmount; // 100
PaymentConfig.maxAmount; // 50,000,000
PaymentConfig.requestTimeout; // 30 seconds
PaymentConfig.maxRetryAttempts; // 3
```

## Error Handling

### Exception Types

- `PaymentInitializationException`: Payment initialization failed
- `PaymentVerificationException`: Payment verification failed
- `WebhookVerificationException`: Webhook signature verification failed
- `PaymentRefundException`: Refund processing failed
- `PaymentAuthenticationException`: API authentication failed
- `PaymentTimeoutException`: Request timeout
- `PaymentValidationException`: Validation failed (card, amount, etc.)
- `PaymentNetworkException`: Network error

### Example Error Handling

```dart
try {
  final response = await repository.initiatePayment(...);
} on PaymentValidationException catch (e) {
  print('Validation error: ${e.errors}');
} on PaymentNetworkException catch (e) {
  print('Network error: ${e.message}');
} on PaymentException catch (e) {
  print('Payment error: ${e.message} (${e.code})');
}
```

## Validation

### Card Validation

```dart
// Validate card number using Luhn algorithm
final isValid = PaymentHelper.validateCardNumber('4111111111111111');

// Validate expiry
final isValidExpiry = PaymentHelper.validateCardExpiry('12', '25');

// Validate CVV
final isValidCvv = PaymentHelper.validateCVV('123');

// Get card type
final cardType = PaymentHelper.getCardType('4111111111111111'); // 'Visa'
```

### Amount Validation

```dart
// Check if amount is within limits
final isValid = PaymentConfig.isValidAmount(50000);

// Calculate fee
final fee = PaymentHelper.calculateFee(50000, 1.5);

// Get total with fee
final total = PaymentHelper.calculateTotalWithFee(50000, 1.5);
```

## Logging

### Payment Logger Usage

```dart
final logger = PaymentTransactionLogger();

// Log payment events
logger.logPaymentInitiation(
  transactionId: 'TXN_123',
  amount: 50000,
  provider: 'paystack',
  method: 'card',
);

logger.logPaymentVerification(
  transactionId: 'TXN_123',
  provider: 'paystack',
  status: 'success',
);

// Get logs
final logs = logger.getLogs();
final transactionLogs = logger.getLogsForTransaction('TXN_123');

// Export for analytics
final json = logger.exportAsJson();
```

## Riverpod Integration

### Using Payment Controllers

```dart
// Watch payment state
final paymentState = ref.watch(
  paymentControllerProvider(PaymentProvider.paystack)
);

// Process payment
final controller = ref.read(
  paymentControllerProvider(PaymentProvider.paystack)
);
await controller.processPayment(paymentRequest);

// Verify payment
final verifyState = ref.watch(verifyPaymentProvider(referenceId));
verifyState.when(
  loading: () => CircularProgressIndicator(),
  data: (response) => Text('Payment ${response.status}'),
  error: (error, stack) => Text('Error: $error'),
);

// Get transaction history
final historyState = ref.watch(transactionHistoryProvider(1));
```

## API Endpoints

### Paystack
- **Initialize**: `POST /transaction/initialize`
- **Verify**: `GET /transaction/verify/{reference}`
- **Refund**: `POST /refund`
- **Webhook Event**: `charge.success`, `charge.failed`, etc.

### Flutterwave
- **Initialize**: `POST /payments`
- **Verify**: `GET /transactions/{id}/verify`
- **Refund**: `POST /transactions/{id}/refund`
- **Webhook Event**: `charge.completed`, `charge.failed`, etc.

## Best Practices

1. **Always verify webhooks** before processing payment events
2. **Use transaction IDs** to track payments across systems
3. **Handle retries** for failed payments
4. **Log all payment events** for audit trails
5. **Validate amounts** before initiating payment
6. **Use production keys** only in production environment
7. **Mask sensitive card data** before logging
8. **Implement idempotency** to prevent duplicate charges

## Testing

### Mock Data

```dart
final mockPaymentRequest = PaymentRequest(
  transactionId: 'TXN_TEST_123',
  amount: 50000,
  currency: 'NGN',
  provider: PaymentProvider.paystack,
  method: PaymentMethod.card,
  customerId: 'CUST_123',
  customerEmail: 'test@example.com',
  customerName: 'Test User',
  customerPhone: '+2348012345678',
);

final mockResponse = PaymentResponse(
  transactionId: 'TXN_TEST_123',
  paymentId: 'PAY_123',
  status: 'success',
  authorizationUrl: 'https://checkout.paystack.com/...',
  timestamp: DateTime.now(),
);
```

### Test Payment Cards

**Paystack Test Cards:**
- **Visa**: 4111 1111 1111 1111 (CVV: 123, Any future date)
- **Mastercard**: 5531 8866 5214 2950 (CVV: 564, Any future date)

**Flutterwave Test Cards:**
- **Visa**: 5399 8343 1234 5678 (CVV: 123, Any future date)
- **Mastercard**: 5531 8866 5214 2950 (CVV: 564, Any future date)

## Troubleshooting

### Common Issues

1. **"Invalid API Key"**
   - Ensure PAYSTACK_SECRET_KEY or FLUTTERWAVE_SECRET_KEY is set
   - Check environment variable is correct

2. **"Webhook signature verification failed"**
   - Verify webhook secret matches provider configuration
   - Check body hasn't been modified

3. **"Amount out of range"**
   - Check against PaymentConfig.minAmount and maxAmount
   - Ensure amount is in correct currency unit

4. **"Card validation failed"**
   - Use valid test card numbers
   - Verify card number passes Luhn algorithm
   - Check expiry is in future

## Future Enhancements

- [ ] 3D Secure (3DS) support for enhanced security
- [ ] Payment plan/subscription support
- [ ] Installment payment options
- [ ] Multi-currency conversion
- [ ] Payment analytics dashboard
- [ ] Fraud detection integration
- [ ] Apple Pay / Google Pay support
- [ ] Cryptocurrency payment support
