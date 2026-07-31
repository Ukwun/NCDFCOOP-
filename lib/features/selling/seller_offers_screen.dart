import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerOffersScreen extends ConsumerWidget {
  const SellerOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sign in to continue.')));
    }
    final products = FirebaseFirestore.instance
        .collection('seller_products')
        .where('sellerUserId', isEqualTo: user.id)
        .snapshots();
    final offers = FirebaseFirestore.instance
        .collection('product_offers')
        .where('sellerId', isEqualTo: user.id)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Offers & Deals')),
      floatingActionButton: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: products,
        builder: (context, snapshot) {
          final approved = snapshot.data?.docs
                  .where((doc) => doc.data()['status'] == 'approved')
                  .toList() ??
              const [];
          return FloatingActionButton.extended(
            onPressed: () {
              if (snapshot.connectionState == ConnectionState.waiting) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loading your products…')),
                );
                return;
              }
              if (snapshot.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Your products could not be loaded. Please try again.',
                    ),
                  ),
                );
                return;
              }
              if (approved.isEmpty) {
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('No approved product yet'),
                    content: const Text(
                      'Offers can only be created for products approved by the CoopX administrator. Your submitted products remain visible on your dashboard while they are reviewed.',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Understood'),
                      ),
                    ],
                  ),
                );
                return;
              }
              _showOfferForm(context, approved);
            },
            icon: const Icon(Icons.local_offer_outlined),
            label: const Text('Create offer'),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: offers,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Unable to load offers: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs
            ..sort((a, b) {
              final aTime = a.data()['endsAt'] as Timestamp?;
              final bTime = b.data()['endsAt'] as Timestamp?;
              return (bTime?.millisecondsSinceEpoch ?? 0)
                  .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
            });
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Create your first deal for an approved product. Active deals will appear automatically to eligible buyers.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final endsAt = (data['endsAt'] as Timestamp?)?.toDate();
              final active = data['active'] == true &&
                  endsAt != null &&
                  endsAt.isAfter(DateTime.now());
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: .12),
                    child: const Icon(Icons.percent, color: AppColors.primary),
                  ),
                  title: Text(data['title']?.toString() ?? 'Product offer'),
                  subtitle: Text(
                    '${data['productName'] ?? ''}\n${data['audience'] ?? 'both'} • ends ${endsAt == null ? '—' : '${endsAt.day}/${endsAt.month}/${endsAt.year}'}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(data['discountPercent'] as num?)?.toStringAsFixed(0) ?? '0'}% OFF',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (active)
                        InkWell(
                          onTap: () => _deactivate(context, docs[index].id),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text('End offer',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showOfferForm(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) async {
    var productId = products.first.id;
    var audience = 'both';
    var start = DateTime.now();
    var end = DateTime.now().add(const Duration(days: 7));
    final title = TextEditingController();
    final discount = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create product offer'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: productId,
                      decoration: const InputDecoration(labelText: 'Product'),
                      items: products
                          .map((doc) => DropdownMenuItem(
                                value: doc.id,
                                child: Text(
                                  doc.data()['productName']?.toString() ??
                                      'Product',
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => productId = value ?? productId,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: title,
                      decoration:
                          const InputDecoration(labelText: 'Offer title'),
                      validator: (value) => (value?.trim().length ?? 0) < 3
                          ? 'Enter an offer title'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: discount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount percentage',
                        suffixText: '%',
                      ),
                      validator: (value) {
                        final number = double.tryParse(value ?? '');
                        return number == null || number < 1 || number > 80
                            ? 'Enter a discount from 1% to 80%'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: audience,
                      decoration:
                          const InputDecoration(labelText: 'Visible to'),
                      items: const [
                        DropdownMenuItem(
                            value: 'both', child: Text('Members & Wholesale')),
                        DropdownMenuItem(
                            value: 'members', child: Text('Members only')),
                        DropdownMenuItem(
                            value: 'wholesale', child: Text('Wholesale only')),
                      ],
                      onChanged: (value) => audience = value ?? audience,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Offer end date'),
                      subtitle: Text('${end.day}/${end.month}/${end.year}'),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDate: end,
                        );
                        if (picked != null) {
                          setState(() => end = DateTime(
                              picked.year, picked.month, picked.day, 23, 59));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Publish offer'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || !context.mounted) return;
    try {
      await FirebaseFunctions.instance
          .httpsCallable('upsertSellerProductOffer')
          .call<void>({
        'productId': productId,
        'title': title.text.trim(),
        'discountPercent': double.parse(discount.text),
        'audience': audience,
        'startsAtMillis': start.millisecondsSinceEpoch,
        'endsAtMillis': end.millisecondsSinceEpoch,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer published to eligible buyers.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not publish offer.')),
      );
    } finally {
      title.dispose();
      discount.dispose();
    }
  }

  Future<void> _deactivate(BuildContext context, String productId) async {
    await FirebaseFunctions.instance
        .httpsCallable('deactivateSellerProductOffer')
        .call<void>({'productId': productId});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Offer ended.')));
  }
}
