import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerWithdrawalScreen extends ConsumerStatefulWidget {
  const SellerWithdrawalScreen({super.key});

  @override
  ConsumerState<SellerWithdrawalScreen> createState() =>
      _SellerWithdrawalScreenState();
}

class _SellerWithdrawalScreenState
    extends ConsumerState<SellerWithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _bankName = TextEditingController();
  final _bankCode = TextEditingController();
  final _accountNumber = TextEditingController();
  final _accountName = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAccount();
  }

  Future<void> _loadSavedAccount() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('seller_payout_accounts')
        .doc(user.id)
        .get();
    final data = snapshot.data();
    if (data == null || !mounted) return;
    _bankName.text = data['bankName']?.toString() ?? '';
    _bankCode.text = data['bankCode']?.toString() ?? '';
    _accountNumber.text = data['accountNumber']?.toString() ?? '';
    _accountName.text = data['accountName']?.toString() ?? '';
  }

  @override
  void dispose() {
    _amount.dispose();
    _bankName.dispose();
    _bankCode.dispose();
    _accountNumber.dispose();
    _accountName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sign in to continue.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw seller earnings')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('seller_earnings')
            .doc(user.id)
            .snapshots(),
        builder: (context, snapshot) {
          final available = (snapshot.data?.data()?['availableBalance'] as num?)
                  ?.toDouble() ??
              0;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available balance',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(
                      'NGN ${available.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Requests are securely sent to Ukwun97@gmail.com for review.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(
                      controller: _amount,
                      label: 'Amount (NGN)',
                      icon: Icons.payments_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');
                        if (amount == null || amount < 1000) {
                          return 'Minimum withdrawal is NGN 1,000';
                        }
                        if (amount > available) {
                          return 'Amount exceeds your available balance';
                        }
                        return null;
                      },
                    ),
                    _field(
                      controller: _bankName,
                      label: 'Bank name',
                      icon: Icons.account_balance_outlined,
                    ),
                    _field(
                      controller: _bankCode,
                      label: 'Bank code',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          RegExp(r'^\d{3,6}$').hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Enter the 3–6 digit bank code',
                    ),
                    _field(
                      controller: _accountNumber,
                      label: 'Account number',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          RegExp(r'^\d{10}$').hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Enter a valid 10-digit account number',
                    ),
                    _field(
                      controller: _accountName,
                      label: 'Account name',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text('Request withdrawal'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Request history', style: AppTextStyles.h4),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('seller_withdrawals')
                    .where('sellerId', isEqualTo: user.id)
                    .orderBy('createdAt', descending: true)
                    .limit(25)
                    .snapshots(),
                builder: (context, history) {
                  final docs = history.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Text('No withdrawal requests yet.');
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data();
                      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                      final status = data['status']?.toString() ?? 'pending';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.account_balance_wallet),
                          title: Text('NGN ${amount.toStringAsFixed(2)}'),
                          subtitle: Text(
                            '${data['bankName'] ?? ''} ••••${(data['accountNumber'] ?? '').toString().padLeft(4).substring((data['accountNumber'] ?? '').toString().padLeft(4).length - 4)}',
                          ),
                          trailing: Chip(label: Text(status.toUpperCase())),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ??
            (value) =>
                (value?.trim().isEmpty ?? true) ? '$label is required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('requestSellerWithdrawal');
      await callable.call<void>({
        'amount': double.parse(_amount.text.trim()),
        'bankName': _bankName.text.trim(),
        'bankCode': _bankCode.text.trim(),
        'accountNumber': _accountNumber.text.trim(),
        'accountName': _accountName.text.trim(),
      });
      _amount.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Withdrawal request sent to the super admin for review.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Withdrawal request failed.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
