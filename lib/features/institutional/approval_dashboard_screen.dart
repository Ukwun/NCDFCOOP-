import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/institutional_approver_service.dart';
import '../../models/institutional_approver_models.dart';

/// Approval Dashboard Screen for Institutional Approvers
/// Displays pending POs awaiting approval with status tracking
class ApprovalDashboardScreen extends ConsumerStatefulWidget {
  const ApprovalDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ApprovalDashboardScreen> createState() =>
      _ApprovalDashboardScreenState();
}

class _ApprovalDashboardScreenState
    extends ConsumerState<ApprovalDashboardScreen> {
  late InstitutionalApproverService _approverService;

  @override
  void initState() {
    super.initState();
    _approverService = InstitutionalApproverService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Dashboard'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _approverService.getApprovalDashboardStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final stats = snapshot.data ?? {};
          final totalPOs = (stats['totalPOs'] as num?)?.toInt() ?? 0;
          final pending = (stats['pending'] as num?)?.toInt() ?? 0;
          final approved = (stats['approved'] as num?)?.toInt() ?? 0;
          final rejected = (stats['rejected'] as num?)?.toInt() ?? 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Stats Cards
                Container(
                  color: Colors.deepPurple.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // KPI Row 1
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total POs',
                              value: totalPOs.toString(),
                              color: Colors.blue,
                              icon: Icons.description,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Pending',
                              value: pending.toString(),
                              color: Colors.orange,
                              icon: Icons.schedule,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // KPI Row 2
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Approved',
                              value: approved.toString(),
                              color: Colors.green,
                              icon: Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Rejected',
                              value: rejected.toString(),
                              color: Colors.red,
                              icon: Icons.cancel,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Pending Approvals Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Department Approvals',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<POApprovalWorkflow>>(
                        future: _approverService.getPendingApprovalsForUser(
                          'current_user_id',
                          ApprovalStep.departmentApproval,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final approvals = snapshot.data ?? [];

                          if (approvals.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No pending approvals',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: approvals.length,
                            itemBuilder: (context, index) {
                              final approval = approvals[index];
                              return _buildApprovalCard(approval);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Budget Verification Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Verification Queue',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<POApprovalWorkflow>>(
                        future: _approverService.getPendingApprovalsForUser(
                          'current_user_id',
                          ApprovalStep.budgetVerification,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final approvals = snapshot.data ?? [];

                          if (approvals.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No budget verifications pending',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: approvals.length,
                            itemBuilder: (context, index) {
                              final approval = approvals[index];
                              return _buildBudgetCard(approval);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Final Authorization Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Final Authorization Queue',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<POApprovalWorkflow>>(
                        future: _approverService.getPendingApprovalsForUser(
                          'current_user_id',
                          ApprovalStep.finalAuthorization,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final approvals = snapshot.data ?? [];

                          if (approvals.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No final authorizations pending',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: approvals.length,
                            itemBuilder: (context, index) {
                              final approval = approvals[index];
                              return _buildAuthorizationCard(approval);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(POApprovalWorkflow approval) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  approval.poId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Awaiting Department Approval',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showPODetailsDialog(context, approval),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approvePO(context, approval),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _rejectPO(context, approval),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(POApprovalWorkflow approval) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  approval.poId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'In Review',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Department Approved - Awaiting Budget Verification',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showBudgetDetailsDialog(context, approval),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Review Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approveBudget(context, approval),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _rejectBudget(context, approval),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizationCard(POApprovalWorkflow approval) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  approval.poId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ready',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Awaiting Final Director Authorization',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _authorizeAndApprovePO(context, approval),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Authorize & Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _rejectAuthorization(context, approval),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // APPROVAL ACTION HANDLERS
  // ============================================================================

  void _showPODetailsDialog(BuildContext context, POApprovalWorkflow approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PO Details - ${approval.poId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('PO Number:', approval.poId),
              _DetailRow('Created Date:', '2026-04-03'),
              _DetailRow('Vendor:', 'Agricultural Supplies Co.'),
              _DetailRow('Total Amount:', '₦250,000'),
              _DetailRow('Items Count:', '24 items'),
              _DetailRow('Status:', 'Pending Approval'),
              _DetailRow('Description:', 'Premium rice bulk order'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDetailsDialog(
      BuildContext context, POApprovalWorkflow approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Budget Review - ${approval.poId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('PO Number:', approval.poId),
              _DetailRow('Total Budget:', '₦500,000'),
              _DetailRow('Requested Amount:', '₦250,000'),
              _DetailRow('Budget Available:', '₦380,500'),
              _DetailRow('Budget Status:', 'OK - Within Limits'),
              _DetailRow('Department:', 'Procurement'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _approvePO(BuildContext context, POApprovalWorkflow approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve PO'),
        content: Text(
          'Approve PO ${approval.poId}?\n\nThis will move the PO to the next approval stage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PO ${approval.poId} approved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectPO(BuildContext context, POApprovalWorkflow approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject PO'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject PO ${approval.poId}?'),
            const SizedBox(height: 16),
            const Text('Rejection Reason:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter reason for rejection',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PO ${approval.poId} rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _approveBudget(BuildContext context, POApprovalWorkflow approval) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Budget for PO ${approval.poId} approved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectBudget(BuildContext context, POApprovalWorkflow approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Budget'),
        content: Text('Reject budget for PO ${approval.poId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Budget for PO ${approval.poId} rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _authorizeAndApprovePO(
      BuildContext context, POApprovalWorkflow approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Authorization'),
        content: Text(
          'Authorize and approve PO ${approval.poId}?\n\nThis is the final approval step. The order will be sent to the vendor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PO ${approval.poId} authorized and approved!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Authorize'),
          ),
        ],
      ),
    );
  }

  void _rejectAuthorization(BuildContext context, POApprovalWorkflow approval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Authorization'),
        content: Text('Reject authorization for PO ${approval.poId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Authorization for PO ${approval.poId} rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

/// Helper widget to display detail rows
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
