import 'package:cloud_firestore/cloud_firestore.dart';

/// Product variant (size, color, packaging, etc.)
class ProductVariant {
  final String id;
  final String name; // e.g., "500ml", "Red", "Case of 12"
  final String? description;
  final Map<String, String>
      attributes; // e.g., {"size": "500ml", "color": "red"}
  final String sku; // Unique SKU for this variant
  final double price; // Variant-specific price (if different)
  final int stock;
  final String? imageUrl;
  final bool isActive;

  ProductVariant({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    this.description,
    this.attributes = const {},
    this.imageUrl,
    this.isActive = true,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      stock: map['stock'] ?? 0,
      description: map['description'],
      attributes: Map<String, String>.from(
          map['attributes'] as Map<String, dynamic>? ?? {}),
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'sku': sku,
        'price': price,
        'stock': stock,
        'description': description,
        'attributes': attributes,
        'imageUrl': imageUrl,
        'isActive': isActive,
      };
}

/// Store-level availability
class StoreAvailability {
  final String storeId;
  final int stock;
  final DateTime lastUpdated;
  final bool isAvailable;
  final int daysOfCover; // Estimated days of supply at current sales rate
  final int? minimumOrderQuantity; // Store-specific MOQ

  StoreAvailability({
    required this.storeId,
    required this.stock,
    required this.lastUpdated,
    required this.isAvailable,
    this.daysOfCover = 0,
    this.minimumOrderQuantity,
  });

  factory StoreAvailability.fromMap(Map<String, dynamic> map) {
    return StoreAvailability(
      storeId: map['storeId'] ?? '',
      stock: map['stock'] ?? 0,
      lastUpdated: DateTime.parse(
          map['lastUpdated'] as String? ?? DateTime.now().toIso8601String()),
      isAvailable: map['isAvailable'] ?? true,
      daysOfCover: map['daysOfCover'] ?? 0,
      minimumOrderQuantity: map['minimumOrderQuantity'],
    );
  }

  Map<String, dynamic> toMap() => {
        'storeId': storeId,
        'stock': stock,
        'lastUpdated': lastUpdated.toIso8601String(),
        'isAvailable': isAvailable,
        'daysOfCover': daysOfCover,
        'minimumOrderQuantity': minimumOrderQuantity,
      };
}

/// Institution-specific catalogue entry
class InstitutionCatalogueEntry {
  final String institutionId;
  final String productId;
  final List<String> allowedVariantIds; // Which variants are in this contract
  final double? contractPrice; // Optional override price for institution
  final int? minimumOrderQuantity;
  final int? casePackSize;
  final bool isActive;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;

  InstitutionCatalogueEntry({
    required this.institutionId,
    required this.productId,
    required this.allowedVariantIds,
    this.contractPrice,
    this.minimumOrderQuantity,
    this.casePackSize,
    this.isActive = true,
    required this.effectiveFrom,
    this.effectiveUntil,
  });

  factory InstitutionCatalogueEntry.fromMap(Map<String, dynamic> map) {
    return InstitutionCatalogueEntry(
      institutionId: map['institutionId'] ?? '',
      productId: map['productId'] ?? '',
      allowedVariantIds:
          List<String>.from(map['allowedVariantIds'] as List<dynamic>? ?? []),
      contractPrice: (map['contractPrice'] as num?)?.toDouble(),
      minimumOrderQuantity: map['minimumOrderQuantity'],
      casePackSize: map['casePackSize'],
      isActive: map['isActive'] ?? true,
      effectiveFrom: DateTime.parse(
          map['effectiveFrom'] as String? ?? DateTime.now().toIso8601String()),
      effectiveUntil: map['effectiveUntil'] != null
          ? DateTime.parse(map['effectiveUntil'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'institutionId': institutionId,
        'productId': productId,
        'allowedVariantIds': allowedVariantIds,
        'contractPrice': contractPrice,
        'minimumOrderQuantity': minimumOrderQuantity,
        'casePackSize': casePackSize,
        'isActive': isActive,
        'effectiveFrom': effectiveFrom.toIso8601String(),
        'effectiveUntil': effectiveUntil?.toIso8601String(),
      };

  bool isExpired() =>
      !isActive ||
      (effectiveUntil != null && DateTime.now().isAfter(effectiveUntil!));
}

/// Catalogue product with variants and availability
class CatalogueProduct {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final double baseRetailPrice;
  final double baseWholesalePrice;
  final List<ProductVariant> variants;
  final List<StoreAvailability> storeAvailability;
  final Map<String, String> media; // mediaType -> url (e.g., "image1" -> url)
  final Map<String, String> attributes; // Product-level attributes
  final List<String> tags;
  final double rating;
  final int reviewCount;
  final bool visibleToRetail;
  final bool visibleToWholesale;
  final bool visibleToInstitutions;
  final DateTime createdAt;
  final DateTime updatedAt;

  CatalogueProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.baseRetailPrice,
    required this.baseWholesalePrice,
    this.variants = const [],
    this.storeAvailability = const [],
    this.media = const {},
    this.attributes = const {},
    this.tags = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.visibleToRetail = true,
    this.visibleToWholesale = false,
    this.visibleToInstitutions = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CatalogueProduct.fromMap(Map<String, dynamic> map) {
    return CatalogueProduct(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['categoryId'] ?? '',
      baseRetailPrice: (map['baseRetailPrice'] as num?)?.toDouble() ?? 0,
      baseWholesalePrice: (map['baseWholesalePrice'] as num?)?.toDouble() ?? 0,
      variants: (map['variants'] as List<dynamic>? ?? [])
          .map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
          .toList(),
      storeAvailability: (map['storeAvailability'] as List<dynamic>? ?? [])
          .map((s) => StoreAvailability.fromMap(s as Map<String, dynamic>))
          .toList(),
      media:
          Map<String, String>.from(map['media'] as Map<String, dynamic>? ?? {}),
      attributes: Map<String, String>.from(
          map['attributes'] as Map<String, dynamic>? ?? {}),
      tags: List<String>.from(map['tags'] as List<dynamic>? ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: map['reviewCount'] ?? 0,
      visibleToRetail: map['visibleToRetail'] ?? true,
      visibleToWholesale: map['visibleToWholesale'] ?? false,
      visibleToInstitutions: map['visibleToInstitutions'] ?? false,
      createdAt: DateTime.parse(
          map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          map['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'baseRetailPrice': baseRetailPrice,
        'baseWholesalePrice': baseWholesalePrice,
        'variants': variants.map((v) => v.toMap()).toList(),
        'storeAvailability': storeAvailability.map((s) => s.toMap()).toList(),
        'media': media,
        'attributes': attributes,
        'tags': tags,
        'rating': rating,
        'reviewCount': reviewCount,
        'visibleToRetail': visibleToRetail,
        'visibleToWholesale': visibleToWholesale,
        'visibleToInstitutions': visibleToInstitutions,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Get availability for a specific store
  StoreAvailability? getStoreAvailability(String storeId) {
    try {
      return storeAvailability.firstWhere((s) => s.storeId == storeId);
    } catch (e) {
      return null;
    }
  }

  /// Check if available at store
  bool isAvailableAt(String storeId) {
    final availability = getStoreAvailability(storeId);
    return availability != null &&
        availability.isAvailable &&
        availability.stock > 0;
  }

  /// Get total stock across all stores
  int getTotalStock() => storeAvailability.fold(0, (prev, s) => prev + s.stock);
}

/// Catalogue Service
class CatalogueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _productsCollection = 'catalogue_products';
  static const String _institutionCatalogueCollection =
      'institution_catalogues';
  static const String _storeAvailabilityCollection = 'store_availability';

  /// Get product by ID with all variants and availability
  Future<CatalogueProduct?> getProductById(String productId) async {
    try {
      final doc =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!doc.exists) return null;

      return CatalogueProduct.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'id': productId,
      });
    } catch (e) {
      print('Error getting product: $e');
      rethrow;
    }
  }

  /// Get products by category
  Future<List<CatalogueProduct>> getProductsByCategory(
    String categoryId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .where('visibleToRetail', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CatalogueProduct.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get products filtered by role
  /// retail: visibleToRetail = true
  /// wholesale: visibleToWholesale = true
  /// institutional: visibleToInstitutions = true
  Future<List<CatalogueProduct>> getProductsByRole(
    String role, {
    String? storeId,
    int limit = 50,
  }) async {
    try {
      late Query query;

      switch (role.toLowerCase()) {
        case 'retail_customer':
        case 'consumer':
          query = _firestore
              .collection(_productsCollection)
              .where('visibleToRetail', isEqualTo: true);
        case 'franchisee':
        case 'wholesale':
          query = _firestore
              .collection(_productsCollection)
              .where('visibleToWholesale', isEqualTo: true);
        case 'institution':
        case 'institutional':
          query = _firestore
              .collection(_productsCollection)
              .where('visibleToInstitutions', isEqualTo: true);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => CatalogueProduct.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search products by name or tags
  Future<List<CatalogueProduct>> searchProducts(
    String query, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('visibleToRetail', isEqualTo: true)
          .limit(limit)
          .get();

      // Client-side filtering on name and tags
      return snapshot.docs
          .map((doc) => CatalogueProduct.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.tags.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase())) ||
            product.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get institution-specific catalogue
  Future<List<CatalogueProduct>> getInstitutionCatalogue(
    String institutionId, {
    int limit = 100,
  }) async {
    try {
      // Get institution catalogue entries
      final catalogueSnapshot = await _firestore
          .collection(_institutionCatalogueCollection)
          .where('institutionId', isEqualTo: institutionId)
          .where('isActive', isEqualTo: true)
          .get();

      // Get product IDs from catalogue entries
      final productIds = catalogueSnapshot.docs
          .map((doc) => doc['productId'] as String)
          .toList();

      if (productIds.isEmpty) {
        return [];
      }

      // Fetch products in batches (Firestore has 10 item limit for 'in')
      final products = <CatalogueProduct>[];
      for (int i = 0; i < productIds.length; i += 10) {
        final batch = productIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(_productsCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        products.addAll(snapshot.docs
            .map((doc) => CatalogueProduct.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
      }

      return products;
    } catch (e) {
      rethrow;
    }
  }

  /// Get products available at store with real-time availability
  Future<List<CatalogueProduct>> getProductsByStore(
    String storeId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_productsCollection)
          .where('visibleToRetail', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) {
            final product = CatalogueProduct.fromMap({
              ...doc.data(),
              'id': doc.id,
            });
            return product;
          })
          .where((product) => product.isAvailableAt(storeId))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Watch products by role for real-time updates
  Stream<List<CatalogueProduct>> watchProductsByRole(String role) {
    late Query query;

    switch (role.toLowerCase()) {
      case 'retail_customer':
      case 'consumer':
        query = _firestore
            .collection(_productsCollection)
            .where('visibleToRetail', isEqualTo: true);
      case 'franchisee':
      case 'wholesale':
        query = _firestore
            .collection(_productsCollection)
            .where('visibleToWholesale', isEqualTo: true);
      case 'institution':
      case 'institutional':
        query = _firestore
            .collection(_productsCollection)
            .where('visibleToInstitutions', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CatalogueProduct.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    });
  }

  /// Update store availability (called by inventory service)
  Future<void> updateStoreAvailability({
    required String productId,
    required String storeId,
    required int stock,
    required int daysOfCover,
    bool isAvailable = true,
  }) async {
    try {
      await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .collection(_storeAvailabilityCollection)
          .doc(storeId)
          .set({
        'storeId': storeId,
        'stock': stock,
        'daysOfCover': daysOfCover,
        'isAvailable': isAvailable,
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Create new catalogue product (admin only)
  Future<String> createProduct(CatalogueProduct product) async {
    try {
      final docRef =
          await _firestore.collection(_productsCollection).add(product.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update catalogue product (admin only)
  Future<void> updateProduct(String productId, CatalogueProduct product) async {
    try {
      await _firestore
          .collection(_productsCollection)
          .doc(productId)
          .set(product.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Delete catalogue product (admin only)
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_productsCollection).doc(productId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
