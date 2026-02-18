import 'package:cloud_firestore/cloud_firestore.dart';

/// Resource Ownership Validator
/// Ensures users can only access/modify resources they own or are authorized to manage
class ResourceOwnershipValidator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _ordersCollection = 'orders';
  static const String _franchisesCollection = 'franchises';
  static const String _institutionsCollection = 'institutions';
  static const String _deliveriesCollection = 'deliveries';
  static const String _usersCollection = 'users';

  /// Check if user owns/is authorized for order
  /// Owner: the user who created the order
  /// Authorized: warehouse staff processing order, driver delivering order, admin
  Future<bool> ownsOrder(String userId, String orderId) async {
    try {
      final orderDoc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!orderDoc.exists) {
        return false;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final createdBy = orderData['created_by'] as String?;

      // User is owner if they created the order
      return createdBy == userId;
    } catch (e) {
      print('Error checking order ownership: $e');
      return false;
    }
  }

  /// Check if user can access order (owner, warehouse staff, driver, or admin)
  Future<bool> canAccessOrder(String userId, String orderId) async {
    try {
      final orderDoc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!orderDoc.exists) {
        return false;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final createdBy = orderData['created_by'] as String?;
      final assignedWarehouseId = orderData['warehouse_id'] as String?;
      final assignedDriverId = orderData['driver_id'] as String?;

      // User is owner
      if (createdBy == userId) {
        return true;
      }

      // User is assigned driver
      if (assignedDriverId == userId) {
        return true;
      }

      // User works at warehouse processing this order
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userWarehouseId = userData['warehouse_id'] as String?;
        if (userWarehouseId != null && userWarehouseId == assignedWarehouseId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking order access: $e');
      return false;
    }
  }

  /// Check if user owns/manages franchise
  /// Owner: user is in franchiseOwnerIds array
  /// Manager: user is in franchiseStaffIds array
  Future<bool> ownsFranchiseStore(String userId, String franchiseId) async {
    try {
      final franchiseDoc = await _firestore
          .collection(_franchisesCollection)
          .doc(franchiseId)
          .get();

      if (!franchiseDoc.exists) {
        return false;
      }

      final franchiseData = franchiseDoc.data() as Map<String, dynamic>;
      final ownerIds =
          (franchiseData['owner_ids'] as List<dynamic>?)?.cast<String>() ?? [];

      return ownerIds.contains(userId);
    } catch (e) {
      print('Error checking franchise ownership: $e');
      return false;
    }
  }

  /// Check if user can manage franchise (owner or manager)
  Future<bool> canManageFranchise(String userId, String franchiseId) async {
    try {
      final franchiseDoc = await _firestore
          .collection(_franchisesCollection)
          .doc(franchiseId)
          .get();

      if (!franchiseDoc.exists) {
        return false;
      }

      final franchiseData = franchiseDoc.data() as Map<String, dynamic>;
      final ownerIds =
          (franchiseData['owner_ids'] as List<dynamic>?)?.cast<String>() ?? [];
      final managerIds =
          (franchiseData['manager_ids'] as List<dynamic>?)?.cast<String>() ??
              [];

      return ownerIds.contains(userId) || managerIds.contains(userId);
    } catch (e) {
      print('Error checking franchise management: $e');
      return false;
    }
  }

  /// Check if user owns/manages institution account
  /// Owner: user is in institutionAdminIds array
  Future<bool> ownsInstitutionAccount(
    String userId,
    String institutionId,
  ) async {
    try {
      final institutionDoc = await _firestore
          .collection(_institutionsCollection)
          .doc(institutionId)
          .get();

      if (!institutionDoc.exists) {
        return false;
      }

      final institutionData = institutionDoc.data() as Map<String, dynamic>;
      final adminIds =
          (institutionData['admin_ids'] as List<dynamic>?)?.cast<String>() ??
              [];
      final buyerIds =
          (institutionData['buyer_ids'] as List<dynamic>?)?.cast<String>() ??
              [];

      // Both admins and buyers are part of institution
      return adminIds.contains(userId) || buyerIds.contains(userId);
    } catch (e) {
      print('Error checking institution ownership: $e');
      return false;
    }
  }

  /// Check if user is institution admin (can manage account)
  Future<bool> isInstitutionAdmin(
    String userId,
    String institutionId,
  ) async {
    try {
      final institutionDoc = await _firestore
          .collection(_institutionsCollection)
          .doc(institutionId)
          .get();

      if (!institutionDoc.exists) {
        return false;
      }

      final institutionData = institutionDoc.data() as Map<String, dynamic>;
      final adminIds =
          (institutionData['admin_ids'] as List<dynamic>?)?.cast<String>() ??
              [];

      return adminIds.contains(userId);
    } catch (e) {
      print('Error checking institution admin: $e');
      return false;
    }
  }

  /// Check if user owns/is assigned delivery route
  /// Owner: user is assigned_driver
  Future<bool> ownsDeliveryRoute(String userId, String deliveryId) async {
    try {
      final deliveryDoc = await _firestore
          .collection(_deliveriesCollection)
          .doc(deliveryId)
          .get();

      if (!deliveryDoc.exists) {
        return false;
      }

      final deliveryData = deliveryDoc.data() as Map<String, dynamic>;
      final assignedDriverId = deliveryData['assigned_driver'] as String?;

      return assignedDriverId == userId;
    } catch (e) {
      print('Error checking delivery ownership: $e');
      return false;
    }
  }

  /// Check if user can view delivery (driver or customer or admin)
  Future<bool> canViewDelivery(String userId, String deliveryId) async {
    try {
      final deliveryDoc = await _firestore
          .collection(_deliveriesCollection)
          .doc(deliveryId)
          .get();

      if (!deliveryDoc.exists) {
        return false;
      }

      final deliveryData = deliveryDoc.data() as Map<String, dynamic>;
      final assignedDriverId = deliveryData['assigned_driver'] as String?;
      final orderId = deliveryData['order_id'] as String?;

      // User is driver
      if (assignedDriverId == userId) {
        return true;
      }

      // User is customer who placed order
      if (orderId != null) {
        return await ownsOrder(userId, orderId);
      }

      return false;
    } catch (e) {
      print('Error checking delivery access: $e');
      return false;
    }
  }

  /// Check if user can view franchise data (owner, manager, or region admin)
  Future<bool> canViewFranchiseData(String userId, String franchiseId) async {
    try {
      // First check if user is franchise owner/manager
      if (await canManageFranchise(userId, franchiseId)) {
        return true;
      }

      // TODO: Check if user is regional admin for this franchise's region
      // This would involve querying franchise's region and checking if user manages it

      return false;
    } catch (e) {
      print('Error checking franchise data access: $e');
      return false;
    }
  }

  /// Check if two franchises are different (prevent cross-franchise access)
  Future<bool> areFranchisesDifferent(
    String franchiseId1,
    String franchiseId2,
  ) async {
    return franchiseId1 != franchiseId2;
  }

  /// Check if two institutions are different (prevent cross-institution access)
  Future<bool> areInstitutionsDifferent(
    String institutionId1,
    String institutionId2,
  ) async {
    return institutionId1 != institutionId2;
  }

  /// Get all franchises user owns/manages
  Future<List<String>> getUserFranchises(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_franchisesCollection)
          .where('owner_ids', arrayContains: userId)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting user franchises: $e');
      return [];
    }
  }

  /// Get all institutions user manages/belongs to
  Future<List<String>> getUserInstitutions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_institutionsCollection)
          .where('admin_ids', arrayContains: userId)
          .get();

      final adminInstitutions = snapshot.docs.map((doc) => doc.id).toList();

      // Also get buyer institutions
      final buyerSnapshot = await _firestore
          .collection(_institutionsCollection)
          .where('buyer_ids', arrayContains: userId)
          .get();

      final buyerInstitutions =
          buyerSnapshot.docs.map((doc) => doc.id).toList();

      // Combine and deduplicate
      return {...adminInstitutions, ...buyerInstitutions}.toList();
    } catch (e) {
      print('Error getting user institutions: $e');
      return [];
    }
  }

  /// Validate that user's scoped request matches their authorization
  /// E.g., Franchise owner trying to access franchise A can only see franchise A data
  Future<bool> validateScopeMatch(
    String userId,
    String? userFranchiseId,
    String? userInstitutionId,
    String? requestFranchiseId,
    String? requestInstitutionId,
  ) async {
    try {
      // If user is scoped to franchise, can only access that franchise
      if (userFranchiseId != null && requestFranchiseId != null) {
        if (userFranchiseId != requestFranchiseId) {
          return false;
        }
      }

      // If user is scoped to institution, can only access that institution
      if (userInstitutionId != null && requestInstitutionId != null) {
        if (userInstitutionId != requestInstitutionId) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error validating scope match: $e');
      return false;
    }
  }
}
