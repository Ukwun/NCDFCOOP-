import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_repository.dart';
import 'payment_helper.dart';
import 'payment_logger.dart';

/// Example usage of the payment system
/// This demonstrates various payment operations

class PaymentSystemExample {
  /// Example 1: Initiate a card payment
  static Future<void> example1InitiateCardPayment(WidgetRef ref) async {
    try {
      // Get payment repository (in real app, inject this)
      // final repository = ref.watch(paymentRepositoryProvider);

      // Generate transaction ID
      // final transactionId = PaymentHelper.generateTransactionId();

      // Prepare payment details
      // const amount = 50000; // NGN 500 (50000 kobo for Paystack)
      // const currency = 'NGN';

      // Initiate payment
      // final response = await repository.initiatePayment(
      //   transactionId: transactionId,
      //   amount: amount,
      //   currency: currency,
      //   paymentMethod: 'card',
      //   customerId: 'CUST_12345',
      //   customerEmail: 'customer@example.com',
      //   customerName: 'John Doe',
      //   customerPhone: '+2348012345678',
      //   metadata: {
      //     'orderId': 'ORD_12345',
      //     'productCount': 5,
      //   },
      // );

      // // Redirect to payment page
      // if (response.authorizationUrl != null) {
      //   // launchUrl(Uri.parse(response.authorizationUrl!));
      // }
    } catch (e) {
      debugPrint('Error initiating payment: $e');
    }
  }

  /// Example 2: Verify payment after user returns
  static Future<void> example2VerifyPayment(
    WidgetRef ref,
    String reference,
  ) async {
    try {
      // final repository = ref.watch(paymentRepositoryProvider);

      // Verify payment
      // final response = await repository.verifyPayment(reference: reference);

      // Check payment status
      // if (response.status == 'success') {
      //   print('Payment successful!');
      //   // Update order status in database
      // } else if (response.status == 'pending') {
      //   print('Payment pending...');
      // } else {
      //   print('Payment failed');
      // }
    } catch (e) {
      debugPrint('Error verifying payment: $e');
    }
  }

  /// Example 3: Validate card before payment
  static bool example3ValidateCard({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
  }) {
    // Validate card number using Luhn algorithm
    if (!PaymentHelper.validateCardNumber(cardNumber)) {
      debugPrint('Invalid card number');
      return false;
    }

    // Validate expiry
    if (!PaymentHelper.validateCardExpiry(expiryMonth, expiryYear)) {
      debugPrint('Card expired or invalid expiry');
      return false;
    }

    // Validate CVV
    if (!PaymentHelper.validateCVV(cvv)) {
      debugPrint('Invalid CVV');
      return false;
    }

    // Get card type for information
    final cardType = PaymentHelper.getCardType(cardNumber);
    debugPrint('Card Type: $cardType');

    return true;
  }

  /// Example 4: Handle webhook from payment provider
  static Future<void> example4HandleWebhook({
    required String body,
    required String signature,
    required PaymentRepository repository,
  }) async {
    try {
      // Verify webhook signature
      if (!repository.verifyWebhook(body: body, signature: signature)) {
        debugPrint('Webhook signature verification failed');
        return;
      }

      debugPrint('Webhook signature verified');

      // Parse webhook data
      // final eventData = jsonDecode(body) as Map<String, dynamic>;

      // Process webhook event
      // await repository.processWebhookEvent(
      //   eventData: eventData,
      //   signature: signature,
      // );
    } catch (e) {
      debugPrint('Error handling webhook: $e');
    }
  }

  /// Example 5: Calculate payment with fees
  static void example5CalculatePaymentWithFee() {
    const baseAmount = 50000.0; // NGN 500
    const cardFeePercentage = 1.5; // 1.5%
    const fixedFee = 50.0; // NGN 50

    // Calculate fee
    final fee = PaymentHelper.calculateFee(
      baseAmount,
      cardFeePercentage,
      fixedFee: fixedFee,
    );
    debugPrint('Fee: $fee NGN');

    // Calculate total with fee
    final totalWithFee = PaymentHelper.calculateTotalWithFee(
      baseAmount,
      cardFeePercentage,
      fixedFee: fixedFee,
    );
    debugPrint('Total with fee: $totalWithFee NGN');

    // Format for display
    final formatted = PaymentHelper.formatAmount(totalWithFee, '₦');
    debugPrint('Display: $formatted');
  }

  /// Example 6: Handle payment with custom event handlers
  static void example6RegisterCustomHandlers(PaymentRepository repository) {
    // Register handler for successful payments
    repository.registerWebhookHandler(
      eventType: 'charge.success',
      handler: (event) {
        debugPrint('Payment successful: ${event.id}');
        // Update order status
        // Send email confirmation
        // Generate invoice
      },
    );

    // Register handler for failed payments
    repository.registerWebhookHandler(
      eventType: 'charge.failed',
      handler: (event) {
        debugPrint('Payment failed: ${event.id}');
        // Notify customer
        // Log error
      },
    );

    // Register handler for pending payments
    repository.registerWebhookHandler(
      eventType: 'charge.pending',
      handler: (event) {
        debugPrint('Payment pending: ${event.id}');
        // Wait for confirmation
      },
    );
  }

  /// Example 7: Get transaction history
  static Future<void> example7GetTransactionHistory(
    PaymentRepository repository,
  ) async {
    try {
      // Fetch transaction history
      // final transactions = await repository.getTransactionHistory(
      //   page: 1,
      //   limit: 10,
      // );

      // Process transactions
      // for (final transaction in transactions) {
      //   print('Transaction: ${transaction.id}');
      //   print('  Status: ${transaction.status}');
      //   print('  Amount: ${transaction.amount} ${transaction.currency}');
      //   print('  Provider: ${transaction.provider}');
      //   print('  Created: ${transaction.createdAt}');
      // }
    } catch (e) {
      debugPrint('Error fetching transaction history: $e');
    }
  }

  /// Example 8: Process refund
  static Future<void> example8ProcessRefund(
    PaymentRepository repository,
  ) async {
    try {
      // Process refund for transaction
      // final response = await repository.refundPayment(
      //   transactionId: 'TXN_12345',
      //   amount: 50000, // Amount in kobo/cents
      // );

      // Check refund status
      // if (response.status == 'success') {
      //   print('Refund processed successfully');
      // } else {
      //   print('Refund failed: ${response.status}');
      // }
    } catch (e) {
      debugPrint('Error processing refund: $e');
    }
  }

  /// Example 9: Use payment logger for debugging
  static void example9PaymentLogging() {
    final logger = PaymentTransactionLogger();

    // Log payment initiation
    logger.logPaymentInitiation(
      transactionId: 'TXN_12345',
      amount: 50000,
      provider: 'paystack',
      method: 'card',
    );

    // Log payment verification
    logger.logPaymentVerification(
      transactionId: 'TXN_12345',
      provider: 'paystack',
      status: 'success',
    );

    // Log webhook
    logger.logWebhookReceived(
      provider: 'paystack',
      event: 'charge.success',
      transactionId: 'TXN_12345',
    );

    // Get logs for debugging
    final logs = logger.getLogsForTransaction('TXN_12345');
    debugPrint('Transaction logs: ${logs.length}');

    // Export logs for analytics
    final jsonLogs = logger.exportAsJson();
    debugPrint('Exported logs: ${jsonLogs.length} entries');

    // Get only error logs
    final errors = logger.getLogsByLevel(LogLevel.error);
    debugPrint('Errors: ${errors.length}');
  }

  /// Example 10: Bank transfer payment
  static Future<void> example10BankTransferPayment(WidgetRef ref) async {
    try {
      // Generate transaction ID
      // final transactionId = PaymentHelper.generateTransactionId();

      // Prepare bank transfer details
      // final repository = ref.watch(paymentRepositoryProvider);

      // const bankCode = '011'; // Zenith Bank
      // const accountNumber = '3120000000';

      // Validate bank transfer details
      // final isValid = PaymentHelper.validateBankTransfer(
      //   bankCode: bankCode,
      //   accountNumber: accountNumber,
      //   bankName: 'Zenith Bank',
      // );

      // if (!isValid) {
      //   print('Invalid bank details');
      //   return;
      // }

      // Initiate bank transfer payment
      // final response = await repository.initiatePayment(
      //   transactionId: transactionId,
      //   amount: 50000,
      //   currency: 'NGN',
      //   paymentMethod: 'bank_transfer',
      //   customerId: 'CUST_12345',
      //   customerEmail: 'customer@example.com',
      //   customerName: 'John Doe',
      //   customerPhone: '+2348012345678',
      //   metadata: {
      //     'bankCode': bankCode,
      //     'accountNumber': accountNumber,
      //   },
      // );
    } catch (e) {
      debugPrint('Error with bank transfer: $e');
    }
  }

  /// Example 11: Mask card for display
  static void example11MaskCardNumber() {
    const cardNumber = '4111111111111111';

    // Mask card number
    final masked = PaymentHelper.maskCardNumber(cardNumber);
    debugPrint('Masked card: $masked'); // Output: **** **** **** 1111

    // Format card number
    final formatted = PaymentHelper.formatCardNumber(cardNumber);
    debugPrint('Formatted card: $formatted'); // Output: 4111 1111 1111 1111
  }

  /// Example 12: Validate amount
  static void example12ValidateAmount() {
    // const amount = 50000;

    // Check if amount is valid
    if (!PaymentHelper.validateCardNumber('4111111111111111')) {
      debugPrint('Amount out of range');
      return;
    }

    debugPrint('Amount is valid');

    // Check if amount is valid for card
    // if (!PaymentConfig.isValidCardAmount(amount)) {
    //   print('Amount outside card payment range');
    //   return;
    // }
  }
}

/// To use these examples in your app:
///
/// 1. Import this file:
/// ```dart
/// import 'payment_system_example.dart';
/// ```
///
/// 2. Call example methods in your widgets:
/// ```dart
/// class PaymentScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return ElevatedButton(
///       onPressed: () {
///         PaymentSystemExample.example1_initiateCardPayment(ref);
///       },
///       child: Text('Pay Now'),
///     );
///   }
/// }
/// ```
///
/// 3. For webhook handling in your backend:
/// ```dart
/// @Post('/webhook/payment')
/// Future<Response> handlePaymentWebhook(
///   @Body() String body,
///   @Header('X-Paystack-Signature') String signature,
/// ) async {
///   final repository = PaymentRepository(...);
///   await PaymentSystemExample.example4_handleWebhook(
///     body: body,
///     signature: signature,
///     repository: repository,
///   );
///   return Response.ok('Webhook processed');
/// }
/// ```
