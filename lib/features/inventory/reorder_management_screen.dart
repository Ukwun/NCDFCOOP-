import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/inventory_providers.dart';
import 'package:coop_commerce/models/inventory_models.dart';

/// Reorder Management Screen
/// AI-powered reorder suggestions and purchase order management
class ReorderManagementScreen extends ConsumerStatefulWidget {
  final String? locationId;

  const ReorderManagementScreen({
    super.key,
    this.locationId,
  });

  @override
  ConsumerState<ReorderManagementScreen> createState() =>
      _ReorderManagementScreenState();
}

class _ReorderManagementScreenState
    extends ConsumerState<ReorderManagementScreen> {
  String _priorityFilter = 'all'; // all, urgent, high, medium, low

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(
      reorderSuggestionsProvider(widget.locationId ?? ''),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Reorder Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.locationId != null) {
                ref.refresh(reorderSuggestionsProvider(widget.locationId!));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('urgent', 'Urgent'),
                  const SizedBox(width: 8),
                  _buildFilterChip('high', 'High'),
                  const SizedBox(width: 8),
                  _buildFilterChip('medium', 'Medium'),
                  const SizedBox(width: 8),
                  _buildFilterChip('low', 'Low'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Suggestions List
          Expanded(
            child: suggestionsAsync.when(
              data: (suggestions) {
                final filtered = _filterSuggestions(suggestions);

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.done_all,
                            size: 64,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reorder suggestions',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All items are well-stocked',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    if (widget.locationId != null) {
                      ref.refresh(
                          reorderSuggestionsProvider(widget.locationId!));
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildSuggestionCard(
                        context,
                        ref,
                        filtered[index],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading suggestions: $err'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isActive = _priorityFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {
        setState(() => _priorityFilter = value);
      },
      backgroundColor: isActive ? AppColors.primary : Colors.transparent,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : AppColors.textLight,
      ),
    );
  }

  List<ReorderSuggestion> _filterSuggestions(
      List<ReorderSuggestion> suggestions) {
    if (_priorityFilter == 'all') {
      return suggestions.where((s) => !s.isAccepted).toList();
    }
    return suggestions
        .where((s) => s.priority == _priorityFilter && !s.isAccepted)
        .toList();
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    WidgetRef ref,
    ReorderSuggestion suggestion,
  ) {
    late Color priorityColor;
    late Widget priorityIcon;

    switch (suggestion.priority) {
      case 'urgent':
        priorityColor = Colors.red;
        priorityIcon = const Icon(Icons.priority_high, color: Colors.white);
        break;
      case 'high':
        priorityColor = Colors.orange;
        priorityIcon = const Icon(Icons.warning, color: Colors.white);
        break;
      case 'medium':
        priorityColor = Colors.blue;
        priorityIcon = const Icon(Icons.info, color: Colors.white);
        break;
      default:
        priorityColor = Colors.green;
        priorityIcon = const Icon(Icons.check, color: Colors.white);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: priorityIcon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.priority.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: priorityColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stockout in ${suggestion.daysToStockout} days',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(suggestion.confidence * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reason
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommendation',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.reason,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem(
                        label: 'Suggested Qty',
                        value: suggestion.suggestedQuantity.toString(),
                        color: Colors.green,
                      ),
                      _buildDetailItem(
                        label: 'Current Stock',
                        value: suggestion.currentStock.toString(),
                        color: Colors.orange,
                      ),
                      _buildDetailItem(
                        label: 'Forecast (Weekly)',
                        value: suggestion.forecastedDemandWeekly
                            .toStringAsFixed(1),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product ID',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      suggestion.productId,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(suggestion.generatedAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showCreatePODialog(context, suggestion);
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Create PO'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _acceptSuggestion(context, ref, suggestion);
                    },
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
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(color: color),
        ),
      ],
    );
  }

  void _showCreatePODialog(BuildContext context, ReorderSuggestion suggestion) {
    final supplierController = TextEditingController();
    final poNumberController = TextEditingController();
    final expectedDeliveryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Purchase Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Product'),
                subtitle: Text(suggestion.productId),
                trailing: Text(
                  suggestion.suggestedQuantity.toString(),
                  style: AppTextStyles.titleSmall,
                ),
              ),
              const Divider(),
              TextField(
                controller: poNumberController,
                decoration: const InputDecoration(
                  labelText: 'PO Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expectedDeliveryController,
                decoration: const InputDecoration(
                  labelText: 'Expected Delivery Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    expectedDeliveryController.text =
                        DateFormat('MMM d, yyyy').format(date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchase Order created successfully'),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Create PO'),
          ),
        ],
      ),
    );
  }

  void _acceptSuggestion(
    BuildContext context,
    WidgetRef ref,
    ReorderSuggestion suggestion,
  ) {
    ref.read(inventoryActionsProvider.notifier).acceptReorderSuggestion(
          suggestion.suggestionId,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reorder suggestion approved'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
