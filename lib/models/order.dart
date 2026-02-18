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

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        items: (json['items'] as List)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        address:
            DeliveryAddress.fromJson(json['address'] as Map<String, dynamic>),
        paymentMethod: json['paymentMethod'] as String,
        paymentStatus:
            PaymentStatus.values.byName(json['paymentStatus'] as String),
        orderStatus: OrderStatus.values.byName(json['orderStatus'] as String),
        subtotal: json['subtotal'] as double,
        deliveryFee: json['deliveryFee'] as double,
        totalSavings: json['totalSavings'] as double,
        total: json['total'] as double,
        createdAt: DateTime.parse(json['createdAt'] as String),
        estimatedDeliveryAt: json['estimatedDeliveryAt'] != null
            ? DateTime.parse(json['estimatedDeliveryAt'] as String)
            : null,
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.parse(json['deliveredAt'] as String)
            : null,
        driverName: json['driverName'] as String?,
        driverPhone: json['driverPhone'] as String?,
        driverImage: json['driverImage'] as String?,
        driverRating: json['driverRating'] as double?,
        trackingNumber: json['trackingNumber'] as String?,
      );
}
