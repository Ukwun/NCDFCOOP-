import 'package:dio/dio.dart';
import 'api_config.dart';

/// Detects which backend is available and healthy
class BackendHealthChecker {
  final Dio _dio;

  BackendHealthChecker({Dio? dio}) : _dio = dio ?? Dio();

  /// Check if backend is running at given URL
  Future<BackendHealthResult> checkBackendHealth(
    String baseUrl, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/health',
        options: Options(
          sendTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return BackendHealthResult(
        isHealthy: response.statusCode == 200,
        baseUrl: baseUrl,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return BackendHealthResult(
        isHealthy: false,
        baseUrl: baseUrl,
        error: e.toString(),
      );
    }
  }

  /// Auto-detect which backend is available
  /// Tries in order: local → emulator → production → firebase
  Future<BackendHealthResult> autoDetectBackend() async {
    print('🔍 Scanning for available backends...');

    final results = await Future.wait([
      checkBackendHealth(ApiConfig.getBaseUrl(env: 'local')),
      checkBackendHealth(ApiConfig.getBaseUrl(env: 'emulator')),
      checkBackendHealth(ApiConfig.getBaseUrl(env: 'production')),
      checkBackendHealth(ApiConfig.getBaseUrl(env: 'firebase')),
    ]);

    // Return first healthy backend
    final healthy = results.firstWhere(
      (r) => r.isHealthy,
      orElse: () => results.first, // Fall back to production config
    );

    print('✅ Using backend: ${healthy.baseUrl}');
    return healthy;
  }

  /// Check specific endpoint exists
  Future<bool> checkEndpointExists(String baseUrl, String endpoint) async {
    try {
      final response = await _dio.head(
        '$baseUrl$endpoint',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          validateStatus: (status) => true,
        ),
      );
      return response.statusCode != 404;
    } catch (e) {
      return false;
    }
  }

  /// Verify all required authentication endpoints exist
  Future<Map<String, bool>> verifyAuthEndpoints(String baseUrl) async {
    print('🔐 Verifying authentication endpoints...');

    return {
      'login': await checkEndpointExists(baseUrl, ApiConfig.loginEndpoint),
      'register':
          await checkEndpointExists(baseUrl, ApiConfig.registerEndpoint),
      'google':
          await checkEndpointExists(baseUrl, ApiConfig.googleAuthEndpoint),
      'facebook':
          await checkEndpointExists(baseUrl, ApiConfig.facebookAuthEndpoint),
      'apple': await checkEndpointExists(baseUrl, ApiConfig.appleAuthEndpoint),
      'refresh':
          await checkEndpointExists(baseUrl, ApiConfig.refreshTokenEndpoint),
    };
  }
}
