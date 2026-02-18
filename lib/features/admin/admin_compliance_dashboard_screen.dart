import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Compliance issue model
class ComplianceIssue {
  final String id;
  final String type; // 'pricing', 'inventory', 'delivery', 'fraud'
  final String severity; // 'critical', 'warning', 'info'
  final String title;
  final String description;
  final String affectedEntity;
  final DateTime detectedAt;
  final String status; // 'open', 'acknowledged', 'resolved'

  ComplianceIssue({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.affectedEntity,
    required this.detectedAt,
    required this.status,
  });
}

/// Compliance score model
class ComplianceScore {
  final double overallScore; // 0-100
  final double pricingScore;
  final double inventoryScore;
  final double deliveryScore;
  final double fraudScore;
  final List<ComplianceIssue> openIssues;
  final List<ComplianceIssue> resolvedIssues;

  ComplianceScore({
    required this.overallScore,
    required this.pricingScore,
    required this.inventoryScore,
    required this.deliveryScore,
    required this.fraudScore,
    required this.openIssues,
    required this.resolvedIssues,
  });
}

/// Provider for compliance data
final complianceScoreProvider = FutureProvider<ComplianceScore>((ref) async {
  // TODO: Integrate with compliance service
  await Future.delayed(const Duration(milliseconds: 500));

  return ComplianceScore(
    overallScore: 87.5,
    pricingScore: 92.0,
    inventoryScore: 85.0,
    deliveryScore: 88.5,
    fraudScore: 80.0,
    openIssues: [
      ComplianceIssue(
        id: 'issue-001',
        type: 'pricing',
        severity: 'warning',
        title: 'Unusual Price Adjustment',
        description:
            'Product SKU-2451 price increased 15% without override approval',
        affectedEntity: 'SKU-2451',
        detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'open',
      ),
      ComplianceIssue(
        id: 'issue-002',
        type: 'delivery',
        severity: 'critical',
        title: 'Delivery SLA Breach',
        description: 'Order ORD-5821 missed delivery deadline by 4 hours',
        affectedEntity: 'ORD-5821',
        detectedAt: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'open',
      ),
      ComplianceIssue(
        id: 'issue-003',
        type: 'inventory',
        severity: 'info',
        title: 'Stock Level Alert',
        description: 'Warehouse inventory for SKU-1234 below reorder threshold',
        affectedEntity: 'SKU-1234',
        detectedAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'acknowledged',
      ),
    ],
    resolvedIssues: [
      ComplianceIssue(
        id: 'issue-004',
        type: 'fraud',
        severity: 'critical',
        title: 'Suspicious Payment Attempt',
        description:
            'Multiple failed payment attempts detected from account ACC-9821',
        affectedEntity: 'ACC-9821',
        detectedAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'resolved',
      ),
    ],
  );
});

/// Admin Compliance Dashboard Screen
class AdminComplianceDashboardScreen extends ConsumerWidget {
  const AdminComplianceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complianceAsync = ref.watch(complianceScoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Dashboard'),
        elevation: 0,
      ),
      body: complianceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading compliance data: $error'),
            ],
          ),
        ),
        data: (compliance) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Score Card
              _buildOverallScoreCard(context, compliance),
              const SizedBox(height: 24),

              // Category Scores
              _buildCategoryScores(context, compliance),
              const SizedBox(height: 24),

              // Issues Section
              _buildIssuesSection(context, compliance),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallScoreCard(
      BuildContext context, ComplianceScore compliance) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Overall Compliance Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: compliance.overallScore / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(compliance.overallScore),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          compliance.overallScore.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'out of 100',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  avatar: Icon(
                    Icons.warning,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  label: Text(
                    '${compliance.openIssues.length} Open Issues',
                  ),
                  backgroundColor: Colors.orange.shade50,
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  label: Text(
                    '${compliance.resolvedIssues.length} Resolved',
                  ),
                  backgroundColor: Colors.green.shade50,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryScores(
      BuildContext context, ComplianceScore compliance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _ScoreBar(
          label: 'Pricing Compliance',
          score: compliance.pricingScore,
          icon: Icons.local_offer,
        ),
        const SizedBox(height: 12),
        _ScoreBar(
          label: 'Inventory Accuracy',
          score: compliance.inventoryScore,
          icon: Icons.inventory_2,
        ),
        const SizedBox(height: 12),
        _ScoreBar(
          label: 'Delivery Performance',
          score: compliance.deliveryScore,
          icon: Icons.local_shipping,
        ),
        const SizedBox(height: 12),
        _ScoreBar(
          label: 'Fraud Detection',
          score: compliance.fraudScore,
          icon: Icons.security,
        ),
      ],
    );
  }

  Widget _buildIssuesSection(BuildContext context, ComplianceScore compliance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open Issues (${compliance.openIssues.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (compliance.openIssues.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle,
                        size: 48, color: Colors.green.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'No open issues',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...compliance.openIssues.map(
              (issue) => _ComplianceIssueCard(issue: issue, onResolve: () {})),
        const SizedBox(height: 24),
        if (compliance.resolvedIssues.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recently Resolved',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...compliance.resolvedIssues.map((issue) =>
                  _ComplianceIssueCard(issue: issue, onResolve: () {})),
            ],
          ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}

/// Score Bar Widget
class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;

  const _ScoreBar({
    required this.label,
    required this.score,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColor(score),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}

/// Compliance Issue Card Widget
class _ComplianceIssueCard extends StatelessWidget {
  final ComplianceIssue issue;
  final VoidCallback onResolve;

  const _ComplianceIssueCard({
    required this.issue,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      borderOnForeground: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _getSeverityColor(),
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getTypeIcon(),
                              size: 18,
                              color: _getSeverityColor(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                issue.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          issue.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getSeverityColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      issue.severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getSeverityColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Entity: ${issue.affectedEntity}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    _formatDate(issue.detectedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              if (issue.status == 'open')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onResolve,
                      child: const Text('Mark Resolved'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor() {
    switch (issue.severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (issue.type) {
      case 'pricing':
        return Icons.local_offer;
      case 'inventory':
        return Icons.inventory_2;
      case 'delivery':
        return Icons.local_shipping;
      case 'fraud':
        return Icons.security;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
