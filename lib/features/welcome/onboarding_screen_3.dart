import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/lastonboardimg.png",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF12202F));
              },
            ),
          ),

          // Bottom Glass/Overlay Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9).withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                border: Border.all(
                  color: const Color(0xFFFAFAFA).withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x3A303030),
                    blurRadius: 4,
                    offset: const Offset(4, 4),
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Main Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Multiple Ways to ',
                                style: TextStyle(
                                  color: Color(0xFFFAFAFA),
                                  fontSize: 32,
                                  fontFamily: 'Libre Baskerville',
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              TextSpan(
                                text: 'grow',
                                style: TextStyle(
                                  color: Color(0xFFF3951A),
                                  fontSize: 32,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Libre Baskerville',
                                  fontWeight: FontWeight.w400,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF3951A)
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: const Column(
                            children: [
                              _RoleOption(
                                icon: Icons.shopping_bag,
                                title: 'Shop Retail',
                                subtitle: 'Find great deals as a consumer',
                              ),
                              SizedBox(height: 10),
                              _RoleOption(
                                icon: Icons.store,
                                title: 'Be a Franchisee',
                                subtitle: 'Own your own store with our support',
                              ),
                              SizedBox(height: 10),
                              _RoleOption(
                                icon: Icons.business,
                                title: 'Institutional Buying',
                                subtitle: 'Bulk orders for organizations',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Join a community of entrepreneurs and smart shoppers',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFCCCCCC),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A4E00),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A4E00),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 50,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF98D32A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Get Started Button
                  GestureDetector(
                    onTap: () {
                      context.go('/signup');
                    },
                    child: Container(
                      width: 280,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4E00),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3F000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: 20,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Status Bar (Simulated)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '9:45',
                      style: TextStyle(
                        color: Color(0xFFFAFAFA),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Icons placeholder
                    Row(
                      children: [
                        Container(width: 20, height: 20, color: Colors.white24),
                        const SizedBox(width: 6),
                        Container(width: 20, height: 20, color: Colors.white24),
                        const SizedBox(width: 6),
                        Container(width: 30, height: 20, color: Colors.white24),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF3951A).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFF3951A), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFAFAFA),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
