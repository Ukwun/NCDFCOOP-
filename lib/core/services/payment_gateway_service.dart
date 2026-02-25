/// Result of a payment transaction
class PaymentResult {
  final bool success;
  final String transactionId;
  final String message;
  final String paymentMethod; // 'flutterwave' or 'paystack'
  final DateTime timestamp;
  final double amount;

  PaymentResult({
    required this.success,
    required this.transactionId,
    required this.message,
    required this.paymentMethod,
    required this.amount,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'success': success,
        'transactionId': transactionId,
        'message': message,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Payment gateway service for Flutterwave and Paystack
class PaymentGatewayService {
  // Configuration keys should be passed via environment variables during build
  // See build/deploy documentation for setup instructions

  static final PaymentGatewayService _instance =
      PaymentGatewayService._internal();

  factory PaymentGatewayService() {
    return _instance;
  }

  static PaymentGatewayService get instance => _instance;

  PaymentGatewayService._internal() {
    // Initialization can be added for Flutterwave if needed
  }

  /// Process payment via Flutterwave
  ///
  /// Note: This is a placeholder that should be called from a screen with BuildContext
  /// The actual payment processing requires UI interaction and should be done in the widget layer
  ///
  /// Parameters:
  /// - orderId: Unique order identifier
  /// - amount: Payment amount in NGN
  /// - email: Customer email address
  /// - phoneNumber: Customer phone number
  /// - fullName: Customer full name
  /// - description: Order description
  Future<PaymentResult> processFlutterwave({
    required String orderId,
    required double amount,
    required String email,
    required String phoneNumber,
    required String fullName,
    required String description,
  }) async {
    try {
      // Flutterwave payment initialization
      // This is typically called from a widget context
      // Returning a placeholder response for now
      return PaymentResult(
        success: false,
        transactionId: orderId,
        message:
            'Flutterwave payment must be initiated from widget with BuildContext',
        paymentMethod: 'flutterwave',
        amount: amount,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        transactionId: orderId,
        message: 'Flutterwave error: ${e.toString()}',
        paymentMethod: 'flutterwave',
        amount: amount,
      );
    }
  }

  /// Verify Flutterwave transaction
  Future<bool> verifyFlutterwaveTransaction(String transactionId) async {
    try {
      // This would call Flutterwave's verification API
      // Implementation depends on backend setup
      // For now, return true if transactionId is not empty
      return transactionId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
