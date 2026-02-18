import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Service for managing user saved/wishlist items
class SavedItemsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _savedItemsCollection = 'saved_items';

  // ===================== SAVE / UNSAVE =====================

  /// Add item to user's saved items
  Future<void> addToSaved({
    required String userId,
    required String productId,
    required String productName,
    required double price,
    required double originalPrice,
    required String company,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_savedItemsCollection)
          .doc(productId)
          .set({
        'productId': productId,
        'productName': productName,
        'price': price,
        'originalPrice': originalPrice,
        'company': company,
        'savedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save item: $e');
    }
  }

  /// Remove item from user's saved items
  Future<void> removeFromSaved({
    required String userId,
    required String productId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_savedItemsCollection)
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove saved item: $e');
    }
  }

  /// Check if item is saved by user
  Future<bool> isItemSaved({
    required String userId,
    required String productId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_savedItemsCollection)
          .doc(productId)
          .get();

      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check saved status: $e');
    }
  }

  // ===================== RETRIEVAL =====================

  /// Get all saved items for a user
  Future<List<SavedItem>> getUserSavedItems(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_savedItemsCollection)
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => SavedItem.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch saved items: $e');
    }
  }

  /// Stream saved items for real-time updates
  Stream<List<SavedItem>> getSavedItemsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_savedItemsCollection)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SavedItem.fromFirestore(doc)).toList());
  }

  /// Get saved items with pagination
  Future<SavedItemsPage> getSavedItemsPaginated({
    required String userId,
    int pageSize = 20,
    int page = 1,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_savedItemsCollection)
          .orderBy('savedAt', descending: true)
          .get();

      final totalCount = snapshot.docs.length;
      final offset = (page - 1) * pageSize;

      final paginatedDocs = snapshot.docs.skip(offset).take(pageSize).toList();

      final items =
          paginatedDocs.map((doc) => SavedItem.fromFirestore(doc)).toList();

      return SavedItemsPage(
        items: items,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
        totalPages: (totalCount / pageSize).ceil(),
      );
    } catch (e) {
      throw Exception('Failed to fetch paginated saved items: $e');
    }
  }

  /// Count saved items for a user
  Future<int> getSavedItemsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_savedItemsCollection)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get saved items count: $e');
    }
  }

  // ===================== CART CONVERSION =====================

  /// Move saved item to cart (creates order item)
  Future<String> savedItemToCart({
    required String userId,
    required String productId,
    int quantity = 1,
  }) async {
    try {
      final savedItem = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_savedItemsCollection)
          .doc(productId)
          .get();

      if (!savedItem.exists) {
        throw Exception('Saved item not found');
      }

      final data = savedItem.data() as Map<String, dynamic>;
      final cartItemId = const Uuid().v4();

      // Add to cart
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartItemId)
          .set({
        'cartItemId': cartItemId,
        'productId': productId,
        'productName': data['productName'],
        'price': data['price'],
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return cartItemId;
    } catch (e) {
      throw Exception('Failed to add saved item to cart: $e');
    }
  }

  /// Move all saved items to cart
  Future<int> savedItemsAllToCart({
    required String userId,
  }) async {
    try {
      final savedItems = await getUserSavedItems(userId);

      int addedCount = 0;
      for (final item in savedItems) {
        try {
          await savedItemToCart(
            userId: userId,
            productId: item.productId,
            quantity: 1,
          );
          addedCount++;
        } catch (e) {
          print('Failed to add ${item.productName} to cart: $e');
        }
      }

      return addedCount;
    } catch (e) {
      throw Exception('Failed to add all saved items to cart: $e');
    }
  }

  // ===================== COLLECTIONS =====================

  /// Create a saved items collection (e.g., "Essentials", "Bulk Deals")
  Future<String> createCollection({
    required String userId,
    required String name,
    String? description,
  }) async {
    try {
      final collectionId = const Uuid().v4();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_collections')
          .doc(collectionId)
          .set({
        'collectionId': collectionId,
        'name': name,
        'description': description,
        'itemCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return collectionId;
    } catch (e) {
      throw Exception('Failed to create collection: $e');
    }
  }

  /// Add saved item to a collection
  Future<void> addItemToCollection({
    required String userId,
    required String collectionId,
    required String productId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_collections')
          .doc(collectionId)
          .collection('items')
          .doc(productId)
          .set({'productId': productId});

      // Update item count
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_collections')
          .doc(collectionId)
          .collection('items')
          .count()
          .get();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_collections')
          .doc(collectionId)
          .update({'itemCount': snapshot.count ?? 0});
    } catch (e) {
      throw Exception('Failed to add item to collection: $e');
    }
  }

  /// Get all collections for user
  Future<List<SavedCollection>> getUserCollections(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_collections')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SavedCollection.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch collections: $e');
    }
  }
}

// ===================== DATA MODELS =====================

class SavedItem {
  final String productId;
  final String productName;
  final double price;
  final double originalPrice;
  final String company;
  final DateTime savedAt;

  SavedItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.originalPrice,
    required this.company,
    required this.savedAt,
  });

  double get savings => originalPrice - price;

  double get savingsPercent => (savings / originalPrice) * 100;

  factory SavedItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedItem(
      productId: data['productId'] as String,
      productName: data['productName'] as String,
      price: (data['price'] as num).toDouble(),
      originalPrice: (data['originalPrice'] as num).toDouble(),
      company: data['company'] as String,
      savedAt: (data['savedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'originalPrice': originalPrice,
      'company': company,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}

class SavedItemsPage {
  final List<SavedItem> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  SavedItemsPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
}

class SavedCollection {
  final String collectionId;
  final String name;
  final String? description;
  final int itemCount;
  final DateTime createdAt;

  SavedCollection({
    required this.collectionId,
    required this.name,
    this.description,
    required this.itemCount,
    required this.createdAt,
  });

  factory SavedCollection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedCollection(
      collectionId: data['collectionId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      itemCount: data['itemCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'collectionId': collectionId,
      'name': name,
      'description': description,
      'itemCount': itemCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
