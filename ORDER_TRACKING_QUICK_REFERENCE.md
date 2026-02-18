# Order Tracking Quick Reference

## 🎯 Feature Status
**Order Tracking: 20% → 60% Complete**  
Core Integration Done ✅ | Mapping & Testing Pending ⏳

---

## 📱 Screen Overview

### 1. Order Confirmation Screen
**Path:** `lib/features/checkout/order_confirmation_screen.dart`

```dart
// Usage (from checkout/payment flow)
context.pushNamed('order-confirmation', pathParameters: {
  'orderId': orderId,
});
```

**Displays:**
- ✓ Animated checkmark confirmation
- ✓ Order number & details
- ✓ Items purchased with pricing
- ✓ Delivery address
- ✓ Payment summary
- ✓ "Track Order" button

### 2. Order Tracking Screen
**Path:** `lib/features/checkout/order_tracking_screen.dart`

```dart
// Usage
context.pushNamed('order-tracking', pathParameters: {
  'orderId': orderId,
});
```

**Displays:**
- ✓ Order header (ID, status badge, tracking #)
- ✓ Status timeline with checkmarks
- ✓ Driver info (name, rating, phone, photo)
- ✓ Delivery address
- ✓ Order items
- ✓ Map placeholder (for real implementation)

### 3. Order History Screen
**Path:** `lib/features/profile/orders_screen.dart`

```dart
// Automatic (part of navigation)
```

**Displays:**
- ✓ List of user's orders
- ✓ Status badges (color-coded)
- ✓ Order date, total, items summary
- ✓ "View Details" → navigates to tracking screen
- ✓ Pagination with "Load More" button

---

## 🔧 Provider Reference

### Getting Order Data

**Single Order:**
```dart
final orderAsync = ref.watch(orderDetailProvider('order-id'));

orderAsync.when(
  data: (order) => Text('Total: ₦${order.total}'),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

**Order History (Paginated):**
```dart
int currentPage = 1;
final ordersAsync = ref.watch(
  orderHistoryProvider((page: currentPage, pageSize: 10)),
);

ordersAsync.when(
  data: (orderPage) {
    // orderPage.orders: List<OrderData>
    // orderPage.totalCount: int
    // orderPage.totalPages: int
    // orderPage.page: int
  },
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

**Recent Orders (Quick Access):**
```dart
final recentAsync = ref.watch(recentOrdersProvider);

recentAsync.when(
  data: (orders) => Column(
    children: orders.map((order) => OrderCard(order)).toList(),
  ),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => SizedBox.shrink(),
);
```

**Active Orders Only:**
```dart
final activeAsync = ref.watch(activeOrdersProvider);

activeAsync.when(
  data: (orders) => ListView.builder(
    itemCount: orders.length,
    itemBuilder: (context, index) {
      return OrderTile(orders[index]);
    },
  ),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error loading active orders'),
);
```

**Real-time Order Updates (Firestore Stream):**
```dart
// For live updates (upgrades from Future to Stream)
final orderStreamAsync = ref.watch(orderStatusStreamProvider('order-id'));

orderStreamAsync.when(
  data: (order) => order != null 
    ? Text('Status: ${order.orderStatus.displayName}')
    : Text('Order not found'),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

### Status Checks

**Is Order Delivered?**
```dart
final isDeliveredAsync = ref.watch(isOrderDeliveredProvider('order-id'));

isDeliveredAsync.whenData((isDelivered) {
  if (isDelivered) {
    // Show "completed" UI
  }
});
```

**Is Order Active?**
```dart
final isActiveAsync = ref.watch(isOrderActiveProvider('order-id'));

isActiveAsync.whenData((isActive) {
  if (!isActive) {
    // Order is cancelled, failed, or delivered
  }
});
```

**Time Remaining:**
```dart
final timeAsync = ref.watch(deliveryTimeRemainingProvider('order-id'));

timeAsync.whenData((duration) {
  if (duration != null && duration.inHours > 0) {
    print('${duration.inHours} hours remaining');
  }
});
```

---

## 📦 OrderData Model Reference

### Core Properties
```dart
OrderData order = /* from provider */;

// Identification
order.id              // String: "order-123"
order.trackingNumber  // String?: "TRACK-456"

// Timestamps
order.createdAt           // DateTime
order.estimatedDeliveryAt // DateTime?
order.deliveredAt         // DateTime?

// Status
order.orderStatus     // OrderStatus enum
order.paymentStatus   // PaymentStatus enum

// Items
order.items           // List<OrderItem>
for (var item in order.items) {
  item.productId     // String
  item.name          // String
  item.quantity      // int
  item.price         // double
  item.savings       // double
  item.subtotal      // double (computed)
}

// Delivery
order.address               // DeliveryAddress
order.address.fullName      // String
order.address.phoneNumber   // String
order.address.street        // String
order.address.city          // String
order.address.zipCode       // String
order.address.fullAddress   // String (computed)

// Pricing
order.subtotal      // double
order.deliveryFee   // double
order.totalSavings  // double
order.total         // double

// Driver Info (after dispatched)
order.driverName    // String?
order.driverPhone   // String?
order.driverImage   // String?
order.driverRating  // double?
```

### OrderStatus Enum
```dart
enum OrderStatus {
  pending,           // Just placed, awaiting confirmation
  confirmed,         // Confirmed by system
  processing,        // Being prepared
  dispatched,        // Left warehouse, assigned to driver
  outForDelivery,    // Driver is delivering
  delivered,         // Delivered successfully
  cancelled,         // User cancelled
  failed,            // Delivery failed
}

// Usage:
order.orderStatus == OrderStatus.delivered
order.orderStatus.displayName   // "Delivered"
order.orderStatus.description   // "Your order has been delivered"
```

### PaymentStatus Enum
```dart
enum PaymentStatus {
  pending,           // Awaiting payment
  processing,        // Processing payment
  success,           // Payment successful
  failed,            // Payment failed
  refunded,          // Refund issued
}

// Usage:
if (order.paymentStatus == PaymentStatus.success) {
  // Order paid
}
```

---

## 🎨 UI Components

### Status Badge
```dart
// Color-coded status display
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: _getStatusColor(order.orderStatus).withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    order.orderStatus.displayName,
    style: TextStyle(
      color: _getStatusColor(order.orderStatus),
      fontWeight: FontWeight.w600,
    ),
  ),
);

// Helper method
Color _getStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.delivered:
      return Colors.green; // Primary
    case OrderStatus.outForDelivery:
    case OrderStatus.dispatched:
      return Colors.orange; // Accent
    case OrderStatus.cancelled:
    case OrderStatus.failed:
      return Colors.red;
    default:
      return Colors.grey;
  }
}
```

### Order Card
```dart
GestureDetector(
  onTap: () {
    context.pushNamed('order-tracking', pathParameters: {
      'orderId': order.id,
    });
  },
  child: Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id.substring(0, 8).toUpperCase()}'),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              Text(order.orderStatus.displayName),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          // Items
          ...order.items.map((item) => Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name),
                    Text('${item.quantity}x ₦${item.price}'),
                  ],
                ),
              ),
              Text('₦${item.subtotal}'),
            ],
          )),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:'),
              Text('₦${order.total}', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ),
  ),
);
```

---

## 🔄 Pagination Example

```dart
class OrdersScreenState extends ConsumerState {
  int currentPage = 1;
  final int pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(
      orderHistoryProvider((page: currentPage, pageSize: pageSize)),
    );

    return ordersAsync.when(
      data: (orderPage) {
        return Column(
          children: [
            // Order list
            ListView.builder(
              itemCount: orderPage.orders.length,
              itemBuilder: (context, index) {
                return OrderCard(orderPage.orders[index]);
              },
            ),
            // Load more button
            if (orderPage.totalPages > currentPage)
              ElevatedButton(
                onPressed: () {
                  setState(() => currentPage++);
                },
                child: Text('Load More'),
              ),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }
}
```

---

## 🚀 Common Tasks

### Navigate to Order Tracking
```dart
void openOrderTracking(String orderId) {
  context.pushNamed('order-tracking', pathParameters: {
    'orderId': orderId,
  });
}
```

### Format Order Date
```dart
String formatDate(DateTime date) {
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
```

### Check Delivery Status
```dart
bool isOrderDelivered(OrderData order) {
  return order.orderStatus == OrderStatus.delivered &&
         order.deliveredAt != null;
}

bool isOrderActive(OrderData order) {
  return order.orderStatus != OrderStatus.delivered &&
         order.orderStatus != OrderStatus.cancelled &&
         order.orderStatus != OrderStatus.failed;
}
```

### Show Driver Info
```dart
if (order.orderStatus.index >= OrderStatus.dispatched.index) {
  // Show driver details
  ShowDriverCard(
    name: order.driverName ?? 'Driver',
    phone: order.driverPhone,
    rating: order.driverRating,
    image: order.driverImage,
  );
}
```

---

## ⚠️ Common Pitfalls

### ❌ Don't
```dart
// ❌ Don't use old providers
final order = ref.watch(ordersProvider); // DEPRECATED

// ❌ Don't hardcode order data
Order order = Order(id: '123', ...);

// ❌ Don't forget pagination params
final orders = ref.watch(orderHistoryProvider()); // ERROR!

// ❌ Don't ignore error states
final order = ref.watch(orderDetailProvider('id')).data!; // CRASH!
```

### ✅ Do
```dart
// ✅ Use new order_providers
final order = ref.watch(orderDetailProvider('id'));

// ✅ Fetch real data from service
final orders = ref.watch(recentOrdersProvider);

// ✅ Always include pagination params
final orders = ref.watch(
  orderHistoryProvider((page: 1, pageSize: 10))
);

// ✅ Handle all states with .when()
final order = ref.watch(orderDetailProvider('id')).when(
  data: (order) => Text(order.total.toString()),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

---

## 📞 Troubleshooting

### "orderDetailProvider not found"
**Solution:** Ensure import exists:
```dart
import 'package:coop_commerce/core/providers/order_providers.dart';
```

### "OrderStatus doesn't have displayName"
**Solution:** Make sure using enum, not string:
```dart
// ✅ Correct
final name = order.orderStatus.displayName;

// ❌ Wrong
final name = order.status.displayName; // status is String!
```

### "Loading state never completes"
**Solution:** Check if service is returning data:
```dart
// Verify OrderManagementService is working
final service = OrderManagementService();
final order = await service.getOrderById('id');
print(order); // Should print OrderData, not null
```

### "Pagination resets when page changes"
**Solution:** Use proper state management:
```dart
// ✅ Store currentPage in State
class MyState extends ConsumerState {
  int currentPage = 1; // Maintain across rebuilds
  
  void loadMore() => setState(() => currentPage++);
}
```

---

**Last Updated:** 2024  
**Status:** ✅ Integration Complete - Ready for Testing
