import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:coop_commerce/core/services/approval_service.dart';
import 'package:coop_commerce/core/services/order_fulfillment_service.dart';
import 'package:coop_commerce/core/services/payment_processing_service.dart';
import 'package:coop_commerce/core/services/order_management_api_service.dart';
import 'package:coop_commerce/core/services/fcm_service.dart';

// Service Providers

final approvalServiceProvider = Provider((ref) => ApprovalService());

final orderFulfillmentServiceProvider =
    Provider((ref) => OrderFulfillmentService());

final paymentProcessingServiceProvider =
    Provider((ref) => PaymentProcessingService());

final orderManagementServiceProvider =
    Provider((ref) => OrderManagementService());

// ===================== APPROVAL PROVIDERS =====================

/// Stream of pending approvals for current user
final pendingApprovalsProvider =
    StreamProvider.family<List<ApprovalRecord>, String>((ref, userId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('approvals')
      .where('approverIds', arrayContains: userId)
      .where('status', isEqualTo: 'pending')
      .orderBy('priority', descending: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ApprovalRecord.fromFirestore(doc))
          .toList());
});

/// Stream of approval history for a specific user
final approvalHistoryProvider =
    StreamProvider.family<List<ApprovalRecord>, String>((ref, userId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('approvals')
      .where('approverIds', arrayContains: userId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ApprovalRecord.fromFirestore(doc))
          .toList());
});

/// Stream of specific approval record
final approvalDetailProvider =
    StreamProvider.family<ApprovalRecord?, String>((ref, approvalId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('approvals')
      .doc(approvalId)
      .snapshots()
      .map((doc) => doc.exists ? ApprovalRecord.fromFirestore(doc) : null);
});

/// Count of pending approvals for user
final pendingApprovalsCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('approvals')
      .where('approverIds', arrayContains: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// ===================== ORDER PROVIDERS =====================

/// Stream of orders for current user
final userOrdersProvider =
    StreamProvider.family<List<OrderData>, String>((ref, buyerId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .where('buyerId', isEqualTo: buyerId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => OrderData.fromFirestore(doc)).toList());
});

/// Stream of specific order details
final orderDetailsProvider =
    StreamProvider.family<OrderData?, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((doc) => doc.exists ? OrderData.fromFirestore(doc) : null);
});

/// Stream of orders by status
final ordersByStatusProvider =
    StreamProvider.family<List<OrderData>, ({String buyerId, String status})>(
  (ref, params) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('orders')
        .where('buyerId', isEqualTo: params.buyerId)
        .where('status', isEqualTo: params.status)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderData.fromFirestore(doc)).toList());
  },
);

/// Stream of pending orders (not yet approved)
final pendingOrdersProvider =
    StreamProvider.family<List<OrderData>, String>((ref, buyerId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .where('buyerId', isEqualTo: buyerId)
      .where('status', whereIn: ['draft', 'submitted'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => OrderData.fromFirestore(doc)).toList());
});

/// Stream of in-transit orders (shipped but not delivered)
final inTransitOrdersProvider =
    StreamProvider.family<List<OrderData>, String>((ref, buyerId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .where('buyerId', isEqualTo: buyerId)
      .where('status', whereIn: ['shipped', 'processing', 'packed'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => OrderData.fromFirestore(doc)).toList());
});

/// Stream of delivered orders
final deliveredOrdersProvider =
    StreamProvider.family<List<OrderData>, String>((ref, buyerId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .where('buyerId', isEqualTo: buyerId)
      .where('status', isEqualTo: 'delivered')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => OrderData.fromFirestore(doc)).toList());
});

/// Count of active orders for user
final activeOrdersCountProvider =
    StreamProvider.family<int, String>((ref, buyerId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .where('buyerId', isEqualTo: buyerId)
      .where('status', whereIn: [
        'draft',
        'submitted',
        'approved',
        'processing',
        'packed',
        'shipped'
      ])
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Stream of fulfillment details for an order
final orderFulfillmentProvider =
    StreamProvider.family<List<OrderFulfillmentData>, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .doc(orderId)
      .collection('fulfillments')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => OrderFulfillmentData.fromFirestore(doc))
          .toList());
});

// ===================== PAYMENT PROVIDERS =====================

/// Stream of payments for a specific order
final orderPaymentsProvider =
    StreamProvider.family<List<PaymentData>, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('payments')
      .where('orderId', isEqualTo: orderId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => PaymentData.fromFirestore(doc)).toList());
});

/// Stream of payment details
final paymentDetailsProvider =
    StreamProvider.family<PaymentData?, String>((ref, paymentId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('payments')
      .doc(paymentId)
      .snapshots()
      .map((doc) => doc.exists ? PaymentData.fromFirestore(doc) : null);
});

/// Stream of user's payment history
final userPaymentHistoryProvider =
    StreamProvider.family<List<PaymentData>, String>((ref, buyerId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('payments')
      .where('buyerId', isEqualTo: buyerId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => PaymentData.fromFirestore(doc)).toList());
});

/// Stream of pending payments
final pendingPaymentsProvider =
    StreamProvider.family<List<PaymentData>, String>((ref, buyerId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('payments')
      .where('buyerId', isEqualTo: buyerId)
      .where('status', whereIn: ['pending', 'processing'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => PaymentData.fromFirestore(doc)).toList());
});

/// Stream of successful payments for an order
final successfulPaymentsProvider =
    StreamProvider.family<List<PaymentData>, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('payments')
      .where('orderId', isEqualTo: orderId)
      .where('status', isEqualTo: 'successful')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => PaymentData.fromFirestore(doc)).toList());
});

/// Stream of payment transactions for a specific payment
final paymentTransactionsProvider =
    StreamProvider.family<List<PaymentTransactionData>, String>(
        (ref, paymentId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('payments')
      .doc(paymentId)
      .collection('transactions')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PaymentTransactionData.fromFirestore(doc))
          .toList());
});

// ===================== AGGREGATION PROVIDERS =====================

/// Get order statistics for a date range
final orderStatisticsProvider = FutureProvider.family<OrderStatistics?,
    ({String? buyerId, DateTime dateFrom, DateTime dateTo})>(
  (ref, params) async {
    final orderManagementService = ref.watch(orderManagementServiceProvider);
    return orderManagementService.getOrderStatistics(
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      buyerId: params.buyerId,
    );
  },
);

/// Get top buyers for a date range
final topBuyersProvider = FutureProvider.family<List<BuyerStatistics>,
    ({DateTime dateFrom, DateTime dateTo, int limit})>(
  (ref, params) async {
    final orderManagementService = ref.watch(orderManagementServiceProvider);
    return orderManagementService.getTopBuyers(
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      limit: params.limit,
    );
  },
);

/// Get fulfillment status summary
final fulfillmentStatusSummaryProvider = FutureProvider.family<
    FulfillmentStatusSummary?, ({DateTime dateFrom, DateTime dateTo})>(
  (ref, params) async {
    final orderManagementService = ref.watch(orderManagementServiceProvider);
    return orderManagementService.getFulfillmentStatusSummary(
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
    );
  },
);

// ===================== NOTIFICATION PROVIDERS =====================

/// Notification when a new order is created
final newOrderNotificationProvider =
    StreamProvider.family<OrderData?, String>((ref, buyerId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .where('buyerId', isEqualTo: buyerId)
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty
          ? OrderData.fromFirestore(snapshot.docs.first)
          : null);
});

/// Notification when order status changes
final orderStatusChangeNotificationProvider = StreamProvider.family<
    ({OrderData order, String oldStatus, String newStatus})?,
    String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore.collection('orders').doc(orderId).snapshots().map((doc) {
    if (!doc.exists) return null;

    final orderData = OrderData.fromFirestore(doc);
    return (
      order: orderData,
      oldStatus: 'processing',
      newStatus: orderData.status
    );
  });
});

/// Notification when payment is completed
final paymentCompletionNotificationProvider =
    StreamProvider.family<PaymentData?, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('payments')
      .where('orderId', isEqualTo: orderId)
      .where('status', isEqualTo: 'successful')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty
          ? PaymentData.fromFirestore(snapshot.docs.first)
          : null);
});

// ===================== SEARCH & FILTER PROVIDERS =====================

/// Search orders by query
final searchOrdersProvider =
    FutureProvider.family<List<OrderData>, ({String query, int limit})>(
  (ref, params) async {
    final orderManagementService = ref.watch(orderManagementServiceProvider);
    return orderManagementService.searchOrders(
      query: params.query,
      limit: params.limit,
    );
  },
);

/// Get paginated orders with filters
final paginatedOrdersProvider = FutureProvider.family<OrderPage,
    ({String? buyerId, String? status, int page, int pageSize})>(
  (ref, params) async {
    final orderManagementService = ref.watch(orderManagementServiceProvider);
    return orderManagementService.getAllOrders(
      buyerId: params.buyerId,
      status: params.status,
      page: params.page,
      pageSize: params.pageSize,
    );
  },
);

// Data models for payments

class PaymentTransactionData {
  final String transactionId;
  final String status;
  final String? responseCode;
  final String? responseMessage;
  final DateTime timestamp;

  PaymentTransactionData({
    required this.transactionId,
    required this.status,
    this.responseCode,
    this.responseMessage,
    required this.timestamp,
  });

  factory PaymentTransactionData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentTransactionData(
      transactionId: data['transactionId'] as String,
      status: data['status'] as String,
      responseCode: data['responseCode'] as String?,
      responseMessage: data['responseMessage'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class OrderFulfillmentData {
  final String fulfillmentId;
  final String status;
  final List<Map<String, dynamic>> items;
  final String? carrier;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;

  OrderFulfillmentData({
    required this.fulfillmentId,
    required this.status,
    required this.items,
    this.carrier,
    this.trackingNumber,
    this.estimatedDelivery,
    this.deliveredAt,
  });

  factory OrderFulfillmentData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderFulfillmentData(
      fulfillmentId: doc.id,
      status: data['status'] as String,
      items: (data['items'] as List).cast<Map<String, dynamic>>(),
      carrier: data['carrier'] as String?,
      trackingNumber: data['trackingNumber'] as String?,
      estimatedDelivery: data['estimatedDelivery'] != null
          ? (data['estimatedDelivery'] as Timestamp).toDate()
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
    );
  }
}

// ===================== ORDER DETAIL PROVIDERS =====================

/// Get a single order by ID with real-time updates
final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderData, String>((ref, orderId) async {
  final service = ref.watch(orderManagementServiceProvider);

  try {
    return await service.getOrderById(orderId);
  } catch (e) {
    throw Exception('Failed to load order: $e');
  }
});

/// Get user's order history with pagination
final orderHistoryProvider = FutureProvider.autoDispose
    .family<OrderPage, ({int page, int pageSize})>((ref, params) async {
  final service = ref.watch(orderManagementServiceProvider);

  try {
    return await service.getAllOrders(
      page: params.page,
      pageSize: params.pageSize,
      ascending: false, // Most recent first
    );
  } catch (e) {
    throw Exception('Failed to load order history: $e');
  }
});

/// Get recent orders (last 5)
final recentOrdersProvider =
    FutureProvider.autoDispose<List<OrderData>>((ref) async {
  final service = ref.watch(orderManagementServiceProvider);

  try {
    final result = await service.getAllOrders(
      page: 1,
      pageSize: 5,
      ascending: false,
    );
    return result.orders;
  } catch (e) {
    throw Exception('Failed to load recent orders: $e');
  }
});

/// Get active orders (not delivered, not cancelled)
final activeOrdersProvider =
    FutureProvider.autoDispose<List<OrderData>>((ref) async {
  final service = ref.watch(orderManagementServiceProvider);

  try {
    final result = await service.getAllOrders(
      status: 'active',
      pageSize: 100,
      ascending: false,
    );
    return result.orders;
  } catch (e) {
    throw Exception('Failed to load active orders: $e');
  }
});

/// Stream of order status updates for real-time tracking
final orderStatusStreamProvider =
    StreamProvider.autoDispose.family<OrderData?, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return OrderData.fromFirestore(snapshot);
  });
});

/// Pagination notifier for order history
final orderHistoryPaginationProvider = Provider<OrderHistoryPaginationNotifier>(
  (ref) => OrderHistoryPaginationNotifier(),
);

// ===================== ORDER STATUS HELPERS =====================

/// Check if specific order is delivered
final isOrderDeliveredProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, orderId) async {
  final order = await ref.watch(orderDetailProvider(orderId).future);
  return order.status.toLowerCase() == 'delivered';
});

/// Check if specific order is active
final isOrderActiveProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, orderId) async {
  final order = await ref.watch(orderDetailProvider(orderId).future);
  final status = order.status.toLowerCase();
  return status != 'delivered' && status != 'cancelled' && status != 'failed';
});

/// Get remaining delivery time
final deliveryTimeRemainingProvider =
    FutureProvider.autoDispose.family<Duration?, String>((ref, orderId) async {
  final order = await ref.watch(orderDetailProvider(orderId).future);
  if (order.estimatedDeliveryAt == null) return null;

  final remaining = order.estimatedDeliveryAt!.difference(DateTime.now());
  return remaining.isNegative ? Duration.zero : remaining;
});

// ===================== PAGINATION SUPPORT =====================

class OrderHistoryPaginationNotifier {
  int currentPage = 1;
  final int pageSize = 10;

  void reset() => currentPage = 1;

  void nextPage() => currentPage++;

  void previousPage() {
    if (currentPage > 1) currentPage--;
  }

  bool canLoadMore(int totalCount) {
    return (currentPage * pageSize) < totalCount;
  }
}

// ===================== REAL-TIME NOTIFICATIONS =====================

/// Listen for order status changes and trigger notifications
final orderStatusNotificationProvider = StreamProvider.autoDispose
    .family<OrderStatusNotification?, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;

    final data = snapshot.data() as Map<String, dynamic>;
    final previousStatus = data['previousStatus'] as String?;
    final currentStatus = data['status'] as String;

    // Only emit if status changed
    if (previousStatus != null && previousStatus != currentStatus) {
      return OrderStatusNotification(
        orderId: orderId,
        previousStatus: previousStatus,
        currentStatus: currentStatus,
        timestamp: DateTime.now(),
        title: _getStatusNotificationTitle(currentStatus),
        message: _getStatusNotificationMessage(currentStatus),
      );
    }

    return null;
  }).where((notification) => notification != null);
});

/// Listen for delivery updates and estimated time changes
final deliveryUpdatesProvider =
    StreamProvider.autoDispose.family<DeliveryUpdate?, String>((ref, orderId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;

    final data = snapshot.data() as Map<String, dynamic>;
    final estimatedDelivery = data['estimatedDeliveryAt'] as Timestamp?;
    final driverName = data['driverName'] as String?;
    final driverPhone = data['driverPhone'] as String?;

    return DeliveryUpdate(
      orderId: orderId,
      estimatedDeliveryAt: estimatedDelivery?.toDate(),
      driverName: driverName,
      driverPhone: driverPhone,
      timestamp: DateTime.now(),
    );
  });
});

/// Stream of unread order notifications for current user
final unreadOrderNotificationsProvider = StreamProvider.autoDispose<int>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('notifications')
      .where('type', isEqualTo: 'order_status')
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// ===================== HELPER CLASSES =====================

class OrderStatusNotification {
  final String orderId;
  final String previousStatus;
  final String currentStatus;
  final DateTime timestamp;
  final String title;
  final String message;

  OrderStatusNotification({
    required this.orderId,
    required this.previousStatus,
    required this.currentStatus,
    required this.timestamp,
    required this.title,
    required this.message,
  });

  Map<String, dynamic> toFirestore() => {
        'orderId': orderId,
        'previousStatus': previousStatus,
        'currentStatus': currentStatus,
        'timestamp': Timestamp.fromDate(timestamp),
        'title': title,
        'message': message,
        'read': false,
      };
}

class DeliveryUpdate {
  final String orderId;
  final DateTime? estimatedDeliveryAt;
  final String? driverName;
  final String? driverPhone;
  final DateTime timestamp;

  DeliveryUpdate({
    required this.orderId,
    this.estimatedDeliveryAt,
    this.driverName,
    this.driverPhone,
    required this.timestamp,
  });
}

// ===================== NOTIFICATION TEXT HELPERS =====================

String _getStatusNotificationTitle(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return 'Order Confirmed ✓';
    case 'processing':
      return 'Order Processing';
    case 'dispatched':
      return 'Order Dispatched 🚚';
    case 'outfordelivery':
      return 'Out for Delivery';
    case 'delivered':
      return 'Order Delivered! 🎉';
    case 'cancelled':
      return 'Order Cancelled';
    case 'failed':
      return 'Delivery Failed';
    default:
      return 'Order Status Updated';
  }
}

String _getStatusNotificationMessage(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return 'Your order has been confirmed and is being prepared.';
    case 'processing':
      return 'We\'re preparing your order for dispatch.';
    case 'dispatched':
      return 'Your order is on the way! Check tracking details for updates.';
    case 'outfordelivery':
      return 'Your driver is nearby. Please be ready to receive your order.';
    case 'delivered':
      return 'Order delivered successfully! We hope you enjoy your purchase.';
    case 'cancelled':
      return 'Your order has been cancelled. Check your account for details.';
    case 'failed':
      return 'We couldn\'t deliver your order. Contact support for assistance.';
    default:
      return 'Your order status has been updated.';
  }
}

// ===================== FCM PUSH NOTIFICATION PROVIDERS =====================

/// FCM Service Provider
final fcmServiceProvider = Provider((ref) => FCMService());

/// Stream of incoming FCM messages
final fcmMessageStreamProvider = StreamProvider<RemoteMessage>((ref) {
  final firebaseMessaging = FirebaseMessaging.instance;

  return FirebaseMessaging.onMessage;
});

/// Stream of FCM tokens (refreshed when token changes)
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final fcmService = ref.watch(fcmServiceProvider);
  return fcmService.getToken();
});

/// Provider for parsing FCM order notifications
final fcmOrderNotificationProvider =
    FutureProvider.family<OrderStatusNotification?, RemoteMessage>(
        (ref, message) async {
  if (FCMService.isOrderNotification(message)) {
    return FCMService.parseOrderNotification(message);
  }
  return null;
});

/// Stream for order notifications from FCM messages
final fcmOrderNotificationsStreamProvider =
    StreamProvider<OrderStatusNotification?>((ref) async* {
  await for (final message in FirebaseMessaging.onMessage) {
    if (FCMService.isOrderNotification(message)) {
      final notification = FCMService.parseOrderNotification(message);
      if (notification != null) {
        yield notification;
      }
    }
  }
});

/// Stream for FCM message opened events (background -> foreground)
final fcmMessageOpenedStreamProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessageOpenedApp;
});
