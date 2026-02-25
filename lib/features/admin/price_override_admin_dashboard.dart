import 'package:flutter/material.dart';

/// Admin Dashboard for Price Override Approvals
/// Temporarily disabled for MVP - will be re-enabled in v1.1
class PriceOverrideAdminDashboard extends StatelessWidget {
  const PriceOverrideAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Price Management'),
      ),
      body: const Center(
        child: Text('Price admin features will be available in v1.1'),
      ),
    );
  }
}
