import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wishlist item model
class WishlistItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final double originalPrice;
  final String? imageUrl;
  final DateTime addedDate;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.originalPrice,
    this.imageUrl,
    DateTime? addedDate,
  }) : addedDate = addedDate ?? DateTime.now();

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'price': price,
        'originalPrice': originalPrice,
        'imageUrl': imageUrl,
        'addedDate': addedDate.toIso8601String(),
      };

  /// Create from JSON
  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        price: (json['price'] as num).toDouble(),
        originalPrice: (json['originalPrice'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
        addedDate: DateTime.parse(json['addedDate'] as String),
      );

  /// Calculate discount percentage
  double get discountPercent {
    if (originalPrice == 0) return 0;
    return ((originalPrice - price) / originalPrice * 100);
  }

  /// Create a copy with modified fields
  WishlistItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? price,
    double? originalPrice,
    String? imageUrl,
    DateTime? addedDate,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      addedDate: addedDate ?? this.addedDate,
    );
  }
}

/// Wishlist state model
class WishlistState {
  final List<WishlistItem> items;
  final bool isLoading;
  final String? error;

  const WishlistState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  /// Total number of items in wishlist
  int get itemCount => items.length;

  /// Check if a product is in the wishlist
  bool contains(String productId) {
    return items.any((item) => item.productId == productId);
  }

  /// Get item by product ID
  WishlistItem? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Copy with modified fields
  WishlistState copyWith({
    List<WishlistItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Wishlist Notifier
class WishlistNotifier extends Notifier<WishlistState> {
  @override
  WishlistState build() {
    return const WishlistState();
  }

  /// Add item to wishlist
  void addItem(WishlistItem item) {
    if (!state.contains(item.productId)) {
      state = state.copyWith(
        items: [...state.items, item],
        error: null,
      );
    }
  }

  /// Remove item from wishlist by product ID
  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items
          .where((item) => item.productId != productId)
          .toList(),
      error: null,
    );
  }

  /// Toggle wishlist for a product (add if not present, remove if present)
  bool toggleWishlist({
    required String productId,
    required String productName,
    required double price,
    required double originalPrice,
    String? imageUrl,
  }) {
    final exists = state.contains(productId);

    if (exists) {
      removeItem(productId);
      return false; // Item was removed
    } else {
      addItem(
        WishlistItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: productId,
          productName: productName,
          price: price,
          originalPrice: originalPrice,
          imageUrl: imageUrl,
        ),
      );
      return true; // Item was added
    }
  }

  /// Clear all items from wishlist
  void clearWishlist() {
    state = const WishlistState();
  }

  /// Set error message
  void setError(String message) {
    state = state.copyWith(error: message);
  }
}

/// Base Wishlist Provider
final wishlistProvider =
    NotifierProvider<WishlistNotifier, WishlistState>(
  WishlistNotifier.new,
);

/// Provider for wishlist item count
final wishlistItemCountProvider = Provider<int>((ref) {
  final wishlist = ref.watch(wishlistProvider);
  return wishlist.itemCount;
});

/// Provider to check if specific product is in wishlist
final isProductInWishlistProvider = Provider.family<bool, String>((ref, productId) {
  final wishlist = ref.watch(wishlistProvider);
  return wishlist.contains(productId);
});

/// Provider to get wishlist item for a specific product
final wishlistItemProvider = Provider.family<WishlistItem?, String>((ref, productId) {
  final wishlist = ref.watch(wishlistProvider);
  return wishlist.getItem(productId);
});
