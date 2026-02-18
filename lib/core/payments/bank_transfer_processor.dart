import 'package:dio/dio.dart';
import 'payment_exceptions.dart' show BankTransferException;

/// Bank transfer payment processor
class BankTransferProcessor {
  final Dio _dio;
  late String _apiKey;
  bool _testMode = true;

  static const String _baseUrlProd = 'https://api.flutterwave.com/v3';
  static const String _baseUrlTest = 'https://api.flutterwave.com/v3';

  BankTransferProcessor({required Dio dio}) : _dio = dio;

  /// Initialize processor
  Future<void> initialize({
    required String apiKey,
    bool testMode = true,
  }) async {
    _apiKey = apiKey;
    _testMode = testMode;
    _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
  }

  /// Initiate bank transfer payment
  Future<BankTransferResponse> initiateBankTransfer({
    required double amount,
    required String currency,
    required String customerEmail,
    required String customerName,
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      // Validate account details
      _validateAccountDetails(accountNumber, bankCode);

      final baseUrl = _testMode ? _baseUrlTest : _baseUrlProd;

      final response = await _dio.post(
        '$baseUrl/transfers',
        data: {
          'account_bank': bankCode,
          'account_number': accountNumber,
          'amount': amount,
          'currency': currency,
          'narration': 'COOP Commerce Payment',
          'reference': 'txn_${DateTime.now().millisecondsSinceEpoch}',
          'meta': {
            'email': customerEmail,
            'name': customerName,
          },
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return BankTransferResponse(
          success: data['status'] == 'success',
          reference: data['data']?['id']?.toString() ?? '',
          message: data['message'],
          bankDetails: BankDetails(
            bankName: data['data']?['bank_name'] ?? '',
            accountNumber: accountNumber,
            accountName: data['data']?['full_name'] ?? customerName,
            amount: amount,
            transferCode: data['data']?['transfer_code'] ?? '',
          ),
        );
      }

      throw Exception(
          'Bank transfer initiation failed: ${response.statusCode}');
    } catch (e) {
      throw BankTransferException('Bank transfer initiation error: $e');
    }
  }

  /// Verify bank account details
  Future<AccountVerification> verifyBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      _validateAccountDetails(accountNumber, bankCode);

      final baseUrl = _testMode ? _baseUrlTest : _baseUrlProd;

      final response = await _dio.get(
        '$baseUrl/banks/$bankCode/resolve',
        queryParameters: {
          'account_number': accountNumber,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return AccountVerification(
          verified: data['status'] == 'success',
          accountName: data['data']?['account_name'] ?? '',
          accountNumber: accountNumber,
          bankCode: bankCode,
          message: data['message'],
        );
      }

      throw Exception('Account verification failed');
    } catch (e) {
      throw BankTransferException('Account verification error: $e');
    }
  }

  /// Get list of supported banks
  Future<List<Bank>> getSupportedBanks({
    required String country,
  }) async {
    try {
      final baseUrl = _testMode ? _baseUrlTest : _baseUrlProd;

      final response = await _dio.get(
        '$baseUrl/banks/$country',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final banksData = data['data'] as List<dynamic>;

        return banksData
            .map((bank) => Bank.fromJson(bank as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Failed to fetch banks');
    } catch (e) {
      throw BankTransferException('Bank list error: $e');
    }
  }

  /// Check transfer status
  Future<TransferStatus> checkTransferStatus(String transferReference) async {
    try {
      final baseUrl = _testMode ? _baseUrlTest : _baseUrlProd;

      final response = await _dio.get(
        '$baseUrl/transfers/$transferReference',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final transferData = data['data'] as Map<String, dynamic>;

        return TransferStatus(
          status: transferData['status'] ?? 'pending',
          reference: transferReference,
          amount: (transferData['amount'] as num).toDouble(),
          fee: (transferData['fee'] as num?)?.toDouble() ?? 0,
          timestamp: transferData['created_at'],
          reason: transferData['reason'],
        );
      }

      throw Exception('Transfer status check failed');
    } catch (e) {
      throw BankTransferException('Transfer status check error: $e');
    }
  }

  /// Validate account details
  void _validateAccountDetails(String accountNumber, String bankCode) {
    if (accountNumber.isEmpty || bankCode.isEmpty) {
      throw BankTransferException('Account number and bank code are required');
    }

    if (!RegExp(r'^\d{10,18}$').hasMatch(accountNumber)) {
      throw BankTransferException('Invalid account number format');
    }

    if (!RegExp(r'^\d{3,6}$').hasMatch(bankCode)) {
      throw BankTransferException('Invalid bank code format');
    }
  }
}

/// Bank transfer response
class BankTransferResponse {
  final bool success;
  final String reference;
  final String? message;
  final BankDetails bankDetails;

  BankTransferResponse({
    required this.success,
    required this.reference,
    this.message,
    required this.bankDetails,
  });
}

/// Bank account details
class BankDetails {
  final String bankName;
  final String accountNumber;
  final String accountName;
  final double amount;
  final String transferCode;

  BankDetails({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.transferCode,
  });
}

/// Account verification result
class AccountVerification {
  final bool verified;
  final String accountName;
  final String accountNumber;
  final String bankCode;
  final String? message;

  AccountVerification({
    required this.verified,
    required this.accountName,
    required this.accountNumber,
    required this.bankCode,
    this.message,
  });
}

/// Bank information
class Bank {
  final String code;
  final String name;
  final String country;

  Bank({
    required this.code,
    required this.name,
    required this.country,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      code: json['code']?.toString() ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

/// Transfer status
class TransferStatus {
  final String status; // pending, success, failed
  final String reference;
  final double amount;
  final double fee;
  final String? timestamp;
  final String? reason;

  TransferStatus({
    required this.status,
    required this.reference,
    required this.amount,
    required this.fee,
    this.timestamp,
    this.reason,
  });

  bool get isPending => status == 'pending';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
}
