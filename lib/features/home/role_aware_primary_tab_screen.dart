import 'package:coop_commerce/core/auth/role.dart';
import 'package:coop_commerce/features/cart/cart_screen.dart';
import 'package:coop_commerce/features/dashboard/personalized_dashboard_screen.dart';
import 'package:coop_commerce/features/home/role_aware_home_screen.dart';
import 'package:coop_commerce/features/messages/messages_screen.dart';
import 'package:coop_commerce/features/profile/role_aware_profile_screen.dart';
import 'package:coop_commerce/features/offers/offers_screen.dart';
import 'package:coop_commerce/features/products/products_listing_screen.dart';
import 'package:coop_commerce/features/selling/seller_home_screen.dart';
import 'package:coop_commerce/features/selling/seller_earnings_screen.dart';
import 'package:coop_commerce/features/selling/screens/seller_products_tab_screen.dart';
import 'package:coop_commerce/features/home/role_screens/wholesale_buyer_home_screen.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoleAwarePrimaryTabScreen extends ConsumerWidget {
  const RoleAwarePrimaryTabScreen({required this.tabIndex, super.key});

  final int tabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);

    if (_isMember(role)) {
      return _buildMemberTab(tabIndex);
    }

    if (_isSeller(role)) {
      return _buildSellerTab(tabIndex);
    }

    if (_isWholesale(role)) {
      return _buildWholesaleTab(tabIndex, role);
    }

    return _buildDefaultTab(tabIndex);
  }

  bool _isMember(UserRole role) {
    return role == UserRole.coopMember;
  }

  bool _isSeller(UserRole role) {
    return role == UserRole.seller;
  }

  bool _isWholesale(UserRole role) {
    return role == UserRole.wholesaleBuyer ||
        role == UserRole.institutionalBuyer;
  }

  Widget _buildMemberTab(int index) {
    switch (index) {
      case 0:
        return const RoleAwareHomeScreen();
      case 1:
        return const ProductsListingScreen(title: 'Member Marketplace');
      case 2:
        return const MessagesScreen();
      case 3:
        return const CartScreen();
      case 4:
        return const RoleAwareProfileScreen();
      default:
        return const RoleAwareHomeScreen();
    }
  }

  Widget _buildSellerTab(int index) {
    switch (index) {
      case 0:
        return const SellerHomeScreen();
      case 1:
        return const MessagesScreen();
      case 2:
        return const SellerProductsTabScreen();
      case 3:
        return const SellerEarningsScreen();
      case 4:
        return const RoleAwareProfileScreen();
      default:
        return const SellerHomeScreen();
    }
  }

  Widget _buildWholesaleTab(int index, UserRole role) {
    switch (index) {
      case 0:
        return const WholesaleBuyerHomeScreen();
      case 1:
        return const ProductsListingScreen(title: 'Wholesale Marketplace');
      case 2:
        return const MessagesScreen();
      case 3:
        return const CartScreen();
      case 4:
        return const RoleAwareProfileScreen();
      default:
        return const WholesaleBuyerHomeScreen();
    }
  }

  Widget _buildDefaultTab(int index) {
    switch (index) {
      case 0:
        return const RoleAwareHomeScreen();
      case 1:
        return const OffersScreen();
      case 2:
        return const MessagesScreen();
      case 3:
        return const CartScreen();
      case 4:
        return const RoleAwareProfileScreen();
      default:
        return const RoleAwareHomeScreen();
    }
  }
}

class AnalyticsDashboardShell extends StatelessWidget {
  const AnalyticsDashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const PersonalizedDashboardScreen();
  }
}
