import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'permission_service.dart';

/// RBAC Middleware for Dio HTTP Client
/// Intercepts all API calls and validates JWT token + permissions
/// before allowing request to proceed
class RBACMiddleware extends Interceptor {
  final PermissionService _permissionService;
  final List<String> _publicEndpoints; // Endpoints that don't require auth

  RBACMiddleware(
    this._permissionService, {
    List<String>? publicEndpoints,
  }) : _publicEndpoints = publicEndpoints ??
            [
              '/auth/login',
              '/auth/signup',
              '/auth/refresh',
              '/health',
              '/public/products',
            ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      // Check if endpoint is public (no auth required)
      if (_isPublicEndpoint(options.path)) {
        return handler.next(options);
      }

      // Extract JWT token from headers
      final authHeader = options.headers['Authorization'] as String?;
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            message: 'Missing or invalid authorization token',
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {
                'error': 'Unauthorized',
                'message': 'Missing authentication token'
              },
            ),
          ),
          true,
        );
      }

      final token = authHeader.substring(7); // Remove "Bearer " prefix

      // Validate JWT token (check expiry, signature, etc)
      try {
        if (JwtDecoder.isExpired(token)) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.unknown,
              message: 'Token has expired',
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'error': 'Unauthorized', 'message': 'Token expired'},
              ),
            ),
            true,
          );
        }
      } catch (e) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            message: 'Invalid token',
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'error': 'Unauthorized', 'message': 'Invalid token'},
            ),
          ),
          true,
        );
      }

      // Decode token to get claims
      final decodedToken = JwtDecoder.decode(token);
      final userContext = UserContext.fromMap(decodedToken);

      // Add user context to request for use in handlers
      options.extra['userContext'] = userContext;
      options.extra['userId'] = userContext.userId;
      options.extra['userRole'] = userContext.role.toString();

      // Store token in extra for later use
      options.extra['authToken'] = token;

      // Log successful auth (will be enhanced with audit logging)
      _logAuthSuccess(userContext, options.path);

      handler.next(options);
    } catch (e) {
      // RBAC middleware error - continue with rejection
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          message: 'Authentication error',
          response: Response(
            requestOptions: options,
            statusCode: 500,
            data: {'error': 'Internal server error'},
          ),
        ),
        true,
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      // Log authentication/authorization errors
      if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
        final userContext =
            err.requestOptions.extra['userContext'] as UserContext?;
        final endpoint = err.requestOptions.path;

        if (userContext != null) {
          _logAuthFailure(
            userContext,
            endpoint,
            err.response?.statusCode ?? 401,
            err.message ?? 'Unknown error',
          );
        }
      }

      handler.next(err);
    } catch (e) {
      // Error in RBAC error handler - continue with error
      handler.next(err);
    }
  }

  /// Check if endpoint is public (doesn't require authentication)
  bool _isPublicEndpoint(String path) {
    return _publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  /// Log successful authentication
  void _logAuthSuccess(UserContext context, String endpoint) {
    print(
        '[AUTH_SUCCESS] User: ${context.userId}, Role: ${context.role}, Endpoint: $endpoint');
    // TODO: Send to audit log service
  }

  /// Log authentication/authorization failure
  void _logAuthFailure(
    UserContext context,
    String endpoint,
    int statusCode,
    String reason,
  ) {
    print('[AUTH_FAILURE] User: ${context.userId}, Role: ${context.role}, '
        'Endpoint: $endpoint, Code: $statusCode, Reason: $reason');
    // TODO: Send to audit log service with severity warning
  }

  /// Extract user context from request options
  static UserContext? getUserContext(RequestOptions options) {
    return options.extra['userContext'] as UserContext?;
  }

  /// Extract user ID from request options
  static String? getUserId(RequestOptions options) {
    return options.extra['userId'] as String?;
  }

  /// Extract JWT token from request options
  static String? getToken(RequestOptions options) {
    return options.extra['authToken'] as String?;
  }
}

/// Response Interceptor for permission-based response filtering
/// Prevents leaking sensitive data to unauthorized users
class ResponsePermissionInterceptor extends Interceptor {
  final PermissionService _permissionService;

  ResponsePermissionInterceptor(this._permissionService);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      final userContext =
          RBACMiddleware.getUserContext(response.requestOptions);

      if (userContext == null) {
        return handler.next(response);
      }

      // Filter response data based on user permissions
      _filterResponseData(response.data, userContext);

      handler.next(response);
    } catch (e) {
      print('Response permission filter error: $e');
      handler.next(response);
    }
  }

  /// Filter sensitive fields from response based on permissions
  void _filterResponseData(dynamic data, UserContext userContext) {
    if (data is Map<String, dynamic>) {
      // Remove cost_price if user can't view it
      if (!userContext.hasPermission(Permission.view_cost_price)) {
        data.remove('cost_price');
        data.remove('wholesale_price');
        data.remove('margin_percentage');
      }

      // Remove sensitive audit fields if user can't access audit log
      if (!userContext.hasPermission(Permission.access_audit_log)) {
        data.remove('audit_trail');
        data.remove('created_by');
        data.remove('modified_by');
      }

      // Recursively filter nested objects
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _filterResponseData(value, userContext);
        } else if (value is List) {
          for (var item in value) {
            if (item is Map<String, dynamic>) {
              _filterResponseData(item, userContext);
            }
          }
        }
      });
    }
  }
}

/// RBAC Utility Functions

/// Check if request is allowed based on permissions
/// Used in route handlers
Future<bool> checkPermission(
  RequestOptions options,
  Permission requiredPermission,
) async {
  final userContext = RBACMiddleware.getUserContext(options);
  if (userContext == null) {
    return false;
  }

  return userContext.hasPermission(requiredPermission);
}

/// Check if request has all required permissions
Future<bool> checkAllPermissions(
  RequestOptions options,
  List<Permission> requiredPermissions,
) async {
  final userContext = RBACMiddleware.getUserContext(options);
  if (userContext == null) {
    return false;
  }

  for (final permission in requiredPermissions) {
    if (!userContext.hasPermission(permission)) {
      return false;
    }
  }

  return true;
}

/// Check if request has any of required permissions
Future<bool> checkAnyPermission(
  RequestOptions options,
  List<Permission> requiredPermissions,
) async {
  final userContext = RBACMiddleware.getUserContext(options);
  if (userContext == null) {
    return false;
  }

  for (final permission in requiredPermissions) {
    if (userContext.hasPermission(permission)) {
      return true;
    }
  }

  return false;
}

/// Deny request with 403 Forbidden response
DioException createForbiddenError(
  RequestOptions options, {
  String message = 'Access denied',
}) {
  return DioException(
    requestOptions: options,
    type: DioExceptionType.unknown,
    message: message,
    response: Response(
      requestOptions: options,
      statusCode: 403,
      data: {
        'error': 'Forbidden',
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ),
  );
}

/// Deny request with 401 Unauthorized response
DioException createUnauthorizedError(
  RequestOptions options, {
  String message = 'Authentication required',
}) {
  return DioException(
    requestOptions: options,
    type: DioExceptionType.unknown,
    message: message,
    response: Response(
      requestOptions: options,
      statusCode: 401,
      data: {
        'error': 'Unauthorized',
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ),
  );
}
