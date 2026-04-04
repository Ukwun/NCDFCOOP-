import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seller_models.dart';

/// Service to manage seller operations and product listings
class SellerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or update seller profile
  Future<SellerProfile> createSellerProfile(SellerProfile profile) async {
    try {
      final docRef =
          await _firestore.collection('sellers').add(profile.toFirestore());

      return SellerProfile(
        id: docRef.id,
        userId: profile.userId,
        businessName: profile.businessName,
        sellerType: profile.sellerType,
        country: profile.country,
        category: profile.category,
        targetCustomer: profile.targetCustomer,
        isVerified: profile.isVerified,
        createdAt: profile.createdAt,
        approvedAt: profile.approvedAt,
      );
    } catch (e) {
      throw Exception('Failed to create seller profile: $e');
    }
  }

  /// Get seller profile by user ID
  Future<SellerProfile?> getSellerProfileByUserId(String userId) async {
    try {
      final query = await _firestore
          .collection('sellers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return SellerProfile.fromFirestore(query.docs.first);
    } catch (e) {
      throw Exception('Failed to get seller profile: $e');
    }
  }

  /// Get seller profile by seller ID
  Future<SellerProfile?> getSellerProfileById(String sellerId) async {
    try {
      final doc = await _firestore.collection('sellers').doc(sellerId).get();
      if (!doc.exists) return null;
      return SellerProfile.fromFirestore(doc);
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
    } catch (e) {
      throw Exception('Failed to get seller products: $e');
    }
  }

  /// Add new product
  Future<SellerProduct> addProduct(SellerProduct product) async {
    try {
      final docRef = await _firestore
          .collection('seller_products')
          .add(product.toFirestore());

      // Create moderation request
      await _firestore.collection('product_moderation').add(
            ProductModerationRequest(
              productId: docRef.id,
              sellerId: product.sellerId,
              productName: product.productName,
              submittedAt: DateTime.now(),
              status: ProductApprovalStatus.pending,
            ).toFirestore(),
          );

      return SellerProduct(
        id: docRef.id,
        sellerId: product.sellerId,
        productName: product.productName,
        category: product.category,
        price: product.price,
        quantity: product.quantity,
        moq: product.moq,
        imageUrl: product.imageUrl,
        description: product.description,
        status: ProductApprovalStatus.pending,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  /// Approve product (admin only)
  Future<void> approveProduct(String productId) async {
    try {
      await _firestore.collection('seller_products').doc(productId).update({
        'status': ProductApprovalStatus.approved.name,
        'approvedAt': Timestamp.now(),
      });

      // Update moderation request
      final moderationQuery = await _firestore
          .collection('product_moderation')
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (moderationQuery.docs.isNotEmpty) {
        await moderationQuery.docs.first.reference.update({
          'status': ProductApprovalStatus.approved.name,
          'reviewedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Failed to approve product: $e');
    }
  }

  /// Reject product with reason (admin only)
  Future<void> rejectProduct(String productId, String reason) async {
    try {
      await _firestore.collection('seller_products').doc(productId).update({
        'status': ProductApprovalStatus.rejected.name,
        'rejectionReason': reason,
        'rejectedAt': Timestamp.now(),
      });

      // Update moderation request
      final moderationQuery = await _firestore
          .collection('product_moderation')
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (moderationQuery.docs.isNotEmpty) {
        await moderationQuery.docs.first.reference.update({
          'status': ProductApprovalStatus.rejected.name,
          'reviewedAt': Timestamp.now(),
          'reviewNotes': reason,
        });
      }
    } catch (e) {
      throw Exception('Failed to reject product: $e');
    }
  }

  /// Get product by ID
  Future<SellerProduct?> getProductById(String productId) async {
    try {
      final doc =
          await _firestore.collection('seller_products').doc(productId).get();
      if (!doc.exists) return null;
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
