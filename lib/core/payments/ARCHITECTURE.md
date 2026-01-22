# Payment System Architecture

## System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                       Flutter UI Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ PaymentForm  │  │ CheckoutUI   │  │ OrderHistory │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                 │                 │                    │
└─────────┼─────────────────┼─────────────────┼────────────────────┘
          │                 │                 │
┌─────────┼─────────────────┼─────────────────┼────────────────────┐
│  Riverpod State Management Layer                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ payment_provider.dart                                    │   │
│  │ ├─ paymentControllerProvider                             │   │
│  │ ├─ activePaymentServiceProvider                          │   │
│  │ ├─ paymentProcessingProvider                             │   │
│  │ ├─ currentPaymentResponseProvider                        │   │
│  │ └─ transactionHistoryProvider                            │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────┬──────────────────────────────────────────────┘
                     │
┌────────────────────┼──────────────────────────────────────────────┐
│  Repository Layer                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ payment_repository.dart                                  │   │
│  │ • Abstracts PaymentService & WebhookService             │   │
│  │ • High-level API for payment operations                 │   │
│  └──────────────────────────────────────────────────────────┘   │
└────┬─────────────────────────────────────────────────┬───────────┘
     │                                                 │
┌────┴─────────────────────┐            ┌─────────────┴────────────┐
│                          │            │                          │
│  Service Layer           │            │  Webhook Layer           │
│  ────────────────        │            │  ──────────────          │
│                          │            │                          │
│ PaymentService (IF)      │            │ WebhookService           │
│ ├─ PaystackPaymentSvc    │            │ ├─ Verification         │
│ └─ FlutterwavePaymentSvc │            │ ├─ Event Handling       │
│                          │            │ └─ Handler Management    │
└────┬─────────────────────┘            └─────────────┬────────────┘
     │                                                │
     └─────────────────────────┬────────────────────┬─┘
                               │
┌──────────────────────────────┼─────────────────────────────────────┐
│  Utility & Config Layer                                           │
│  ┌─────────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │payment_helper   │  │payment_config│  │payment_logger      │  │
│  │• Validation     │  │• API URLs    │  │• Transaction logs  │  │
│  │• Calculations   │  │• API Keys    │  │• Error tracking    │  │
│  │• Formatting     │  │• Business    │  │• Export/Analytics  │  │
│  │                 │  │  Rules       │  │                    │  │
│  └─────────────────┘  └──────────────┘  └────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │payment_exceptions.dart                                   │   │
│  │• PaymentException (Base)                                │   │
│  │• PaymentInitializationException                         │   │
│  │• PaymentVerificationException                           │   │
│  │• WebhookVerificationException                           │   │
│  │• PaymentRefundException                                 │   │
│  │• ... and more                                           │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────────────────────┐
│  External Payment APIs                                             │
│                                                                    │
│  ┌──────────────────────┐          ┌──────────────────────┐       │
│  │  Paystack API        │          │  Flutterwave API     │       │
│  │  api.paystack.co     │          │  api.flutterwave.com │       │
│  │                      │          │                      │       │
│  │ Endpoints:           │          │ Endpoints:           │       │
│  │ • /transaction/      │          │ • /payments          │       │
│  │   initialize         │          │ • /transactions/     │       │
│  │ • /transaction/      │          │   verify             │       │
│  │   verify             │          │                      │       │
│  │ • /refund            │          │                      │       │
│  └──────────────────────┘          └──────────────────────┘       │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │           Webhook Endpoints (Backend)                    │     │
│  │  • POST /webhooks/payment                               │     │
│  │  • Verify signature                                     │     │
│  │  • Process events                                       │     │
│  └─────────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Payment Initialization Flow

```
User Input (Amount, Card Details)
         │
         ▼
PaymentForm Widget
         │
         ▼
Validate Input (PaymentHelper)
         │
         ▼
Create PaymentRequest
         │
         ▼
paymentControllerProvider
         │
         ▼
PaymentService.initiatePayment()
         │
         ├─ Paystack: POST /transaction/initialize
         │
         └─ Flutterwave: POST /payments
         │
         ▼
Receive PaymentResponse (with authorization URL)
         │
         ▼
Redirect to Payment Gateway
         │
         ▼
User Completes Payment
         │
         ▼
Redirect to Callback URL
         │
         ├─ Success: verification endpoint
         │
         └─ Cancel: app
```

### Webhook Processing Flow

```
Payment Provider (Paystack/Flutterwave)
         │
         ▼
Backend Webhook Endpoint
         │
         ▼
Extract Body & Signature
         │
         ▼
WebhookService.verify()
         │
         ├─ Paystack: SHA-512 Verification
         │
         └─ Flutterwave: SHA-256 Verification
         │
         ▼
If Valid:
         │
         ├─ Extract Event Data
         │
         └─ WebhookEventHandler
             │
             ├─ onSuccess → Update Order Status
             │
             ├─ onFailed → Notify User
             │
             └─ onPending → Wait for Confirmation
         │
         ▼
Response 200 OK to Provider
```

### Error Handling Flow

```
Payment Operation
         │
         ▼
     Success?
     ├─ Yes → Update State → Return Response
     │
     └─ No → Catch Exception
             │
             ▼
         Exception Type?
         ├─ Network → PaymentNetworkException
         ├─ Validation → PaymentValidationException
         ├─ Auth → PaymentAuthenticationException
         ├─ Timeout → PaymentTimeoutException
         └─ Other → PaymentException
             │
             ▼
         Log Error (PaymentLogger)
             │
             ▼
         Set Error State
             │
             ▼
         Display Error UI
```

## File Structure

```
lib/
├── core/
│   └── payments/
│       ├── payment_models.dart
│       │   ├─ PaymentProvider enum
│       │   ├─ PaymentMethod enum
│       │   ├─ PaymentStatus enum
│       │   ├─ PaymentRequest class
│       │   ├─ PaymentResponse class
│       │   ├─ WebhookEvent class
│       │   └─ PaymentTransaction class
│       │
│       ├── payment_service.dart
│       │   ├─ PaymentService interface
│       │   ├─ PaystackPaymentService impl
│       │   └─ FlutterwavePaymentService impl
│       │
│       ├── webhook_service.dart
│       │   ├─ WebhookService class
│       │   └─ WebhookEventHandler class
│       │
│       ├── payment_provider.dart
│       │   ├─ Riverpod providers
│       │   └─ PaymentController StateNotifier
│       │
│       ├── payment_repository.dart
│       │   └─ PaymentRepository class
│       │
│       ├── payment_config.dart
│       │   └─ PaymentConfig class
│       │
│       ├── payment_helper.dart
│       │   └─ PaymentHelper utility class
│       │
│       ├── payment_logger.dart
│       │   ├─ PaymentTransactionLogger class
│       │   └─ PaymentLog class
│       │
│       ├── payment_exceptions.dart
│       │   ├─ PaymentException base
│       │   ├─ PaymentInitializationException
│       │   ├─ PaymentVerificationException
│       │   ├─ WebhookVerificationException
│       │   ├─ PaymentRefundException
│       │   ├─ PaymentAuthenticationException
│       │   ├─ PaymentTimeoutException
│       │   ├─ PaymentValidationException
│       │   └─ PaymentNetworkException
│       │
│       ├── payment_system_example.dart
│       │   └─ Example usage patterns
│       │
│       └── PAYMENT_SYSTEM_README.md
│           └─ Documentation
```

## Component Responsibilities

### PaymentService Interface
- Defines contract for payment operations
- Methods: initiatePayment, verifyPayment, getAvailableMethods, processRefund, getTransactionHistory

### PaystackPaymentService
- Implements PaymentService for Paystack
- Converts amounts to kobo (×100)
- Handles Paystack API responses

### FlutterwavePaymentService
- Implements PaymentService for Flutterwave
- Uses actual currency amounts
- Handles Flutterwave API responses

### WebhookService
- Verifies webhook signatures (SHA-512 and SHA-256)
- Processes webhook events
- Manages event handlers

### PaymentRepository
- High-level API abstraction
- Coordinates between service and webhook layers
- Provides unified interface for UI layer

### PaymentProvider
- Riverpod state management
- Payment controllers for orchestration
- Providers for accessing payment state

### PaymentHelper
- Card validation (Luhn algorithm)
- Expiry validation
- CVV validation
- Card type detection
- Amount calculations

### PaymentLogger
- Transaction logging
- Error tracking
- Export capabilities

### PaymentConfig
- Centralized configuration
- API URLs and keys
- Business rules and limits

## Key Design Patterns

### 1. Repository Pattern
```
UI → Repository → Service + Webhook Service
```

### 2. Provider Pattern (Riverpod)
```
UI → StateNotifierProvider → PaymentController → Repository
```

### 3. Strategy Pattern
```
PaymentService (interface) → PaystackPaymentService | FlutterwavePaymentService
```

### 4. Observer Pattern
```
WebhookEventHandler → Register Handlers → Process Events
```

### 5. Singleton Pattern
```
PaymentTransactionLogger._instance
```

## Security Considerations

1. **API Key Management**
   - Store in environment variables
   - Never commit to version control
   - Use different keys for test/production

2. **Webhook Verification**
   - Always verify signatures
   - Use provider-specific algorithms
   - Validate body hasn't been tampered

3. **Card Data**
   - Never log full card numbers
   - Use masking for display
   - Use established payment providers (don't implement PCI compliance yourself)

4. **HTTPS Only**
   - All API calls over HTTPS
   - Webhook endpoints should enforce HTTPS

5. **Error Messages**
   - Don't leak sensitive information in error messages
   - Log detailed errors server-side
   - Show generic messages to users

## Performance Considerations

1. **Caching**
   - Cache available payment methods
   - Cache transaction history if appropriate

2. **Timeout**
   - Set reasonable timeouts (30 seconds default)
   - Handle timeout exceptions gracefully

3. **Retry Logic**
   - Implement exponential backoff
   - Max retry attempts configured

4. **Logging**
   - Keep logs within memory limit (500 max by default)
   - Export old logs for analytics

## Testing Strategy

1. **Unit Tests**
   - Test validation functions
   - Test amount calculations
   - Test card type detection

2. **Integration Tests**
   - Test payment flow with mock services
   - Test webhook verification

3. **E2E Tests**
   - Use test cards from payment providers
   - Test complete payment flow

## Future Enhancements

1. **Payment Plans/Subscriptions**
   - Add recurring payment support

2. **3D Secure**
   - Enhanced security for card payments

3. **Multi-Currency**
   - Support multiple currencies

4. **Payment Analytics**
   - Dashboard for payment metrics

5. **Cryptocurrency**
   - Support crypto payments

6. **Installments**
   - Split payments over time
