import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';

/// Voting Dashboard Screen for Coop Members
/// Members can view active proposals and vote on cooperative decisions
class VotingDashboardScreen extends StatefulWidget {
  const VotingDashboardScreen({Key? key}) : super(key: key);

  @override
  State<VotingDashboardScreen> createState() => _VotingDashboardScreenState();
}

class _VotingDashboardScreenState extends State<VotingDashboardScreen> {
  String _filterStatus = 'active'; // active, closed, archived

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Member Voting',
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
              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Active Proposals',
                      selected: _filterStatus == 'active',
                      onTap: () => setState(() => _filterStatus = 'active'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Closed Votes',
                      selected: _filterStatus == 'closed',
                      onTap: () => setState(() => _filterStatus = 'closed'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Archived',
                      selected: _filterStatus == 'archived',
                      onTap: () => setState(() => _filterStatus = 'archived'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Voting guidelines
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Voting Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Each member has 1 vote per proposal. Proposals pass with 50%+ member approval. Voting periods are typically 7 days.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Active proposals section
              if (_filterStatus == 'active') ...[
                Text(
                  'Active Proposals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildProposalList('active'),
              ],

              // Closed votes section
              if (_filterStatus == 'closed') ...[
                Text(
                  'Closed Votes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildProposalList('closed'),
              ],

              // Archived section
              if (_filterStatus == 'archived') ...[
                Text(
                  'Archived Votes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildProposalList('archived'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProposalList(String status) {
    final proposals = {
      'active': [
        {
          'id': 'PROP-2026-001',
          'title': 'Increase member dividend payout from 2% to 3%',
          'description': 'Proposal to increase annual member dividends',
          'category': 'Finance',
          'votesFor': 245,
          'votesAgainst': 52,
          'totalMembers': 320,
          'daysLeft': 3,
          'youVoted': false,
        },
        {
          'id': 'PROP-2026-002',
          'title': 'Expand warehouse to include cold storage',
          'description': 'Capital investment for facility expansion',
          'category': 'Infrastructure',
          'votesFor': 178,
          'votesAgainst': 89,
          'totalMembers': 320,
          'daysLeft': 5,
          'youVoted': true,
        },
        {
          'id': 'PROP-2026-003',
          'title':
              'Launch sustainability initiative for eco-friendly packaging',
          'description': 'Reduce plastic use across all deliveries',
          'category': 'Environment',
          'votesFor': 298,
          'votesAgainst': 15,
          'totalMembers': 320,
          'daysLeft': 1,
          'youVoted': false,
        },
      ],
      'closed': [
        {
          'id': 'PROP-2026-004',
          'title': 'Approve new vendor partnership with Agri-Tech Solutions',
          'description': 'Strategic partnership to improve supply chain',
          'category': 'Partnerships',
          'votesFor': 267,
          'votesAgainst': 28,
          'totalMembers': 320,
          'status': 'Approved',
          'passedDate': '2026-03-28',
          'youVoted': true,
        },
        {
          'id': 'PROP-2026-005',
          'title': 'Establish member advisory council',
          'description': 'Create governance body for member input',
          'category': 'Governance',
          'votesFor': 89,
          'votesAgainst': 201,
          'totalMembers': 320,
          'status': 'Rejected',
          'passedDate': '2026-03-21',
          'youVoted': false,
        },
      ],
      'archived': [
        {
          'id': 'PROP-2025-098',
          'title': 'Annual membership fee structure 2025',
          'description': 'Approved membership fees for 2025',
          'category': 'Finance',
          'votesFor': 312,
          'votesAgainst': 8,
          'totalMembers': 320,
          'status': 'Approved',
          'passedDate': '2025-12-15',
          'youVoted': true,
        },
      ],
    };

    final items = proposals[status] as List<Map<String, dynamic>>? ?? [];

    if (items.isEmpty) {
      return [
        SizedBox(
          height: 150,
          child: Center(
            child: Text(
              'No proposals in this category',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ),
      ];
    }

    return items.map((proposal) {
      return Column(
        children: [
          _ProposalCard(proposal: proposal),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
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

/// Proposal card widget
class _ProposalCard extends StatefulWidget {
  final Map<String, dynamic> proposal;

  const _ProposalCard({required this.proposal});

  @override
  State<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<_ProposalCard> {
  late bool _userVoted;

  @override
  void initState() {
    super.initState();
    _userVoted = widget.proposal['youVoted'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.proposal.containsKey('daysLeft');
    final votesFor = widget.proposal['votesFor'] as int;
    final votesAgainst = widget.proposal['votesAgainst'] as int;
    final totalVotes = votesFor + votesAgainst;
    final percentFor = totalVotes > 0 ? (votesFor / totalVotes * 100) : 0.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.proposal['id'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.proposal['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.proposal['category'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              widget.proposal['description'] as String,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // Voting progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Voting Results',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '$totalVotes / ${widget.proposal['totalMembers']} votes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentFor / 100,
                    minHeight: 24,
                    backgroundColor: Colors.red[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green[600]!,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'For: $votesFor (${percentFor.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Against: $votesAgainst (${(100 - percentFor).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status & actions
            if (isActive) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Left',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.proposal['daysLeft']} days',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  if (!_userVoted)
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _vote(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Vote For',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _vote(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Vote Against',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.blue, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'You Voted',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Outcome: ${widget.proposal['status'] as String}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.proposal['status'] == 'Approved'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  Text(
                    'Ended: ${widget.proposal['passedDate'] as String}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _vote(BuildContext context, bool voteFor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Vote'),
        content: Text(
          'You are voting ${voteFor ? 'FOR' : 'AGAINST'} this proposal.\n\nThis action cannot be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _userVoted = true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Your vote has been recorded (${voteFor ? 'FOR' : 'AGAINST'})',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: voteFor ? Colors.green : Colors.red,
            ),
            child: Text(voteFor ? 'Vote For' : 'Vote Against'),
          ),
        ],
      ),
    );
  }
}
