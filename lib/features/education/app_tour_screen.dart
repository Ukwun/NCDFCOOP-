import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

/// Interactive onboarding tour for new users to discover app features
class AppTourScreen extends StatefulWidget {
  const AppTourScreen({super.key});

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<TourSlide> slides = [
    TourSlide(
      title: 'Welcome to Coop Commerce',
      description: 'Join a cooperative marketplace where members own, decide, and benefit together.',
      icon: '🎉',
      color: const Color(0xFF1A4E00),
    ),
    TourSlide(
      title: 'Your Role Matters',
      description: 'You\'re not just a customer—you\'re a cooperative owner with a voice and vote.',
      icon: '👑',
      color: const Color(0xFF8D560F),
    ),
    TourSlide(
      title: 'Fair Pricing',
      description: 'Access exclusive member-only prices and flash sales with early bird access.',
      icon: '💳',
      color: const Color(0xFF130F8D),
    ),
    TourSlide(
      title: 'Earn & Share',
      description: 'Earn rewards on every purchase and share in community dividends.',
      icon: '💰',
      color: const Color(0xFF8D0F43),
    ),
    TourSlide(
      title: 'Track Your Impact',
      description: 'Use analytics to see your savings and support local communities.',
      icon: '📊',
      color: const Color(0xFFE61456),
    ),
    TourSlide(
      title: 'Smart Reviews',
      description: 'Read honest product reviews from real community members.',
      icon: '⭐',
      color: const Color(0xFF0F8D0F),
    ),
    TourSlide(
      title: 'Easy Invoicing',
      description: 'Generate professional invoices for all your purchases.',
      icon: '📝',
      color: const Color(0xFFF3981A),
    ),
    TourSlide(
      title: 'You\'re Ready!',
      description: 'Start exploring and enjoy the benefits of cooperative commerce.',
      icon: '🚀',
      color: const Color(0xFF2B0B3A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return _buildSlide(slide);
            },
          ),

          // Navigation buttons at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Action buttons
                  if (_currentPage == slides.length - 1)
                    // Last slide - Start button
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => context.go('/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Start Exploring',
                            style: AppTextStyles.buttonText.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: () => context.go('/about-cooperatives'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Learn More About Cooperatives',
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Other slides - Next/Previous buttons
                    Row(
                      children: [
                        // Skip button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/home'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              side: const BorderSide(color: AppColors.divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Skip Tour',
                              style: AppTextStyles.buttonText.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Next button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Next',
                              style: AppTextStyles.buttonText.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Close button (top right)
          Positioned(
            top: 15,
            right: 15,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(TourSlide slide) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            alignment: Alignment.center,
            child: Text(
              slide.icon,
              style: const TextStyle(fontSize: 64),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            slide.title,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.text,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            slide.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.muted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Optional: Feature list for specific slides
          if (slide.title == 'Your Role Matters')
            _buildFeatureList(
              features: [
                'Vote on cooperative decisions',
                'Receive dividend payments',
                'Influence product offerings',
                'Build community together',
              ],
            )
          else if (slide.title == 'Fair Pricing')
            _buildFeatureList(
              features: [
                'Member-exclusive discounts',
                '2-hour early access to sales',
                'Transparent pricing',
                'No hidden markups',
              ],
            )
          else if (slide.title == 'Earn & Share')
            _buildFeatureList(
              features: [
                '1 point per ₦1 spent',
                '5% bonus (Gold members)',
                'Quarterly dividends',
                'Reward redemptions',
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureList({required List<String> features}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: features
            .map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  feature,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }
}

class TourSlide {
  final String title;
  final String description;
  final String icon;
  final Color color;

  TourSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
