import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final String status;
  final List<OrderItem> items;
  final double subtotal;
  final double taxAmount;
  final double shippingCost;
  final double total;
  final String shippingAddress;
  final String shippingCity;
  final String shippingState;
  final String shippingZip;
  final String paymentMethod;
  final String paymentStatus;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.shippingCost,
    required this.total,
    required this.shippingAddress,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingZip,
    required this.paymentMethod,
    required this.paymentStatus,
    this.trackingNumber,
    required this.createdAt,
    this.deliveredAt,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'pending',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      shippingCost: (data['shippingCost'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      shippingAddress: data['shippingAddress'] ?? '',
      shippingCity: data['shippingCity'] ?? '',
      shippingState: data['shippingState'] ?? '',
      shippingZip: data['shippingZip'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      trackingNumber: data['trackingNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'shippingCost': shippingCost,
      'total': total,
      'shippingAddress': shippingAddress,
      'shippingCity': shippingCity,
      'shippingState': shippingState,
      'shippingZip': shippingZip,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'trackingNumber': trackingNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? status,
    List<OrderItem>? items,
    double? subtotal,
    double? taxAmount,
    double? shippingCost,
    double? total,
    String? shippingAddress,
    String? shippingCity,
    String? shippingState,
    String? shippingZip,
    String? paymentMethod,
    String? paymentStatus,
    String? trackingNumber,
    DateTime? createdAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingState: shippingState ?? this.shippingState,
      shippingZip: shippingZip ?? this.shippingZip,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isShipped => status.toLowerCase() == 'shipped';
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}
