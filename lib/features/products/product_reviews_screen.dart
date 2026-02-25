import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coop_commerce/core/services/product_review_service.dart';
import 'package:coop_commerce/core/services/review_activity_logger.dart';
import 'package:coop_commerce/core/services/activity_tracking_service.dart';
import 'package:coop_commerce/core/error_handling.dart';

class ProductReviewsScreen extends ConsumerStatefulWidget {
  final String productId;
  final String productName;

  const ProductReviewsScreen({
    required this.productId,
    required this.productName,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ProductReviewsScreen> createState() =>
      _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends ConsumerState<ProductReviewsScreen> {
  String _sortBy = 'recent'; // 'recent', 'helpful', 'rating-high', 'rating-low'

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(productReviewsProvider(widget.productId));
    final summaryAsync =
        ref.watch(productRatingSummaryProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews - ${widget.productName}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary Card
            summaryAsync.when(
              data: (summary) => _buildRatingSummary(summary),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),

            const SizedBox(height: 20),

            // Sort Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Reviews',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  DropdownButton<String>(
                    value: _sortBy,
                    items: [
                      DropdownMenuItem(
                        value: 'recent',
                        child: Row(
                          children: const [
                            Icon(Icons.schedule, size: 18),
                            SizedBox(width: 8),
                            Text('Most Recent'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'helpful',
                        child: Row(
                          children: const [
                            Icon(Icons.thumb_up, size: 18),
                            SizedBox(width: 8),
                            Text('Most Helpful'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'rating-high',
                        child: Row(
                          children: const [
                            Icon(Icons.star, size: 18),
                            SizedBox(width: 8),
                            Text('Highest Rated'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'rating-low',
                        child: Row(
                          children: const [
                            Icon(Icons.star_border, size: 18),
                            SizedBox(width: 8),
                            Text('Lowest Rated'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reviews List
            reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.rate_review, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to review this product',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) =>
                      _buildReviewCard(reviews[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) =>
                  Center(child: Text('Error loading reviews: $err')),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReviewDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRatingSummary(dynamic summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.getStarDisplay(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on ${summary.totalReviews} reviews',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  ...[5, 4, 3, 2, 1].map((rating) {
                    final percentage = summary.getPercentageAtRating(rating);
                    return Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 4,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation(
                                rating >= 4
                                    ? Colors.green
                                    : rating >= 3
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                              rating,
                              (i) => const Icon(Icons.star,
                                  size: 14, color: Colors.orange)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Rating, Badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (review.verified)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Verified Buyer',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            review.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),

          // Comment
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),

          // Helpful button
          Row(
            children: [
              Icon(Icons.thumb_up_outlined,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Helpful (${review.helpfulCount})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(width: 16),
              Text(
                'Unhelpful',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(productId: widget.productId),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}

class AddReviewDialog extends ConsumerStatefulWidget {
  final String productId;

  const AddReviewDialog({required this.productId, Key? key}) : super(key: key);

  @override
  ConsumerState<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends ConsumerState<AddReviewDialog> {
  int _rating = 5;
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Selector
            Text('Rating', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text('Title', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Summary of your review',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // Comment
            Text('Comment', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Share your experience with this product',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 4,
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
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Review'),
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    if (_titleController.text.isEmpty || _commentController.text.isEmpty) {
      context.showWarningSnackBar('Please fill all fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(productReviewServiceProvider);
      await service.submitReview(
        productId: widget.productId,
        userId: 'user_001', // TODO: Get from auth provider
        userName: 'John Doe', // TODO: Get from auth provider
        rating: _rating,
        title: _titleController.text,
        comment: _commentController.text,
        verified: true,
      );

      // Log review activity
      try {
        final reviewLogger = ReviewActivityLogger(ActivityTrackingService());
        await reviewLogger.logReviewSubmitted(
          productId: widget.productId,
          productName: 'Product (ID: ${widget.productId})',
          category: 'Uncategorized', // Category from product detail
          rating: _rating,
          title: _titleController.text,
          comment: _commentController.text,
        );
        debugPrint(
            '✅ Review logged for product ${widget.productId} (⭐ $_rating/5)');
      } catch (logError) {
        debugPrint('⚠️ Error logging review: $logError');
        // Silent fail - don't block UI
      }

      if (mounted) {
        Navigator.pop(context);
        context.showSuccessSnackBar('Review submitted successfully!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.logError(
          context: 'Product Reviews - Submit Review',
          error: e,
        );
        context.showErrorSnackBar(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
