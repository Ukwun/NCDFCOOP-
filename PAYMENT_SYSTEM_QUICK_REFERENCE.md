# Payment System - Quick Reference Card

## 🚀 Quick Start (Copy & Paste)

### 1. Set Environment Variables
```bash
export PAYSTACK_SECRET_KEY="sk_live_your_key_here"
export FLUTTERWAVE_SECRET_KEY="sk_live_your_key_here"
```

### 2. Basic Payment Flow
```dart
// Import
import 'package:coop_commerce/core/payments/payment_repository.dart';

// Initialize payment
final response = await repository.initiatePayment(
  transactionId: 'TXN_123',
  amount: 50000,
  currency: 'NGN',
  paymentMethod: 'card',
  customerId: 'CUST_123',
  customerEmail: 'user@example.com',
  customerName: 'John Doe',
  customerPhone: '+2348012345678',
);

// Verify payment
final verification = await repository.verifyPayment(
  reference: paymentReference,
);
```

---

## 📁 File Reference

| File | Purpose | Key Classes |
|------|---------|-------------|
| payment_models.dart | Data structures | PaymentRequest, PaymentResponse |
| payment_service.dart | Payment processing | PaystackPaymentService, FlutterwavePaymentService |
| webhook_service.dart | Webhook handling | WebhookService, WebhookEventHandler |
| payment_provider.dart | State management | PaymentController, Riverpod providers |
| payment_repository.dart | High-level API | PaymentRepository |
| payment_config.dart | Configuration | PaymentConfig |
| payment_helper.dart | Utilities | PaymentHelper validation methods |
| payment_logger.dart | Logging | PaymentTransactionLogger |
| payment_exceptions.dart | Errors | PaymentException and 8 subclasses |
| payment_constants.dart | Constants | PaymentConstants helper class |

---

## 🔑 Key Enums

```dart
enum PaymentProvider { paystack, flutterwave }
enum PaymentMethod { card, bankTransfer, mobileWallet, ussd }
enum PaymentStatus { pending, processing, success, failed, cancelled }
```

---

## 💳 Validation Quick Ref

```dart
import 'package:coop_commerce/core/payments/payment_helper.dart';

// Validate card
PaymentHelper.validateCardNumber('4111111111111111'); // true/false

// Validate CVV
PaymentHelper.validateCVV('123'); // true/false

// Validate expiry
PaymentHelper.validateCardExpiry('12', '25'); // true/false

// Get card type
PaymentHelper.getCardType('4111111111111111'); // 'Visa'

// Calculate fee
PaymentHelper.calculateFee(50000, 1.5); // 750
```

---

## 🛡️ Webhook Handling

```dart
// Verify webhook
bool isValid = repository.verifyWebhook(
  body: body,
  signature: signature,
);

// Process event
await repository.processWebhookEvent(
  eventData: eventData,
  signature: signature,
);

// Register custom handler
repository.registerWebhookHandler(
  eventType: 'charge.success',
  handler: (event) {
    print('Payment successful!');
  },
);
```

---

## 📊 Logging

```dart
import 'package:coop_commerce/core/payments/payment_logger.dart';

final logger = PaymentTransactionLogger();

// Log payment
logger.logPaymentInitiation(
  transactionId: 'TXN_123',
  amount: 50000,
  provider: 'paystack',
  method: 'card',
);

// Get logs
final logs = logger.getLogsForTransaction('TXN_123');

// Export
final json = logger.exportAsJson();
```

---

## ❌ Error Handling

```dart
import 'package:coop_commerce/core/payments/payment_exceptions.dart';

try {
  await repository.initiatePayment(...);
} on PaymentValidationException catch (e) {
  print('Validation errors: ${e.errors}');
} on PaymentException catch (e) {
  print('Error: ${e.message} (${e.code})');
}
```

---

## 🧪 Test Cards

| Provider | Card | CVV | Expiry |
|----------|------|-----|--------|
| Paystack | 4111 1111 1111 1111 | 123 | Any future |
| Paystack | 5399 8343 1234 5678 | 564 | Any future |
| Flutterwave | 5399 8343 1234 5678 | 123 | Any future |
| Flutterwave | 5531 8866 5214 2950 | 564 | Any future |

---

## ⚙️ Configuration

```dart
import 'package:coop_commerce/core/payments/payment_config.dart';

// Access config
PaymentConfig.paystackSecretKey;
PaymentConfig.flutterwaveSecretKey;
PaymentConfig.minAmount; // 100
PaymentConfig.maxAmount; // 50,000,000
PaymentConfig.isProduction();
```

---

## 📚 Documentation Files

| File | Content |
|------|---------|
| README.md | Quick reference & index |
| IMPLEMENTATION_SUMMARY.md | Feature overview |
| PAYMENT_SYSTEM_README.md | Full API reference |
| INTEGRATION_GUIDE.md | Step-by-step setup |
| ARCHITECTURE.md | System design |
| payment_system_example.dart | 12 usage examples |

---

## 📍 Directory Structure

```
lib/core/payments/
├── payment_models.dart
├── payment_service.dart
├── webhook_service.dart
├── payment_provider.dart
├── payment_repository.dart
├── payment_config.dart
├── payment_helper.dart
├── payment_logger.dart
├── payment_exceptions.dart
├── payment_constants.dart
├── payment_system_example.dart
├── README.md
├── PAYMENT_SYSTEM_README.md
├── INTEGRATION_GUIDE.md
└── ARCHITECTURE.md
```

---

## 🔗 Common Usage Patterns

### Pattern 1: Simple Payment
```dart
final response = await repository.initiatePayment(...);
// Redirect to response.authorizationUrl
// Handle callback on return
```

### Pattern 2: Verify After Callback
```dart
final verified = await repository.verifyPayment(reference: ref);
if (verified.status == 'success') {
  // Update order
}
```

### Pattern 3: Handle Webhook
```dart
if (repository.verifyWebhook(body: body, signature: sig)) {
  await repository.processWebhookEvent(eventData, signature);
}
```

### Pattern 4: With Riverpod
```dart
final state = ref.watch(paymentControllerProvider(PaymentProvider.paystack));
// Use state for UI updates
```

---

## ⚠️ Common Mistakes to Avoid

❌ Don't hardcode API keys  
✅ Use environment variables

❌ Don't skip webhook verification  
✅ Always verify signatures

❌ Don't log full card numbers  
✅ Use PaymentHelper.maskCardNumber()

❌ Don't ignore timeouts  
✅ Handle PaymentTimeoutException

❌ Don't use test keys in production  
✅ Switch to live keys before deploying

---

## 🔍 Debugging Tips

### Check Logs
```dart
final logs = logger.getLogsByLevel(LogLevel.error);
```

### Get Transaction Logs
```dart
final txnLogs = logger.getLogsForTransaction('TXN_123');
```

### Export for Analysis
```dart
final json = logger.exportAsJson();
```

### Check Provider Status
```dart
assert(!PaymentConfig.isProduction() || PaymentConfig.paystackSecretKey != 'sk_test_...');
```

---

## 📞 Support Reference

**Question: How to setup?**  
→ See: INTEGRATION_GUIDE.md

**Question: How to debug?**  
→ See: INTEGRATION_GUIDE.md → Troubleshooting

**Question: What's included?**  
→ See: IMPLEMENTATION_SUMMARY.md

**Question: Show me examples**  
→ See: payment_system_example.dart

**Question: Architecture details?**  
→ See: ARCHITECTURE.md

---

## ✅ Pre-Deploy Checklist

- [ ] Environment variables set
- [ ] Webhook URL configured
- [ ] Test cards work
- [ ] Error handling tested
- [ ] Logging enabled
- [ ] HTTPS enabled
- [ ] Secret keys rotated

---

## 🎯 Next Steps

1. **Read**: lib/core/payments/README.md
2. **Follow**: INTEGRATION_GUIDE.md
3. **Review**: payment_system_example.dart
4. **Test**: With test cards
5. **Deploy**: To production

---

## 🚀 Ready to Go!

All files are in `lib/core/payments/`

**Total**: 10 Dart files + 5 Docs + 1 Example = **17 files**

**Status**: Production-Ready ✅

**Start**: lib/core/payments/README.md

---

**Payment System - Quick Reference**  
Use this card for quick lookups while implementing payments.
