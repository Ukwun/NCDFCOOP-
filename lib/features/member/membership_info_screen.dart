import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/member_models.dart';
import '../../providers/member_providers.dart';

class MembershipInfoScreen extends ConsumerWidget {
  const MembershipInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final loyaltyAsync = ref.watch(memberLoyaltyProvider);
    final benefitsAsync = ref.watch(memberTierBenefitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Membership Info')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current tier card
            memberAsync.when(
              data: (member) => _buildCurrentTierCard(member),
              loading: () =>
                  Container(height: 200, color: Colors.grey.shade300),
              error: (e, st) => Text('Error: $e'),
            ),

            const SizedBox(height: 20),

            // Tier progression
            _buildTierProgression(),

            const SizedBox(height: 20),

            // Benefits comparison
            benefitsAsync.when(
              data: (benefits) => _buildBenefitsComparison(benefits),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // Member info
            memberAsync.when(
              data: (member) => _buildMemberInfo(member),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTierCard(Member? member) {
    if (member == null) return const SizedBox.shrink();

    final tierColor = _getTierColor(member.memberTier);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColor, tierColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Membership',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                member.memberTier,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(
                _getTierIcon(member.memberTier),
                size: 48,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Member Since',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  _formatDate(member.memberSince),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgression() {
    final tiers = ['BASIC', 'SILVER', 'GOLD', 'PLATINUM'];
    final currentTierIndex = 0; // TODO: Get from member

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(tiers.length, (index) {
              final isReached = index <= currentTierIndex;
              final isNext = index == currentTierIndex + 1;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isReached ? Colors.blue : Colors.grey.shade300,
                        border: isNext
                            ? Border.all(
                                color: Colors.blue,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isReached
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : Text(
                                (index + 1).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tiers[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isReached ? FontWeight.bold : FontWeight.normal,
                        color: isReached ? Colors.blue : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsComparison(List<MemberBenefit> benefits) {
    final tiers = ['BASIC', 'SILVER', 'GOLD', 'PLATINUM'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Benefits by Tier',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Benefit')),
                ...tiers.map((t) => DataColumn(label: Text(t))),
              ],
              rows: benefits.take(5).map((benefit) {
                return DataRow(
                  cells: [
                    DataCell(Text(benefit.name)),
                    ...tiers.map((tier) {
                      final hasIt = benefit.tiers.contains(tier);
                      return DataCell(
                        Center(
                          child: hasIt
                              ? const Icon(Icons.check, color: Colors.green)
                              : const Icon(Icons.close, color: Colors.grey),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberInfo(Member? member) {
    if (member == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Membership Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Total Orders', '${member.totalOrders}'),
          _buildInfoRow(
            'Total Spent',
            '\$${member.totalSpent.toStringAsFixed(2)}',
          ),
          _buildInfoRow(
            'Last Purchase',
            member.lastPurchaseDate != null
                ? _formatDate(member.lastPurchaseDate!)
                : 'No purchases',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'SILVER':
        return Colors.grey;
      case 'GOLD':
        return Colors.amber;
      case 'PLATINUM':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier) {
      case 'SILVER':
        return Icons.diamond;
      case 'GOLD':
        return Icons.diamond;
      case 'PLATINUM':
        return Icons.diamond;
      default:
        return Icons.card_giftcard;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
