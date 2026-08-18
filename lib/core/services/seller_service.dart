import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/seller_models.dart';

/// Service to manage seller operations and product listings
class SellerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, SellerProfile> _localProfileCacheByUserId = {};
  static const String _localProfileKeyPrefix = 'seller_profile_';

  String _localProfileKey(String userId) => '$_localProfileKeyPrefix$userId';

  Future<void> _persistLocalProfile(SellerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'id': profile.id,
      'userId': profile.userId,
      'businessName': profile.businessName,
      'sellerType': profile.sellerType,
      'sellingPath': profile.sellingPath,
      'country': profile.country,
      'category': profile.category,
      'targetCustomer': profile.targetCustomer.name,
      'isVerified': profile.isVerified,
      'createdAt': profile.createdAt.toIso8601String(),
      'approvedAt': profile.approvedAt?.toIso8601String(),
    };

    await prefs.setString(
        _localProfileKey(profile.userId), jsonEncode(payload));
  }

  Future<SellerProfile?> _readLocalProfile(String userId) async {
    if (_localProfileCacheByUserId.containsKey(userId)) {
      return _localProfileCacheByUserId[userId];
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localProfileKey(userId));
    SellerProfile? parseProfile(String encoded) {
      if (encoded.isEmpty) {
        return null;
      }

      try {
        final data = jsonDecode(encoded) as Map<String, dynamic>;
        return SellerProfile(
          id: data['id'] as String?,
          userId: (data['userId'] ?? userId) as String,
          businessName: (data['businessName'] ?? '') as String,
          sellerType: (data['sellerType'] ?? 'individual') as String,
          sellingPath: (data['sellingPath'] ?? 'member') as String,
          country: (data['country'] ?? 'Nigeria') as String,
          category: (data['category'] ?? '') as String,
          targetCustomer: TargetCustomer.values.firstWhere(
            (e) => e.name == (data['targetCustomer'] ?? 'individual'),
            orElse: () => TargetCustomer.individual,
          ),
          isVerified: (data['isVerified'] ?? false) as bool,
          createdAt: DateTime.tryParse((data['createdAt'] ?? '') as String) ??
              DateTime.now(),
          approvedAt: data['approvedAt'] != null
              ? DateTime.tryParse(data['approvedAt'] as String)
              : null,
        );
      } catch (_) {
        return null;
      }
    }

    if (raw != null && raw.isNotEmpty) {
      final directProfile = parseProfile(raw);
      if (directProfile != null) {
        _localProfileCacheByUserId[userId] = directProfile;
        return directProfile;
      }
    }

    // Never reuse another account's cached profile. A device may be shared,
    // and seller identity must remain bound to the authenticated Firebase uid.
    return null;
  }

  /// Create or update seller profile
  Future<SellerProfile> createSellerProfile(SellerProfile profile) async {
    try {
      // Use auth userId as document id for stable cross-device persistence.
      final docRef = _firestore.collection('sellers').doc(profile.userId);
      await docRef.set(profile.toFirestore(), SetOptions(merge: true));

      final savedProfile = SellerProfile(
        id: profile.userId,
        userId: profile.userId,
        businessName: profile.businessName,
        sellerType: profile.sellerType,
        sellingPath: profile.sellingPath,
        country: profile.country,
        category: profile.category,
        targetCustomer: profile.targetCustomer,
        isVerified: profile.isVerified,
        createdAt: profile.createdAt,
        approvedAt: profile.approvedAt,
      );

      _localProfileCacheByUserId[profile.userId] = savedProfile;
      await _persistLocalProfile(savedProfile);
      return savedProfile;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Keep onboarding flow functional even when Firestore writes are blocked.
        final localProfile = SellerProfile(
          id: 'local_${profile.userId}',
          userId: profile.userId,
          businessName: profile.businessName,
          sellerType: profile.sellerType,
          sellingPath: profile.sellingPath,
          country: profile.country,
          category: profile.category,
          targetCustomer: profile.targetCustomer,
          isVerified: profile.isVerified,
          createdAt: profile.createdAt,
          approvedAt: profile.approvedAt,
        );
        _localProfileCacheByUserId[profile.userId] = localProfile;
        await _persistLocalProfile(localProfile);
        return localProfile;
      }
      throw Exception('Failed to create seller profile: $e');
    } catch (e) {
      throw Exception('Failed to create seller profile: $e');
    }
  }

  /// Get seller profile by user ID
  Future<SellerProfile?> getSellerProfileByUserId(String userId) async {
    try {
      // Primary lookup for normalized schema where doc id == userId.
      final directDoc =
          await _firestore.collection('sellers').doc(userId).get();
      if (directDoc.exists) {
        final profile = SellerProfile.fromFirestore(directDoc);
        _localProfileCacheByUserId[userId] = profile;
        await _persistLocalProfile(profile);
        return profile;
      }

      // Legacy fallback for historical records created with auto-id.
      final query = await _firestore
          .collection('sellers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return await _readLocalProfile(userId);
      }

      final profile = SellerProfile.fromFirestore(query.docs.first);
      _localProfileCacheByUserId[userId] = profile;
      await _persistLocalProfile(profile);
      return profile;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Fall back to cached local profile instead of breaking seller dashboard.
        return await _readLocalProfile(userId);
      }
      throw Exception('Failed to get seller profile: $e');
    } catch (e) {
      throw Exception('Failed to get seller profile: $e');
    }
  }

  /// Get seller profile by seller ID
  Future<SellerProfile?> getSellerProfileById(String sellerId) async {
    try {
      final doc = await _firestore.collection('sellers').doc(sellerId).get();
      if (!doc.exists) return null;
      final profile = SellerProfile.fromFirestore(doc);
      _localProfileCacheByUserId[profile.userId] = profile;
      await _persistLocalProfile(profile);
      return profile;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        try {
          return _localProfileCacheByUserId.values.firstWhere(
            (profile) => profile.id == sellerId,
          );
        } catch (_) {
          return null;
        }
      }
      throw Exception('Failed to get seller profile: $e');
    } catch (e) {
      throw Exception('Failed to get seller profile: $e');
    }
  }

  /// List seller products
  Future<List<SellerProduct>> getSellerProducts(
    String sellerId, {
    ProductApprovalStatus? filterStatus,
  }) async {
    try {
      var query = _firestore
          .collection('seller_products')
          .where('sellerId', isEqualTo: sellerId);

      if (filterStatus != null) {
        query = query.where('status', isEqualTo: filterStatus.name);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => SellerProduct.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Keep the seller dashboard usable even when product list access is blocked.
        return const [];
      }
      throw Exception('Failed to get seller products: $e');
    } catch (e) {
      throw Exception('Failed to get seller products: $e');
    }
  }

  /// Get seller products with support for both legacy and normalized schemas.
  Future<List<SellerProduct>> getSellerProductsForSeller({
    required String userId,
    String? sellerProfileId,
    ProductApprovalStatus? filterStatus,
  }) async {
    try {
      final Map<String, SellerProduct> merged = {};

      Future<void> collectQuery(Query query) async {
        try {
          if (filterStatus != null) {
            query = query.where('status', isEqualTo: filterStatus.name);
          }
          final snapshot = await query.get();
          for (final doc in snapshot.docs) {
            try {
              final product = SellerProduct.fromFirestore(doc);
              merged[doc.id] = product;
            } catch (_) {
              // One historical malformed listing must not erase valid inventory.
            }
          }
        } on FirebaseException catch (error) {
          if (error.code != 'permission-denied' &&
              error.code != 'failed-precondition') {
            rethrow;
          }
        }
      }

      final sellerProductsCollection = _firestore.collection('seller_products');
      final marketplaceProductsCollection = _firestore.collection('products');

      // Seller listings stored directly in seller_products
      await collectQuery(
        sellerProductsCollection.where('sellerUserId', isEqualTo: userId),
      );
      await collectQuery(
        sellerProductsCollection.where('sellerId', isEqualTo: userId),
      );
      if (sellerProfileId != null && sellerProfileId.isNotEmpty) {
        await collectQuery(
          sellerProductsCollection.where('sellerProfileId',
              isEqualTo: sellerProfileId),
        );
      }
      await collectQuery(
        sellerProductsCollection.where('sellerUserIds', arrayContains: userId),
      );
      await collectQuery(
        sellerProductsCollection.where('sellerIds', arrayContains: userId),
      );
      await collectQuery(
        sellerProductsCollection.where('sellerProfileIds',
            arrayContains: userId),
      );

      // Some seller inventory exists in the marketplace products collection.
      await collectQuery(
        marketplaceProductsCollection.where('uploadedBy', isEqualTo: userId),
      );
      await collectQuery(
        marketplaceProductsCollection.where('sellerUserId', isEqualTo: userId),
      );
      await collectQuery(
        marketplaceProductsCollection.where('sellerId', isEqualTo: userId),
      );
      if (sellerProfileId != null && sellerProfileId.isNotEmpty) {
        await collectQuery(
          marketplaceProductsCollection.where('sellerProfileId',
              isEqualTo: sellerProfileId),
        );
      }
      await collectQuery(
        marketplaceProductsCollection.where('sellerUserIds',
            arrayContains: userId),
      );
      await collectQuery(
        marketplaceProductsCollection.where('sellerIds', arrayContains: userId),
      );
      await collectQuery(
        marketplaceProductsCollection.where('sellerProfileIds',
            arrayContains: userId),
      );

      final products = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    } on FirebaseException catch (e) {
      throw Exception('Failed to get seller products: $e');
    } catch (e) {
      throw Exception('Failed to get seller products: $e');
    }
  }

  /// Add new product
  Future<SellerProduct> addProduct(SellerProduct product) async {
    try {
      final batch = _firestore.batch();
      final sellerDocRef = _firestore.collection('seller_products').doc();
      final marketplaceDocRef =
          _firestore.collection('products').doc(sellerDocRef.id);
      final moderationDocRef =
          _firestore.collection('product_moderation').doc();

      batch.set(sellerDocRef, product.toFirestore());
      batch.set(
        marketplaceDocRef,
        product.toMarketplaceProductMap(productId: sellerDocRef.id),
      );
      batch.set(
        moderationDocRef,
        ProductModerationRequest(
          productId: sellerDocRef.id,
          sellerId: product.sellerUserId ?? product.sellerId,
          sellerUserId: product.sellerUserId,
          productName: product.productName,
          submittedAt: DateTime.now(),
          status: ProductApprovalStatus.pending,
        ).toFirestore(),
      );

      await batch.commit();

      return SellerProduct(
        id: sellerDocRef.id,
        sellerId: product.sellerId,
        sellerUserId: product.sellerUserId,
        sellerProfileId: product.sellerProfileId,
        productName: product.productName,
        category: product.category,
        price: product.price,
        retailPrice: product.retailPrice,
        wholesalePrice: product.wholesalePrice,
        audience: product.audience,
        quantity: product.quantity,
        moq: product.moq,
        imageUrl: product.imageUrl,
        description: product.description,
        status: ProductApprovalStatus.pending,
        createdAt: product.createdAt,
      );
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  /// Update existing product
  Future<void> updateProduct(SellerProduct product) async {
    if (product.id == null || product.id!.isEmpty) {
      throw Exception('Product id is required for update');
    }

    try {
      final batch = _firestore.batch();
      batch.update(
        _firestore.collection('seller_products').doc(product.id),
        product.toFirestore(),
      );
      batch.update(
        _firestore.collection('products').doc(product.id),
        product.toMarketplaceProductMap(productId: product.id!),
      );
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Approve product (admin only)
  Future<void> approveProduct(String productId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('seller_products').doc(productId), {
        'status': ProductApprovalStatus.approved.name,
        'approvedAt': Timestamp.now(),
      });
      batch.update(_firestore.collection('products').doc(productId), {
        'status': ProductApprovalStatus.approved.name,
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update moderation request
      final moderationQuery = await _firestore
          .collection('product_moderation')
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (moderationQuery.docs.isNotEmpty) {
        batch.update(moderationQuery.docs.first.reference, {
          'status': ProductApprovalStatus.approved.name,
          'reviewedAt': Timestamp.now(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to approve product: $e');
    }
  }

  /// Reject product with reason (admin only)
  Future<void> rejectProduct(String productId, String reason) async {
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('seller_products').doc(productId), {
        'status': ProductApprovalStatus.rejected.name,
        'rejectionReason': reason,
        'rejectedAt': Timestamp.now(),
      });
      batch.update(_firestore.collection('products').doc(productId), {
        'status': ProductApprovalStatus.rejected.name,
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update moderation request
      final moderationQuery = await _firestore
          .collection('product_moderation')
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (moderationQuery.docs.isNotEmpty) {
        batch.update(moderationQuery.docs.first.reference, {
          'status': ProductApprovalStatus.rejected.name,
          'reviewedAt': Timestamp.now(),
          'reviewNotes': reason,
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reject product: $e');
    }
  }

  /// Get product by ID
  Future<SellerProduct> getProductById(String productId) async {
    try {
      final doc =
          await _firestore.collection('seller_products').doc(productId).get();
      if (!doc.exists) {
        throw Exception('Product not found');
      }
      return SellerProduct.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  /// Get pending products for moderation (admin)
  Future<List<ProductModerationRequest>> getPendingModerations() async {
    try {
      final snapshot = await _firestore
          .collection('product_moderation')
          .where('status', isEqualTo: ProductApprovalStatus.pending.name)
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModerationRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending moderations: $e');
    }
  }
}
