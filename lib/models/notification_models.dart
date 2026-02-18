import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of notifications in the system
enum NotificationType {
  order, // Order placed, ready, shipped, delivered
  payment, // Payment received, failed, refund
  inventory, // Stock update, low stock alert
  promotion, // Special offers, discounts
  account, // Profile updates, security alerts
  system, // System maintenance, announcements
  b2b, // PO approval, invoice, contract updates
  franchise, // Store performance, compliance alerts, sales reports
  driver, // Route assigned, delivery updates, earnings
}

/// Priority levels for notifications
enum NotificationPriority {
  low, // Can be bundled
  normal, // Standard notification
  high, // Immediate delivery
  urgent, // Time-sensitive, immediate delivery
}

/// Notification status
enum NotificationStatus {
  unread, // New, not yet seen
  read, // User has seen it
  archived, // User archived it
  deleted, // Soft deleted
}

/// Base notification model
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data; // Extra data (orderId, etc)
  final String? imageUrl;
  final bool isFcmEnabled; // Was this sent via FCM?

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.readAt,
    this.data,
    this.imageUrl,
    this.isFcmEnabled = true,
  });

  /// Mark notification as read
  AppNotification copyWithRead() {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      priority: priority,
      status: NotificationStatus.read,
      createdAt: createdAt,
      readAt: DateTime.now(),
      data: data,
      imageUrl: imageUrl,
      isFcmEnabled: isFcmEnabled,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
      'imageUrl': imageUrl,
      'isFcmEnabled': isFcmEnabled,
    };
  }

  /// Create from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppNotification(
      id: data['id'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: _parseNotificationType(data['type'] as String?),
      priority: _parseNotificationPriority(data['priority'] as String?),
      status: _parseNotificationStatus(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      data: data['data'] as Map<String, dynamic>?,
      imageUrl: data['imageUrl'] as String?,
      isFcmEnabled: data['isFcmEnabled'] as bool? ?? true,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'order':
        return NotificationType.order;
      case 'payment':
        return NotificationType.payment;
      case 'inventory':
        return NotificationType.inventory;
      case 'promotion':
        return NotificationType.promotion;
      case 'account':
        return NotificationType.account;
      case 'system':
        return NotificationType.system;
      case 'b2b':
        return NotificationType.b2b;
      case 'franchise':
        return NotificationType.franchise;
      case 'driver':
        return NotificationType.driver;
      default:
        return NotificationType.system;
    }
  }

  static NotificationPriority _parseNotificationPriority(String? priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  static NotificationStatus _parseNotificationStatus(String? status) {
    switch (status) {
      case 'unread':
        return NotificationStatus.unread;
      case 'read':
        return NotificationStatus.read;
      case 'archived':
        return NotificationStatus.archived;
      case 'deleted':
        return NotificationStatus.deleted;
      default:
        return NotificationStatus.unread;
    }
  }
}

/// Order notification (tracks order lifecycle)
class OrderNotification extends AppNotification {
  final String orderId;
  final String
      orderStatus; // pending, confirmed, picking, packed, qc, shipped, delivered
  final DateTime? estimatedDeliveryDate;
  final String? trackingNumber;
  final double? totalAmount;

  OrderNotification({
    required super.id,
    required super.userId,
    required super.title,
    required super.message,
    required this.orderId,
    required this.orderStatus,
    this.estimatedDeliveryDate,
    this.trackingNumber,
    this.totalAmount,
    super.priority,
    super.imageUrl,
  }) : super(
          type: NotificationType.order,
          createdAt: DateTime.now(),
          data: {
            'orderId': orderId,
            'orderStatus': orderStatus,
            'trackingNumber': trackingNumber,
          },
        );

  @override
  Map<String, dynamic> toFirestore() {
    final base = super.toFirestore();
    return {
      ...base,
      'orderId': orderId,
      'orderStatus': orderStatus,
      'estimatedDeliveryDate': estimatedDeliveryDate != null
          ? Timestamp.fromDate(estimatedDeliveryDate!)
          : null,
      'trackingNumber': trackingNumber,
      'totalAmount': totalAmount,
    };
  }

  factory OrderNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final base = AppNotification.fromFirestore(doc);

    return OrderNotification(
      id: base.id,
      userId: base.userId,
      title: base.title,
      message: base.message,
      orderId: data['orderId'] as String? ?? '',
      orderStatus: data['orderStatus'] as String? ?? 'pending',
      estimatedDeliveryDate:
          (data['estimatedDeliveryDate'] as Timestamp?)?.toDate(),
      trackingNumber: data['trackingNumber'] as String?,
      totalAmount: (data['totalAmount'] as num?)?.toDouble(),
      priority: base.priority,
      imageUrl: base.imageUrl,
    );
  }
}

/// Payment notification
class PaymentNotification extends AppNotification {
  final String orderId;
  final String paymentStatus; // pending, completed, failed, refunded
  final double amount;
  final String? transactionId;
  final String paymentMethod; // card, mobile_money, bank_transfer

  PaymentNotification({
    required super.id,
    required super.userId,
    required super.title,
    required super.message,
    required this.orderId,
    required this.paymentStatus,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    super.priority = NotificationPriority.high,
  }) : super(
          type: NotificationType.payment,
          createdAt: DateTime.now(),
          data: {
            'orderId': orderId,
            'paymentStatus': paymentStatus,
            'transactionId': transactionId,
          },
        );

  @override
  Map<String, dynamic> toFirestore() {
    final base = super.toFirestore();
    return {
      ...base,
      'orderId': orderId,
      'paymentStatus': paymentStatus,
      'amount': amount,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
    };
  }
}

/// B2B notification (PO, contracts, invoices)
class B2BNotification extends AppNotification {
  final String? purchaseOrderId;
  final String? contractId;
  final String? invoiceId;
  final String
      actionType; // po_created, po_approved, invoice_ready, payment_due
  final String? requiredAction; // approval_needed, payment_required

  B2BNotification({
    required super.id,
    required super.userId,
    required super.title,
    required super.message,
    required this.actionType,
    this.purchaseOrderId,
    this.contractId,
    this.invoiceId,
    this.requiredAction,
    super.priority = NotificationPriority.high,
  }) : super(
          type: NotificationType.b2b,
          createdAt: DateTime.now(),
          data: {
            'purchaseOrderId': purchaseOrderId,
            'contractId': contractId,
            'invoiceId': invoiceId,
            'actionType': actionType,
            'requiredAction': requiredAction,
          },
        );

  @override
  Map<String, dynamic> toFirestore() {
    final base = super.toFirestore();
    return {
      ...base,
      'purchaseOrderId': purchaseOrderId,
      'contractId': contractId,
      'invoiceId': invoiceId,
      'actionType': actionType,
      'requiredAction': requiredAction,
    };
  }
}

/// Franchise notification (sales, compliance, inventory)
class FranchiseNotification extends AppNotification {
  final String storeId;
  final String
      alertType; // sales_report, compliance_due, low_inventory, performance_alert
  final Map<String, dynamic>? metrics; // sales data, compliance score, etc

  FranchiseNotification({
    required super.id,
    required super.userId,
    required super.title,
    required super.message,
    required this.storeId,
    required this.alertType,
    this.metrics,
    super.priority,
  }) : super(
          type: NotificationType.franchise,
          createdAt: DateTime.now(),
          data: {
            'storeId': storeId,
            'alertType': alertType,
            'metrics': metrics,
          },
        );

  @override
  Map<String, dynamic> toFirestore() {
    final base = super.toFirestore();
    return {
      ...base,
      'storeId': storeId,
      'alertType': alertType,
      'metrics': metrics,
    };
  }
}

/// Driver notification (route, delivery, earnings)
class DriverNotification extends AppNotification {
  final String driverId;
  final String
      notificationType; // route_assigned, delivery_completed, earnings_available
  final String? routeId;
  final String? deliveryId;
  final double? earnedAmount;

  DriverNotification({
    required super.id,
    required super.userId,
    required super.title,
    required super.message,
    required this.driverId,
    required this.notificationType,
    this.routeId,
    this.deliveryId,
    this.earnedAmount,
    super.priority = NotificationPriority.high,
  }) : super(
          type: NotificationType.driver,
          createdAt: DateTime.now(),
          data: {
            'driverId': driverId,
            'notificationType': notificationType,
            'routeId': routeId,
            'deliveryId': deliveryId,
          },
        );

  @override
  Map<String, dynamic> toFirestore() {
    final base = super.toFirestore();
    return {
      ...base,
      'driverId': driverId,
      'notificationType': notificationType,
      'routeId': routeId,
      'deliveryId': deliveryId,
      'earnedAmount': earnedAmount,
    };
  }
}

/// Notification preferences (do not disturb, channels, etc)
class NotificationPreferences {
  final String userId;
  final bool pushNotificationsEnabled;
  final bool inAppNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool smsNotificationsEnabled;
  final Set<NotificationType> enabledTypes;
  final Map<String, TimeRange> quietHours; // 'start' and 'end' times
  final bool showPreviewContent; // Show content in notification preview

  NotificationPreferences({
    required this.userId,
    this.pushNotificationsEnabled = true,
    this.inAppNotificationsEnabled = true,
    this.emailNotificationsEnabled = false,
    this.smsNotificationsEnabled = false,
    this.enabledTypes = const {
      NotificationType.order,
      NotificationType.payment,
      NotificationType.promotion,
      NotificationType.account,
    },
    this.quietHours = const {},
    this.showPreviewContent = true,
  });

  /// Check if user wants notifications for this type
  bool isTypeEnabled(NotificationType type) {
    return enabledTypes.contains(type);
  }

  /// Check if currently in quiet hours
  bool isInQuietHours() {
    final now = DateTime.now();
    final quiet = quietHours['start'];

    if (quiet == null) return false;

    final startTime =
        DateTime(now.year, now.month, now.day, quiet.hour, quiet.minute);
    final endTime = DateTime(
        now.year, now.month, now.day, (quiet.hour + 2) % 24, quiet.minute);

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'inAppNotificationsEnabled': inAppNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'smsNotificationsEnabled': smsNotificationsEnabled,
      'enabledTypes':
          enabledTypes.map((t) => t.toString().split('.').last).toList(),
      'showPreviewContent': showPreviewContent,
    };
  }

  factory NotificationPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final enabledTypesStr =
        (data['enabledTypes'] as List?)?.cast<String>() ?? [];

    return NotificationPreferences(
      userId: data['userId'] as String? ?? '',
      pushNotificationsEnabled:
          data['pushNotificationsEnabled'] as bool? ?? true,
      inAppNotificationsEnabled:
          data['inAppNotificationsEnabled'] as bool? ?? true,
      emailNotificationsEnabled:
          data['emailNotificationsEnabled'] as bool? ?? false,
      smsNotificationsEnabled:
          data['smsNotificationsEnabled'] as bool? ?? false,
      enabledTypes: enabledTypesStr.map(_parseNotificationType).toSet(),
      showPreviewContent: data['showPreviewContent'] as bool? ?? true,
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'order':
        return NotificationType.order;
      case 'payment':
        return NotificationType.payment;
      case 'inventory':
        return NotificationType.inventory;
      case 'promotion':
        return NotificationType.promotion;
      case 'account':
        return NotificationType.account;
      case 'system':
        return NotificationType.system;
      case 'b2b':
        return NotificationType.b2b;
      case 'franchise':
        return NotificationType.franchise;
      case 'driver':
        return NotificationType.driver;
      default:
        return NotificationType.system;
    }
  }
}

/// Time range for quiet hours
class TimeRange {
  final int hour;
  final int minute;

  TimeRange(this.hour, this.minute);
}

/// Order tracking event (for real-time tracking)
class OrderTrackingEvent {
  final String orderId;
  final String
      eventType; // placed, confirmed, picking, packed, qc_check, qc_passed, shipped, in_transit, out_for_delivery, delivered
  final String description;
  final DateTime timestamp;
  final LatLng? location;
  final String? estimatedNextUpdate;

  OrderTrackingEvent({
    required this.orderId,
    required this.eventType,
    required this.description,
    required this.timestamp,
    this.location,
    this.estimatedNextUpdate,
  });

  /// Get user-friendly event label
  String getEventLabel() {
    switch (eventType) {
      case 'placed':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'picking':
        return 'Picking Items';
      case 'packed':
        return 'Order Packed';
      case 'qc_check':
        return 'Quality Check';
      case 'qc_passed':
        return 'QC Passed';
      case 'shipped':
        return 'Shipped';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return eventType;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'eventType': eventType,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location?.toMap(),
      'estimatedNextUpdate': estimatedNextUpdate,
    };
  }

  factory OrderTrackingEvent.fromMap(Map<String, dynamic> map) {
    return OrderTrackingEvent(
      orderId: map['orderId'] as String,
      eventType: map['eventType'] as String,
      description: map['description'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      location:
          map['location'] != null ? LatLng.fromMap(map['location']) : null,
      estimatedNextUpdate: map['estimatedNextUpdate'] as String?,
    );
  }
}

/// Simple LatLng model (reuse from driver_service if needed)
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  factory LatLng.fromMap(Map<String, dynamic> map) {
    return LatLng(
      map['latitude'] as double,
      map['longitude'] as double,
    );
  }
}

/// Notification stats summary
class NotificationStats {
  final int unreadCount;
  final int todayCount;
  final int weekCount;
  final Map<NotificationType, int> countByType;
  final DateTime lastReadAt;

  NotificationStats({
    required this.unreadCount,
    required this.todayCount,
    required this.weekCount,
    required this.countByType,
    required this.lastReadAt,
  });

  /// Has unread notifications
  bool get hasUnread => unreadCount > 0;

  /// Get count for specific type
  int getCountForType(NotificationType type) {
    return countByType[type] ?? 0;
  }
}
