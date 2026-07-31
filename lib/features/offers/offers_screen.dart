import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);
    final allowedAudience =
        role == UserRole.wholesaleBuyer ? 'wholesale' : 'members';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offers & Deals'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search live deals',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('product_offers')
                  .where('active', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Unable to load deals: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final now = DateTime.now();
                final offers = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final startsAt = (data['startsAt'] as Timestamp?)?.toDate();
                  final endsAt = (data['endsAt'] as Timestamp?)?.toDate();
                  final audience = data['audience']?.toString() ?? 'both';
                  final searchable =
                      '${data['title']} ${data['productName']}'.toLowerCase();
                  return (startsAt == null || !startsAt.isAfter(now)) &&
                      endsAt != null &&
                      endsAt.isAfter(now) &&
                      (audience == 'both' || audience == allowedAudience) &&
                      (_query.isEmpty || searchable.contains(_query));
                }).toList()
                  ..sort((a, b) {
                    final aEnd = a.data()['endsAt'] as Timestamp?;
                    final bEnd = b.data()['endsAt'] as Timestamp?;
                    return (aEnd?.millisecondsSinceEpoch ?? 0)
                        .compareTo(bEnd?.millisecondsSinceEpoch ?? 0);
                  });
                if (offers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'There are no active offers for your account right now.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = offers[index].data();
                    final image = data['productImageUrl']?.toString() ?? '';
                    final endsAt = (data['endsAt'] as Timestamp).toDate();
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.pushNamed(
                        'product-detail',
                        pathParameters: {
                          'productId': data['productId'].toString(),
                        },
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: .25),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: image.isEmpty
                                  ? Container(
                                      width: 82,
                                      height: 82,
                                      color: AppColors.background,
                                      child: const Icon(Icons.local_offer),
                                    )
                                  : Image.network(
                                      image,
                                      width: 82,
                                      height: 82,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title']?.toString() ?? 'Deal',
                                    style: AppTextStyles.h4,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(data['productName']?.toString() ?? ''),
                                  const SizedBox(height: 7),
                                  Text(
                                    'Ends ${endsAt.day}/${endsAt.month}/${endsAt.year}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${(data['discountPercent'] as num).toStringAsFixed(0)}%\nOFF',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
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
          ),
        ],
      ),
    );
  }
}
