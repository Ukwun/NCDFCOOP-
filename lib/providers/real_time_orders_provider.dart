import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:coop_commerce/models/order.dart';

/// Watch user's orders in real-time
final userOrdersStreamProvider =
    StreamProvider.family<List<Order>, String>((ref, userId) {
  if (userId.isEmpty) return const Stream.empty();

  final firestore = FirebaseFirestore.instance;
  final controller = StreamController<List<Order>>();
  final sources = <String, List<Order>>{};
  final subscriptions = <StreamSubscription<QuerySnapshot>>[];

  void emit() {
    final merged = <String, Order>{};
    for (final orders in sources.values) {
      for (final order in orders) {
        merged[order.id] = order;
      }
    }
    final result = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!controller.isClosed) controller.add(result);
  }

  void listen(String key, Query<Map<String, dynamic>> query) {
    subscriptions.add(query.snapshots().listen((snapshot) {
      sources[key] = snapshot.docs
          .map((doc) {
            final data = <String, dynamic>{...doc.data(), 'id': doc.id};
            try {
              return Order.fromJson(data);
            } catch (_) {
              return null;
            }
          })
          .whereType<Order>()
          .toList();
      emit();
    }, onError: (_) {
      sources[key] = const [];
      emit();
    }));
  }

  listen(
    'legacy',
    firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('createdAt', descending: true),
  );
  listen('userId',
      firestore.collection('orders').where('userId', isEqualTo: userId));
  listen('buyerId',
      firestore.collection('orders').where('buyerId', isEqualTo: userId));
  ref.onDispose(() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    controller.close();
  });
  return controller.stream;
});

/// Watch a specific order in real-time
final orderStreamProvider =
    StreamProvider.family<Order?, Map<String, String>>((ref, params) {
  final userId = params['userId'] ?? '';
  final orderId = params['orderId'] ?? '';

  if (userId.isEmpty || orderId.isEmpty) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;

    try {
      final data = snapshot.data()!;
      data['id'] = orderId;
      return Order.fromJson(data);
    } catch (e) {
      print('Error parsing order: $e');
      return null;
    }
  });
});

/// Watch order status in real-time (lighter weight than full order)
final orderStatusStreamProvider =
    StreamProvider.family<OrderStatus?, Map<String, String>>((ref, params) {
  final userId = params['userId'] ?? '';
  final orderId = params['orderId'] ?? '';

  if (userId.isEmpty || orderId.isEmpty) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;

    try {
      final data = snapshot.data()!;
      final statusStr = data['orderStatus'] as String?;
      if (statusStr == null) return null;

      return OrderStatus.values.firstWhere(
        (status) => status.name == statusStr,
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      print('Error parsing order status: $e');
      return null;
    }
  });
});

/// Watch payment status in real-time
final paymentStatusStreamProvider =
    StreamProvider.family<PaymentStatus?, Map<String, String>>((ref, params) {
  final userId = params['userId'] ?? '';
  final orderId = params['orderId'] ?? '';

  if (userId.isEmpty || orderId.isEmpty) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;

    try {
      final data = snapshot.data()!;
      final statusStr = data['paymentStatus'] as String?;
      if (statusStr == null) return null;

      return PaymentStatus.values.firstWhere(
        (status) => status.name == statusStr,
        orElse: () => PaymentStatus.pending,
      );
    } catch (e) {
      print('Error parsing payment status: $e');
      return null;
    }
  });
});

/// Watch pending orders waiting for payment (real-time)
final pendingOrdersStreamProvider =
    StreamProvider.family<List<Order>, String>((ref, userId) {
  if (userId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('orders')
      .where('paymentStatus', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            return Order.fromJson(data);
          } catch (e) {
            print('Error parsing order: $e');
            return null;
          }
        })
        .whereType<Order>()
        .toList();
  });
});

/// Watch confirmed/paid orders (real-time)
final confirmedOrdersStreamProvider =
    StreamProvider.family<List<Order>, String>((ref, userId) {
  if (userId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('orders')
      .where('paymentStatus', isEqualTo: 'paid')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            return Order.fromJson(data);
          } catch (e) {
            print('Error parsing order: $e');
            return null;
          }
        })
        .whereType<Order>()
        .toList();
  });
});

/// Update order payment status
Future<void> updateOrderPaymentStatus(
  String userId,
  String orderId,
  PaymentStatus status,
) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('orders')
      .doc(orderId)
      .update({
    'paymentStatus': status.name,
    'paidAt': DateTime.now().toIso8601String(),
  });
}

/// Update order status
Future<void> updateOrderStatus(
  String userId,
  String orderId,
  OrderStatus status,
) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('orders')
      .doc(orderId)
      .update({
    'orderStatus': status.name,
  });
}
