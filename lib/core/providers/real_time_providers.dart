import 'package:flutter/foundation.dart';
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
/// Gracefully returns a no_change event on permission errors to avoid infinite retry loops.
final cartPricingUpdatesProvider =
    StreamProvider.autoDispose.family<PricingUpdateEvent, List<String>>(
  (ref, productIds) {
    if (productIds.isEmpty) {
      return Stream.value(PricingUpdateEvent(
        eventType: 'no_change',
        affectedProducts: [],
        timestamp: DateTime.now(),
        description: 'No products to watch',
      ));
    }

    final firestore = FirebaseFirestore.instance;

    // Watch for pricing rule changes; handle permission errors gracefully
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
    }).handleError(
      (error, stackTrace) {
        // Log permission/access errors but allow the stream to complete gracefully
        debugPrint(
            '⚠️ cartPricingUpdatesProvider: Pricing updates unavailable ($error)');
        // Don't re-throw; let stream end gracefully so provider returns initial loading state
      },
    );
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
    StreamProvider.autoDispose.family<ProductInventoryStatusData, String>(
  (ref, productId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return ProductInventoryStatusData(
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

      return ProductInventoryStatusData(
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

/// Real-time conversation previews for Messenger.
final messengerConversationsProvider = StreamProvider.autoDispose
    .family<List<MessengerConversationPreview>, String>(
  (ref, userId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (_isConversationArchivedForUser(data, userId)) {
              return null;
            }
            final updatedAt = _readConversationTime(data);

            return MessengerConversationPreview(
              id: doc.id,
              title: _readConversationTitle(data, userId),
              lastMessage: _readLastMessage(data),
              unreadCount: _readUnreadCountForUser(data, userId),
              updatedAt: updatedAt,
              isOnline: _readOnlineStatus(data, userId),
              avatarText: _readAvatarText(data, userId),
            );
          })
          .whereType<MessengerConversationPreview>()
          .toList();

      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    }).handleError((_) {
      // Keep UI stable on permission/index/schema issues.
      return <MessengerConversationPreview>[];
    });
  },
);

/// Real-time message stream for a conversation thread.
final messengerConversationMessagesProvider = StreamProvider.autoDispose
    .family<List<MessengerConversationMessage>, String>(
  (ref, conversationId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return MessengerConversationMessage(
          id: doc.id,
          conversationId: conversationId,
          senderId: data['senderId']?.toString() ?? '',
          senderName: data['senderName']?.toString(),
          senderAvatar: data['senderAvatar']?.toString(),
          text: data['text']?.toString() ?? '',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    }).handleError((_) {
      return <MessengerConversationMessage>[];
    });
  },
);

/// Real-time unread conversation count for Messenger badge.
/// Expected conversation schema:
/// - participantIds: list of user ids
/// - unreadByUser: map of user id to count (preferred)
/// Optional fallback schema supported:
/// - unreadCounts: map of user id to count
/// - unreadCount: num (single conversation-level unread count)
final unreadMessengerCountProvider =
    StreamProvider.autoDispose.family<int, String>(
  (ref, userId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (_isConversationArchivedForUser(data, userId)) {
          continue;
        }
        totalUnread += _readUnreadCountForUser(data, userId);
      }

      return totalUnread;
    }).handleError((_) {
      // Keep UI stable on permission/index/schema issues.
      return 0;
    });
  },
);

int _readUnreadCountForUser(Map<String, dynamic> data, String userId) {
  final unreadByUser = data['unreadByUser'];
  if (unreadByUser is Map) {
    final raw = unreadByUser[userId];
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? 0;
    }
  }

  final unreadCounts = data['unreadCounts'];
  if (unreadCounts is Map) {
    final raw = unreadCounts[userId];
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? 0;
    }
  }

  final fallbackUnread = data['unreadCount'];
  if (fallbackUnread is num) {
    return fallbackUnread.toInt();
  }
  if (fallbackUnread is String) {
    return int.tryParse(fallbackUnread) ?? 0;
  }

  return 0;
}

DateTime _readConversationTime(Map<String, dynamic> data) {
  final updatedAt = data['updatedAt'];
  if (updatedAt is Timestamp) {
    return updatedAt.toDate();
  }

  final lastMessageAt = data['lastMessageAt'];
  if (lastMessageAt is Timestamp) {
    return lastMessageAt.toDate();
  }

  final createdAt = data['createdAt'];
  if (createdAt is Timestamp) {
    return createdAt.toDate();
  }

  return DateTime.now();
}

String _readConversationTitle(Map<String, dynamic> data, String userId) {
  final title = data['title'];
  if (title is String && title.trim().isNotEmpty) {
    return title;
  }

  final participantNames = data['participantNames'];
  if (participantNames is Map) {
    for (final entry in participantNames.entries) {
      if (entry.key.toString() != userId && entry.value is String) {
        final otherName = (entry.value as String).trim();
        if (otherName.isNotEmpty) {
          return otherName;
        }
      }
    }
  }

  return 'Conversation';
}

String _readLastMessage(Map<String, dynamic> data) {
  final text = data['lastMessageText'];
  if (text is String && text.trim().isNotEmpty) {
    return text;
  }

  final fallback = data['lastMessage'];
  if (fallback is String && fallback.trim().isNotEmpty) {
    return fallback;
  }

  return 'Start conversation';
}

bool _readOnlineStatus(Map<String, dynamic> data, String userId) {
  final participantOnline = data['participantOnline'];
  if (participantOnline is Map) {
    for (final entry in participantOnline.entries) {
      if (entry.key.toString() != userId && entry.value is bool) {
        return entry.value as bool;
      }
    }
  }

  return false;
}

String _readAvatarText(Map<String, dynamic> data, String userId) {
  final participantAvatars = data['participantAvatars'];
  if (participantAvatars is Map) {
    for (final entry in participantAvatars.entries) {
      if (entry.key.toString() != userId && entry.value is String) {
        final avatar = (entry.value as String).trim();
        if (avatar.isNotEmpty) {
          return avatar;
        }
      }
    }
  }

  final avatar = data['avatar'];
  if (avatar is String && avatar.trim().isNotEmpty) {
    return avatar;
  }

  return '💬';
}

bool _isConversationArchivedForUser(Map<String, dynamic> data, String userId) {
  final archivedByUser = data['archivedByUser'];
  if (archivedByUser is Map) {
    final raw = archivedByUser[userId];
    if (raw is bool && raw) {
      return true;
    }
    if (raw is String && raw.toLowerCase() == 'true') {
      return true;
    }
  }

  final archivedFor = data['archivedFor'];
  if (archivedFor is List) {
    return archivedFor.map((e) => e.toString()).contains(userId);
  }

  return false;
}

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

/// Product inventory status class for real-time tracking
/// Different from the InventoryStatus enum in inventory_warning_service.dart
class ProductInventoryStatusData {
  final String productId;
  final int stock;
  final String status; // 'in_stock', 'low_stock', 'out_of_stock'
  final DateTime? lastUpdated;

  ProductInventoryStatusData({
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

class MessengerConversationPreview {
  final String id;
  final String title;
  final String lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final bool isOnline;
  final String avatarText;

  MessengerConversationPreview({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
    required this.isOnline,
    required this.avatarText,
  });
}

class MessengerConversationMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String text;
  final DateTime createdAt;

  MessengerConversationMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.text,
    required this.createdAt,
  });
}
