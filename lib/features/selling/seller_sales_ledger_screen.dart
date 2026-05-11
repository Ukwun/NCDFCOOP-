import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class SellerSalesLedgerScreen extends ConsumerStatefulWidget {
  const SellerSalesLedgerScreen({super.key});

  @override
  ConsumerState<SellerSalesLedgerScreen> createState() =>
      _SellerSalesLedgerScreenState();
}

class _SellerSalesLedgerScreenState
    extends ConsumerState<SellerSalesLedgerScreen> {
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _loadOrders() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return [];
    }

    try {
      final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

      Future<void> collect(Query<Map<String, dynamic>> query) async {
        final snapshot = await query.limit(100).get();
        for (final doc in snapshot.docs) {
          merged[doc.id] = doc;
        }
      }

      final Query<Map<String, dynamic>> collection =
          FirebaseFirestore.instance.collection('orders');

      await collect(
        collection
            .where('sellerUserId', isEqualTo: user.id)
            .orderBy('createdAt', descending: true),
      );
      await collect(
        collection
            .where('sellerId', isEqualTo: user.id)
            .orderBy('createdAt', descending: true),
      );
      await collect(
        collection
            .where('sellerProfileId', isEqualTo: user.id)
            .orderBy('createdAt', descending: true),
      );
      await collect(
        collection
            .where('sellerUserIds', arrayContains: user.id)
            .orderBy('createdAt', descending: true),
      );
      await collect(
        collection
            .where('sellerIds', arrayContains: user.id)
            .orderBy('createdAt', descending: true),
      );
      await collect(
        collection
            .where('sellerProfileIds', arrayContains: user.id)
            .orderBy('createdAt', descending: true),
      );

      final docs = merged.values.toList()
        ..sort((a, b) {
          final aCreated = (a.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bCreated = (b.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bCreated.compareTo(aCreated);
        });
      return docs;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return [];
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sales Ledger'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _ordersFuture = _loadOrders();
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    const Text('Unable to load seller sales ledger.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _ordersFuture = _loadOrders();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data ?? [];
          final totalSales = docs.length;
          final totalRevenue = docs.fold<double>(0, (sum, doc) {
            final amount = (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
            return sum + amount;
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Orders',
                      value: totalSales.toString(),
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Revenue',
                      value: 'NGN ${totalRevenue.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Transactions', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'No sales records yet. Once orders are linked to your seller account, they will appear here.',
                  ),
                )
              else
                ...docs.map((doc) {
                  final data = doc.data();
                  final orderId = data['orderId']?.toString() ?? doc.id;
                  final status = data['status']?.toString() ?? 'unknown';
                  final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.shopping_bag_outlined,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(orderId, style: AppTextStyles.labelLarge),
                              const SizedBox(height: 4),
                              Text(
                                'Status: $status',
                                style: AppTextStyles.bodySmall,
                              ),
                              if (createdAt != null)
                                Text(
                                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textLight,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          'NGN ${amount.toStringAsFixed(0)}',
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
