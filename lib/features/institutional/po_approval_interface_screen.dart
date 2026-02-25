import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/institutional_approver_service.dart';
import '../../models/institutional_approver_models.dart';

/// PO Approval Interface Screen
/// Handles approval/rejection of POs with budget validation
class POApprovalInterfaceScreen extends ConsumerStatefulWidget {
  final String poId;
  final String poNumber;
  final double poAmount;
  final String vendorName;
  final String departmentName;
  final String description;

  const POApprovalInterfaceScreen({
    Key? key,
    required this.poId,
    required this.poNumber,
    required this.poAmount,
    required this.vendorName,
    required this.departmentName,
    required this.description,
  }) : super(key: key);

  @override
  ConsumerState<POApprovalInterfaceScreen> createState() =>
      _POApprovalInterfaceScreenState();
}

class _POApprovalInterfaceScreenState
    extends ConsumerState<POApprovalInterfaceScreen> {
  late InstitutionalApproverService _approverService;
  int _activeStepIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _approverService = InstitutionalApproverService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PO Approval'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<POApprovalWorkflow?>(
        future: _approverService.getApprovalStatus(widget.poId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final workflow = snapshot.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                // PO Details Card
                Container(
                  color: Colors.deepPurple.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PO Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('PO Number', widget.poNumber),
                      _buildDetailRow(
                          'Amount', '₦${widget.poAmount.toStringAsFixed(2)}'),
                      _buildDetailRow('Vendor', widget.vendorName),
                      _buildDetailRow('Department', widget.departmentName),
                      _buildDetailRow('Description', widget.description),
                    ],
                  ),
                ),
                // Approval Workflow Steps
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approval Workflow',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildWorkflowStepper(workflow),
                    ],
                  ),
                ),
                // Budget Verification Info
                if (workflow?.budgetVerification != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Card(
                      color: workflow!.budgetVerification!.withinBudget
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  workflow.budgetVerification!.withinBudget
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: workflow
                                          .budgetVerification!.withinBudget
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Budget Status',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildBudgetRow(
                              'PO Amount',
                              '₦${workflow.budgetVerification!.poAmount.toStringAsFixed(2)}',
                            ),
                            _buildBudgetRow(
                              'Remaining Budget',
                              '₦${workflow.budgetVerification!.remainingBudget.toStringAsFixed(2)}',
                              isHighlight:
                                  !workflow.budgetVerification!.withinBudget,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Approval Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Action',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildApprovalForm(),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isHighlight ? Colors.red : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isHighlight ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStepper(POApprovalWorkflow? workflow) {
    final steps = [
      {
        'title': 'Department Approval',
        'status': workflow?.departmentApproval?.status ?? ApprovalStatus.pending,
        'approver': workflow?.departmentApproval?.approverName ?? 'Pending',
      },
      {
        'title': 'Budget Verification',
        'status': workflow?.budgetVerification?.status ?? ApprovalStatus.pending,
        'approver':
            workflow?.budgetVerification?.budgetOfficerName ?? 'Pending',
      },
      {
        'title': 'Final Authorization',
        'status':
            workflow?.finalAuthorization?.status ?? ApprovalStatus.pending,
        'approver': workflow?.finalAuthorization?.directorName ?? 'Pending',
      },
    ];

    return Column(
      children: List.generate(
        steps.length,
        (index) {
          final step = steps[index];
          final status = step['status'] as ApprovalStatus;
          final isCompleted = status == ApprovalStatus.approved;
          final isRejected = status == ApprovalStatus.rejected;
          final isPending = status == ApprovalStatus.pending;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : isRejected
                            ? Colors.red
                            : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white)
                        : isRejected
                            ? const Icon(Icons.close, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 16),
                // Step details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted
                            ? 'Approved by ${step['approver']}'
                            : isRejected
                                ? 'Rejected'
                                : 'Awaiting ${step['approver']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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

  Widget _buildApprovalForm() {
    return Column(
      children: [
        // Tab selector
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeStepIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeStepIndex == 0
                              ? Colors.deepPurple
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'Approve',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _activeStepIndex == 0
                            ? Colors.deepPurple
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeStepIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeStepIndex == 1
                              ? Colors.red
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _activeStepIndex == 1 ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Approval content
        if (_activeStepIndex == 0) _buildApproveForm(),
        if (_activeStepIndex == 1) _buildRejectForm(),
      ],
    );
  }

  Widget _buildApproveForm() {
    final notesController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add approval notes (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _approveAction(notesController.text),
            icon: const Icon(Icons.check_circle),
            label: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Approve PO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Text(
            '✓ Approving this PO will move it to the next approval stage',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectForm() {
    final reasonController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rejection Reason',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: reasonController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Provide a reason for rejection',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _rejectAction(reasonController.text),
            icon: const Icon(Icons.cancel),
            label: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Reject PO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: const Text(
            '⚠ Rejecting this PO will require the requester to resubmit',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  void _approveAction(String notes) async {
    setState(() => _isProcessing = true);

    try {
      await _approverService.approveDepartment(
        poId: widget.poId,
        departmentName: widget.departmentName,
        approverId: 'current_user_id',
        approverName: 'Current User',
        notes: notes.isNotEmpty ? notes : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PO approved successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _rejectAction(String reason) async {
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _approverService.rejectDepartment(
        poId: widget.poId,
        departmentName: widget.departmentName,
        approverId: 'current_user_id',
        approverName: 'Current User',
        rejectionReason: reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PO rejected successfully'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
