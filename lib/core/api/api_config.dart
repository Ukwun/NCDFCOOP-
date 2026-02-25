/// API Configuration Management
///
/// Supports both local development and production backends
class ApiEnvironment {
  static const String local = 'local'; // http://localhost:3000
  static const String emulator = 'emulator'; // http://10.0.2.2:3000
  static const String production = 'production'; // https://api.ncdfcoop.ng
  static const String firebase = 'firebase'; // Cloud Functions fallback
}

class ApiConfig {
  static const String _localUrl = 'http://localhost:3000';
  static const String _emulatorUrl = 'http://10.0.2.2:3000';
  static const String _productionUrl = 'https://api.ncdfcoop.ng';
  static const String _firebaseUrl =
      'https://us-central1-coop-commerce.cloudfunctions.net';

  /// Get base URL for current environment
  static String getBaseUrl({String env = 'production'}) {
    switch (env) {
      case 'local':
        return _localUrl;
      case 'emulator':
        return _emulatorUrl;
      case 'firebase':
        return _firebaseUrl;
      default:
        return _productionUrl;
    }
  }

  /// API Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String googleAuthEndpoint = '/api/auth/google';
  static const String facebookAuthEndpoint = '/api/auth/facebook';
  static const String appleAuthEndpoint = '/api/auth/apple';
  static const String refreshTokenEndpoint = '/api/auth/refresh';
  static const String logoutEndpoint = '/api/auth/logout';

  /// Payment endpoints
  static const String initializePaymentEndpoint = '/api/payments/initialize';
  static const String verifyPaymentEndpoint = '/api/payments/verify';
  static const String generateReceiptEndpoint = '/api/payments/receipt';

  /// Product endpoints
  static const String productsEndpoint = '/api/products';
  static const String categoriesEndpoint = '/api/categories';

  /// Order endpoints
  static const String ordersEndpoint = '/api/orders';

  /// Default timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// Backend health check result
class BackendHealthResult {
  final bool isHealthy;
  final String baseUrl;
  final String? error;
  final int? statusCode;

  BackendHealthResult({
    required this.isHealthy,
    required this.baseUrl,
    this.error,
    this.statusCode,
  });

  @override
  String toString() =>
      'Backend: ${isHealthy ? "✅ HEALTHY" : "❌ UNAVAILABLE"} at $baseUrl${error != null ? " ($error)" : ""}';
}
