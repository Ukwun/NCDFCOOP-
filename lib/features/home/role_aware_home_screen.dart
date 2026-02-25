import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/core/providers/rbac_providers.dart';
import 'package:coop_commerce/features/home/role_screens/consumer_home_screen.dart';
import 'package:coop_commerce/features/home/role_screens/member_home_screen.dart';
import 'package:coop_commerce/features/home/role_screens/franchise_owner_home_screen_v2.dart';
import 'package:coop_commerce/features/home/role_screens/institutional_buyer_home_screen_v2.dart';
import 'package:coop_commerce/features/home/role_screens/warehouse_staff_home_screen.dart';
import 'package:coop_commerce/features/home/role_screens/admin_home_screen_v2.dart';

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
      case UserRole.consumer:
        return const ConsumerHomeScreen();

      case UserRole.coopMember:
        return const MemberHomeScreen();

      case UserRole.franchiseOwner:
        return const FranchiseOwnerHomeScreenV2();

      case UserRole.storeManager:
        return const FranchiseOwnerHomeScreenV2(); // Same UI as franchise owner

      case UserRole.storeStaff:
        return const WarehouseStaffHomeScreen(); // Similar task-based UI

      case UserRole.institutionalBuyer:
        return const InstitutionalBuyerHomeScreenV2();

      case UserRole.institutionalApprover:
        return const InstitutionalBuyerHomeScreenV2(); // Similar approval flows

      case UserRole.warehouseStaff:
        return const WarehouseStaffHomeScreen();

      case UserRole.deliveryDriver:
        return const WarehouseStaffHomeScreen(); // Similar logistics UI

      case UserRole.admin:
        return const AdminHomeScreenV2();

      case UserRole.superAdmin:
        return const AdminHomeScreenV2();

      default:
        return const ConsumerHomeScreen();
    }
  }
}
