import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/services/real_time_sync_service.dart';

// ===================== REAL-TIME SYNC SERVICE PROVIDER =====================

/// Centralized real-time sync service
final realTimeSyncServiceProvider = Provider<RealTimeSyncService>((ref) {
  return RealTimeSyncService();
});

// ===================== 1. INVENTORY SYNC =====================
// Warehouse updates → Franchise dashboard (live)

/// Real-time inventory updates for a specific franchise store
/// Emits whenever warehouse inventory levels change affecting this franchise's reorder needs
final franchiseInventorySyncProvider =
    StreamProvider.autoDispose.family<InventorySyncUpdate, String>(
  (ref, franchiseId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('franchise_inventory_sync')
        .where('franchiseId', isEqualTo: franchiseId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return InventorySyncUpdate(
          franchiseId: franchiseId,
          itemsLowOnStock: [],
          itemsOutOfStock: [],
          reorderSuggestions: [],
          lastUpdated: DateTime.now(),
        );
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      return InventorySyncUpdate(
        franchiseId: franchiseId,
        itemsLowOnStock: List<String>.from(data['itemsLowOnStock'] ?? []),
        itemsOutOfStock: List<String>.from(data['itemsOutOfStock'] ?? []),
        reorderSuggestions: List<String>.from(data['reorderSuggestions'] ?? []),
        lastUpdated:
            (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        syncStatus: data['syncStatus'] ?? 'synced',
      );
    });
  },
);

/// Count of items requiring immediate reorder for a franchise
final franchiseReorderCountProvider =
    StreamProvider.autoDispose.family<int, String>(
  (ref, franchiseId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('franchise_reorder_alerts')
        .where('franchiseId', isEqualTo: franchiseId)
        .where('urgency', isEqualTo: 'critical')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  },
);

// ===================== 2. PRICING UPDATES =====================
// Pricing rule changes → Shopping cart (live)

/// Real-time pricing updates for items in cart
/// Emits whenever pricing rules change (promotions, contract updates, etc.)
final cartPricingUpdatesProvider =
    StreamProvider.autoDispose.family<PricingUpdateEvent, List<String>>(
  (ref, productIds) {
    final firestore = FirebaseFirestore.instance;

    // Watch for pricing rule changes
    return firestore
        .collection('pricing_rules_updates')
        .where('affectedProductIds', arrayContainsAny: productIds)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return PricingUpdateEvent(
          eventType: 'no_change',
          affectedProducts: productIds,
          timestamp: DateTime.now(),
          description: 'No pricing changes',
        );
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      return PricingUpdateEvent(
        eventType: data['eventType'] ?? 'price_changed',
        affectedProducts: List<String>.from(data['affectedProductIds'] ?? []),
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        description: data['description'] ?? 'Pricing updated',
        oldPrice: (data['oldPrice'] as num?)?.toDouble(),
        newPrice: (data['newPrice'] as num?)?.toDouble(),
        promotionActive: data['promotionActive'] ?? false,
      );
    });
  },
);

/// Real-time contract price updates for B2B users
final contractPricingUpdatesProvider =
    StreamProvider.autoDispose.family<ContractPricingUpdate, String>(
  (ref, institutionId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('contract_pricing_updates')
        .where('institutionId', isEqualTo: institutionId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return ContractPricingUpdate(
          institutionId: institutionId,
          updateType: 'none',
          timestamp: DateTime.now(),
        );
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      return ContractPricingUpdate(
        institutionId: institutionId,
        updateType: data['updateType'] ?? 'price_change',
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        affectedItems: List<String>.from(data['affectedItems'] ?? []),
        message: data['message'],
      );
    });
  },
);

/// Real-time product inventory status for display badges
/// Shows low stock warning when stock < 10, out of stock when stock = 0
final productInventoryStatusProvider =
    StreamProvider.autoDispose.family<InventoryStatus, String>(
  (ref, productId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return InventoryStatus(
          productId: productId,
          stock: 0,
          status: 'out_of_stock',
        );
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final stock = data['stock'] ?? 0;

      String status = 'in_stock';
      if (stock == 0) {
        status = 'out_of_stock';
      } else if (stock < 10) {
        status = 'low_stock';
      }

      return InventoryStatus(
        productId: productId,
        stock: stock,
        status: status,
        lastUpdated:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  },
);

// ===================== 3. ORDER STATUS SYNC =====================
// Fulfillment updates → Customer tracking (live)

/// Real-time order fulfillment status updates
/// Enhanced version of orderStatusChangeNotificationProvider
final orderFulfillmentUpdateProvider =
    StreamProvider.autoDispose.family<OrderFulfillmentSync, String>(
  (ref, orderId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return OrderFulfillmentSync(
          orderId: orderId,
          status: 'unknown',
          timestamp: DateTime.now(),
        );
      }

      final data = snapshot.data() as Map<String, dynamic>;

      return OrderFulfillmentSync(
        orderId: orderId,
        status: data['status'] ?? 'pending',
        previousStatus: data['previousStatus'],
        timestamp:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        warehouseId: data['warehouseId'],
        pickListId: data['pickListId'],
        packedAt: (data['packedAt'] as Timestamp?)?.toDate(),
        shippedAt: (data['shippedAt'] as Timestamp?)?.toDate(),
        estimatedDeliveryAt:
            (data['estimatedDeliveryAt'] as Timestamp?)?.toDate(),
        deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
        statusHistory: List<String>.from(data['statusHistory'] ?? []),
      );
    });
  },
);

/// Real-time warehouse operations progress for an order
final warehouseOperationsProgressProvider =
    StreamProvider.autoDispose.family<WarehouseProgress, String>(
  (ref, orderId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('warehouse_operations')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return WarehouseProgress(
          orderId: orderId,
          stage: 'pending',
          percentComplete: 0,
          timestamp: DateTime.now(),
        );
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      return WarehouseProgress(
        orderId: orderId,
        stage: data['stage'] ?? 'pending',
        percentComplete: (data['percentComplete'] as num?)?.toInt() ?? 0,
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        currentStep: data['currentStep'],
        estimatedCompletionTime:
            (data['estimatedCompletionTime'] as Timestamp?)?.toDate(),
      );
    });
  },
);

// ===================== 4. DELIVERY TRACKING =====================
// GPS updates → Customer map (live)

/// Real-time driver location updates for delivery tracking
final driverLocationSyncProvider =
    StreamProvider.autoDispose.family<DriverLocationUpdate, String>(
  (ref, driverId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('driver_locations')
        .doc(driverId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return DriverLocationUpdate(
          driverId: driverId,
          timestamp: DateTime.now(),
        );
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final geoPoint = data['location'] as GeoPoint?;

      return DriverLocationUpdate(
        driverId: driverId,
        latitude: geoPoint?.latitude ?? 0.0,
        longitude: geoPoint?.longitude ?? 0.0,
        heading: (data['heading'] as num?)?.toDouble(),
        speed: (data['speed'] as num?)?.toDouble(),
        accuracy: (data['accuracy'] as num?)?.toDouble(),
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] ?? 'idle',
        activeOrderId: data['activeOrderId'],
      );
    });
  },
);

/// Real-time delivery ETA updates for a specific order
final deliveryETAUpdateProvider =
    StreamProvider.autoDispose.family<DeliveryETAUpdate, String>(
  (ref, orderId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('delivery_eta_updates')
        .where('orderId', isEqualTo: orderId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return DeliveryETAUpdate(
          orderId: orderId,
          timestamp: DateTime.now(),
        );
      }

      final doc = snapshot.docs.first;
      final data = doc.data();

      return DeliveryETAUpdate(
        orderId: orderId,
        estimatedDeliveryTime:
            (data['estimatedDeliveryTime'] as Timestamp?)?.toDate(),
        driverId: data['driverId'],
        driverName: data['driverName'],
        driverPhone: data['driverPhone'],
        vehicleInfo: data['vehicleInfo'],
        currentLocation: data['currentLocation'],
        distanceToDelivery: (data['distanceToDelivery'] as num?)?.toDouble(),
        minutesToDelivery: (data['minutesToDelivery'] as num?)?.toInt(),
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  },
);

// ===================== 5. NOTIFICATIONS (Real-Time) =====================
// Events → Users (live)

/// Real-time unread notification count with live updates
final unreadNotificationCountProvider =
    StreamProvider.autoDispose.family<int, String>(
  (ref, userId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  },
);

/// Stream of important notifications (high priority) for real-time display
final importantNotificationStreamProvider =
    StreamProvider.autoDispose.family<ImportantNotification, String>(
  (ref, userId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('priority', isEqualTo: 'high')
        .where('status', whereIn: ['unread', 'read'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return ImportantNotification(
              userId: userId,
              hasNew: false,
              timestamp: DateTime.now(),
            );
          }

          final doc = snapshot.docs.first;
          final data = doc.data();

          return ImportantNotification(
            userId: userId,
            notificationId: doc.id,
            title: data['title'] ?? 'Notification',
            message: data['message'] ?? '',
            type: data['type'] ?? 'general',
            priority: data['priority'] ?? 'normal',
            hasNew: data['status'] == 'unread',
            timestamp:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        });
  },
);

// ===================== MODELS FOR REAL-TIME DATA =====================

class InventorySyncUpdate {
  final String franchiseId;
  final List<String> itemsLowOnStock;
  final List<String> itemsOutOfStock;
  final List<String> reorderSuggestions;
  final DateTime lastUpdated;
  final String? syncStatus;

  InventorySyncUpdate({
    required this.franchiseId,
    required this.itemsLowOnStock,
    required this.itemsOutOfStock,
    required this.reorderSuggestions,
    required this.lastUpdated,
    this.syncStatus,
  });
}

/// Product inventory status for real-time display badges
class InventoryStatus {
  final String productId;
  final int stock;
  final String status; // 'in_stock', 'low_stock', 'out_of_stock'
  final DateTime? lastUpdated;

  InventoryStatus({
    required this.productId,
    required this.stock,
    required this.status,
    this.lastUpdated,
  });
}

class PricingUpdateEvent {
  final String eventType;
  final List<String> affectedProducts;
  final DateTime timestamp;
  final String description;
  final double? oldPrice;
  final double? newPrice;
  final bool promotionActive;

  PricingUpdateEvent({
    required this.eventType,
    required this.affectedProducts,
    required this.timestamp,
    required this.description,
    this.oldPrice,
    this.newPrice,
    this.promotionActive = false,
  });
}

class ContractPricingUpdate {
  final String institutionId;
  final String updateType;
  final DateTime timestamp;
  final List<String> affectedItems;
  final String? message;

  ContractPricingUpdate({
    required this.institutionId,
    required this.updateType,
    required this.timestamp,
    this.affectedItems = const [],
    this.message,
  });
}

class OrderFulfillmentSync {
  final String orderId;
  final String status;
  final String? previousStatus;
  final DateTime timestamp;
  final String? warehouseId;
  final String? pickListId;
  final DateTime? packedAt;
  final DateTime? shippedAt;
  final DateTime? estimatedDeliveryAt;
  final DateTime? deliveredAt;
  final List<String> statusHistory;

  OrderFulfillmentSync({
    required this.orderId,
    required this.status,
    this.previousStatus,
    required this.timestamp,
    this.warehouseId,
    this.pickListId,
    this.packedAt,
    this.shippedAt,
    this.estimatedDeliveryAt,
    this.deliveredAt,
    this.statusHistory = const [],
  });

  bool get isStatusChange => previousStatus != null && previousStatus != status;
}

class WarehouseProgress {
  final String orderId;
  final String stage;
  final int percentComplete;
  final DateTime timestamp;
  final String? currentStep;
  final DateTime? estimatedCompletionTime;

  WarehouseProgress({
    required this.orderId,
    required this.stage,
    required this.percentComplete,
    required this.timestamp,
    this.currentStep,
    this.estimatedCompletionTime,
  });
}

class DriverLocationUpdate {
  final String driverId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final DateTime timestamp;
  final String status;
  final String? activeOrderId;

  DriverLocationUpdate({
    required this.driverId,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.heading,
    this.speed,
    this.accuracy,
    required this.timestamp,
    this.status = 'idle',
    this.activeOrderId,
  });
}

class DeliveryETAUpdate {
  final String orderId;
  final DateTime? estimatedDeliveryTime;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleInfo;
  final String? currentLocation;
  final double? distanceToDelivery;
  final int? minutesToDelivery;
  final DateTime timestamp;

  DeliveryETAUpdate({
    required this.orderId,
    this.estimatedDeliveryTime,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleInfo,
    this.currentLocation,
    this.distanceToDelivery,
    this.minutesToDelivery,
    required this.timestamp,
  });
}

class ImportantNotification {
  final String userId;
  final String? notificationId;
  final String title;
  final String message;
  final String type;
  final String priority;
  final bool hasNew;
  final DateTime timestamp;

  ImportantNotification({
    required this.userId,
    this.notificationId,
    this.title = '',
    this.message = '',
    this.type = 'general',
    this.priority = 'normal',
    this.hasNew = false,
    required this.timestamp,
  });
}
