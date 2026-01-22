import 'api_client.dart';
import 'auth_service.dart';
import 'category_service.dart';
import 'member_service.dart';
import 'order_service.dart';
import 'product_service.dart';
import 'package:coop_commerce/core/storage/local_storage.dart';

/// Service locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  late ApiClient _apiClient;
  late AuthService _authService;
  late ProductService _productService;
  late CategoryService _categoryService;
  late OrderService _orderService;
  late MemberService _memberService;
  late LocalStorage _localStorage;

  ServiceLocator._internal();

  factory ServiceLocator() {
    return _instance;
  }

  /// Initialize services
  void initialize() {
    _localStorage = LocalStorage();
    _apiClient = ApiClient();
    _authService = AuthService(_apiClient, _localStorage);
    _productService = ProductService(_apiClient);
    _categoryService = CategoryService(_apiClient);
    _orderService = OrderService(_apiClient);
    _memberService = MemberService(_apiClient);
  }

  /// Get API client
  ApiClient get apiClient => _apiClient;

  /// Get authentication service
  AuthService get authService => _authService;

  /// Get local storage
  LocalStorage get localStorage => _localStorage;

  /// Get product service
  ProductService get productService => _productService;

  /// Get category service
  CategoryService get categoryService => _categoryService;

  /// Get order service
  OrderService get orderService => _orderService;

  /// Get member service
  MemberService get memberService => _memberService;

  /// Dispose services
  void dispose() {
    // Clean up resources if needed
  }
}

/// Global service locator instance
final serviceLocator = ServiceLocator();
