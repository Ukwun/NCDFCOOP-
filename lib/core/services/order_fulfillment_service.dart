import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum OrderStatus {
  draft,
  submitted,
  approved,
  processing,
  packed,
  shipped,
  delivered,
  cancelled,
  returned
}

enum FulfillmentStatus {
  pending,
  inProgress,
  packed,
  shipped,
  delivered,
  failed,
  returned
}

/// Service for handling order creation and fulfillment
class OrderFulfillmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ordersCollection = 'orders';
  static const String _fulfillmentsCollection = 'fulfillments';
  static const _uuid = Uuid();

  /// Create a new order
  Future<String> createOrder({
    required String buyerId,
    required List<OrderItem> items,
    required double totalAmount,
    required String shippingAddress,
    required String billingAddress,
    required String paymentMethodId,
    String? notes,
  }) async {
    try {
      final orderId = _uuid.v4();

      final order = {
        'orderId': orderId,
        'buyerId': buyerId,
        'items': items.map((item) => item.toMap()).toList(),
        'totalAmount': totalAmount,
        'subtotal': _calculateSubtotal(items),
        'tax': _calculateTax(items),
        'shippingCost': _calculateShipping(items),
        'shippingAddress': shippingAddress,
        'billingAddress': billingAddress,
        'paymentMethodId': paymentMethodId,
        'notes': notes,
        'status': OrderStatus.draft.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'submittedAt': null,
        'approvedAt': null,
        'shippedAt': null,
        'deliveredAt': null,
      };

      await _firestore.collection(_ordersCollection).doc(orderId).set(order);

      // Create initial fulfillment record
      await _createFulfillmentRecord(orderId, items);

      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Submit order for processing
  Future<void> submitOrder(String orderId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': OrderStatus.submitted.toString().split('.').last,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit order: $e');
    }
  }

  /// Approve order for fulfillment
  Future<void> approveOrder(String orderId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': OrderStatus.approved.toString().split('.').last,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update fulfillment status
      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .collection(_fulfillmentsCollection)
          .doc(orderId)
          .update({
        'status': FulfillmentStatus.pending.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to approve order: $e');
    }
  }

  /// Start fulfillment processing
  Future<void> startFulfillment(String orderId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': OrderStatus.processing.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .collection(_fulfillmentsCollection)
          .doc(orderId)
          .update({
        'status': FulfillmentStatus.inProgress.toString().split('.').last,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to start fulfillment: $e');
    }
  }

  /// Mark items as packed
  Future<void> markItemsPacked({
    required String orderId,
    required List<String> itemIds,
  }) async {
    try {
      final fulfillmentDoc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .collection(_fulfillmentsCollection)
          .doc(orderId)
          .get();

      final fulfillmentData = fulfillmentDoc.data() as Map<String, dynamic>;
      final items = fulfillmentData['items'] as List<dynamic>;

      // Update packed status for specified items
      for (int i = 0; i < items.length; i++) {
        if (itemIds.contains(items[i]['itemId'])) {
          items[i]['packedAt'] = FieldValue.serverTimestamp();
          items[i]['status'] =
              FulfillmentStatus.packed.toString().split('.').last;
        }
      }

      // Check if all items are packed
      final allPacked = items.every((item) =>
          item['status'] ==
          FulfillmentStatus.packed.toString().split('.').last);

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .collection(_fulfillmentsCollection)
          .doc(orderId)
          .update({
        'items': items,
        'status': allPacked
            ? FulfillmentStatus.packed.toString().split('.').last
            : FulfillmentStatus.inProgress.toString().split('.').last,
        'packedAt': allPacked ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (allPacked) {
        await _firestore.collection(_ordersCollection).doc(orderId).update({
          'status': OrderStatus.packed.toString().split('.').last,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to mark items packed: $e');
    }
  }

  /// Ship order
  Future<String> shipOrder({
    required String orderId,
    required String carrier,
    required String trackingNumber,
    required String estimatedDelivery,
  }) async {
    try {
      final shippingId = _uuid.v4();

      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': OrderStatus.shipped.toString().split('.').last,
        'shippedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .collection(_fulfillmentsCollection)
          .doc(orderId)
          .update({
        'status': FulfillmentStatus.shipped.toString().split('.').last,
        'carrier': carrier,
        'trackingNumber': trackingNumber,
        'estimatedDelivery': estimatedDelivery,
        'shippingId': shippingId,
        'shippedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return shippingId;
    } catch (e) {
      throw Exception('Failed to ship order: $e');
    }
  }

  /// Mark order as delivered
  Future<void> markDelivered(String orderId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': OrderStatus.delivered.toString().split('.').last,
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .collection(_fulfillmentsCollection)
          .doc(orderId)
          .update({
        'status': FulfillmentStatus.delivered.toString().split('.').last,
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark order delivered: $e');
    }
  }

  /// Cancel order
  Future<void> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': OrderStatus.cancelled.toString().split('.').last,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// Get order details
  Future<OrderData?> getOrder(String orderId) async {
    try {
      final doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!doc.exists) return null;

      return OrderData.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Get user orders with filtering
  Future<List<OrderData>> getUserOrders({
    required String buyerId,
    OrderStatus? status,
    int limit = 50,
    DateTime? startDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_ordersCollection)
          .where('buyerId', isEqualTo: buyerId);

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThan: startDate);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs.map((doc) => OrderData.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user orders: $e');
    }
  }

  /// Create fulfillment record for order
  Future<void> _createFulfillmentRecord(
      String orderId, List<OrderItem> items) async {
    try {
      final fulfillment = {
        'orderId': orderId,
        'status': FulfillmentStatus.pending.toString().split('.').last,
        'items': items
            .map((item) => {
                  'itemId': item.id,
                  'productId': item.productId,
                  'quantity': item.quantity,
                  'status':
                      FulfillmentStatus.pending.toString().split('.').last,
                  'packedAt': null,
                })
            .toList(),
        'carrier': null,
        'trackingNumber': null,
        'shippingId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .collection(_fulfillmentsCollection)
          .doc(orderId)
          .set(fulfillment);
    } catch (e) {
      throw Exception('Failed to create fulfillment record: $e');
    }
  }

  double _calculateSubtotal(List<OrderItem> items) {
    return items.fold(0.0, (prev, item) => prev + (item.price * item.quantity));
  }

  double _calculateTax(List<OrderItem> items) {
    final subtotal = _calculateSubtotal(items);
    return subtotal * 0.08; // 8% tax
  }

  double _calculateShipping(List<OrderItem> items) {
    if (_calculateSubtotal(items) > 5000) {
      return 0.0; // Free shipping for large orders
    }
    return 25.0; // Flat $25 shipping
  }
}

/// Order item model
class OrderItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String sku;

  OrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.sku,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'sku': sku,
        'subtotal': price * quantity,
      };
}

/// Order data model
class OrderData {
  final String orderId;
  final String buyerId;
  final List<OrderItem> items;
  final double totalAmount;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final String shippingAddress;
  final String billingAddress;
  final String paymentMethodId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? notes;

  OrderData({
    required this.orderId,
    required this.buyerId,
    required this.items,
    required this.totalAmount,
    required this.subtotal,
    required this.tax,
    required this.shippingCost,
    required this.shippingAddress,
    required this.billingAddress,
    required this.paymentMethodId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.approvedAt,
    this.shippedAt,
    this.deliveredAt,
    this.notes,
  });

  factory OrderData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsData = data['items'] as List<dynamic>? ?? [];

    return OrderData(
      orderId: data['orderId'] as String,
      buyerId: data['buyerId'] as String,
      items: itemsData
          .map((item) => OrderItem(
                id: item['id'] as String,
                productId: item['productId'] as String,
                name: item['name'] as String,
                price: (item['price'] as num).toDouble(),
                quantity: item['quantity'] as int,
                sku: item['sku'] as String,
              ))
          .toList(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      subtotal: (data['subtotal'] as num).toDouble(),
      tax: (data['tax'] as num).toDouble(),
      shippingCost: (data['shippingCost'] as num).toDouble(),
      shippingAddress: data['shippingAddress'] as String,
      billingAddress: data['billingAddress'] as String,
      paymentMethodId: data['paymentMethodId'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as Timestamp).toDate()
          : null,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      shippedAt: data['shippedAt'] != null
          ? (data['shippedAt'] as Timestamp).toDate()
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'] as String?,
    );
  }
}
