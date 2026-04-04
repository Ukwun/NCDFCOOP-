import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// APP FOOTER NAVIGATION (Bottom Tab Bar)
/// Provides quick access to: Home, Offer, Message, Cart, My NCDFCOOP
class AppFooterNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showBadges;
  final int messageCount;
  final int cartCount;

  const AppFooterNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showBadges = true,
    this.messageCount = 0,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.local_offer_outlined,
                activeIcon: Icons.local_offer,
                label: 'Offer',
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.message_outlined,
                activeIcon: Icons.message,
                label: 'Message',
                badgeCount: showBadges ? messageCount : null,
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                label: 'Cart',
                badgeCount: showBadges ? cartCount : null,
              ),
              _buildNavItem(
                context,
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'My NCDFCOOP',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? badgeCount,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () {
        onTap(index);
        // Navigate based on index
        switch (index) {
          case 0:
            // Home - already there
            context.pushNamed('home');
            break;
          case 1:
            // Offer/Promotions - navigate to products page
            context.pushNamed('products');
            break;
          case 2:
            // Messages - navigate to notifications
            context.pushNamed('notifications');
            break;
          case 3:
            // Cart
            context.pushNamed('cart');
            break;
          case 4:
            // Profile
            context.pushNamed('profile');
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.textLight,
                size: 24,
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isActive ? AppColors.primary : AppColors.textLight,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful wrapper for managing footer state
class AppFooterNavigationManager extends StatefulWidget {
  final Widget Function(int) builder;

  const AppFooterNavigationManager({
    super.key,
    required this.builder,
  });

  @override
  State<AppFooterNavigationManager> createState() =>
      _AppFooterNavigationManagerState();
}

class _AppFooterNavigationManagerState
    extends State<AppFooterNavigationManager> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.builder(_currentIndex),
      bottomNavigationBar: AppFooterNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
