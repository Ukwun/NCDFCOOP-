import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/seller_models.dart';

/// SCREEN 4 - PRODUCT REVIEW & APPROVAL STATUS
/// Shows product status with approval/rejection details
class ProductStatusScreen extends StatelessWidget {
  final String productName;
  final ProductApprovalStatus status;
  final String? rejectionReason;
  final VoidCallback onEditProduct;
  final VoidCallback onAddAnotherProduct;
  final VoidCallback onGoToDashboard;

  const ProductStatusScreen({
    super.key,
    required this.productName,
    required this.status,
    this.rejectionReason,
    required this.onEditProduct,
    required this.onAddAnotherProduct,
    required this.onGoToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Product Status',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildProgressIndicator(4),
            ),
            const SizedBox(height: 16),

            // Status card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStatusCard(),
            ),
            const SizedBox(height: 32),

            // Trust messaging section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTrustSection(),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status == ProductApprovalStatus.rejected)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onEditProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            child: Text(
                              'Edit & Resubmit',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAddAnotherProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'Add Another Product',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onGoToDashboard,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'Go to Dashboard',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int step) {
    return Row(
      children: List.generate(5, (index) {
        final stepNum = index + 1;
        final isActive = stepNum <= step;
        return Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    String statusMessage;

    switch (status) {
      case ProductApprovalStatus.pending:
        statusColor = Colors.amber;
        statusLabel = '🟡 Pending Approval';
        statusIcon = Icons.hourglass_empty;
        statusMessage =
            'Your product is being reviewed by NCDF COOP team. This ensures quality and trust for buyers.';
        break;
      case ProductApprovalStatus.approved:
        statusColor = Colors.green;
        statusLabel = '🟢 Approved';
        statusIcon = Icons.check_circle;
        statusMessage =
            'Congratulations! Your product has been approved and is now live on the marketplace.';
        break;
      case ProductApprovalStatus.rejected:
        statusColor = Colors.red;
        statusLabel = '🔴 Rejected';
        statusIcon = Icons.cancel;
        statusMessage = 'Your product was not approved. Please review the '
            'reason below and make necessary changes.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header with icon
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: AppTextStyles.h3.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      productName,
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              statusMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.text,
                height: 1.6,
              ),
            ),
          ),

          // Rejection reason (if applicable)
          if (status == ProductApprovalStatus.rejected &&
              rejectionReason != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Reason for Rejection',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    rejectionReason!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.red[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTrustSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Approval Matters',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTrustItem(
          icon: Icons.check_circle_outline,
          title: 'Ensures product quality',
          description:
              'We verify that products meet our standards and buyer expectations.',
        ),
        const SizedBox(height: 12),
        _buildTrustItem(
          icon: Icons.people_outline,
          title: 'Builds buyer trust',
          description:
              'Buyers have confidence that every product on NCDF COOP is verified.',
        ),
        const SizedBox(height: 12),
        _buildTrustItem(
          icon: Icons.security_outlined,
          title: 'Prevents fraud',
          description:
              'We protect both sellers and buyers from unauthorized or counterfeit products.',
        ),
        const SizedBox(height: 12),
        _buildTrustItem(
          icon: Icons.public_outlined,
          title: 'Supports export compliance',
          description:
              'Products are verified to meet international trade regulations.',
        ),
      ],
    );
  }

  Widget _buildTrustItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
