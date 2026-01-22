/// Payment system constants and string resources
class PaymentConstants {
  // Payment Providers
  static const String paystack = 'paystack';
  static const String flutterwave = 'flutterwave';

  // Payment Methods
  static const String methodCard = 'card';
  static const String methodBankTransfer = 'bank_transfer';
  static const String methodMobileWallet = 'mobile_wallet';
  static const String methodUssd = 'ussd';

  // Payment Status
  static const String statusPending = 'pending';
  static const String statusProcessing = 'processing';
  static const String statusSuccess = 'success';
  static const String statusFailed = 'failed';
  static const String statusCancelled = 'cancelled';

  // Currencies
  static const String currencyNGN = 'NGN';
  static const String currencyGHS = 'GHS';
  static const String currencyUSD = 'USD';
  static const String currencyKES = 'KES';

  // Error Messages
  static const String errorInitializationFailed =
      'Payment initialization failed';
  static const String errorVerificationFailed = 'Payment verification failed';
  static const String errorWebhookVerificationFailed =
      'Webhook signature verification failed';
  static const String errorRefundFailed = 'Refund processing failed';
  static const String errorAuthenticationFailed = 'API authentication failed';
  static const String errorTimeoutOccurred = 'Payment request timed out';
  static const String errorValidationFailed = 'Payment validation failed';
  static const String errorNetworkFailure = 'Network error occurred';
  static const String errorInsufficientFunds = 'Insufficient funds';
  static const String errorCardDeclined = 'Card was declined';
  static const String errorInvalidCard = 'Invalid card number';
  static const String errorInvalidCVV = 'Invalid CVV';
  static const String errorExpiredCard = 'Card has expired';
  static const String errorAmountOutOfRange = 'Amount is outside valid range';

  // Success Messages
  static const String successPaymentInitiated =
      'Payment initiated successfully';
  static const String successPaymentVerified = 'Payment verified successfully';
  static const String successRefundProcessed = 'Refund processed successfully';
  static const String successWebhookProcessed =
      'Webhook processed successfully';

  // Card Types
  static const String cardTypeVisa = 'Visa';
  static const String cardTypeMastercard = 'Mastercard';
  static const String cardTypeAmex = 'American Express';
  static const String cardTypeDiners = 'Diners Club';
  static const String cardTypeDiscover = 'Discover';
  static const String cardTypeUnionpay = 'UnionPay';
  static const String cardTypeAura = 'Aura';
  static const String cardTypeUnknown = 'Unknown';

  // Transaction Status Strings
  static const String txnInitialized = 'initialized';
  static const String txnCharging = 'charging';
  static const String txnChargeCompleted = 'charge_completed';
  static const String txnChargeFailed = 'charge_failed';
  static const String txnAuthorizationOngoing = 'authorization_ongoing';
  static const String txnVerificationPending = 'verification_pending';

  // Event Types
  static const String eventChargeSuccess = 'charge.success';
  static const String eventChargeFailed = 'charge.failed';
  static const String eventChargePending = 'charge.pending';
  static const String eventChargeComplete = 'charge.complete';
  static const String eventChargeUpdated = 'charge.updated';

  // API Endpoints
  static const String paystackBaseUrl = 'https://api.paystack.co';
  static const String flutterwaveBaseUrl = 'https://api.flutterwave.com/v3';

  // Paystack Endpoints
  static const String paystackInitialize = '/transaction/initialize';
  static const String paystackVerify = '/transaction/verify';
  static const String paystackRefund = '/refund';
  static const String paystackList = '/transaction';
  static const String paystackFetch = '/transaction';

  // Flutterwave Endpoints
  static const String flutterwavePayments = '/payments';
  static const String flutterwaveTransactions = '/transactions';
  static const String flutterwaveVerify = '/transactions/verify_by_reference';
  static const String flutterwaveRefund = '/transactions/refund';

  // HTTP Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';
  static const String headerPaystackSignature = 'X-Paystack-Signature';
  static const String headerFlutterwaveSignature = 'verifyHash';
  static const String contentTypeJson = 'application/json';

  // Request Parameters
  static const String paramEmail = 'email';
  static const String paramAmount = 'amount';
  static const String paramMetadata = 'metadata';
  static const String paramReference = 'reference';
  static const String paramAccessCode = 'access_code';
  static const String paramAuthorizationUrl = 'authorization_url';
  static const String paramStatus = 'status';

  // Webhook Parameters
  static const String webhookId = 'id';
  static const String webhookEvent = 'event';
  static const String webhookData = 'data';
  static const String webhookTimestamp = 'timestamp';
  static const String webhookReference = 'reference';

  // Payment Method Display Names
  static const Map<String, String> paymentMethodNames = {
    'card': 'Credit/Debit Card',
    'bank_transfer': 'Bank Transfer',
    'mobile_wallet': 'Mobile Wallet',
    'ussd': 'USSD',
  };

  // Payment Status Display Names
  static const Map<String, String> paymentStatusNames = {
    'pending': 'Pending',
    'processing': 'Processing',
    'success': 'Successful',
    'failed': 'Failed',
    'cancelled': 'Cancelled',
  };

  // Card Type Icons (if using icon provider)
  static const Map<String, String> cardTypeIcons = {
    'Visa': 'assets/icons/visa.png',
    'Mastercard': 'assets/icons/mastercard.png',
    'American Express': 'assets/icons/amex.png',
    'Diners Club': 'assets/icons/diners.png',
    'Discover': 'assets/icons/discover.png',
  };

  // Amount in kobo/cents for different currencies
  static const Map<String, int> currencyMultiplier = {
    'NGN': 100, // Paystack uses kobo
    'GHS': 100, // Ghana cedis
    'KES': 100, // Kenya shillings
    'USD': 100, // US dollars in cents
  };

  // Validation Patterns
  static const String cardNumberPattern = r'^\d{13,19}$';
  static const String cvvPattern = r'^\d{3,4}$';
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\+?1?\d{9,15}$';
  static const String accountNumberPattern = r'^\d{10,12}$';

  // Limits
  static const int minAmount = 100;
  static const int maxAmount = 50000000;
  static const int minCardAmount = 500;
  static const int maxCardAmount = 50000000;
  static const int maxRetryAttempts = 3;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration retryDelay = Duration(seconds: 5);

  // Fees (in percentage)
  static const double cardFeePercentage = 1.5;
  static const double bankTransferFeePercentage = 0.5;
  static const double mobileWalletFeePercentage = 1.0;
  static const double ussdFeePercentage = 0.8;

  // Fixed Fees (in currency units)
  static const double fixedFee = 50.0;

  // Log Level Names
  static const Map<String, String> logLevelNames = {
    'debug': 'DEBUG',
    'info': 'INFO',
    'warning': 'WARNING',
    'error': 'ERROR',
  };

  // Environment
  static const String envProduction = 'production';
  static const String envStaging = 'staging';
  static const String envDevelopment = 'development';

  // Helper Methods

  /// Get payment method display name
  static String getPaymentMethodName(String method) {
    return paymentMethodNames[method] ?? method;
  }

  /// Get payment status display name
  static String getPaymentStatusName(String status) {
    return paymentStatusNames[status] ?? status;
  }

  /// Get card type from first digit pattern
  static String getCardTypeFromPattern(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return cardTypeUnknown;

    if (digits[0] == '4') {
      return cardTypeVisa;
    } else if (digits[0] == '5') {
      return cardTypeMastercard;
    } else if (digits[0] == '3') {
      return cardTypeAmex;
    } else if (digits.startsWith('6011')) {
      return cardTypeDiscover;
    }

    return cardTypeUnknown;
  }

  /// Get currency multiplier for amount conversion
  static int getCurrencyMultiplier(String currency) {
    return currencyMultiplier[currency] ?? 100;
  }

  /// Convert amount to smallest unit (kobo/cents)
  static int convertToSmallestUnit(double amount, String currency) {
    final multiplier = getCurrencyMultiplier(currency);
    return (amount * multiplier).toInt();
  }

  /// Convert amount from smallest unit (kobo/cents)
  static double convertFromSmallestUnit(int amount, String currency) {
    final multiplier = getCurrencyMultiplier(currency);
    return amount / multiplier;
  }

  /// Get fee for payment method
  static double getFeeForMethod(String method) {
    switch (method) {
      case methodCard:
        return cardFeePercentage;
      case methodBankTransfer:
        return bankTransferFeePercentage;
      case methodMobileWallet:
        return mobileWalletFeePercentage;
      case methodUssd:
        return ussdFeePercentage;
      default:
        return cardFeePercentage;
    }
  }

  /// Check if amount is within valid range
  static bool isValidAmount(int amount) {
    return amount >= minAmount && amount <= maxAmount;
  }

  /// Check if card amount is within valid range
  static bool isValidCardAmount(int amount) {
    return amount >= minCardAmount && amount <= maxCardAmount;
  }

  /// Check if amount is retryable
  static bool isRetryableAmount(int amount) {
    return isValidAmount(amount);
  }
}
