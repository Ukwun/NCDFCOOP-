import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/auth_provider.dart';
import 'package:coop_commerce/core/providers/order_providers.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Membership1(),
          ),
          // Back Button
          Positioned(
            top: 35,
            left: 20,
            child: GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/welcome');
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Membership1 extends ConsumerWidget {
  const Membership1({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    // If no user, show login prompt
    if (currentUser == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Text(
            'Sign in to manage your membership',
            style: TextStyle(
              color: const Color(0xFF0A0A0A),
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 60),
        ],
      );
    }

    // Check if user has any orders
    final userOrdersAsync = ref.watch(userOrdersProvider(currentUser.id));
    
    return userOrdersAsync.when(
      data: (orders) => _buildContent(context, orders.isNotEmpty),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => _buildContent(context, false),
    );
  }

  Widget _buildContent(BuildContext context, bool isActiveMember) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header with time and status icons
        Container(
          width: double.infinity,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:45',
                style: TextStyle(
                  color: const Color(0xFF0A0A0A),
                  fontSize: 20,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                spacing: 6,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Logo
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NCDFCOOP',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF1A4E00),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'FAIRMARKET',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF1A4E00),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Conditional content based on membership status
        if (isActiveMember)
          _buildActiveMemberContent(context)
        else
          _buildNewUserContent(context),

        // Benefits sections (show for both new and active members)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            spacing: 20,
            children: [
              GestureDetector(
                onTap: () => context.pushNamed('member-benefits'),
                child: _buildBenefitSection(
                  icon: '🎁',
                  title: 'Your benefits   >>>',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE61456), Color(0xFF8D560F)],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('exclusive-pricing'),
                child: _buildBenefitSection(
                  icon: '💳',
                  title: 'Member only pricing   >>>',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1AF3AA), Color(0xFF130F8D)],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('bulk-access'),
                child: _buildBenefitSection(
                  icon: '🔑',
                  title: 'Bulk access  >>>',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF31AC7), Color(0xFF2B0B3A)],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('flash-sales'),
                child: _buildBenefitSection(
                  icon: '⚡',
                  title: 'Flash sales early access   >>>',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3981A), Color(0xFF8D0F43)],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('community-dividends'),
                child: _buildBenefitSection(
                  icon: '🎊',
                  title: 'Community dividends   >>>',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEAD8D8), Color(0xFF0F8D0F)],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Help & Support Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => context.pushNamed('help-center'),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Help?',
                          style: TextStyle(
                            color: const Color(0xFF0A0A0A),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact our support team',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Impact section with image
        Text(
          'Your membership impacts',
          style: TextStyle(
            color: const Color(0xFF0A0A0A),
            fontSize: 28,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 20),

        // Impact image
        Container(
          width: double.infinity,
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=500&h=300&fit=crop',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group,
                      size: 60,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Building Better Communities',
                      style: TextStyle(
                        color: const Color(0xFFFAFAFA),
                        fontSize: 18,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Unlock more savings section (with different copy for new users)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.50, 0.50),
              radius: 1.52,
              colors: [const Color(0xFFF3951A), const Color(0x2DF3951A)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 30,
            children: [
              Column(
                spacing: 20,
                children: [
                  Text(
                    isActiveMember ? 'Unlock more savings' : 'Start your savings journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF0A0A0A),
                      fontSize: 28,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isActiveMember)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Upgrade to ',
                            style: TextStyle(
                              color: const Color(0xFF0A0A0A),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: 'Platinum',
                            style: TextStyle(
                              color: const Color(0xFF3F2604),
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      'Make your first purchase and start earning rewards',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF0A0A0A),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    isActiveMember ? 'Save up to ₦30K monthly' : 'Join thousands saving together',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFAFAFA),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.go('/'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF1A4E00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    isActiveMember ? 'View benefits' : 'Start shopping',
                    style: TextStyle(
                      color: const Color(0xFFFAFAFA),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // New user onboarding content
  Widget _buildNewUserContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            'Your membership journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF0A0A0A),
              fontSize: 30,
              fontFamily: 'Libre Baskerville',
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 30),

          // Welcome message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A4E00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1A4E00).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              spacing: 12,
              children: [
                Text(
                  'Welcome to NCDFCOOP Fairmarket!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF0A0A0A),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'As a new member, you\'re about to join thousands of Nigerians saving money on quality products. Every purchase earns you rewards and brings you closer to exclusive benefits.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Journey roadmap
          Text(
            'Your membership roadmap',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF0A0A0A),
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // Journey steps
          _buildJourneyStep(
            number: '1',
            title: 'Make your first purchase',
            description: 'Browse our selection of fresh products and place your first order',
            icon: '🛒',
          ),
          _buildJourneyStep(
            number: '2',
            title: 'Start earning savings',
            description: 'Each purchase automatically earns you member discounts and rewards',
            icon: '💰',
          ),
          _buildJourneyStep(
            number: '3',
            title: 'Unlock tier benefits',
            description: 'As you spend more, unlock Gold and Platinum membership benefits',
            icon: '⭐',
          ),
          _buildJourneyStep(
            number: '4',
            title: 'Earn community dividends',
            description: 'Share in the profits generated by our cooperative community',
            icon: '🎁',
          ),

          const SizedBox(height: 40),

          // Benefits preview
          Text(
            'What you\'ll gain',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF0A0A0A),
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          _buildBenefitPreview(
            icon: '📊',
            title: 'Price transparency',
            description: 'See real-time savings on every product',
          ),
          _buildBenefitPreview(
            icon: '🚚',
            title: 'Fast delivery',
            description: '2-3 day delivery to most locations',
          ),
          _buildBenefitPreview(
            icon: '🛡️',
            title: 'Quality assured',
            description: 'All products verified and certified',
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Active member content showing statistics
  Widget _buildActiveMemberContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            'My cooperate wallet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF0A0A0A),
              fontSize: 30,
              fontFamily: 'Libre Baskerville',
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 20),

          // Total savings banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(color: Color(0xFF1A4E00)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      'Total savings:',
                      style: TextStyle(
                        color: const Color(0xFFFAFAFA),
                        fontSize: 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₦42,500.00',
                      style: TextStyle(
                        color: const Color(0xFFFAFAFA),
                        fontSize: 28,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF3951A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    spacing: 6,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.black,
                        size: 14,
                      ),
                      Text(
                        'Gold member',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Savings stat cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 16,
                children: [
                  _buildStatCard(
                    title: "You've saved a total of",
                    value: '₦42,500',
                    color: const Color(0xFFF3951A),
                  ),
                  _buildStatCard(
                    title: 'You saved the most on',
                    value: 'Groceries',
                    color: const Color(0xFF1A4E00),
                  ),
                  _buildStatCard(
                    title: 'This month\nyou saved',
                    value: '₦8,200',
                    color: const Color(0xFF98D32A),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Date range
          Text(
            'December 01, 2025 - December 31, 2025',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 30),

          // Pie chart and legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildPieChart(),
          ),

          const SizedBox(height: 30),

          // Table legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCategoryTable(),
          ),

          const SizedBox(height: 40),

          // Purchase history title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Purchase History',
                  style: TextStyle(
                    color: const Color(0xFF0A0A0A),
                    fontSize: 28,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.more_vert, size: 28),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Purchase history items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              spacing: 16,
              children: [
                _buildPurchaseHistoryCard(
                  name: 'Ijebu garri',
                  original: '₦7,500',
                  price: '₦5,500',
                  save: 'Save ₦2000',
                  quantity: '5.0kg',
                  date: '19/12/2025',
                  imageUrl:
                      'https://images.unsplash.com/photo-1599599810694-b5ac4dd33cca?w=100&h=100&fit=crop',
                ),
                _buildPurchaseHistoryCard(
                  name: 'Honey beans',
                  original: '₦7,800',
                  price: '₦7,000',
                  save: 'Save ₦800',
                  quantity: '5.0kg',
                  date: '11/12/2025',
                  imageUrl:
                      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=100&h=100&fit=crop',
                ),
                _buildPurchaseHistoryCard(
                  name: 'Egusi seeds',
                  original: '₦3,500',
                  price: '₦2,000',
                  save: 'Save ₦1,500',
                  quantity: '1.0kg',
                  imageUrl:
                      'https://images.unsplash.com/photo-1585328707852-8ec06e647f0b?w=100&h=100&fit=crop',
                ),
                _buildPurchaseHistoryCard(
                  name: 'Natural honey',
                  original: '₦8,000',
                  price: '₦7,000',
                  save: 'Save ₦1000',
                  quantity: '50cl',
                  imageUrl:
                      'https://images.unsplash.com/photo-1587049352584-5374c67271f1?w=100&h=100&fit=crop',
                ),
                _buildPurchaseHistoryCard(
                  name: '6in1 Spices',
                  original: '₦14,000',
                  price: '₦12,000',
                  save: 'Save ₦2000',
                  quantity: '1.0kg',
                  imageUrl:
                      'https://images.unsplash.com/photo-1596040541256-a8e434c75c31?w=100&h=100&fit=crop',
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Journey step for new users
  Widget _buildJourneyStep({
    required String number,
    required String title,
    required String description,
    required String icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1A4E00),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF0A0A0A),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
        if (number != '4') ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Container(
              width: 2,
              height: 20,
              color: const Color(0xFF1A4E00).withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // Benefit preview cards for new users
  Widget _buildBenefitPreview({
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF0A0A0A),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(4, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFFAFAFA),
              fontSize: 12,
              fontFamily: 'Libre Baskerville',
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFFAFAFA),
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFFEFF31A),
                  Color(0xFFE9415D),
                  Color(0xFFEFF31A),
                ],
              ),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFAFAFA),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total savings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  '₦8,200',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTable() {
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            color: Color(0xFFB7B7B7),
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(4, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          spacing: 16,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category',
                  style: TextStyle(
                    color: const Color(0xFFB7B7B7),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Earnings',
                  style: TextStyle(
                    color: const Color(0xFFB7B7B7),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '% of total',
                  style: TextStyle(
                    color: const Color(0xFFB7B7B7),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            _buildTableRow('Groceries', '₦2,870', '35%'),
            _buildTableRow('Bulk orders', '₦1,640', '20%'),
            _buildTableRow('Seafood', '₦820', '10%'),
            _buildTableRow('Household', '₦1,640', '20%'),
            _buildTableRow('Meat', '₦1,230', '15%'),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String category, String amount, String percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          spacing: 8,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getCategoryColor(category),
              ),
            ),
            Text(
              category,
              style: TextStyle(
                color: const Color(0xFF0A0A0A),
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            color: const Color(0xFF0A0A0A),
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            color: const Color(0xFF0A0A0A),
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Groceries':
        return const Color(0xFFEFF31A);
      case 'Bulk orders':
        return const Color(0xFFE9415D);
      case 'Seafood':
        return const Color(0xFF8A38F5);
      case 'Household':
        return const Color(0xFF2AC8D3);
      case 'Meat':
        return const Color(0xFF8DDD9D);
      default:
        return Colors.grey;
    }
  }

  Widget _buildBenefitSection({
    required String icon,
    required String title,
    required LinearGradient gradient,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHistoryCard({
    required String name,
    required String original,
    required String price,
    required String save,
    required String quantity,
    String? date,
    String? imageUrl,
  }) {
    return Column(
      spacing: 8,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: ShapeDecoration(
            color: const Color(0xFFE9E6E6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[300],
                ),
                child: imageUrl == null
                    ? Center(
                        child: Text(
                          quantity,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: const Color(0xFF0A0A0A),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      spacing: 6,
                      children: [
                        Text(
                          original,
                          style: TextStyle(
                            color: const Color(0x7FF3951A),
                            fontSize: 11,
                            fontFamily: 'Inter',
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          price,
                          style: TextStyle(
                            color: const Color(0xFF1A4E00),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          save,
                          style: TextStyle(
                            color: const Color(0xFF1A4E00),
                            fontSize: 9,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (date != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                date,
                style: TextStyle(
                  color: const Color(0xFF9B9B9B),
                  fontSize: 10,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
