import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:coop_commerce/features/checkout/order_tracking_helpers.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerEarningsScreen extends ConsumerWidget {
  const SellerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('Sign in to view earnings.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Earnings & withdrawals')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('seller_earnings')
            .doc(user.id)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final available = (data['availableBalance'] as num?)?.toDouble() ?? 0;
          final pending = (data['pendingBalance'] as num?)?.toDouble() ?? 0;
          final lifetime = (data['lifetimeEarnings'] as num?)?.toDouble() ?? 0;
          final withdrawing =
              (data['pendingWithdrawal'] as num?)?.toDouble() ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B6B3A), Color(0xFF15965A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available to withdraw',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      'NGN ${available.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: available >= 1000
                          ? () => _showWithdrawalDialog(context, available)
                          : null,
                      icon: const Icon(Icons.account_balance_outlined),
                      label: const Text('Withdraw earnings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Metric(label: 'Pending settlement', value: pending),
                  _Metric(label: 'Withdrawal processing', value: withdrawing),
                  _Metric(label: 'Lifetime earnings', value: lifetime),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('seller_payout_accounts')
                    .doc(user.id)
                    .snapshots(),
                builder: (context, accountSnapshot) {
                  final account = accountSnapshot.data?.data();
                  final lastFour = (account?['accountNumber'] as String? ?? '');
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: Text(account == null
                          ? 'Add payout bank account'
                          : (account['accountName'] ?? 'Payout account')),
                      subtitle: Text(account == null
                          ? 'Required before requesting a withdrawal'
                          : '${account['bankName'] ?? account['bankCode'] ?? 'Bank'} · ••••${lastFour.length >= 4 ? lastFour.substring(lastFour.length - 4) : lastFour}'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _saveBankDetails(context, user.id, account),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Withdrawal history', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('seller_withdrawals')
                    .where('sellerId', isEqualTo: user.id)
                    .snapshots(),
                builder: (context, withdrawalSnapshot) {
                  final docs = withdrawalSnapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No withdrawals yet.'),
                      ),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final withdrawal = doc.data();
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: Text(
                            'NGN ${((withdrawal['amount'] as num?) ?? 0).toStringAsFixed(2)}',
                          ),
                          subtitle: Text(
                              'Status: ${withdrawal['status'] ?? 'pending'}'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showWithdrawalDialog(
    BuildContext context,
    double available,
  ) async {
    final amount = TextEditingController();
    final bankCode = TextEditingController();
    final accountNumber = TextEditingController();
    final accountName = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw to bank account'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (NGN)',
                    helperText:
                        'Available: NGN ${available.toStringAsFixed(2)}',
                  ),
                ),
                TextField(
                  controller: bankCode,
                  decoration: const InputDecoration(labelText: 'Bank code'),
                ),
                TextField(
                  controller: accountNumber,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Account number'),
                ),
                TextField(
                  controller: accountName,
                  decoration: const InputDecoration(labelText: 'Account name'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Submit withdrawal'),
          ),
        ],
      ),
    );
    if (submitted != true) return;

    final value = double.tryParse(amount.text.trim());
    final payoutError = validatePayoutDetails(
      bankName: 'Bank',
      bankCode: bankCode.text.trim(),
      accountNumber: accountNumber.text.trim(),
      accountName: accountName.text.trim(),
    );
    if (payoutError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(payoutError)),
        );
      }
      return;
    }
    if (value == null || value < 1000 || value > available) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Enter a valid available amount of at least NGN 1,000.')),
        );
      }
      return;
    }
    await FirebaseFunctions.instance
        .httpsCallable('requestSellerWithdrawal')
        .call({
      'amount': value,
      'bankCode': bankCode.text.trim(),
      'accountNumber': accountNumber.text.trim(),
      'accountName': accountName.text.trim(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal submitted for processing.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _saveBankDetails(
    BuildContext context,
    String sellerId,
    Map<String, dynamic>? existing,
  ) async {
    final bankName = TextEditingController(text: existing?['bankName']);
    final bankCode = TextEditingController(text: existing?['bankCode']);
    final accountNumber =
        TextEditingController(text: existing?['accountNumber']);
    final accountName = TextEditingController(text: existing?['accountName']);
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payout bank details'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankName,
                decoration: const InputDecoration(labelText: 'Bank name'),
              ),
              TextField(
                controller: bankCode,
                decoration: const InputDecoration(labelText: 'Bank code'),
              ),
              TextField(
                controller: accountNumber,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Account number'),
              ),
              TextField(
                controller: accountName,
                decoration: const InputDecoration(labelText: 'Account name'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save bank details'),
          ),
        ],
      ),
    );
    if (save != true) return;
    final payoutError = validatePayoutDetails(
      bankName: bankName.text.trim(),
      bankCode: bankCode.text.trim(),
      accountNumber: accountNumber.text.trim(),
      accountName: accountName.text.trim(),
    );
    if (payoutError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(payoutError)),
        );
      }
      return;
    }
    await FirebaseFirestore.instance
        .collection('seller_payout_accounts')
        .doc(sellerId)
        .set({
      'sellerId': sellerId,
      'bankName': bankName.text.trim(),
      'bankCode': bankCode.text.trim(),
      'accountNumber': accountNumber.text.trim(),
      'accountName': accountName.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout bank details saved.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 6),
                Text('NGN ${value.toStringAsFixed(2)}',
                    style: AppTextStyles.h4),
              ],
            ),
          ),
        ),
      );
}
