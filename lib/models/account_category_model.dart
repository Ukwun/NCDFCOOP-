import 'package:flutter/material.dart';
import 'package:coop_commerce/core/auth/role.dart';

/// Category model for Member (B2C) user segment
class MemberCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isPremium;
  final String? badge;

  MemberCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.isPremium = false,
    this.badge,
  });
}

/// Category model for Wholesale Buyer (B2B) user segment
class WholesaleCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String type; // 'business' or 'franchise'
  final String? badge;

  WholesaleCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.type,
    this.badge,
  });
}

/// Account menu item model
class AccountMenuItem {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool showDivider;
  final bool isSectionHeader;

  AccountMenuItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.showDivider = true,
    this.isSectionHeader = false,
  });
}

/// Category and account page config
class AccountAndCategoriesConfig {
  final UserRole userRole;
  final List<MemberCategory>? memberCategories;
  final List<WholesaleCategory>? wholesaleCategories;
  final List<AccountMenuItem> accountMenuItems;
  final bool showCooperativeTransparency;

  AccountAndCategoriesConfig({
    required this.userRole,
    this.memberCategories,
    this.wholesaleCategories,
    required this.accountMenuItems,
    this.showCooperativeTransparency = false,
  });

  factory AccountAndCategoriesConfig.forMember() {
    return AccountAndCategoriesConfig(
      userRole: UserRole.coopMember,
      memberCategories: [
        MemberCategory(
          id: 'member',
          title: 'Member',
          subtitle: 'Standard cooperative member benefits',
          icon: Icons.people_alt_outlined,
          iconColor: const Color(0xFF8B6F47),
          isPremium: false,
        ),
        MemberCategory(
          id: 'premium',
          title: 'Premium',
          subtitle: 'Upgrade for exclusive benefits',
          icon: Icons.star_outlined,
          iconColor: const Color(0xFFFFD700),
          isPremium: true,
          badge: 'NEW',
        ),
      ],
      accountMenuItems: _getMemberAccountMenuItems(),
      showCooperativeTransparency: true,
    );
  }

  factory AccountAndCategoriesConfig.forWholesaleBuyer() {
    return AccountAndCategoriesConfig(
      userRole: UserRole.wholesaleBuyer,
      wholesaleCategories: [
        WholesaleCategory(
          id: 'business',
          title: 'Business',
          subtitle: 'Individual business purchases',
          icon: Icons.business_outlined,
          iconColor: const Color(0xFF2E5090),
          type: 'business',
        ),
        WholesaleCategory(
          id: 'franchise',
          title: 'Franchise',
          subtitle: 'Multi-location franchise management',
          icon: Icons.store_outlined,
          iconColor: const Color(0xFFF3951A),
          type: 'franchise',
          badge: 'PREMIUM',
        ),
      ],
      accountMenuItems: _getWholesaleBuyerAccountMenuItems(),
      showCooperativeTransparency: false,
    );
  }

  static List<AccountMenuItem> _getMemberAccountMenuItems() {
    return [
      // Orders & Rewards
      AccountMenuItem(
        id: 'my-orders',
        label: 'My Orders',
        subtitle: 'Track and manage orders',
        icon: Icons.shopping_bag_outlined,
        route: 'orders',
      ),
      AccountMenuItem(
        id: 'my-rewards',
        label: 'My Rewards',
        subtitle: 'Loyalty points and redemptions',
        icon: Icons.card_giftcard_outlined,
        route: 'my-rewards',
      ),

      // Cooperative
      AccountMenuItem(
        id: 'cooperative-transparency',
        label: 'Cooperative Transparency',
        subtitle: 'View reports and dividends',
        icon: Icons.assessment_outlined,
        route: 'cooperative-transparency',
        isSectionHeader: true,
      ),

      // Wishlist & Saved
      AccountMenuItem(
        id: 'saved-items',
        label: 'Saved Items',
        subtitle: 'Your wishlist items',
        icon: Icons.favorite_outline,
        route: 'saved-items',
      ),

      // Payments & Addresses
      AccountMenuItem(
        id: 'payment-methods',
        label: 'Payment Methods',
        subtitle: 'Manage cards and wallets',
        icon: Icons.account_balance_wallet_outlined,
        route: 'payment-methods',
      ),
      AccountMenuItem(
        id: 'addresses',
        label: 'Addresses',
        subtitle: 'Delivery addresses',
        icon: Icons.location_on_outlined,
        route: 'addresses',
      ),

      // Settings & Support
      AccountMenuItem(
        id: 'notifications',
        label: 'Notifications',
        subtitle: 'Push & email preferences',
        icon: Icons.notifications_outlined,
        route: 'notifications',
      ),
      AccountMenuItem(
        id: 'help-support',
        label: 'Help & Support',
        subtitle: 'FAQs and contact support',
        icon: Icons.help_outline,
        route: 'help-support',
      ),
      AccountMenuItem(
        id: 'settings',
        label: 'Settings',
        subtitle: 'Account and app settings',
        icon: Icons.settings_outlined,
        route: 'settings',
      ),
    ];
  }

  static List<AccountMenuItem> _getWholesaleBuyerAccountMenuItems() {
    return [
      // Orders & Invoices
      AccountMenuItem(
        id: 'my-orders',
        label: 'My Orders',
        subtitle: 'Track and manage orders',
        icon: Icons.shopping_bag_outlined,
        route: 'orders',
      ),
      AccountMenuItem(
        id: 'invoices',
        label: 'Invoices',
        subtitle: 'View and download invoices',
        icon: Icons.receipt_outlined,
        route: 'invoices',
      ),

      // Business Tools
      AccountMenuItem(
        id: 'bulk-orders',
        label: 'Bulk Orders',
        subtitle: 'Create and manage bulk orders',
        icon: Icons.inventory_2_outlined,
        route: 'bulk-orders',
        isSectionHeader: true,
      ),
      AccountMenuItem(
        id: 'catalogs',
        label: 'Catalogs',
        subtitle: 'Browse wholesale catalogs',
        icon: Icons.inventory_2_outlined,
        route: 'catalogs',
      ),

      // Account Management
      AccountMenuItem(
        id: 'payment-methods',
        label: 'Payment Methods',
        subtitle: 'Manage cards and accounts',
        icon: Icons.account_balance_wallet_outlined,
        route: 'payment-methods',
      ),
      AccountMenuItem(
        id: 'addresses',
        label: 'Addresses',
        subtitle: 'Business locations',
        icon: Icons.location_on_outlined,
        route: 'addresses',
      ),
      AccountMenuItem(
        id: 'team-members',
        label: 'Team Members',
        subtitle: 'Manage account users',
        icon: Icons.group_outlined,
        route: 'team-members',
      ),

      // Support & Settings
      AccountMenuItem(
        id: 'notifications',
        label: 'Notifications',
        subtitle: 'Email & SMS preferences',
        icon: Icons.notifications_outlined,
        route: 'notifications',
      ),
      AccountMenuItem(
        id: 'help-support',
        label: 'Help & Support',
        subtitle: 'Business support & docs',
        icon: Icons.help_outline,
        route: 'help-support',
      ),
      AccountMenuItem(
        id: 'settings',
        label: 'Settings',
        subtitle: 'Account and app settings',
        icon: Icons.settings_outlined,
        route: 'settings',
      ),
    ];
  }
}
