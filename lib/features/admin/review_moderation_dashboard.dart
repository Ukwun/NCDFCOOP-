import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/review_providers.dart';
import 'package:coop_commerce/models/enhanced_review_models.dart';

/// Review Moderation Dashboard
/// Admin screen for reviewing and moderating user reviews
class ReviewModerationDashboard extends ConsumerStatefulWidget {
  const ReviewModerationDashboard({super.key});

  @override
  ConsumerState<ReviewModerationDashboard> createState() =>
      _ReviewModerationDashboardState();
}

class _ReviewModerationDashboardState
    extends ConsumerState<ReviewModerationDashboard> {
  String _filterStatus = 'pending'; // pending, approved, rejected

  @override
  Widget build(BuildContext context) {
    final pendingReviews = ref.watch(pendingReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Review Moderation',
          style: AppTextStyles.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(pendingReviewsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterTab('pending', 'Pending'),
                const SizedBox(width: 12),
                _buildFilterTab('approved', 'Approved'),
                const SizedBox(width: 12),
                _buildFilterTab('rejected', 'Rejected'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: pendingReviews.when(
              data: (records) {
                final filtered = _filterRecords(records);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filterStatus == 'pending'
                              ? Icons.done_all
                              : Icons.check_circle,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'pending'
                              ? 'No pending reviews'
                              : 'No reviews with this status',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildModerationCard(
                      context,
                      ref,
                      filtered[index],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading reviews: $error',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isActive = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive ? AppColors.primary : AppColors.textLight,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (isActive)
            Container(
              height: 3,
              width: 20,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  List<ReviewModerationRecord> _filterRecords(
    List<ReviewModerationRecord> records,
  ) {
    return records.where((record) {
      return record.status == _filterStatus;
    }).toList();
  }

  Widget _buildModerationCard(
    BuildContext context,
    WidgetRef ref,
    ReviewModerationRecord record,
  ) {
    final actions = ref.read(reviewActionsProvider);

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
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      record.reviewerName[0].toUpperCase(),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            record.reviewerName,
                            style: AppTextStyles.titleSmall,
                          ),
                          _buildStatusBadge(record.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < record.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(record.createdAt),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review Content
            Text(
              record.reviewTitle,
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              record.reviewComment,
              style: AppTextStyles.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Flags (if any)
            if (record.flags.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag_outlined,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Flagged Issues',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.flags.join(', '),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

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
                      record.productId.length > 20
                          ? '${record.productId.substring(0, 20)}...'
                          : record.productId,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                if (record.rejectionReason != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rejection Reason',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.rejectionReason!,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Action Buttons (only for pending reviews)
            if (record.status == 'pending')
              Column(
                children: [
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await actions.approveReview(
                                reviewId: record.reviewId,
                                moderatorId: 'current_moderator_id',
                              );
                              ref.refresh(pendingReviewsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Review approved'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showRejectDialog(
                              context,
                              record,
                              actions,
                              ref,
                            );
                          },
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    late Color bgColor;
    late Color textColor;
    late String label;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        label = 'Pending';
        break;
      case 'approved':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        bgColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    ReviewModerationRecord record,
    ReviewActions actions,
    WidgetRef ref,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please specify the reason for rejection:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Inappropriate language, Spam, Off-topic',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                  ),
                );
                return;
              }

              try {
                await actions.rejectReview(
                  reviewId: record.reviewId,
                  moderatorId: 'current_moderator_id',
                  reason: reasonController.text.trim(),
                );
                ref.refresh(pendingReviewsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review rejected'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
