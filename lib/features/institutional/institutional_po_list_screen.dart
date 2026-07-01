import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:coop_commerce/models/b2b_models.dart';
import 'package:coop_commerce/core/providers/b2b_providers.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/theme/app_theme.dart';

class InstitutionalPOListScreen extends ConsumerStatefulWidget {
  const InstitutionalPOListScreen({super.key});

  @override
  ConsumerState<InstitutionalPOListScreen> createState() =>
      _InstitutionalPOListScreenState();
}

class _InstitutionalPOListScreenState
    extends ConsumerState<InstitutionalPOListScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentContext = ref.watch(currentContextProvider);
    final institutionId =
        currentContext?.institutionId ?? currentUser?.id ?? '';

    if (institutionId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchase Orders')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Institution context is missing. Please sign in again to access purchase orders.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final purchaseOrdersAsync =
        ref.watch(institutionPurchaseOrdersProvider(institutionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create New PO',
            onPressed: () => context.pushNamed('institutional-po-create'),
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusFilters(
            selectedStatus: _selectedStatus,
            onStatusChanged: (status) {
              setState(() => _selectedStatus = status);
            },
          ),
          Expanded(
            child: purchaseOrdersAsync.when(
              data: (orders) {
                final filteredOrders = _filterByStatus(orders, _selectedStatus);

                if (filteredOrders.isEmpty) {
                  return _EmptyPOState(
                    hasData: orders.isNotEmpty,
                    onCreateTap: () =>
                        context.pushNamed('institutional-po-create'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: filteredOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final po = filteredOrders[index];
                    return _POListItemCard(
                      po: po,
                      onTap: () => context.pushNamed(
                        'institutional-po-detail',
                        pathParameters: {'poId': po.id},
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Could not load purchase orders in real time: $err',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('institutional-po-create'),
        icon: const Icon(Icons.post_add_outlined),
        label: const Text('New PO'),
      ),
    );
  }

  List<PurchaseOrder> _filterByStatus(
      List<PurchaseOrder> orders, String status) {
    if (status == 'all') return orders;
    return orders
        .where((order) => order.status.toLowerCase() == status)
        .toList();
  }
}

class _StatusFilters extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const _StatusFilters({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    const filters = <String>['all', 'pending', 'approved', 'rejected', 'draft'];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = selectedStatus == filter;
          return ChoiceChip(
            label: Text(_toTitleCase(filter)),
            selected: selected,
            onSelected: (_) => onStatusChanged(filter),
          );
        },
      ),
    );
  }

  String _toTitleCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _POListItemCard extends StatelessWidget {
  final PurchaseOrder po;
  final VoidCallback onTap;

  const _POListItemCard({
    required this.po,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    final dateLabel = DateFormat('dd MMM yyyy, h:mm a').format(po.createdDate);
    final (statusColor, statusLabel) = _statusMeta(po.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'PO ${po.id.substring(0, po.id.length > 8 ? 8 : po.id.length).toUpperCase()}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${po.lineItems.length} line items • ${currency.format(po.totalAmount)}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Created $dateLabel',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Delivery: ${DateFormat('dd MMM yyyy').format(po.expectedDeliveryDate)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String) _statusMeta(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return (Colors.orange, 'Pending Approval');
      case 'approved':
        return (Colors.green, 'Approved');
      case 'rejected':
        return (Colors.red, 'Rejected');
      case 'draft':
        return (Colors.blueGrey, 'Draft');
      case 'processing':
        return (Colors.blue, 'Processing');
      case 'shipped':
        return (Colors.indigo, 'Shipped');
      case 'delivered':
        return (Colors.teal, 'Delivered');
      default:
        return (Colors.grey, status);
    }
  }
}

class _EmptyPOState extends StatelessWidget {
  final bool hasData;
  final VoidCallback onCreateTap;

  const _EmptyPOState({required this.hasData, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasData ? Icons.filter_alt_off_outlined : Icons.post_add_outlined,
              size: 42,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 10),
            Text(
              hasData
                  ? 'No purchase orders match this filter yet.'
                  : 'No purchase orders yet. Create your first PO now.',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create New PO'),
            ),
          ],
        ),
      ),
    );
  }
}
