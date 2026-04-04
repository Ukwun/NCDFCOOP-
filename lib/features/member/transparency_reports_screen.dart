import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Transparency Reports Screen for Coop Members
/// Shows where member fees go, financial health, and social impact metrics
class TransparencyReportsScreen extends StatefulWidget {
  const TransparencyReportsScreen({Key? key}) : super(key: key);

  @override
  State<TransparencyReportsScreen> createState() =>
      _TransparencyReportsScreenState();
}

class _TransparencyReportsScreenState extends State<TransparencyReportsScreen> {
  String _selectedTab = 'financial'; // financial, social, operations

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transparency Reports',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Financial',
                      selected: _selectedTab == 'financial',
                      onTap: () => setState(() => _selectedTab = 'financial'),
                    ),
                    const SizedBox(width: 8),
                    _TabButton(
                      label: 'Social Impact',
                      selected: _selectedTab == 'social',
                      onTap: () => setState(() => _selectedTab = 'social'),
                    ),
                    const SizedBox(width: 8),
                    _TabButton(
                      label: 'Operations',
                      selected: _selectedTab == 'operations',
                      onTap: () => setState(() => _selectedTab = 'operations'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Content based on selected tab
              if (_selectedTab == 'financial') ...[
                _buildFinancialSection(),
              ] else if (_selectedTab == 'social') ...[
                _buildSocialImpactSection(),
              ] else ...[
                _buildOperationsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Text(
          'Annual Financial Summary (2025)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        // Key metrics
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Revenue',
                value: '₦4.2M',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Operating Costs',
                value: '₦1.8M',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Member Dividends',
                value: '₦1.2M',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Reserve Fund',
                value: '₦1.2M',
                color: Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Expense breakdown
        Text(
          'Where Member Fees Go',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        _ExpenseBreakdown(
          items: [
            {
              'category': 'Technology & Platform',
              'percentage': 25,
              'amount': '₦420,000',
              'color': Colors.blue,
            },
            {
              'category': 'Operations & Logistics',
              'percentage': 35,
              'amount': '₦588,000',
              'color': Colors.green,
            },
            {
              'category': 'Staff & Administration',
              'percentage': 20,
              'amount': '₦336,000',
              'color': Colors.orange,
            },
            {
              'category': 'Community Programs',
              'percentage': 12,
              'amount': '₦201,600',
              'color': Colors.purple,
            },
            {
              'category': 'Expansion & Innovation',
              'percentage': 8,
              'amount': '₦134,400',
              'color': AppColors.primary,
            },
          ],
        ),

        const SizedBox(height: 20),

        // Detailed breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detailed Expense Report',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow('Server & Cloud Infrastructure', '₦120,000'),
              _DetailRow('Payment Gateway Fees', '₦95,000', true),
              _DetailRow('Driver Incentives', '₦240,000'),
              _DetailRow('Warehouse Rent', '₦150,000', true),
              _DetailRow('Staff Salaries', '₦280,000'),
              _DetailRow('Training Programs', '₦56,000', true),
              _DetailRow('Social Impact: Education', '₦95,400'),
              _DetailRow('Market Expansion', '₦80,000', true),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Download option
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _downloadReport(context),
            icon: const Icon(Icons.file_download),
            label: const Text('Download Full Report (PDF)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialImpactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Impact & Sustainability',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        // Impact metrics
        _ImpactMetric(
          icon: Icons.people,
          title: 'Members Supported',
          value: '2,847',
          description: 'Active cooperative members',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),

        _ImpactMetric(
          icon: Icons.shopping_cart,
          title: 'Farmers & Producers',
          value: '156',
          description: 'Direct market access through platform',
          color: Colors.green,
        ),
        const SizedBox(height: 12),

        _ImpactMetric(
          icon: Icons.school,
          title: 'Students Supported',
          value: '324',
          description: 'Scholarships via member dividends',
          color: Colors.purple,
        ),
        const SizedBox(height: 12),

        _ImpactMetric(
          icon: Icons.local_shipping,
          title: 'Job Opportunities',
          value: '183',
          description: 'Drivers, staff, and logistics partners',
          color: Colors.orange,
        ),

        const SizedBox(height: 24),

        // Community programs
        Text(
          'Community Initiatives',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        _ProgramCard(
          title: 'Agricultural Training Program',
          description: 'Helping farmers improve yields and sustainability',
          participants: '89 farmers',
          status: 'Active',
          investment: '₦450,000',
        ),
        const SizedBox(height: 12),

        _ProgramCard(
          title: 'Youth Empowerment Initiative',
          description: 'Skills training and business development for youth',
          participants: '156 youth',
          status: 'Active',
          investment: '₦720,000',
        ),
        const SizedBox(height: 12),

        _ProgramCard(
          title: 'Women in Commerce',
          description: 'Support for female entrepreneurs and sellers',
          participants: '234 women',
          status: 'Expanding',
          investment: '₦580,000',
        ),

        const SizedBox(height: 20),

        // Environmental impact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.eco, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Environmental Impact',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ImpactStat('Plastic reduced', '3.2 tons', Colors.green[700]!),
              const SizedBox(height: 8),
              _ImpactStat('CO₂ offset via partnerships', '156 tons',
                  Colors.green[700]!),
              const SizedBox(height: 8),
              _ImpactStat('Trees planted via rebate program', '1,240',
                  Colors.green[700]!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operational Performance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        // Performance metrics
        _PerformanceCard(
          title: 'Delivery Performance',
          metric: '97.2%',
          description: 'On-time delivery rate',
          color: Colors.green,
        ),
        const SizedBox(height: 12),

        _PerformanceCard(
          title: 'Customer Satisfaction',
          metric: '4.6/5',
          description: 'Average member rating',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),

        _PerformanceCard(
          title: 'System Uptime',
          metric: '99.8%',
          description: 'Platform availability this year',
          color: Colors.purple,
        ),
        const SizedBox(height: 12),

        _PerformanceCard(
          title: 'Resolution Time',
          metric: '2.1 hours',
          description: 'Average issue resolution',
          color: Colors.orange,
        ),

        const SizedBox(height: 24),

        // Compliance & Security
        Text(
          'Compliance & Security',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _ComplianceItem('✓ Registered with Corporate Affairs Commission'),
              _ComplianceItem(
                  '✓ Compliant with Nigeria Data Protection Regulation (NDPR)'),
              _ComplianceItem('✓ Annual independent audit conducted'),
              _ComplianceItem('✓ PCI-DSS compliance for payments'),
              _ComplianceItem(
                  '✓ Regular security audits & penetration testing'),
              _ComplianceItem('✓ Members data encrypted end-to-end'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Governance structure
        Text(
          'Governance Structure',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GovernanceLevel('Board of Directors',
                  'Strategic oversight - 7 members elected by members'),
              const SizedBox(height: 12),
              _GovernanceLevel('Executive Committee',
                  'Day-to-day operations - 5 committee members'),
              const SizedBox(height: 12),
              _GovernanceLevel('Operations Team',
                  'Platform & logistics management - 23 staff members'),
              const SizedBox(height: 12),
              _GovernanceLevel('Member Assembly',
                  'Annual meeting - All members vote on major decisions'),
            ],
          ),
        ),
      ],
    );
  }

  void _downloadReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report download started...'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _DetailRow(String label, String amount, [bool spacer = false]) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        if (spacer) const SizedBox(height: 12),
      ],
    );
  }

  Widget _ImpactStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _ComplianceItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _GovernanceLevel(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// Tab button widget
class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Expense breakdown widget
class _ExpenseBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _ExpenseBreakdown({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['category'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item['percentage']}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item['amount'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (item['percentage'] as int) / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(item['color'] as Color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Impact metric widget
class _ImpactMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Color color;

  const _ImpactMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Program card widget
class _ProgramCard extends StatelessWidget {
  final String title;
  final String description;
  final String participants;
  final String status;
  final String investment;

  const _ProgramCard({
    required this.title,
    required this.description,
    required this.participants,
    required this.status,
    required this.investment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: status == 'Active'
                      ? Colors.green[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: status == 'Active'
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                participants,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                investment,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Performance card widget
class _PerformanceCard extends StatelessWidget {
  final String title;
  final String metric;
  final String description;
  final Color color;

  const _PerformanceCard({
    required this.title,
    required this.metric,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            metric,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
