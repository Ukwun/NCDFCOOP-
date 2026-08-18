import 'package:flutter/material.dart';

enum LegalDocument { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.document, super.key});
  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final privacy = document == LegalDocument.privacy;
    final sections = privacy ? _privacySections : _termsSections;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F3),
      appBar: AppBar(
        title: Text(privacy ? 'Privacy Policy' : 'Terms of Service'),
        backgroundColor: const Color(0xFF052E24),
        foregroundColor: Colors.white,
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      privacy
                          ? 'CoopX Privacy Policy'
                          : 'CoopX Terms of Service',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text('Effective: 12 August 2026'),
                    const SizedBox(height: 24),
                    for (final section in sections) ...[
                      Text(section.$1,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF064E3B))),
                      const SizedBox(height: 8),
                      Text(section.$2,
                          style: const TextStyle(
                              color: Color(0xFF475569), height: 1.6)),
                      const SizedBox(height: 24),
                    ],
                    const Text(
                        'Questions or requests can be submitted through Contact Support in the CoopX application.',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _privacySections = <(String, String)>[
  (
    'Information we process',
    'CoopX processes account identity and contact details, verified roles, seller or buyer profiles, product and inventory records, inquiries and messages, orders and fulfilment events, rewards, payout requests, device diagnostics and security activity needed to operate the marketplace.'
  ),
  (
    'How information is used',
    'Information is used to authenticate accounts, enforce role-based access, show relevant marketplace content, fulfil orders, maintain buyer–seller conversations, calculate authorized rewards and payouts, prevent abuse, provide support and improve reliability.'
  ),
  (
    'Service providers',
    'CoopX uses Firebase for authentication, database, storage, messaging and server functions. Payment providers process payment details on their protected checkout systems; CoopX clients do not store payment-provider secret keys.'
  ),
  (
    'Sharing and visibility',
    'Information is exposed only as required for commerce. Sellers receive order and inquiry details needed to serve buyers, while operational personnel receive only information authorized for their assigned role.'
  ),
  (
    'Retention and security',
    'Records are retained for account operation, commerce accountability, fraud prevention and applicable financial or legal obligations. Access controls, authenticated requests, audit records and protected server operations reduce unauthorized access.'
  ),
  (
    'Your choices',
    'Users can update ordinary profile information, manage communication preferences and request account deletion. Some transaction records may be retained where required for disputes, fraud prevention, accounting or legal compliance.'
  ),
];

const _termsSections = <(String, String)>[
  (
    'Using CoopX',
    'You must provide accurate account information, protect your sign-in credentials and use only roles and permissions assigned to your account. You may not impersonate another participant, bypass access controls or misuse marketplace data.'
  ),
  (
    'Listings and sellers',
    'Sellers are responsible for accurate product descriptions, lawful goods, stock, pricing and fulfilment. Listings may require review before public discovery and may be suspended when they violate platform requirements.'
  ),
  (
    'Orders and payments',
    'An order becomes binding when the applicable checkout and confirmation steps are completed. Payment status is determined by verified provider or bank confirmation, not by a client-side success message.'
  ),
  (
    'Member and wholesale access',
    'Member benefits, wholesale pricing, minimum quantities, rewards and account limits depend on the verified profile and current eligibility. Displayed access does not independently grant a privileged role or credit facility.'
  ),
  (
    'Acceptable use',
    'Users must not upload harmful content, manipulate prices or reviews, create fraudulent transactions, interfere with other accounts, probe the service, or use CoopX for unlawful trade.'
  ),
  (
    'Availability and enforcement',
    'CoopX may restrict features or accounts to protect users, investigate abuse, comply with law or preserve marketplace integrity. Service interruptions may occur for maintenance or provider outages.'
  ),
];
