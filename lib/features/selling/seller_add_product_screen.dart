import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coop_commerce/core/models/seller_models.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/providers/seller_providers.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class SellerAddProductScreen extends ConsumerStatefulWidget {
  const SellerAddProductScreen({super.key});

  @override
  ConsumerState<SellerAddProductScreen> createState() =>
      _SellerAddProductScreenState();
}

class _SellerAddProductScreenState
    extends ConsumerState<SellerAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _moqController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _category = 'agriculture';
  String _imageUrl = '';
  bool _isUploadingImage = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _moqController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Product')),
        body: const Center(child: Text('Please sign in to continue.')),
      );
    }

    final profileAsync = ref.watch(sellerProfileByUserIdProvider(user.id));

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Add Product')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Unable to load seller profile: $error'),
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Product')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'Set up your seller profile first before adding products.'),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Add Product'),
            backgroundColor: AppColors.surface,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Add a product to ${profile.businessName}',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Product name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'agriculture', child: Text('Agriculture')),
                    DropdownMenuItem(value: 'retail', child: Text('Retail')),
                    DropdownMenuItem(
                        value: 'manufacturing', child: Text('Manufacturing')),
                    DropdownMenuItem(
                        value: 'services', child: Text('Services')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price (NGN)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final parsed = int.tryParse((value ?? '').trim());
                          if (parsed == null || parsed < 0) {
                            return 'Invalid quantity';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _moqController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'MOQ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final parsed = int.tryParse((value ?? '').trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Invalid MOQ';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                  icon: _isUploadingImage
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined),
                  label: Text(
                    _imageUrl.isEmpty
                        ? 'Upload Product Image'
                        : 'Image Uploaded',
                  ),
                ),
                if (_imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _imageUrl,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _saveProduct(profile),
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _isUploadingImage = true);

      final selected = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (selected == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final file = File(selected.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('seller_products')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      if (!mounted) return;
      setState(() {
        _imageUrl = downloadUrl;
        _isUploadingImage = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    }
  }

  Future<void> _saveProduct(SellerProfile profile) async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image first')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final sellerService = ref.read(sellerServiceProvider);
      final product = SellerProduct(
        sellerId: user.id,
        sellerUserId: user.id,
        sellerProfileId: profile.id,
        productName: _nameController.text.trim(),
        category: _category,
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        moq: int.parse(_moqController.text.trim()),
        imageUrl: _imageUrl,
        description: _descriptionController.text.trim(),
        status: ProductApprovalStatus.pending,
        createdAt: DateTime.now(),
      );

      await sellerService.addProduct(product);

      ref.invalidate(
        sellerProductsForSellerProvider(
          (userId: user.id, sellerProfileId: profile.id),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product uploaded and submitted for review.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save product: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
