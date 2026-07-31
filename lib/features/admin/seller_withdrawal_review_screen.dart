import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SellerWithdrawalReviewScreen extends StatelessWidget {
  const SellerWithdrawalReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller withdrawal requests')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('seller_withdrawals')
            .where('assignedAdminEmail', isEqualTo: 'ukwun97@gmail.com')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Unable to load requests: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return const Center(
              child: Text('There are no pending withdrawal requests.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data();
              final amount = (data['amount'] as num?)?.toDouble() ?? 0;
              final account = data['accountNumber']?.toString() ?? '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['sellerName']?.toString().isNotEmpty == true
                            ? data['sellerName'].toString()
                            : 'Seller ${data['sellerId']}',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: 8),
                      Text('NGN ${amount.toStringAsFixed(2)}',
                          style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Text('${data['bankName']} • ${data['accountName']}'),
                      Text(account),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _review(
                                context,
                                doc.id,
                                'rejected',
                              ),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _review(
                                context,
                                doc.id,
                                'approved',
                              ),
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

  Future<void> _review(
    BuildContext context,
    String withdrawalId,
    String decision,
  ) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text('${decision == 'approved' ? 'Approve' : 'Reject'} request?'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Review note (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await FirebaseFunctions.instance
          .httpsCallable('reviewSellerWithdrawal')
          .call<void>({
        'withdrawalId': withdrawalId,
        'decision': decision,
        'note': noteController.text.trim(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Withdrawal $decision.')),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Review failed.')),
      );
    } finally {
      noteController.dispose();
    }
  }
}
