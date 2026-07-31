import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class AdminProductModerationScreen extends StatefulWidget {
  const AdminProductModerationScreen({super.key});

  @override
  State<AdminProductModerationScreen> createState() =>
      _AdminProductModerationScreenState();
}

class _AdminProductModerationScreenState
    extends State<AdminProductModerationScreen> {
  late Future<List<Map<String, dynamic>>> _pending;
  final Set<String> _reviewing = {};

  @override
  void initState() {
    super.initState();
    _pending = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('listPendingSellerProducts')
        .call<Map<String, dynamic>>();
    final values = result.data['products'] as List? ?? const [];
    return values
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
  }

  void _refresh() => setState(() => _pending = _load());

  Future<void> _review(Map<String, dynamic> product, String decision) async {
    var note = '';
    if (decision == 'rejected') {
      final controller = TextEditingController();
      final submitted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject product'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Reason visible to the seller',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      note = controller.text.trim();
      controller.dispose();
      if (submitted != true || note.length < 3) return;
    }
    final id = product['id'].toString();
    setState(() => _reviewing.add(id));
    try {
      await FirebaseFunctions.instance
          .httpsCallable('reviewSellerProduct')
          .call<void>({'productId': id, 'decision': decision, 'note': note});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product $decision successfully.')),
      );
      _refresh();
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Review failed.')),
      );
    } finally {
      if (mounted) setState(() => _reviewing.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Product Approvals'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh approvals',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pending,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child:
                    Text('Unable to load product approvals: ${snapshot.error}'),
              ),
            );
          }
          final products = snapshot.data ?? const [];
          if (products.isEmpty) {
            return const Center(
                child: Text('No products are awaiting review.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              final id = product['id'].toString();
              final busy = _reviewing.contains(id);
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProductImage(product['imageUrl']?.toString() ?? ''),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    product['productName']?.toString() ??
                                        'Product',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                    '${product['category'] ?? 'Uncategorized'} • Qty ${product['quantity'] ?? 0}'),
                                Text(
                                    'Member NGN ${product['retailPrice'] ?? 0} • Wholesale NGN ${product['wholesalePrice'] ?? 0}'),
                                const SizedBox(height: 5),
                                Text(product['description']?.toString() ?? ''),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (busy)
                        const LinearProgressIndicator()
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _review(product, 'rejected'),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _review(product, 'approved'),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                              ),
                            ),
                          ],
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
}

class _ProductImage extends StatelessWidget {
  const _ProductImage(this.url);
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const SizedBox(
          width: 76, height: 76, child: Icon(Icons.image_outlined));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
            width: 76, height: 76, child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
