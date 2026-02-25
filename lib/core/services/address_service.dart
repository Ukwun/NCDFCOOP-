import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/models/address.dart';
import 'package:coop_commerce/core/audit/audit_service.dart';
import 'package:coop_commerce/core/auth/role.dart';

/// Service for managing customer addresses
class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditLogService;

  static const String _addressesCollection = 'addresses';

  AddressService(this._auditLogService);

  /// Add a new address
  Future<Address> addAddress({
    required String userId,
    required String type,
    required String addressLine1,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required String phoneNumber,
    String? addressLine2,
    bool isDefault = false,
  }) async {
    try {
      final docId = _firestore.collection(_addressesCollection).doc().id;

      final address = Address(
        id: docId,
        userId: userId,
        type: type,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        phoneNumber: phoneNumber,
        isDefault: isDefault,
      );

      // If this is default, unset other defaults
      if (isDefault) {
        final userAddresses = await _firestore
            .collection(_addressesCollection)
            .where('user_id', isEqualTo: userId)
            .where('is_default', isEqualTo: true)
            .get();

        for (var doc in userAddresses.docs) {
          await doc.reference.update({'is_default': false});
        }
      }

      await _firestore
          .collection(_addressesCollection)
          .doc(docId)
          .set(address.toMap());

      // Log audit
      await _auditLogService.logAction(
        userId: userId,
        userName: userId,
        userRoles: [UserRole.consumer],
        eventType: AuditEventType.dataExported,
        resource: 'address',
        resourceId: docId,
        action: 'create',
        result: 'success',
        details: {'action': 'created', 'address_type': type},
      );

      return address;
    } catch (e) {
      // Error adding address
      rethrow;
    }
  }

  /// Get address by ID
  Future<Address?> getAddressById({
    required String addressId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_addressesCollection)
          .doc(addressId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      final address = Address.fromMap(data, doc.id);

      // Verify ownership
      if (address.userId != userId) {
        throw Exception('Unauthorized: Address does not belong to user');
      }

      return address;
    } catch (e) {
      // Error getting address
      rethrow;
    }
  }

  /// Get all addresses for user
  Future<List<Address>> getUserAddresses({
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_addressesCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('is_default', descending: true)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Address.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Error getting user addresses
      rethrow;
    }
  }

  /// Get default address for user
  Future<Address?> getDefaultAddress({
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_addressesCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_default', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return Address.fromMap(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      // Error getting default address
      rethrow;
    }
  }

  /// Update address
  Future<Address> updateAddress({
    required String addressId,
    required String userId,
    String? type,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phoneNumber,
    bool? isDefault,
  }) async {
    try {
      // Get existing address and verify ownership
      final existingAddress = await getAddressById(
        addressId: addressId,
        userId: userId,
      );

      if (existingAddress == null) {
        throw Exception('Address not found');
      }

      // Create updated address
      final updatedAddress = existingAddress.copyWith(
        type: type,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
        phoneNumber: phoneNumber,
        isDefault: isDefault,
      );

      // If setting as default, unset others
      if (isDefault == true) {
        final userAddresses = await _firestore
            .collection(_addressesCollection)
            .where('user_id', isEqualTo: userId)
            .where('is_default', isEqualTo: true)
            .get();

        for (var doc in userAddresses.docs) {
          if (doc.id != addressId) {
            await doc.reference.update({'is_default': false});
          }
        }
      }

      await _firestore
          .collection(_addressesCollection)
          .doc(addressId)
          .update(updatedAddress.toMap());

      // Log audit
      await _auditLogService.logAction(
        userId: userId,
        userName: userId,
        userRoles: [UserRole.consumer],
        eventType: AuditEventType.dataExported,
        resource: 'address',
        resourceId: addressId,
        action: 'update',
        result: 'success',
        details: {'action': 'updated'},
      );

      return updatedAddress;
    } catch (e) {
      // Error updating address
      rethrow;
    }
  }

  /// Delete address
  Future<void> deleteAddress({
    required String addressId,
    required String userId,
  }) async {
    try {
      // Verify ownership
      final address = await getAddressById(
        addressId: addressId,
        userId: userId,
      );

      if (address == null) {
        throw Exception('Address not found');
      }

      // If deleting default, set another as default
      if (address.isDefault) {
        final userAddresses = await _firestore
            .collection(_addressesCollection)
            .where('user_id', isEqualTo: userId)
            .get();

        for (var doc in userAddresses.docs) {
          if (doc.id != addressId) {
            await doc.reference.update({'is_default': true});
            break;
          }
        }
      }

      await _firestore.collection(_addressesCollection).doc(addressId).delete();

      // Log audit
      await _auditLogService.logAction(
        userId: userId,
        userName: userId,
        userRoles: [UserRole.consumer],
        eventType: AuditEventType.dataExported,
        resource: 'address',
        resourceId: addressId,
        action: 'delete',
        result: 'success',
        details: {'action': 'deleted'},
      );
    } catch (e) {
      // Error deleting address
      rethrow;
    }
  }

  /// Set address as default
  Future<void> setDefaultAddress({
    required String addressId,
    required String userId,
  }) async {
    try {
      // Get and verify address
      final address = await getAddressById(
        addressId: addressId,
        userId: userId,
      );

      if (address == null) {
        throw Exception('Address not found');
      }

      // Unset other defaults
      final userAddresses = await _firestore
          .collection(_addressesCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_default', isEqualTo: true)
          .get();

      for (var doc in userAddresses.docs) {
        if (doc.id != addressId) {
          await doc.reference.update({'is_default': false});
        }
      }

      // Set this as default
      await _firestore
          .collection(_addressesCollection)
          .doc(addressId)
          .update({'is_default': true});

      // Log audit
      await _auditLogService.logAction(
        userId: userId,
        userName: userId,
        userRoles: [UserRole.consumer],
        eventType: AuditEventType.dataExported,
        resource: 'address',
        resourceId: addressId,
        action: 'update',
        result: 'success',
        details: {'action': 'set_default'},
      );
    } catch (e) {
      // Error setting default address
      rethrow;
    }
  }

  /// Validate address format
  bool validateAddress(Address address) {
    if (address.addressLine1.isEmpty) return false;
    if (address.city.isEmpty) return false;
    if (address.state.isEmpty) return false;
    if (address.postalCode.isEmpty) return false;
    if (address.country.isEmpty) return false;
    if (address.phoneNumber.isEmpty) return false;

    // Basic postal code format check
    if (!RegExp(r'^[0-9]{5,6}$').hasMatch(address.postalCode)) {
      return false;
    }

    // Basic phone format check
    if (!RegExp(r'^[0-9]{10,}$').hasMatch(address.phoneNumber)) {
      return false;
    }

    return true;
  }
}
