import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/core/providers/rbac_providers.dart';
import 'package:coop_commerce/features/home/role_screens/member_home_screen.dart';
import 'package:coop_commerce/features/selling/seller_home_screen.dart';
import 'package:coop_commerce/features/home/role_screens/wholesale_buyer_home_screen.dart';

/// Wrapper that renders the correct home screen based on user role
class RoleAwareHomeScreen extends ConsumerWidget {
  const RoleAwareHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final highestRole = ref.watch(highestUserRoleProvider);

    // If not authenticated, show a login prompt
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in'),
        ),
      );
    }

    // Route to home screen based on highest role
    return _buildHomeScreenForRole(highestRole);
  }

  Widget _buildHomeScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.wholesaleBuyer:
        return const WholesaleBuyerHomeScreen();

      case UserRole.coopMember:
        return const MemberHomeScreen();

      case UserRole.seller:
        return const SellerHomeScreen();

      case UserRole.premiumMember:
      case UserRole.franchiseOwner:
      case UserRole.storeManager:
      case UserRole.storeStaff:
      case UserRole.institutionalBuyer:
      case UserRole.institutionalApprover:
      case UserRole.warehouseStaff:
      case UserRole.deliveryDriver:
      case UserRole.admin:
      case UserRole.superAdmin:
        return const WholesaleBuyerHomeScreen();
    }
  }
}
