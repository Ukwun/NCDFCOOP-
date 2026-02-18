import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import 'cart_provider.dart';

class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
  }) =>
      OrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class OrdersNotifier extends Notifier<OrdersState> {
  @override
  OrdersState build() => const OrdersState();

  void addOrder(Order order) {
    state = state.copyWith(orders: [order, ...state.orders]);
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final updatedOrders = state.orders.map((order) {
      if (order.id == orderId) {
        return order.copyWith(
          orderStatus: status,
          deliveredAt: status == OrderStatus.delivered ? DateTime.now() : null,
        );
      }
      return order;
    }).toList();

    state = state.copyWith(orders: updatedOrders);
  }

  void updatePaymentStatus(String orderId, PaymentStatus status) {
    final updatedOrders = state.orders.map((order) {
      if (order.id == orderId) {
        return order.copyWith(paymentStatus: status);
      }
      return order;
    }).toList();

    state = state.copyWith(orders: updatedOrders);
  }

  Order createOrderFromCart(
    DeliveryAddress address,
    String paymentMethod,
  ) {
    final cart = ref.read(cartProvider);

    const uuid = Uuid();
    final orderId = uuid.v4();

    final order = Order(
      id: orderId,
      items: cart.items
          .map((item) => OrderItem(
                productId: item.productId,
                name: item.productName,
                size: '', // Empty size, can be added to CartItem if needed
                price: item.memberPrice,
                quantity: item.quantity,
                savings: item.totalSavings,
                imageUrl: item.imageUrl,
              ))
          .toList(),
      address: address,
      paymentMethod: paymentMethod,
      paymentStatus: PaymentStatus.pending,
      orderStatus: OrderStatus.pending,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      totalSavings: cart.totalSavings,
      total: cart.totalPrice,
      createdAt: DateTime.now(),
      estimatedDeliveryAt: DateTime.now().add(const Duration(days: 2)),
      trackingNumber: 'TRK-${uuid.v4().substring(0, 8).toUpperCase()}',
    );

    addOrder(order);
    return order;
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, OrdersState>(
  OrdersNotifier.new,
);

final orderByIdProvider = Provider.family<Order?, String>((ref, orderId) {
  final orders = ref.watch(ordersProvider);
  try {
    return orders.orders.firstWhere((order) => order.id == orderId);
  } catch (e) {
    return null;
  }
});

final orderHistoryProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider);
  return orders.orders;
});

final activeOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider);
  return orders.orders.where((order) => order.isActive).toList();
});

final completedOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider);
  return orders.orders.where((order) => order.isDelivered).toList();
});
