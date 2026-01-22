import 'api_client.dart';

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

/// Checkout request model
class CheckoutRequest {
  final List<OrderItem> items;
  final String shippingAddressId;
  final String billingAddressId;
  final String paymentMethodId;
  final String? couponCode;

  CheckoutRequest({
    required this.items,
    required this.shippingAddressId,
    required this.billingAddressId,
    required this.paymentMethodId,
    this.couponCode,
  });

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    'shippingAddressId': shippingAddressId,
    'billingAddressId': billingAddressId,
    'paymentMethodId': paymentMethodId,
    'couponCode': couponCode,
  };
}

/// Order service for API calls
class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  /// Create checkout and place order
  Future<Order> checkout(CheckoutRequest request) async {
    try {
      final response = await _apiClient.client.post(
        '/orders/checkout',
        data: request.toJson(),
      );
      return Order.fromJson(response.data['order']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get order details
  Future<Order> getOrderDetails(String orderId) async {
    try {
      final response = await _apiClient.client.get('/orders/$orderId');
      return Order.fromJson(response.data['order']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's orders
  Future<List<Order>> getUserOrders({int page = 1, int limit = 10}) async {
    try {
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

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _apiClient.client.post('/orders/$orderId/cancel');
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
}
