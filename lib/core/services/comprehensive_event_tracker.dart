import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Comprehensive event tracking system for all user activities
/// Tracks: views, searches, cart actions, purchases, reviews, and more
/// Used for analytics, personalization, churn prevention, and business intelligence

enum EventType {
  // Product interaction
  productViewed,
  productSearched,
  categoryBrowsed,
  filtersApplied,

  // Shopping behavior
  addedToCart,
  removedFromCart,
  quantityChanged,
  cartAbandoned,

  // Purchase journey
  checkoutStarted,
  checkoutCompleted,
  paymentProcessed,
  orderPlaced,

  // Post-purchase
  orderViewed,
  orderCancelled,
  refundRequested,
  reviewCreated,

  // Engagement
  wishlistAdded,
  wishlistRemoved,
  promoApplied,

  // User behavior
  appOpened,
  screenViewed,
  userLoggedIn,
  userLoggedOut,
}

extension EventTypeExt on EventType {
  String get value {
    switch (this) {
      case EventType.productViewed:
        return 'product_viewed';
      case EventType.productSearched:
        return 'product_searched';
      case EventType.categoryBrowsed:
        return 'category_browsed';
      case EventType.filtersApplied:
        return 'filters_applied';
      case EventType.addedToCart:
        return 'added_to_cart';
      case EventType.removedFromCart:
        return 'removed_from_cart';
      case EventType.quantityChanged:
        return 'quantity_changed';
      case EventType.cartAbandoned:
        return 'cart_abandoned';
      case EventType.checkoutStarted:
        return 'checkout_started';
      case EventType.checkoutCompleted:
        return 'checkout_completed';
      case EventType.paymentProcessed:
        return 'payment_processed';
      case EventType.orderPlaced:
        return 'order_placed';
      case EventType.orderViewed:
        return 'order_viewed';
      case EventType.orderCancelled:
        return 'order_cancelled';
      case EventType.refundRequested:
        return 'refund_requested';
      case EventType.reviewCreated:
        return 'review_created';
      case EventType.wishlistAdded:
        return 'wishlist_added';
      case EventType.wishlistRemoved:
        return 'wishlist_removed';
      case EventType.promoApplied:
        return 'promo_applied';
      case EventType.appOpened:
        return 'app_opened';
      case EventType.screenViewed:
        return 'screen_viewed';
      case EventType.userLoggedIn:
        return 'user_logged_in';
      case EventType.userLoggedOut:
        return 'user_logged_out';
    }
  }

  String get displayName {
    switch (this) {
      case EventType.productViewed:
        return 'Product Viewed';
      case EventType.productSearched:
        return 'Product Searched';
      case EventType.categoryBrowsed:
        return 'Category Browsed';
      case EventType.filtersApplied:
        return 'Filters Applied';
      case EventType.addedToCart:
        return 'Added to Cart';
      case EventType.removedFromCart:
        return 'Removed from Cart';
      case EventType.quantityChanged:
        return 'Quantity Changed';
      case EventType.cartAbandoned:
        return 'Cart Abandoned';
      case EventType.checkoutStarted:
        return 'Checkout Started';
      case EventType.checkoutCompleted:
        return 'Checkout Completed';
      case EventType.paymentProcessed:
        return 'Payment Processed';
      case EventType.orderPlaced:
        return 'Order Placed';
      case EventType.orderViewed:
        return 'Order Viewed';
      case EventType.orderCancelled:
        return 'Order Cancelled';
      case EventType.refundRequested:
        return 'Refund Requested';
      case EventType.reviewCreated:
        return 'Review Created';
      case EventType.wishlistAdded:
        return 'Wishlist Added';
      case EventType.wishlistRemoved:
        return 'Wishlist Removed';
      case EventType.promoApplied:
        return 'Promo Applied';
      case EventType.appOpened:
        return 'App Opened';
      case EventType.screenViewed:
        return 'Screen Viewed';
      case EventType.userLoggedIn:
        return 'User Logged In';
      case EventType.userLoggedOut:
        return 'User Logged Out';
    }
  }
}

/// User event model
class UserEvent {
  final String id;
  final String userId;
  final EventType type;
  final DateTime timestamp;
  final Map<String, dynamic> properties;

  UserEvent({
    required this.userId,
    required this.type,
    required this.timestamp,
    this.properties = const {},
    String? id,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'eventType': type.value,
        'timestamp': Timestamp.fromDate(timestamp),
        'properties': properties,
      };

  factory UserEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseEventType(data['eventType'] as String?),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      properties: data['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  static EventType _parseEventType(String? value) {
    switch (value) {
      case 'product_viewed':
        return EventType.productViewed;
      case 'product_searched':
        return EventType.productSearched;
      case 'category_browsed':
        return EventType.categoryBrowsed;
      case 'filters_applied':
        return EventType.filtersApplied;
      case 'added_to_cart':
        return EventType.addedToCart;
      case 'removed_from_cart':
        return EventType.removedFromCart;
      case 'quantity_changed':
        return EventType.quantityChanged;
      case 'cart_abandoned':
        return EventType.cartAbandoned;
      case 'checkout_started':
        return EventType.checkoutStarted;
      case 'checkout_completed':
        return EventType.checkoutCompleted;
      case 'payment_processed':
        return EventType.paymentProcessed;
      case 'order_placed':
        return EventType.orderPlaced;
      case 'order_viewed':
        return EventType.orderViewed;
      case 'order_cancelled':
        return EventType.orderCancelled;
      case 'refund_requested':
        return EventType.refundRequested;
      case 'review_created':
        return EventType.reviewCreated;
      case 'wishlist_added':
        return EventType.wishlistAdded;
      case 'wishlist_removed':
        return EventType.wishlistRemoved;
      case 'promo_applied':
        return EventType.promoApplied;
      case 'app_opened':
        return EventType.appOpened;
      case 'screen_viewed':
        return EventType.screenViewed;
      case 'user_logged_in':
        return EventType.userLoggedIn;
      case 'user_logged_out':
        return EventType.userLoggedOut;
      default:
        return EventType.screenViewed;
    }
  }
}

/// Comprehensive event tracking service
class ComprehensiveEventTracker {
  static final ComprehensiveEventTracker _instance =
      ComprehensiveEventTracker._internal();
  late FirebaseFirestore _firestore;
  late firebase_auth.FirebaseAuth _auth;
  String? _sessionId;

  factory ComprehensiveEventTracker() => _instance;

  ComprehensiveEventTracker._internal() {
    _firestore = FirebaseFirestore.instance;
    _auth = firebase_auth.FirebaseAuth.instance;
    _sessionId = const Uuid().v4();
  }

  /// Track a product view event
  Future<void> trackProductViewed({
    required String productId,
    required String productName,
    String? category,
    double? price,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.productViewed,
      properties: {
        'productId': productId,
        'productName': productName,
        'category': category,
        'price': price,
        ...?additionalProperties,
      },
    );
  }

  /// Track product search
  Future<void> trackProductSearched({
    required String searchQuery,
    int? resultsCount,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.productSearched,
      properties: {
        'searchQuery': searchQuery,
        'resultsCount': resultsCount,
        ...?additionalProperties,
      },
    );
  }

  /// Track category browsed
  Future<void> trackCategoryBrowsed({
    required String categoryId,
    required String categoryName,
    int? productsCount,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.categoryBrowsed,
      properties: {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'productsCount': productsCount,
        ...?additionalProperties,
      },
    );
  }

  /// Track filters applied (search refinement)
  Future<void> trackFiltersApplied({
    required List<String> filterTypes,
    Map<String, dynamic>? filterValues,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.filtersApplied,
      properties: {
        'filterTypes': filterTypes,
        'filterValues': filterValues,
        ...?additionalProperties,
      },
    );
  }

  /// Track item added to cart
  Future<void> trackAddedToCart({
    required String productId,
    required String productName,
    required int quantity,
    required double price,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.addedToCart,
      properties: {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'price': price,
        'totalValue': quantity * price,
        ...?additionalProperties,
      },
    );
  }

  /// Track item removed from cart
  Future<void> trackRemovedFromCart({
    required String productId,
    required String productName,
    required int quantity,
    required double price,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.removedFromCart,
      properties: {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'price': price,
        ...?additionalProperties,
      },
    );
  }

  /// Track checkout started
  Future<void> trackCheckoutStarted({
    required double cartTotal,
    required int itemCount,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.checkoutStarted,
      properties: {
        'cartTotal': cartTotal,
        'itemCount': itemCount,
        ...?additionalProperties,
      },
    );
  }

  /// Track checkout completed
  Future<void> trackCheckoutCompleted({
    required String orderId,
    required double totalAmount,
    required int itemCount,
    String? paymentMethod,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.checkoutCompleted,
      properties: {
        'orderId': orderId,
        'totalAmount': totalAmount,
        'itemCount': itemCount,
        'paymentMethod': paymentMethod,
        ...?additionalProperties,
      },
    );
  }

  /// Track order placed
  Future<void> trackOrderPlaced({
    required String orderId,
    required double orderValue,
    required List<String> productIds,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.orderPlaced,
      properties: {
        'orderId': orderId,
        'orderValue': orderValue,
        'productIds': productIds,
        'productCount': productIds.length,
        ...?additionalProperties,
      },
    );
  }

  /// Track order viewed
  Future<void> trackOrderViewed({
    required String orderId,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.orderViewed,
      properties: {
        'orderId': orderId,
        ...?additionalProperties,
      },
    );
  }

  /// Track review created
  Future<void> trackReviewCreated({
    required String productId,
    required String productName,
    required double rating,
    String? reviewText,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.reviewCreated,
      properties: {
        'productId': productId,
        'productName': productName,
        'rating': rating,
        'reviewLength': reviewText?.length ?? 0,
        ...?additionalProperties,
      },
    );
  }

  /// Track wishlist added
  Future<void> trackWishlistAdded({
    required String productId,
    required String productName,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.wishlistAdded,
      properties: {
        'productId': productId,
        'productName': productName,
        ...?additionalProperties,
      },
    );
  }

  /// Track screen viewed (app navigation)
  Future<void> trackScreenViewed({
    required String screenName,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.screenViewed,
      properties: {
        'screenName': screenName,
        ...?additionalProperties,
      },
    );
  }

  /// Track app opened
  Future<void> trackAppOpened({
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.appOpened,
      properties: {
        ...?additionalProperties,
      },
    );
  }

  /// Track user logged in
  Future<void> trackUserLoggedIn({
    required String userId,
    String? loginMethod,
    Map<String, dynamic>? additionalProperties,
  }) async {
    await _trackEvent(
      type: EventType.userLoggedIn,
      properties: {
        'userId': userId,
        'loginMethod': loginMethod,
        ...?additionalProperties,
      },
    );
  }

  /// Generic event tracking
  Future<void> _trackEvent({
    required EventType type,
    required Map<String, dynamic> properties,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint(
            '⚠️ No user logged in, event not tracked: ${type.displayName}');
        return;
      }

      final event = UserEvent(
        userId: user.uid,
        type: type,
        timestamp: DateTime.now(),
        properties: {
          ...properties,
          'sessionId': _sessionId,
        },
      );

      // Save to Firestore
      await _firestore
          .collection('events')
          .doc(event.id)
          .set(event.toFirestore());

      debugPrint('✅ Event tracked: ${type.displayName} for user ${user.uid}');
    } catch (e) {
      debugPrint('❌ Failed to track event: $e');
      // Don't crash - analytics is non-critical
    }
  }

  /// Get user's recent events
  Future<List<UserEvent>> getUserEvents({
    required String userId,
    int limit = 100,
    EventType? filterByType,
  }) async {
    try {
      Query query = _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (filterByType != null) {
        query = query.where('eventType', isEqualTo: filterByType.value);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => UserEvent.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get user events: $e');
      return [];
    }
  }

  /// Reset session ID (call when user logs in)
  void resetSession() {
    _sessionId = const Uuid().v4();
  }
}
