import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/core/providers/checkout_flow_provider.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/models/address.dart';

class CheckoutAddressScreen extends ConsumerStatefulWidget {
  const CheckoutAddressScreen({super.key});

  @override
  ConsumerState<CheckoutAddressScreen> createState() =>
      _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends ConsumerState<CheckoutAddressScreen> {
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _phoneController;
  Address? _selectedAddress;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _streetController.text.isNotEmpty &&
        _cityController.text.isNotEmpty &&
        _stateController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
  }

  Future<List<Address>> _loadAddresses(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();

      return doc.docs.map((d) {
        final data = d.data();
        return Address(
          id: d.id,
          userId: userId,
          type: data['type'] ?? 'home',
          addressLine1: data['addressLine1'] ?? '',
          addressLine2: data['addressLine2'],
          city: data['city'] ?? '',
          state: data['state'] ?? '',
          postalCode: data['postalCode'] ?? '',
          country: data['country'] ?? 'Nigeria',
          phoneNumber: data['phoneNumber'] ?? '',
          isDefault: data['isDefault'] ?? false,
          createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
          updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
        );
      }).toList();
    } catch (e) {
      // Return empty list if error - user can add address manually
      return [];
    }
  }

  void _proceedWithAddress() {
    if (_selectedAddress == null && !_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Address addressToUse = _selectedAddress!;
    if (_showForm && _isFormValid()) {
      final user = ref.read(currentUserProvider);
      addressToUse = Address(
        id: DateTime.now().toString(),
        userId: user?.id ?? '',
        type: 'home',
        addressLine1: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        postalCode: _zipController.text,
        country: 'Nigeria',
        phoneNumber: _phoneController.text,
        isDefault: true,
      );
    }

    ref.read(checkoutFlowProvider.notifier).setAddress(addressToUse);
    ref.read(checkoutFlowProvider.notifier).nextStep();
    context.push('/checkout/delivery');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // Require authentication for checkout
    if (user == null || user.id.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Please log in to proceed with checkout'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/signin'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Delivery Address'),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/cart');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: 0.33,
                  minHeight: 4,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Where should we deliver?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a saved address or add a new one',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Load and display saved addresses
              FutureBuilder<List<Address>>(
                future: _loadAddresses(user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final addresses = snapshot.data ?? [];

                  if (addresses.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved Addresses',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...addresses.map((address) {
                          bool isSelected = _selectedAddress?.id == address.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAddress = address;
                                _showForm = false;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey[400]!,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          address.type.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address.addressLine1,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${address.city}, ${address.state} ${address.postalCode}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (address.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

              // Option to add new address
              if (!_showForm)
                GestureDetector(
                  onTap: () {
                    setState(() => _showForm = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Add New Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Address Form (shown only when adding new address)
              if (_showForm) ...[  
                const SizedBox(height: 20),
                Text(
                  'Enter Address Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _streetController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Street Address *',
                    hintText: '123 Main Street',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'City *',
                          hintText: 'Lagos',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _stateController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'State *',
                          hintText: 'Lagos',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _zipController,
                  decoration: InputDecoration(
                    labelText: 'Postal Code',
                    hintText: '12345',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.mail_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: '+234 (0) 801 000 0000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedAddress != null || _isFormValid()
                      ? _proceedWithAddress
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedAddress != null || _isFormValid()
                        ? AppColors.primary
                        : Colors.grey[300],
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Continue to Delivery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedAddress != null || _isFormValid()
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
