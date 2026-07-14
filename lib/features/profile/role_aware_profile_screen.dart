import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/role.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../welcome/auth_provider.dart' as auth_controller;

class RoleAwareProfileScreen extends ConsumerWidget {
  const RoleAwareProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentRoleProvider);
    if (user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/signin'),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final collection = switch (role) {
      UserRole.seller => 'sellers',
      UserRole.wholesaleBuyer => 'wholesale_buyers',
      _ => 'members',
    };

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .doc(user.id)
          .snapshots(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data();
        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: () => FirebaseFirestore.instance
                .collection(collection)
                .doc(user.id)
                .get(const GetOptions(source: Source.server)),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _RoleHeader(
                  name: user.name,
                  email: user.email,
                  role: role,
                  photoUrl: user.photoUrl,
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2)
                else if (snapshot.hasError)
                  const _StatusMessage(
                    text:
                        'Profile data is temporarily unavailable. Pull down to retry.',
                  )
                else if (profile == null)
                  const _StatusMessage(
                    text: 'Your role profile has not been completed yet.',
                  )
                else
                  _RoleStatusCard(role: role, data: profile),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(children: _actionsFor(context, role)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context, ref),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(50),
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

  List<Widget> _actionsFor(BuildContext context, UserRole role) {
    final common = <Widget>[
      _ProfileAction(Icons.settings_outlined, 'Account settings',
          () => context.pushNamed('settings')),
      _ProfileAction(Icons.help_outline, 'Help and support',
          () => context.pushNamed('help-support')),
    ];
    return switch (role) {
      UserRole.seller => [
          _ProfileAction(Icons.inventory_2_outlined, 'Manage products',
              () => context.pushNamed('seller-add-product')),
          _ProfileAction(Icons.receipt_long_outlined, 'Sales ledger',
              () => context.pushNamed('seller-sales-ledger')),
          _ProfileAction(Icons.account_balance_outlined, 'Earnings and payouts',
              () => context.go('/cart')),
          ...common,
        ],
      UserRole.wholesaleBuyer => [
          _ProfileAction(Icons.receipt_long_outlined, 'Wholesale orders',
              () => context.pushNamed('orders')),
          _ProfileAction(Icons.location_on_outlined, 'Delivery addresses',
              () => context.pushNamed('addresses')),
          _ProfileAction(Icons.payment_outlined, 'Payment methods',
              () => context.pushNamed('payment-methods')),
          ...common,
        ],
      _ => [
          _ProfileAction(Icons.workspace_premium_outlined, 'Member benefits',
              () => context.pushNamed('member-benefits')),
          _ProfileAction(Icons.loyalty_outlined, 'Loyalty and rewards',
              () => context.pushNamed('member-loyalty')),
          _ProfileAction(Icons.receipt_long_outlined, 'My orders',
              () => context.pushNamed('orders')),
          _ProfileAction(Icons.location_on_outlined, 'Addresses',
              () => context.pushNamed('addresses')),
          ...common,
        ],
    };
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to authenticate again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(auth_controller.authControllerProvider.notifier).signOut();
    if (context.mounted) context.go('/signin');
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      UserRole.seller => const Color(0xFF14532D),
      UserRole.wholesaleBuyer => const Color(0xFF1E3A8A),
      _ => AppColors.primary,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: .78)]),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundImage:
                photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
            child: photoUrl?.isNotEmpty == true
                ? null
                : Text(name.isEmpty ? '?' : name[0].toUpperCase()),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.h3.copyWith(color: Colors.white)),
                Text(email, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(role.displayName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleStatusCard extends StatelessWidget {
  const _RoleStatusCard({required this.role, required this.data});
  final UserRole role;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final entries = switch (role) {
      UserRole.seller => {
          'Store': data['businessName'] ?? data['storeName'] ?? 'Not provided',
          'Verification':
              data['verificationStatus'] ?? data['status'] ?? 'Pending',
        },
      UserRole.wholesaleBuyer => {
          'Business':
              data['businessName'] ?? data['companyName'] ?? 'Not provided',
          'Buyer status': data['status'] ?? 'Pending',
        },
      _ => {
          'Membership tier':
              data['memberTier'] ?? data['tier'] ?? 'Not assigned',
          'Membership status': data['membershipStatus'] ??
              (data['isActive'] == true ? 'Active' : 'Pending'),
        },
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: entries.entries
              .map((entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key),
                    trailing: Text(entry.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
