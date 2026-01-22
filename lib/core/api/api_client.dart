import 'package:dio/dio.dart';

class ApiClient {
  final _dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: 'https://api.example.com',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Dio get client => _dio;

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
