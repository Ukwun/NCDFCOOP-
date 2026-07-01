import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class Address {
  final String id;
  final String type;
  final String street;
  final String city;
  final String zipCode;
  final String phone;
  bool _isDefault;

  Address({
    required this.id,
    required this.type,
    required this.street,
    required this.city,
    required this.zipCode,
    required this.phone,
    required bool isDefault,
  }) : _isDefault = isDefault;

  bool get isDefault => _isDefault;

  set isDefault(bool value) {
    _isDefault = value;
  }

  factory Address.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Address(
      id: doc.id,
      type: (data['type'] ?? 'Home').toString(),
      street: (data['street'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      zipCode: (data['zipCode'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      isDefault: data['isDefault'] == true,
    );
  }
}

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  Stream<List<Address>> _addressesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(Address.fromFirestore).toList();
      list.sort((a, b) {
        if (a.isDefault == b.isDefault) return a.type.compareTo(b.type);
        return a.isDefault ? -1 : 1;
      });
      return list;
    });
  }

  Future<void> _setAsDefault(String userId, String id) async {
    final addressesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses');

    final snapshot = await addressesRef.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == id});
    }

    await batch.commit();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _removeAddress(String userId, String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(id)
        .delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _editAddress(String userId, Address address) async {
    final updated = await _showAddressDialog(initial: address);
    if (updated == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .update({
      'type': updated.type,
      'street': updated.street,
      'city': updated.city,
      'zipCode': updated.zipCode,
      'phone': updated.phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${updated.type} address updated'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addNewAddress(String userId, List<Address> existing) async {
    final created = await _showAddressDialog();
    if (created == null) return;

    final shouldBeDefault = existing.isEmpty;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .add({
      'type': created.type,
      'street': created.street,
      'city': created.city,
      'zipCode': created.zipCode,
      'phone': created.phone,
      'isDefault': shouldBeDefault,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${created.type} address added'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<Address?> _showAddressDialog({Address? initial}) async {
    final typeController = TextEditingController(text: initial?.type ?? 'Home');
    final streetController = TextEditingController(text: initial?.street ?? '');
    final cityController = TextEditingController(text: initial?.city ?? '');
    final zipController = TextEditingController(text: initial?.zipCode ?? '');
    final phoneController = TextEditingController(text: initial?.phone ?? '');

    final result = await showDialog<Address>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initial == null ? 'Add Address' : 'Edit Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: streetController,
                  decoration: const InputDecoration(labelText: 'Street'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: zipController,
                  decoration: const InputDecoration(labelText: 'Zip Code'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final type = typeController.text.trim();
                final street = streetController.text.trim();
                final city = cityController.text.trim();
                final zip = zipController.text.trim();
                final phone = phoneController.text.trim();

                if (type.isEmpty ||
                    street.isEmpty ||
                    city.isEmpty ||
                    zip.isEmpty ||
                    phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please complete all address fields'),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  Address(
                    id: initial?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    type: type,
                    street: street,
                    city: city,
                    zipCode: zip,
                    phone: phone,
                    isDefault: initial?.isDefault ?? false,
                  ),
                );
              },
              child: Text(initial == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );

    typeController.dispose();
    streetController.dispose();
    cityController.dispose();
    zipController.dispose();
    phoneController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Addresses')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, color: AppColors.textLight, size: 40),
                const SizedBox(height: 10),
                Text(
                  'Please sign in to manage addresses.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Address>>(
        stream: _addressesStream(userId),
        builder: (context, snapshot) {
          final addresses = snapshot.data ?? const <Address>[];

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                _buildAddressesList(addresses, userId),
                _buildAddButton(
                  onTap: () => _addNewAddress(userId, addresses),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:45',
                style: AppTextStyles.h4.copyWith(color: AppColors.surface),
              ),
              Row(
                spacing: 6,
                children: [
                  _buildStatusIcon('assets/icons/signal.png'),
                  _buildStatusIcon('assets/icons/wifi.png'),
                  _buildStatusIcon('assets/icons/battery.png'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Addresses',
                style: AppTextStyles.h2.copyWith(color: AppColors.surface),
              ),
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.surface,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String assetPath) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.muted, width: 0.5),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressesList(List<Address> addresses, String userId) {
    if (addresses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off_outlined,
                color: AppColors.textLight, size: 36),
            const SizedBox(height: 8),
            Text(
              'No saved addresses yet',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: addresses.map((address) {
          return _buildAddressCard(address, userId);
        }).toList(),
      ),
    );
  }

  Widget _buildAddressCard(Address address, String userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: address.isDefault
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.border,
          width: address.isDefault ? 2 : 1,
        ),
        boxShadow: AppShadows.smList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.type,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.city,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (address.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'Default',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Address Details
          Text(
            address.street,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address.city}, ${address.zipCode}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            address.phone,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Actions
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _editAddress(userId, address),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      'Edit',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _setAsDefault(userId, address.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: address.isDefault
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      'Set as Default',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: address.isDefault
                            ? AppColors.surface
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _removeAddress(userId, address.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton({required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              Text(
                'Add New Address',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
