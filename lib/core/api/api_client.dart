import 'package:dio/dio.dart';
import 'api_config.dart';
import 'backend_health_checker.dart';

class ApiClient {
  static String _baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.ncdfcoop.ng',
  );

  static bool _useMockBackend = false;

  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    print(
        '🌐 API Client initialized with base URL: $_baseUrl (Mock: $_useMockBackend)');
  }

  Dio get client => _dio;

  /// Get current base URL
  static String get baseUrl => _baseUrl;

  /// Check if using mock backend
  static bool get isMockBackend => _useMockBackend;

  /// Auto-detect and configure backend
  Future<void> autoConfigureBackend() async {
    final checker = BackendHealthChecker(dio: _dio);
    final health = await checker.autoDetectBackend();

    _baseUrl = health.baseUrl;
    _useMockBackend = !health.isHealthy;

    _dio.options.baseUrl = _baseUrl;

    print('✅ Backend configured: $_baseUrl (Mock: $_useMockBackend)');
  }

  /// Manually set backend URL
  static void setBackendUrl(String url, {bool useMock = false}) {
    _baseUrl = url;
    _useMockBackend = useMock;
    print('🔧 Backend URL changed to: $_baseUrl (Mock: $_useMockBackend)');
  }

  /// Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Add request interceptor
  void addRequestInterceptor(
    Future<RequestOptions> Function(RequestOptions) handler,
  ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, interceptorHandler) async {
          final result = await handler(options);
          interceptorHandler.next(result);
        },
      ),
    );
  }

  /// Add response interceptor
  void addResponseInterceptor(Future<Response> Function(Response) handler) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, interceptorHandler) async {
          final result = await handler(response);
          interceptorHandler.next(result);
        },
      ),
    );
  }

  /// Add error interceptor
  void addErrorInterceptor(Future<dynamic> Function(DioException) handler) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, interceptorHandler) async {
          final result = await handler(error);
          if (result is Response) {
            interceptorHandler.resolve(result);
          } else if (result is DioException) {
            interceptorHandler.next(result);
          } else {
            interceptorHandler.next(error);
          }
        },
      ),
    );
  }
}
