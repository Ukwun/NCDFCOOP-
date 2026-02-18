import 'package:dio/dio.dart';
import 'payment_exceptions.dart' show USSDException;

/// USSD and Mobile Money processor
class USSDProcessor {
  final Dio _dio;
  late String _apiKey;
  bool _testMode = true;

  static const String _baseUrlProd = 'https://api.flutterwave.com/v3';
  static const String _baseUrlTest = 'https://api.flutterwave.com/v3';

  USSDProcessor({required Dio dio}) : _dio = dio;

  /// Initialize processor
  Future<void> initialize({
    required String apiKey,
    bool testMode = true,
  }) async {
    _apiKey = apiKey;
    _testMode = testMode;
    _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
  }

  /// Initiate USSD payment
  Future<USSDPaymentResponse> initiateUSSDPayment({
    required double amount,
    required String currency,
    required String phoneNumber,
    required String customerEmail,
    required String customerName,
    required String ussdCode, // e.g., '*901*1#' for specific bank
  }) async {
    try {
      _validatePhoneNumber(phoneNumber);

      final baseUrl = _testMode ? _baseUrlTest : _baseUrlProd;
      final reference = 'txn_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _dio.post(
        '$baseUrl/charges?type=ussd',
        data: {
          'tx_ref': reference,
          'amount': amount,
          'currency': currency,
          'email': customerEmail,
          'phone_number': phoneNumber,
          'full_name': customerName,
          'ussd_type': 'merchant_broadcast',
          'meta': {
            'ussd_code': ussdCode,
          },
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return USSDPaymentResponse(
          success: data['status'] == 'success',
          reference: reference,
          ussdCode: data['data']?['ussd'] ?? ussdCode,
          message: data['message'],
          authUrl: data['data']?['auth_url'],
          phoneNumber: phoneNumber,
        );
      }

      throw Exception('USSD payment initiation failed');
    } catch (e) {
      throw USSDException('USSD payment error: $e');
    }
  }

  /// Initiate Mobile Money payment
  Future<MobileMoneyResponse> initiateMobileMoneyPayment({
    required double amount,
    required String currency,
    required String phoneNumber,
    required String customerEmail,
    required String customerName,
    required String provider, // mtn, vodafone, airtel, etc.
  }) async {
    try {
      _validatePhoneNumber(phoneNumber);

      final baseUrl = _testMode ? _baseUrlTest : _baseUrlProd;
      final reference = 'txn_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _dio.post(
        '$baseUrl/charges?type=mobile_money_ghana',
        data: {
          'tx_ref': reference,
          'amount': amount,
          'currency': currency,
          'email': customerEmail,
          'phone_number': phoneNumber,
          'full_name': customerName,
          'provider': provider,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return MobileMoneyResponse(
          success: data['status'] == 'success',
          reference: reference,
          message: data['message'],
          authUrl: data['data']?['auth_url'],
          phoneNumber: phoneNumber,
          provider: provider,
          authCode: data['data']?['auth_code'],
        );
      }

      throw Exception('Mobile Money payment initiation failed');
    } catch (e) {
      throw USSDException('Mobile Money payment error: $e');
    }
  }

  /// Verify USSD/Mobile Money payment status
  Future<PaymentStatus> verifyPaymentStatus(String reference) async {
    try {
      final baseUrl = _testMode ? _baseUrlTest : _baseUrlProd;

      final response = await _dio.get(
        '$baseUrl/transactions/verify_by_reference',
        queryParameters: {'tx_ref': reference},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final txData = data['data'] as Map<String, dynamic>;

        return PaymentStatus(
          status: txData['status'] ?? 'failed',
          reference: reference,
          amount: (txData['amount'] as num).toDouble(),
          currency: txData['currency'],
          timestamp: txData['created_at'],
          description: txData['narration'],
        );
      }

      throw Exception('Payment verification failed');
    } catch (e) {
      throw USSDException('Payment verification error: $e');
    }
  }

  /// Get USSD codes for supported banks
  Future<List<USSDBank>> getUSSDCodes({
    required String country,
  }) async {
    try {
      final baseUrl = _testMode ? _baseUrlTest : _baseUrlProd;

      final response = await _dio.get(
        '$baseUrl/ussd_codes',
        queryParameters: {'country': country},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final codesData = data['data'] as List<dynamic>;

        return codesData
            .map((bank) => USSDBank.fromJson(bank as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Failed to fetch USSD codes');
    } catch (e) {
      throw USSDException('USSD codes error: $e');
    }
  }

  /// Get supported mobile money providers
  Future<List<MobileMoneyProvider>> getMobileMoneyProviders({
    required String country,
  }) async {
    try {
      // Return static list for Ghana
      if (country.toUpperCase() == 'GH') {
        return [
          MobileMoneyProvider(
            code: 'mtn',
            name: 'MTN Mobile Money',
            country: 'Ghana',
            supportedCurrencies: ['GHS'],
          ),
          MobileMoneyProvider(
            code: 'vodafone',
            name: 'Vodafone Cash',
            country: 'Ghana',
            supportedCurrencies: ['GHS'],
          ),
          MobileMoneyProvider(
            code: 'airtel',
            name: 'Airtel Money',
            country: 'Ghana',
            supportedCurrencies: ['GHS'],
          ),
        ];
      }

      return [];
    } catch (e) {
      throw USSDException('Mobile money providers error: $e');
    }
  }

  /// Validate phone number format
  void _validatePhoneNumber(String phoneNumber) {
    // Remove common prefixes and validate
    String cleanNumber =
        phoneNumber.replaceAll('+', '').replaceAll('-', '').replaceAll(' ', '');

    if (cleanNumber.length < 9 || cleanNumber.length > 13) {
      throw USSDException('Invalid phone number format');
    }
  }

  /// Resend USSD/Mobile Money payment request
  Future<bool> resendPaymentRequest(String reference) async {
    try {
      final baseUrl = _testMode ? _baseUrlTest : _baseUrlProd;

      final response = await _dio.post(
        '$baseUrl/transactions/$reference/resend_otp',
      );

      return response.statusCode == 200;
    } catch (e) {
      throw USSDException('Resend payment request error: $e');
    }
  }
}

/// USSD payment response
class USSDPaymentResponse {
  final bool success;
  final String reference;
  final String ussdCode;
  final String? message;
  final String? authUrl;
  final String phoneNumber;

  USSDPaymentResponse({
    required this.success,
    required this.reference,
    required this.ussdCode,
    this.message,
    this.authUrl,
    required this.phoneNumber,
  });
}

/// Mobile Money response
class MobileMoneyResponse {
  final bool success;
  final String reference;
  final String? message;
  final String? authUrl;
  final String phoneNumber;
  final String provider;
  final String? authCode;

  MobileMoneyResponse({
    required this.success,
    required this.reference,
    this.message,
    this.authUrl,
    required this.phoneNumber,
    required this.provider,
    this.authCode,
  });
}

/// Payment status
class PaymentStatus {
  final String status; // pending, success, failed
  final String reference;
  final double amount;
  final String? currency;
  final String? timestamp;
  final String? description;

  PaymentStatus({
    required this.status,
    required this.reference,
    required this.amount,
    this.currency,
    this.timestamp,
    this.description,
  });

  bool get isPending => status == 'pending';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
}

/// USSD Bank information
class USSDBank {
  final String bankCode;
  final String bankName;
  final String ussdCode;
  final String country;

  USSDBank({
    required this.bankCode,
    required this.bankName,
    required this.ussdCode,
    required this.country,
  });

  factory USSDBank.fromJson(Map<String, dynamic> json) {
    return USSDBank(
      bankCode: json['code']?.toString() ?? '',
      bankName: json['name'] ?? '',
      ussdCode: json['ussd'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

/// Mobile Money Provider information
class MobileMoneyProvider {
  final String code;
  final String name;
  final String country;
  final List<String> supportedCurrencies;

  MobileMoneyProvider({
    required this.code,
    required this.name,
    required this.country,
    required this.supportedCurrencies,
  });
}
