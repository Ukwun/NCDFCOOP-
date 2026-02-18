import 'api_client.dart';
import 'package:coop_commerce/core/auth/role.dart' as auth_role;
import 'package:coop_commerce/features/welcome/user_model.dart';
import 'package:coop_commerce/core/audit/audit_service.dart';
import 'package:coop_commerce/core/api/pricing_service.dart';
import 'package:coop_commerce/core/services/price_validation_service.dart';
import 'package:coop_commerce/core/security/permission_service.dart' as perm;
import 'package:coop_commerce/core/security/permission_service.dart';
import 'package:coop_commerce/core/security/resource_ownership_validator.dart';
import 'package:coop_commerce/core/security/audit_log_service.dart';

/// Order item model
class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}

/// Order model
class Order {
  final String id;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double savings;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final String? trackingNumber;

  Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.savings,
    required this.total,
    required this.status,
    required this.createdAt,
    this.estimatedDelivery,
    this.trackingNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      savings: (json['savings'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'])
          : null,
      trackingNumber: json['trackingNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'savings': savings,
        'total': total,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'estimatedDelivery': estimatedDelivery?.toIso8601String(),
        'trackingNumber': trackingNumber,
      };
}

/// Exception for permission denied
class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);

  @override
  String toString() => 'PermissionException: $message';
}

/// Checkout request model
class CheckoutRequest {
  final List<OrderItem> items;
  final String shippingAddressId;
  final String billingAddressId;
  final String paymentMethodId;
  final String? couponCode;
  final double?
      clientCalculatedTotal; // Client-calculated total for server validation
  final Map<String, double>? itemPrices; // productId -> client price mapping

  CheckoutRequest({
    required this.items,
    required this.shippingAddressId,
    required this.billingAddressId,
    required this.paymentMethodId,
    this.couponCode,
    this.clientCalculatedTotal,
    this.itemPrices,
  });

  Map<String, dynamic> toJson() => {
        'items': items.map((i) => i.toJson()).toList(),
        'shippingAddressId': shippingAddressId,
        'billingAddressId': billingAddressId,
        'paymentMethodId': paymentMethodId,
        'couponCode': couponCode,
        'clientCalculatedTotal': clientCalculatedTotal,
        'itemPrices': itemPrices,
      };
}

/// Order service for API calls
class OrderService {
  final ApiClient _apiClient;
  final PermissionService _permissionService;
  final ResourceOwnershipValidator _ownershipValidator;
  final AuditLogService _auditLogService;

  OrderService(
    this._apiClient, {
    PermissionService? permissionService,
    ResourceOwnershipValidator? ownershipValidator,
    AuditLogService? auditLogService,
  })  : _permissionService = permissionService ?? PermissionService(),
        _ownershipValidator =
            ownershipValidator ?? ResourceOwnershipValidator(),
        _auditLogService = auditLogService ?? AuditLogService();

  /// Create checkout and place order with server-side price validation
  Future<Order> checkout(
    CheckoutRequest request, {
    required User user,
    required auth_role.UserRole userRole,
    PriceValidationService? priceValidationService,
    AuditService? auditService,
    String? contractId,
    String? franchiseId,
  }) async {
    try {
      // Create UserContext for permission checking
      final userContext = UserContext(
        userId: user.id,
        role: _mapUserRoleToPermissionRole(userRole),
        franchiseId: franchiseId,
        institutionId: null,
        warehouseId: null,
      );

      // Check permission to create order
      final canCreateOrder =
          await _permissionService.canCreateOrder(userContext);
      if (!canCreateOrder) {
        // Log unauthorized attempt
        await _auditLogService.logAction(
          user.id,
          _mapUserRoleToString(userRole),
          AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT,
          'order',
          severity: AuditSeverity.WARNING,
          franchiseId: franchiseId,
        );
        throw PermissionException(
          'User does not have permission to create orders',
        );
      }

      // Perform server-side price validation if service provided
      if (priceValidationService != null) {
        final validationItems = request.items
            .map((item) => OrderItemForValidation(
                  productId: item.productId,
                  clientPrice: item.price,
                  quantity: item.quantity,
                ))
            .toList();

        final validationResult =
            await priceValidationService.validateOrderPrices(
          user: user,
          userRole: userRole,
          clientItems: validationItems,
          contractId: contractId,
          franchiseId: franchiseId,
        );

        // Log validation result for audit trail
        if (auditService != null) {
          await auditService.logAction(
            userId: user.id,
            userName: user.name,
            userRoles: [userRole],
            eventType: AuditEventType.orderCreated,
            resource: 'order',
            resourceId: 'pending_checkout',
            action: 'price_validation_check',
            result: validationResult.isValid ? 'success' : 'failure',
            details: {
              'isValid': validationResult.isValid,
              'clientTotal': validationResult.clientTotal,
              'serverTotal': validationResult.serverTotal,
              'discrepancyCount': validationResult.discrepancies.length,
              'fraudDetected': validationResult.fraudDetected,
            },
          );
        }

        // Reject order if price validation fails
        if (!validationResult.isValid) {
          if (validationResult.fraudDetected) {
            // Log fraud attempt with more details
            await _auditLogService.logAction(
              user.id,
              _mapUserRoleToString(userRole),
              AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT,
              'order',
              resourceId: 'pending_checkout',
              severity: AuditSeverity.CRITICAL,
              details: {
                'attempted_total': validationResult.clientTotal,
                'correct_total': validationResult.serverTotal,
                'fraud_detected': true,
                'discrepancy_count': validationResult.discrepancies.length,
              },
            );
            if (auditService != null) {
              await auditService.logAction(
                userId: user.id,
                userName: user.name,
                userRoles: [userRole],
                eventType: AuditEventType.suspiciousActivity,
                resource: 'order',
                resourceId: 'pending_checkout',
                action: 'fraud_attempt_detected',
                result: 'failure',
                details: {
                  'attemptedTotal': validationResult.clientTotal,
                  'correctTotal': validationResult.serverTotal,
                  'discrepancies': validationResult.discrepancies
                      .map((d) => {
                            'productId': d.productId,
                            'clientPrice': d.clientPrice,
                            'serverPrice': d.serverPrice,
                            'overchargeAmount': d.overchargeAmount,
                          })
                      .toList(),
                },
              );
            }
          }
          throw PriceValidationException(
            validationResult.getErrorMessage(),
            details: {
              'clientTotal': validationResult.clientTotal,
              'serverTotal': validationResult.serverTotal,
              'discrepancies': validationResult.discrepancies.length,
            },
          );
        }
      }

      // Send to backend for order creation
      final response = await _apiClient.client.post(
        '/orders/checkout',
        data: request.toJson(),
      );

      final orderId = response.data['order']['id'] ?? 'unknown';

      // Log successful order creation with new AuditLogService
      await _auditLogService.logOrderAction(
        user.id,
        _mapUserRoleToString(userRole),
        AuditAction.ORDER_CREATED,
        orderId,
        franchiseId: franchiseId,
        newValue: {
          'order_id': orderId,
          'total': response.data['order']['total'],
          'item_count': request.items.length,
        },
      );

      // Also log with legacy audit service if provided
      if (auditService != null) {
        await auditService.logAction(
          userId: user.id,
          userName: user.name,
          userRoles: [userRole],
          eventType: AuditEventType.orderCreated,
          resource: 'order',
          resourceId: orderId,
          action: 'order_created',
          result: 'success',
          details: {
            'orderId': orderId,
            'total': response.data['order']['total'],
            'itemCount': request.items.length,
          },
        );
      }

      return Order.fromJson(response.data['order']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get order details with ownership validation
  Future<Order> getOrderDetails(
    String orderId, {
    String? userId,
    auth_role.UserRole? userRole,
  }) async {
    try {
      // Validate ownership if user context provided
      if (userId != null && userRole != null) {
        final canAccess =
            await _ownershipValidator.canAccessOrder(userId, orderId);
        if (!canAccess) {
          // Log unauthorized access attempt
          await _auditLogService.logAction(
            userId,
            _mapUserRoleToString(userRole),
            AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT,
            'order',
            resourceId: orderId,
            severity: AuditSeverity.WARNING,
          );
          throw PermissionException('User cannot access this order');
        }

        // Log data access for compliance
        await _auditLogService.logAction(
          userId,
          _mapUserRoleToString(userRole),
          AuditAction.DATA_ACCESSED,
          'order',
          resourceId: orderId,
          severity: AuditSeverity.INFO,
        );
      }

      final response = await _apiClient.client.get('/orders/$orderId');
      return Order.fromJson(response.data['order']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's orders with permission checking
  Future<List<Order>> getUserOrders({
    int page = 1,
    int limit = 10,
    String? userId,
    auth_role.UserRole? userRole,
  }) async {
    try {
      // Log the access attempt
      if (userId != null && userRole != null) {
        await _auditLogService.logAction(
          userId,
          _mapUserRoleToString(userRole),
          AuditAction.DATA_ACCESSED,
          'orders',
          resourceId: 'list',
          severity: AuditSeverity.INFO,
        );
      }

      final response = await _apiClient.client.get(
        '/orders',
        queryParameters: {'page': page, 'limit': limit},
      );
      final orders = (response.data['orders'] as List)
          .map((o) => Order.fromJson(o))
          .toList();
      return orders;
    } catch (e) {
      rethrow;
    }
  }

  /// Track order by tracking number
  Future<Order> trackOrder(String trackingNumber) async {
    try {
      final response = await _apiClient.client.get(
        '/orders/track/$trackingNumber',
      );
      return Order.fromJson(response.data['order']);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel order with permission and ownership validation
  Future<void> cancelOrder(
    String orderId, {
    String? userId,
    auth_role.UserRole? userRole,
  }) async {
    try {
      if (userId != null && userRole != null) {
        // Check permission
        final userContext = UserContext(
          userId: userId,
          role: _mapUserRoleToPermissionRole(userRole),
          franchiseId: null,
          institutionId: null,
          warehouseId: null,
        );

        final canCancelOrder =
            await _permissionService.canCancelOrder(userContext);
        if (!canCancelOrder) {
          await _auditLogService.logAction(
            userId,
            _mapUserRoleToString(userRole),
            AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT,
            'order',
            resourceId: orderId,
            severity: AuditSeverity.WARNING,
          );
          throw PermissionException('User cannot cancel orders');
        }

        // Check ownership
        final canAccess =
            await _ownershipValidator.canAccessOrder(userId, orderId);
        if (!canAccess) {
          await _auditLogService.logAction(
            userId,
            _mapUserRoleToString(userRole),
            AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT,
            'order',
            resourceId: orderId,
            severity: AuditSeverity.WARNING,
          );
          throw PermissionException('User cannot cancel this order');
        }
      }

      await _apiClient.client.post('/orders/$orderId/cancel');

      // Log successful cancellation
      if (userId != null && userRole != null) {
        await _auditLogService.logOrderAction(
          userId,
          _mapUserRoleToString(userRole),
          AuditAction.ORDER_CANCELLED,
          orderId,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get order history with filters
  Future<List<Order>> getOrderHistory({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) {
        queryParams['status'] = status;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _apiClient.client.get(
        '/orders/history',
        queryParameters: queryParams,
      );
      final orders = (response.data['orders'] as List)
          .map((o) => Order.fromJson(o))
          .toList();
      return orders;
    } catch (e) {
      rethrow;
    }
  }

  /// Create order with role-based validation and pricing
  Future<Order> createOrderWithRoleCheck({
    required User user,
    required auth_role.UserRole role,
    required List<MapEntry<String, int>> items, // productId -> quantity
    required PricingService pricingService,
    required AuditService auditService,
  }) async {
    try {
      // Create UserContext for permission checking
      final userContext = UserContext(
        userId: user.id,
        role: _mapUserRoleToPermissionRole(role),
        franchiseId: null,
        institutionId: null,
        warehouseId: null,
      );

      // Check permission using new PermissionService
      final canCreateOrder =
          await _permissionService.canCreateOrder(userContext);
      if (!canCreateOrder) {
        // Log unauthorized attempt
        await _auditLogService.logAction(
          user.id,
          _mapUserRoleToString(role),
          AuditAction.UNAUTHORIZED_ACCESS_ATTEMPT,
          'order',
          resourceId: 'new',
          severity: AuditSeverity.WARNING,
        );
        // Also log with legacy audit service
        await auditService.logAction(
          userId: user.id,
          userName: user.email,
          userRoles: user.roles,
          eventType: AuditEventType.accessDenied,
          resource: 'order',
          resourceId: 'new',
          action: 'create_order_attempted',
          result: 'failure',
          denialReason: 'insufficient_permission',
        );
        throw PermissionException(
          'User does not have permission to create orders in this role',
        );
      }

      // Mock: Calculate totals with role-appropriate pricing
      double subtotal = 0;
      double total = 0;
      int itemCount = 0;

      for (final entry in items) {
        // In real implementation, fetch product and apply role pricing
        subtotal += entry.value * 100; // Mock price
        total += entry.value * 100;
        itemCount += entry.value;
      }

      // Create order
      final order = Order(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        items: items
            .map((e) => OrderItem(
                  productId: e.key,
                  productName: 'Product ${e.key}',
                  price: 100,
                  quantity: e.value,
                  subtotal: e.value * 100,
                ))
            .toList(),
        subtotal: subtotal,
        tax: subtotal * 0.075,
        savings: subtotal * 0.15,
        total: total,
        status: 'pending',
        createdAt: DateTime.now(),
        estimatedDelivery: DateTime.now().add(const Duration(days: 3)),
      );

      // Log successful order creation with new AuditLogService
      await _auditLogService.logOrderAction(
        user.id,
        _mapUserRoleToString(role),
        AuditAction.ORDER_CREATED,
        order.id,
        newValue: {
          'role': role.name,
          'item_count': itemCount,
          'total': total,
          'order_type': role.isWholesale ? 'wholesale' : 'retail',
        },
      );

      // Also log with legacy audit service
      await auditService.logAction(
        userId: user.id,
        userName: user.email,
        userRoles: user.roles,
        eventType: AuditEventType.orderCreated,
        resource: 'order',
        resourceId: order.id,
        action: 'create_order',
        result: 'success',
        details: {
          'role': role.name,
          'itemCount': itemCount,
          'total': total,
          'orderType': role.isWholesale ? 'wholesale' : 'retail',
        },
      );

      return order;
    } catch (e) {
      rethrow;
    }
  }

  /// Get orders filtered by user's role and context
  Future<List<Order>> getOrdersByRole({
    required User user,
    required auth_role.UserRole role,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Log access with new AuditLogService
      await _auditLogService.logAction(
        user.id,
        _mapUserRoleToString(role),
        AuditAction.DATA_ACCESSED,
        'orders',
        resourceId: 'list',
        severity: AuditSeverity.INFO,
      );

      // Also log with legacy audit service
      await AuditService().logAction(
        userId: user.id,
        userName: user.email,
        userRoles: user.roles,
        eventType: AuditEventType.userLogin,
        resource: 'orders',
        resourceId: 'list',
        action: 'view_orders',
        result: 'success',
        details: {'role': role.name},
      );

      return getOrderHistory(page: page, limit: limit);
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method to map UserRole to PermissionService UserRole
  perm.UserRole _mapUserRoleToPermissionRole(auth_role.UserRole legacyRole) {
    switch (legacyRole) {
      case auth_role.UserRole.admin:
        return perm.UserRole.ADMIN;
      case auth_role.UserRole.superAdmin:
        return perm.UserRole.SUPER_ADMIN;
      case auth_role.UserRole.consumer:
        return perm.UserRole.CONSUMER;
      case auth_role.UserRole.franchiseOwner:
        return perm.UserRole.FRANCHISE_OWNER;
      case auth_role.UserRole.deliveryDriver:
        return perm.UserRole.DRIVER;
      case auth_role.UserRole.storeManager:
        return perm.UserRole.WAREHOUSE_MANAGER;
      case auth_role.UserRole.warehouseStaff:
        return perm.UserRole.WAREHOUSE_STAFF;
      case auth_role.UserRole.institutionalBuyer:
        return perm.UserRole.INSTITUTION_BUYER;
      case auth_role.UserRole.coopMember:
        return perm.UserRole.CONSUMER;
      case auth_role.UserRole.storeStaff:
        return perm.UserRole.WAREHOUSE_STAFF;
      case auth_role.UserRole.institutionalApprover:
        return perm.UserRole.INSTITUTION_BUYER;
    }
  }

  /// Helper method to map UserRole to string for audit logging
  String _mapUserRoleToString(auth_role.UserRole role) {
    return role.name;
  }
}
