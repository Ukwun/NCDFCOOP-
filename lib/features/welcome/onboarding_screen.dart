import 'dart:async';

import 'package:coop_commerce/features/welcome/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _green = Color(0xFF006248);
  static const _ink = Color(0xFF101722);
  final _controller = PageController();
  Timer? _autoAdvanceTimer;
  int _page = 0;

  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      image: 'assets/images/coopx_onboarding_welcome.jpg',
      title: 'Welcome to CoopX',
      subtitle:
          "Nigeria's controlled trade infrastructure for reliable buying and selling.",
      features: [],
    ),
    _OnboardingPageData(
      image: 'assets/images/coopx_onboarding_membership.jpg',
      title: 'Membership Benefits',
      subtitle:
          'Unlock exclusive discounts at every tier — from Bronze to Platinum.',
      features: [
        _Feature('Bronze', '5% off every purchase',
            Icons.workspace_premium_outlined),
        _Feature('Silver', '10% member discount', Icons.military_tech_outlined),
        _Feature(
            'Gold', '15% on eligible products', Icons.emoji_events_outlined),
        _Feature('Platinum', '20% maximum savings', Icons.diamond_outlined),
      ],
    ),
    _OnboardingPageData(
      image: 'assets/images/coopx_onboarding_wholesale.jpg',
      title: 'Unlock Wholesale Power',
      subtitle:
          'Take your business further with our cooperative wholesale marketplace.',
      features: [
        _Feature('Wholesale pricing', 'Products built for scale',
            Icons.sell_outlined),
        _Feature('Delivery support', 'Coordinate fulfilment',
            Icons.local_shipping_outlined),
        _Feature('Flexible checkout', 'Secure payment options',
            Icons.credit_card_outlined),
        _Feature('Market insights', 'Make informed decisions',
            Icons.bar_chart_outlined),
      ],
    ),
  ];

  Future<void> _open(String location) async {
    await ref.read(authControllerProvider.notifier).markOnboardingCompleted();
    if (mounted) context.go(location);
  }

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextPage = (_page + 1) % _pages.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (value) {
                setState(() => _page = value);
                _startAutoAdvance();
              },
              itemBuilder: (context, index) => _buildPage(
                context,
                _pages[index],
                index,
                wide,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    _OnboardingPageData data,
    int index,
    bool wide,
  ) {
    final image = _HeroImage(
      data: data,
      page: index,
      activePage: _page,
      pageCount: _pages.length,
    );
    final content = _ContentPanel(
      data: data,
      onLogin: () => _open('/signin'),
      onCreate: () => _open('/signup'),
    );

    if (wide) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(child: image),
            const SizedBox(width: 40),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(flex: data.features.isEmpty ? 9 : 7, child: image),
        Expanded(flex: data.features.isEmpty ? 8 : 10, child: content),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.data,
    required this.page,
    required this.activePage,
    required this.pageCount,
  });

  final _OnboardingPageData data;
  final int page;
  final int activePage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final decodeWidth =
        (media.size.width * media.devicePixelRatio).round().clamp(480, 1080);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: AnimatedOpacity(
                opacity: activePage == page ? 1 : .78,
                duration: const Duration(milliseconds: 360),
                child: AnimatedScale(
                  scale: activePage == page ? 1.0 : 1.035,
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  child: Image.asset(
                    data.image,
                    fit: BoxFit.cover,
                    cacheWidth: decodeWidth,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x8A07140F)],
                  stops: [0.5, 1],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pageCount, (index) {
                  final selected = index == activePage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: selected ? 38 : 9,
                    height: 9,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentPanel extends StatelessWidget {
  const _ContentPanel({
    required this.data,
    required this.onLogin,
    required this.onCreate,
  });

  final _OnboardingPageData data;
  final VoidCallback onLogin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CoopXWordmark(),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  data.title,
                  key: ValueKey(data.title),
                  style: const TextStyle(
                    color: _OnboardingScreenState._ink,
                    fontSize: 31,
                    height: 1.08,
                    letterSpacing: -1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.subtitle,
                style: const TextStyle(
                  color: Color(0xFF657087),
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (data.features.isNotEmpty) ...[
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.7,
                  ),
                  itemCount: data.features.length,
                  itemBuilder: (context, index) =>
                      _FeatureCard(data.features[index]),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.account_circle_outlined, size: 20),
                  label: const Text('Login to an existing account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _OnboardingScreenState._green,
                    side: const BorderSide(color: Color(0xFFD5DADF)),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: onCreate,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Create a new account'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _OnboardingScreenState._green,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'By creating an account you agree to our Privacy Policy and Terms of Service.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF657087), fontSize: 11.5, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoopXWordmark extends StatelessWidget {
  const _CoopXWordmark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'CoopX, powering the agri value chain',
      image: true,
      child: SizedBox(
        width: 215,
        child: Image.asset(
          'assets/images/coopx_brand_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(this.feature);
  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE2E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(feature.icon,
                  color: _OnboardingScreenState._green, size: 19),
              const SizedBox(width: 7),
              Expanded(
                  child: Text(feature.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _OnboardingScreenState._green,
                          fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 6),
          Text(feature.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF657087), fontSize: 11.5, height: 1.15)),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData(
      {required this.image,
      required this.title,
      required this.subtitle,
      required this.features});
  final String image;
  final String title;
  final String subtitle;
  final List<_Feature> features;
}

class _Feature {
  const _Feature(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}
