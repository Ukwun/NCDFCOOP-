import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'category_service.dart';
import 'member_service.dart';
import 'order_service.dart';
import 'product_service.dart';
import 'local_storage.dart';

/// Service locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  ApiClient? _apiClient;
  AuthService? _authService;
  ProductService? _productService;
  CategoryService? _categoryService;
  OrderService? _orderService;
  MemberService? _memberService;
  LocalStorage? _localStorage;

  bool _initialized = false;

  ServiceLocator._internal();

  factory ServiceLocator() {
    return _instance;
  }

  /// Ensure services are initialized
  void _ensureInitialized() {
    if (!_initialized && _authService == null) {
      debugPrint('⚠️ Services not initialized, attempting fallback...');
      _createFallbackServices();
    }
  }

  /// Initialize services
  void initialize() {
    try {
      debugPrint('🔄 ServiceLocator initializing...');
      _localStorage = LocalStorage();
      _apiClient = ApiClient();
      _authService = AuthService(_apiClient!, _localStorage!);
      _productService = ProductService(_apiClient!);
      _categoryService = CategoryService(_apiClient!);
      _orderService = OrderService(_apiClient!);
      _memberService = MemberService(_apiClient!);
      _initialized = true;
      debugPrint('✅ ServiceLocator initialized successfully');
    } catch (e) {
      debugPrint('❌ ServiceLocator initialization error: $e');
      // Create minimal services to prevent null errors
      _createFallbackServices();
    }
  }

  /// Create fallback services when initialization fails
  void _createFallbackServices() {
    try {
      debugPrint('⚠️  Creating fallback services...');
      _localStorage ??= LocalStorage();
      _apiClient ??= ApiClient();

      // Create auth service without Firestore dependency
      try {
        _authService ??= AuthService(_apiClient!, _localStorage!);
      } catch (e) {
        debugPrint('⚠️ AuthService creation failed: $e');
      }

      // For other services, create instances with error handling
      try {
        _productService ??= ProductService(_apiClient!);
      } catch (e) {
        debugPrint('⚠️ ProductService creation failed: $e');
      }

      try {
        _categoryService ??= CategoryService(_apiClient!);
      } catch (e) {
        debugPrint('⚠️ CategoryService creation failed: $e');
      }

      try {
        _orderService ??= OrderService(_apiClient!);
      } catch (e) {
        debugPrint('⚠️ OrderService creation failed: $e');
      }

      try {
        _memberService ??= MemberService(_apiClient!);
      } catch (e) {
        debugPrint('⚠️ MemberService creation failed: $e');
      }

      _initialized = true;
      debugPrint('✅ ServiceLocator initialized with fallback services');
    } catch (e) {
      debugPrint('⚠️ Fallback services setup failed: $e');
    }
  }

  /// Get API client
  ApiClient get apiClient {
    _ensureInitialized();
    return _apiClient!;
  }

  /// Get authentication service
  AuthService get authService {
    _ensureInitialized();
    return _authService!;
  }

  /// Get local storage
  LocalStorage get localStorage {
    _ensureInitialized();
    return _localStorage!;
  }

  /// Get product service
  ProductService get productService {
    _ensureInitialized();
    return _productService!;
  }

  /// Get category service
  CategoryService get categoryService {
    _ensureInitialized();
    return _categoryService!;
  }

  /// Get order service
  OrderService get orderService {
    _ensureInitialized();
    return _orderService!;
  }

  /// Get member service
  MemberService get memberService {
    _ensureInitialized();
    return _memberService!;
  }

  /// Dispose services
  void dispose() {
    // Clean up resources if needed
  }
}

/// Global service locator instance
final serviceLocator = ServiceLocator();
