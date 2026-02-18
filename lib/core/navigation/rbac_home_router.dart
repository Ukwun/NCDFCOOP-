import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/welcome/auth_provider.dart';
import 'package:coop_commerce/core/providers/rbac_providers.dart';
import 'package:coop_commerce/features/home/role_screens/consumer_home_screen.dart';
import 'package:coop_commerce/features/home/role_screens/member_home_screen.dart';
import 'package:coop_commerce/features/home/role_screens/franchise_owner_home_screen.dart';
import 'package:coop_commerce/features/home/role_screens/institutional_buyer_home_screen.dart';
import 'package:coop_commerce/features/home/role_screens/warehouse_staff_home_screen.dart';
import 'package:coop_commerce/features/home/role_screens/admin_home_screen.dart';

/// Home Router with RBAC enforcement
/// Routes users to appropriate home screen based on their roles
class RBACHomeRouter extends ConsumerWidget {
  const RBACHomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final highestRoleAsync = ref.watch(highestUserRoleProvider);

    return authState.when(
      // User is authenticated
      data: (user) {
        if (user == null) {
          return const _UnauthorizedScreen();
        }

        return highestRoleAsync.when(
          data: (highestRole) {
            return _buildRoleScreen(highestRole);
          },
          loading: () => const _LoadingScreen(),
          error: (error, st) => _ErrorScreen(
            error: error.toString(),
            stackTrace: st.toString(),
          ),
        );
      },
      // User is still loading
      loading: () => const _LoadingScreen(),
      // Error fetching auth state
      error: (error, stackTrace) => _ErrorScreen(
        error: error.toString(),
        stackTrace: stackTrace.toString(),
      ),
    );
  }

  /// Build the appropriate home screen for the user's highest role
  Widget _buildRoleScreen(UserRole highestRole) {
    switch (highestRole) {
      case UserRole.consumer:
        return const ConsumerHomeScreen();
      case UserRole.coopMember:
        return const MemberHomeScreen();
      case UserRole.franchiseOwner:
        return const FranchiseOwnerHomeScreen();
      case UserRole.storeManager:
        return const FranchiseOwnerHomeScreen(); // Uses same screen
      case UserRole.storeStaff:
        return const ConsumerHomeScreen(); // Placeholder
      case UserRole.institutionalBuyer:
        return const InstitutionalBuyerHomeScreen();
      case UserRole.institutionalApprover:
        return const InstitutionalBuyerHomeScreen(); // Uses same screen
      case UserRole.warehouseStaff:
        return const WarehouseStaffHomeScreen();
      case UserRole.deliveryDriver:
        // Driver has separate app flow - for now use warehouse staff screen
        return const WarehouseStaffHomeScreen();
      case UserRole.admin:
        return const AdminHomeScreen();
      case UserRole.superAdmin:
        return const AdminHomeScreen(); // Uses same screen as admin
    }
  }
}

/// Loading screen with branding
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Loading your dashboard...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unauthorized access screen
class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unauthorized'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You do not have permission to access this area.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/welcome',
                  (route) => false,
                );
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen
class _ErrorScreen extends StatelessWidget {
  final String error;
  final String stackTrace;

  const _ErrorScreen({
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'An Error Occurred',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/welcome',
                  (route) => false,
                );
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
