import 'dart:io';

/// Configuration for payment providers
class PaymentConfig {
  // Paystack Configuration
  static const String paystackBaseUrl = 'https://api.paystack.co';
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_your_public_key',
  );
  static const String paystackSecretKey = String.fromEnvironment(
    'PAYSTACK_SECRET_KEY',
    defaultValue: 'sk_test_your_secret_key',
  );

  // Flutterwave Configuration
  static const String flutterwaveBaseUrl = 'https://api.flutterwave.com/v3';
  static const String flutterwavePublicKey = String.fromEnvironment(
    'FLUTTERWAVE_PUBLIC_KEY',
    defaultValue: 'FLWPUBK_TEST-d3eeb3cd989d9969d1e06972967ac059-X',
  );
  static const String flutterwaveSecretKey = String.fromEnvironment(
    'FLUTTERWAVE_SECRET_KEY',
    defaultValue: 'FLWSECK_TEST-6f9bc4d562c29ff6c60e0e856f80e3ca-X',
  );

  // General Payment Configuration
  static const String defaultCurrency = 'NGN';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration webhookTimeout = Duration(seconds: 60);

  // Payment Methods
  static const List<String> supportedPaymentMethods = [
    'card',
    'bank_transfer',
    'mobile_wallet',
    'ussd',
  ];

  // Fee Configuration
  static const double cardPaymentFeePercentage = 1.5; // 1.5%
  static const double bankTransferFeePercentage = 0.5; // 0.5%
  static const double mobileWalletFeePercentage = 1.0; // 1.0%
  static const double ussdFeePercentage = 0.8; // 0.8%
  static const double fixedFee = 50; // Fixed fee in NGN

  // Webhook Configuration
  static String getWebhookUrl(String environment) {
    if (environment == 'production') {
      return 'https://api.coop-commerce.com/webhooks/payment';
    } else if (environment == 'staging') {
      return 'https://staging-api.coop-commerce.com/webhooks/payment';
    }
    return 'http://localhost:8000/webhooks/payment';
  }

  // Payment Retry Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // Validation Rules
  static const int minAmount = 100; // NGN 100
  static const int maxAmount = 50000000; // NGN 50M
  static const int minCardAmount = 500; // NGN 500
  static const int maxCardAmount = 50000000; // NGN 50M

  /// Get fee for payment method
  static double getFeeForMethod(String method) {
    switch (method) {
      case 'card':
        return cardPaymentFeePercentage;
      case 'bank_transfer':
        return bankTransferFeePercentage;
      case 'mobile_wallet':
        return mobileWalletFeePercentage;
      case 'ussd':
        return ussdFeePercentage;
      default:
        return cardPaymentFeePercentage;
    }
  }

  /// Check if amount is valid
  static bool isValidAmount(int amount) {
    return amount >= minAmount && amount <= maxAmount;
  }

  /// Check if card amount is valid
  static bool isValidCardAmount(int amount) {
    return amount >= minCardAmount && amount <= maxCardAmount;
  }

  /// Get environment
  static String getEnvironment() {
    return Platform.environment['PAYMENT_ENV'] ?? 'development';
  }

  /// Check if running in production
  static bool isProduction() {
    return getEnvironment() == 'production';
  }

  // Firebase Cloud Functions Configuration
  static const String firebaseBaseUrl =
      'https://us-central1-coop-commerce.cloudfunctions.net/payments';
  static const String firebaseInitializePaymentEndpoint = '/initiatePayment';
  static const String firebaseVerifyPaymentEndpoint = '/verifyPayment';
  static const String firebaseRefundEndpoint = '/processRefund';
  static const String firebaseWebhookEndpoint = '/webhooks/paystack';
  static const String firebaseHealthEndpoint = '/health';

  /// Get Firebase base URL
  static String getFirebaseUrl() {
    return firebaseBaseUrl;
  }

  /// Get API key based on provider
  static String getApiKey(String provider) {
    if (provider == 'paystack') {
      return paystackSecretKey;
    } else if (provider == 'flutterwave') {
      return flutterwaveSecretKey;
    }
    return '';
  }

  /// Get webhook secret for provider
  static String getWebhookSecret(String provider) {
    if (provider == 'paystack') {
      return paystackSecretKey;
    } else if (provider == 'flutterwave') {
      return flutterwaveSecretKey;
    }
    return '';
  }
}
