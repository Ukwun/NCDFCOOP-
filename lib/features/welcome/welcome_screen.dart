import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

enum MemberType { wholesale, member, cooperative }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  MemberType? _selectedType;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Navigate to splash screen after 5 seconds
    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        context.go('/splash');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _selectMemberType(MemberType type) {
    _navigationTimer?.cancel();
    setState(() {
      _selectedType = type;
    });

    // Navigate to home after brief delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 800;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Status Bar Area - Time & Icons
                SizedBox(
                  height: isSmallScreen ? 40 : 60,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '9:45',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.text,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          spacing: 6,
                          children: [
                            _buildStatusIcon('assets/icons/signal.png', 12),
                            _buildStatusIcon('assets/icons/wifi.png', 12),
                            _buildStatusIcon('assets/icons/battery.png', 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 40 : 80),

                // Logo with Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/NCDF_logo1.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'NCDF COOP',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cooperative Commerce',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 40 : 80),

                // Member Type Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Your Type',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.text,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildMemberTypeOption(
                        type: MemberType.wholesale,
                        label: 'Wholesale',
                        description: 'Bulk ordering for businesses',
                        icon: '🏭',
                      ),
                      const SizedBox(height: 12),
                      _buildMemberTypeOption(
                        type: MemberType.member,
                        label: 'Member',
                        description: 'Personal member benefits',
                        icon: '👤',
                      ),
                      const SizedBox(height: 12),
                      _buildMemberTypeOption(
                        type: MemberType.cooperative,
                        label: 'Cooperative',
                        description: 'Cooperative partner',
                        icon: '🤝',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 30 : 60),

                // Divider with text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: AppColors.border),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: AppColors.border),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom tagline
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 11,
                  children: [
                    Text('Wholesale', style: AppTextStyles.bodySmall),
                    Container(height: 12, width: 1, color: AppColors.border),
                    Text('Member', style: AppTextStyles.bodySmall),
                    Container(height: 12, width: 1, color: AppColors.border),
                    Text('Cooperative', style: AppTextStyles.bodySmall),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String assetPath, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.muted),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberTypeOption({
    required MemberType type,
    required String label,
    required String description,
    required String icon,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => _selectMemberType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}
