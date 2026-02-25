import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/core/providers/checkout_flow_provider.dart';

class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  ConsumerState<AddPaymentMethodScreen> createState() =>
      _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState
    extends ConsumerState<AddPaymentMethodScreen> {
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;
  late TextEditingController _cardHolderController;
  String _selectedPaymentType = 'credit_card';
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();
    _cardHolderController = TextEditingController();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_cardHolderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card holder name is required')),
      );
      return false;
    }

    if (_cardNumberController.text.replaceAll(' ', '').length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card number must be 16 digits')),
      );
      return false;
    }

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_expiryController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiry must be in MM/YY format')),
      );
      return false;
    }

    if (_cvvController.text.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CVV must be 3 digits')),
      );
      return false;
    }

    return true;
  }

  Future<void> _savePaymentMethod() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null || user.id.isEmpty) {
        throw 'User not authenticated';
      }

      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final lastFour = cardNumber.substring(cardNumber.length - 4);

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('payment_methods')
          .add({
        'type': _selectedPaymentType,
        'displayName':
            '${_selectedPaymentType == 'credit_card' ? 'Credit' : 'Debit'} Card - $lastFour',
        'lastFour': lastFour,
        'cardNumber': cardNumber, // In production, tokenize this!
        'expiryDate': _expiryController.text,
        'cardHolderName': _cardHolderController.text,
        'isDefault': _isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // If marked as default, unset other defaults
      if (_isDefault) {
        final batch = FirebaseFirestore.instance.batch();
        final methods = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .collection('payment_methods')
            .get();

        for (final doc in methods.docs) {
          if (doc.get('isDefault') == true) {
            batch.update(doc.reference, {'isDefault': false});
          }
        }
        await batch.commit();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment method added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding payment method: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    if (value.length > 16) value = value.substring(0, 16);
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    value = value.replaceAll('/', '');
    if (value.length > 4) value = value.substring(0, 4);
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null || user.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Payment Method')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Please log in to add payment methods'),
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
        title: const Text('Add Payment Method'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Preview
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedPaymentType == 'credit_card'
                              ? 'CREDIT CARD'
                              : 'DEBIT CARD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          _selectedPaymentType == 'credit_card'
                              ? 'VISA'
                              : 'MASTERCARD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _cardNumberController.text.isEmpty
                          ? '•••• •••• •••• ••••'
                          : _cardNumberController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _cardHolderController.text.isEmpty
                              ? 'CARD HOLDER NAME'
                              : _cardHolderController.text.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _expiryController.text.isEmpty
                              ? 'MM/YY'
                              : _expiryController.text,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Payment Type Selection
              Text(
                'Card Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Credit Card'),
                      selected: _selectedPaymentType == 'credit_card',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedPaymentType = 'credit_card');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Debit Card'),
                      selected: _selectedPaymentType == 'debit_card',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedPaymentType = 'debit_card');
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Fields
              Text(
                'Card Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _cardHolderController,
                decoration: InputDecoration(
                  labelText: 'Card Holder Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number *',
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                maxLength: 19,
                onChanged: (value) {
                  _cardNumberController.value = TextEditingValue(
                    text: _formatCardNumber(value),
                    selection: TextSelection.fromPosition(
                      TextPosition(offset: _formatCardNumber(value).length),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      decoration: InputDecoration(
                        labelText: 'Expiry Date *',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      onChanged: (value) {
                        _expiryController.value = TextEditingValue(
                          text: _formatExpiry(value),
                          selection: TextSelection.fromPosition(
                            TextPosition(offset: _formatExpiry(value).length),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV *',
                        hintText: '123',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Default Method Checkbox
              CheckboxListTile(
                title: const Text('Set as default payment method'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() => _isDefault = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePaymentMethod,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Add Payment Method'),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Security Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your card details are encrypted and secure',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
