import 'package:crypto/crypto.dart';

/// Helper class for payment utilities
class PaymentHelper {
  /// Generate a unique transaction ID
  static String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecond).toString();
    return 'TXN_${timestamp}_$random';
  }

  /// Validate card number using Luhn algorithm
  static bool validateCardNumber(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 13 || digits.length > 19) {
      return false;
    }

    int sum = 0;
    bool isEven = false;

    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 == 0;
  }

  /// Validate card expiry date
  static bool validateCardExpiry(String month, String year) {
    try {
      final now = DateTime.now();
      final expiryMonth = int.parse(month);
      final expiryYear = int.parse(year);

      if (expiryMonth < 1 || expiryMonth > 12) {
        return false;
      }

      final expiryDate = DateTime(expiryYear, expiryMonth);
      return expiryDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  /// Validate CVV
  static bool validateCVV(String cvv) {
    return RegExp(r'^\d{3,4}$').hasMatch(cvv);
  }

  /// Format card number
  static String formatCardNumber(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    return digits
        .replaceAllMapped(RegExp(r'.{1,4}'), (match) => '${match.group(0)} ')
        .trim();
  }

  /// Hash for webhook signature verification
  static String hashPayload(String payload, String secret) {
    return sha256.convert((payload + secret).codeUnits).toString();
  }

  /// Format amount for display
  static String formatAmount(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Get card type from number
  static String getCardType(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return 'Unknown';

    final firstDigit = digits[0];
    final firstTwoDigits = digits.length >= 2 ? digits.substring(0, 2) : '';

    if (firstDigit == '4') {
      return 'Visa';
    } else if (firstDigit == '5' &&
        firstTwoDigits.compareTo('51') >= 0 &&
        firstTwoDigits.compareTo('55') <= 0) {
      return 'Mastercard';
    } else if (firstTwoDigits == '34' || firstTwoDigits == '37') {
      return 'American Express';
    } else if (firstTwoDigits == '36' || firstTwoDigits == '38') {
      return 'Diners Club';
    } else if (digits.length >= 4 && digits.substring(0, 4) == '6011') {
      return 'Discover';
    } else if (firstTwoDigits == '62') {
      return 'UnionPay';
    } else if (firstTwoDigits == '50') {
      return 'Aura';
    }

    return 'Unknown';
  }

  /// Calculate transaction fee
  static double calculateFee(
    double amount,
    double feePercentage, {
    double? fixedFee,
  }) {
    double percentageFee = (amount * feePercentage) / 100;
    double totalFee = percentageFee + (fixedFee ?? 0);
    return totalFee;
  }

  /// Calculate total amount with fee
  static double calculateTotalWithFee(
    double amount,
    double feePercentage, {
    double? fixedFee,
  }) {
    final fee = calculateFee(amount, feePercentage, fixedFee: fixedFee);
    return amount + fee;
  }

  /// Mask sensitive card data
  static String maskCardNumber(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return cardNumber;

    final lastFour = digits.substring(digits.length - 4);
    return '**** **** **** $lastFour';
  }

  /// Validate bank transfer details
  static bool validateBankTransfer({
    required String? bankCode,
    required String? accountNumber,
    required String bankName,
  }) {
    if (bankName.isEmpty) return false;

    if (accountNumber != null && accountNumber.isNotEmpty) {
      if (!RegExp(r'^\d{10,12}$').hasMatch(accountNumber)) {
        return false;
      }
    }

    return true;
  }

  /// Get payment method display name
  static String getPaymentMethodName(String method) {
    final methodMap = {
      'card': 'Credit/Debit Card',
      'bank_transfer': 'Bank Transfer',
      'mobile_wallet': 'Mobile Wallet',
      'ussd': 'USSD',
    };

    return methodMap[method] ?? method;
  }

  /// Get payment status display name
  static String getPaymentStatusName(String status) {
    final statusMap = {
      'pending': 'Pending',
      'processing': 'Processing',
      'success': 'Successful',
      'failed': 'Failed',
      'cancelled': 'Cancelled',
    };

    return statusMap[status] ?? status;
  }

  /// Check if payment is retryable
  static bool isPaymentRetryable(String status) {
    return status == 'pending' || status == 'failed';
  }

  /// Generate receipt number
  static String generateReceiptNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'REC_$timestamp';
  }
}
