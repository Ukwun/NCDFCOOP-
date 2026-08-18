enum OrderStatus {
  pending,
  confirmed,
  processing,
  dispatched,
  outForDelivery,
  delivered,
  cancelled,
  failed;

  String get displayName {
    return switch (this) {
      OrderStatus.pending => 'Pending',
      OrderStatus.confirmed => 'Order Confirmed',
      OrderStatus.processing => 'Processing',
      OrderStatus.dispatched => 'Dispatched',
      OrderStatus.outForDelivery => 'Out for Delivery',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
      OrderStatus.failed => 'Failed',
    };
  }

  String get description {
    return switch (this) {
      OrderStatus.pending => 'Waiting for confirmation',
      OrderStatus.confirmed => 'Your order has been confirmed',
      OrderStatus.processing => 'Preparing your items',
      OrderStatus.dispatched => 'Order is on the way',
      OrderStatus.outForDelivery => 'Out for delivery today',
      OrderStatus.delivered => 'Order delivered successfully',
      OrderStatus.cancelled => 'Order was cancelled',
      OrderStatus.failed => 'Order processing failed',
    };
  }
}

enum PaymentStatus {
  pending,
  processing,
  success,
  failed,
  refunded;

  String get displayName {
    return switch (this) {
      PaymentStatus.pending => 'Pending',
      PaymentStatus.processing => 'Processing',
      PaymentStatus.success => 'Success',
      PaymentStatus.failed => 'Failed',
      PaymentStatus.refunded => 'Refunded',
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final String size;
  final double price;
  final int quantity;
  final double savings;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.name,
    required this.size,
    required this.price,
    required this.quantity,
    required this.savings,
    this.imageUrl,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'size': size,
        'price': price,
        'quantity': quantity,
        'savings': savings,
        'imageUrl': imageUrl,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        size: json['size'] as String,
        price: json['price'] as double,
        quantity: json['quantity'] as int,
        savings: json['savings'] as double,
        imageUrl: json['imageUrl'] as String?,
      );
}

class DeliveryAddress {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String? landmark;
  final bool isDefault;

  DeliveryAddress({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.landmark,
    this.isDefault = false,
  });

  String get fullAddress => '$street, $landmark, $city, $state $zipCode'
      .replaceAll('null, ', '')
      .replaceAll(', null', '');

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'landmark': landmark,
        'isDefault': isDefault,
      };

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      DeliveryAddress(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        phoneNumber: json['phoneNumber'] as String,
        street: json['street'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        zipCode: json['zipCode'] as String,
        landmark: json['landmark'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class Order {
  final String id;
  final List<OrderItem> items;
  final DeliveryAddress address;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus orderStatus;
  final double subtotal;
  final double deliveryFee;
  final double totalSavings;
  final double total;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryAt;
  final DateTime? deliveredAt;
  final String? driverName;
  final String? driverPhone;
  final String? driverImage;
  final double? driverRating;
  final String? trackingNumber;

  Order({
    required this.id,
    required this.items,
    required this.address,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalSavings,
    required this.total,
    required this.createdAt,
    this.estimatedDeliveryAt,
    this.deliveredAt,
    this.driverName,
    this.driverPhone,
    this.driverImage,
    this.driverRating,
    this.trackingNumber,
  });

  bool get isPaid => paymentStatus == PaymentStatus.success;
  bool get isDelivered => orderStatus == OrderStatus.delivered;
  bool get isActive => !isDelivered && orderStatus != OrderStatus.cancelled;

  /// Create a copy with modified fields
  Order copyWith({
    String? id,
    List<OrderItem>? items,
    DeliveryAddress? address,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    OrderStatus? orderStatus,
    double? subtotal,
    double? deliveryFee,
    double? totalSavings,
    double? total,
    DateTime? createdAt,
    DateTime? estimatedDeliveryAt,
    DateTime? deliveredAt,
    String? driverName,
    String? driverPhone,
    String? driverImage,
    double? driverRating,
    String? trackingNumber,
  }) =>
      Order(
        id: id ?? this.id,
        items: items ?? this.items,
        address: address ?? this.address,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        orderStatus: orderStatus ?? this.orderStatus,
        subtotal: subtotal ?? this.subtotal,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        totalSavings: totalSavings ?? this.totalSavings,
        total: total ?? this.total,
        createdAt: createdAt ?? this.createdAt,
        estimatedDeliveryAt: estimatedDeliveryAt ?? this.estimatedDeliveryAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        driverName: driverName ?? this.driverName,
        driverPhone: driverPhone ?? this.driverPhone,
        driverImage: driverImage ?? this.driverImage,
        driverRating: driverRating ?? this.driverRating,
        trackingNumber: trackingNumber ?? this.trackingNumber,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((e) => e.toJson()).toList(),
        'address': address.toJson(),
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus.name,
        'orderStatus': orderStatus.name,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'totalSavings': totalSavings,
        'total': total,
        'createdAt': createdAt.toIso8601String(),
        'estimatedDeliveryAt': estimatedDeliveryAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'driverName': driverName,
        'driverPhone': driverPhone,
        'driverImage': driverImage,
        'driverRating': driverRating,
        'trackingNumber': trackingNumber,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) => (value as num?)?.toDouble() ?? 0;
    DateTime date(dynamic value) {
      if (value is DateTime) return value;
      try {
        return value.toDate() as DateTime;
      } catch (_) {
        return DateTime.tryParse(value?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final rawItems = json['items'] is List ? json['items'] as List : const [];
    final items = rawItems.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return OrderItem(
        productId: (item['productId'] ?? item['id'] ?? '').toString(),
        name: (item['name'] ?? item['productName'] ?? 'Product').toString(),
        size: (item['size'] ?? item['unit'] ?? '').toString(),
        price: number(item['price'] ?? item['unitPrice']),
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
        savings: number(item['savings']),
        imageUrl: (item['imageUrl'] ?? item['image'])?.toString(),
      );
    }).toList();
    final addressData = json['address'] is Map
        ? Map<String, dynamic>.from(json['address'] as Map)
        : json['shippingAddress'] is Map
            ? Map<String, dynamic>.from(json['shippingAddress'] as Map)
            : <String, dynamic>{};
    final rawPayment =
        (json['paymentStatus'] ?? 'pending').toString().toLowerCase();
    final payment = switch (rawPayment) {
      'paid' ||
      'completed' ||
      'successful' ||
      'success' =>
        PaymentStatus.success,
      'processing' => PaymentStatus.processing,
      'failed' => PaymentStatus.failed,
      'refunded' => PaymentStatus.refunded,
      _ => PaymentStatus.pending,
    };
    final rawStatus = (json['orderStatus'] ?? json['status'] ?? 'pending')
        .toString()
        .toLowerCase();
    final status = switch (rawStatus) {
      'paid' || 'confirmed' => OrderStatus.confirmed,
      'processing' => OrderStatus.processing,
      'shipped' || 'dispatched' => OrderStatus.dispatched,
      'out_for_delivery' || 'outfordelivery' => OrderStatus.outForDelivery,
      'delivered' => OrderStatus.delivered,
      'cancelled' || 'canceled' => OrderStatus.cancelled,
      'failed' => OrderStatus.failed,
      _ => OrderStatus.pending,
    };
    return Order(
      id: (json['id'] ?? '').toString(),
      items: items,
      address: DeliveryAddress(
        id: (addressData['id'] ?? '').toString(),
        fullName:
            (addressData['fullName'] ?? addressData['name'] ?? '').toString(),
        phoneNumber: (addressData['phoneNumber'] ?? addressData['phone'] ?? '')
            .toString(),
        street:
            (addressData['street'] ?? addressData['address'] ?? '').toString(),
        city: (addressData['city'] ?? '').toString(),
        state: (addressData['state'] ?? '').toString(),
        zipCode: (addressData['zipCode'] ?? addressData['postalCode'] ?? '')
            .toString(),
        landmark: addressData['landmark']?.toString(),
      ),
      paymentMethod: (json['paymentMethod'] ?? 'Not specified').toString(),
      paymentStatus: payment,
      orderStatus: status,
      subtotal: number(json['subtotal']),
      deliveryFee: number(json['deliveryFee'] ?? json['shippingFee']),
      totalSavings: number(json['totalSavings']),
      total: number(json['total'] ?? json['totalAmount']),
      createdAt: date(json['createdAt']),
      estimatedDeliveryAt: json['estimatedDeliveryAt'] == null
          ? null
          : date(json['estimatedDeliveryAt']),
      deliveredAt:
          json['deliveredAt'] == null ? null : date(json['deliveredAt']),
      driverName: json['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      driverImage: json['driverImage']?.toString(),
      driverRating: number(json['driverRating']),
      trackingNumber: json['trackingNumber']?.toString(),
    );
  }
}
