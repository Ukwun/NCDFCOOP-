/// Input validation utilities for secure data handling
class InputValidator {
  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Validate phone number (Nigerian format)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^(\+234|0)[0-9]{10}$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', ''));
  }

  /// Validate password strength
  static bool isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special char
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  /// Validate card number (basic Luhn algorithm)
  static bool isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '').replaceAll('-', '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) return false;

    return _luhnCheck(cleanNumber);
  }

  /// Luhn algorithm for card validation
  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool isEven = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

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

  /// Validate amount (currency)
  static bool isValidAmount(String amount) {
    try {
      final value = double.parse(amount);
      return value > 0 && value <= 10000000; // Max 10 million naira
    } catch (e) {
      return false;
    }
  }

  /// Sanitize user input (prevent injection attacks)
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(';', '');
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      return false;
    }
  }
}
