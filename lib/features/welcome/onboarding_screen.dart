import 'dart:async';

import 'package:coop_commerce/features/welcome/auth_provider.dart';
import 'package:coop_commerce/providers/auth_provider.dart' as global_auth;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const green = Color(0xFF006248);
  static const transitionInterval = Duration(milliseconds: 4500);
  final _controller = PageController();
  Timer? _autoAdvanceTimer;
  int _page = 0;
  bool _isOpening = false;

  static const pages = <_OnboardingPageData>[
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
        _Feature('Bronze', '5% off every purchase', '🥉'),
        _Feature('Silver', '10% member discount', '🥈'),
        _Feature('Gold', '15% on all products', '🥇'),
        _Feature('Platinum', '20% maximum savings', '💎'),
      ],
    ),
    _OnboardingPageData(
      image: 'assets/images/coopx_onboarding_wholesale.jpg',
      title: 'Unlock Wholesale Power',
      subtitle:
          'Take your business further with our cooperative wholesale platform.',
      features: [
        _Feature('Wholesale-priced', 'products', '🏷️'),
        _Feature('Dedicated delivery', 'support', '🚚'),
        _Feature('Flexible payment', 'terms', '💳'),
        _Feature('Sales analytics &', 'insights', '📊'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleAutoAdvance();
  }

  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(transitionInterval, () {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 760),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _openExistingAccount() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    try {
      await ref.read(authControllerProvider.notifier).markOnboardingCompleted();
      if (!mounted) return;
      final user = ref.read(global_auth.currentUserProvider);
      context.go(
        user == null
            ? '/signin'
            : user.roleSelectionCompleted
                ? '/'
                : '/role-selection',
      );
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  Future<void> _createAccount() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    try {
      if (ref.read(global_auth.currentUserProvider) != null) {
        await ref.read(authControllerProvider.notifier).signOut();
      }
      await ref.read(authControllerProvider.notifier).markOnboardingCompleted();
      if (mounted) context.go('/signup');
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final returningUser = ref.watch(global_auth.currentUserProvider) != null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF07120F),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF07120F),
        body: PageView.builder(
          controller: _controller,
          onPageChanged: (value) {
            setState(() => _page = value);
            _scheduleAutoAdvance();
          },
          itemBuilder: (context, index) => _OnboardingPage(
            key: ValueKey(index),
            data: pages[index % pages.length],
            activePage: _page % pages.length,
            loginLabel: returningUser
                ? 'Continue to CoopX'
                : 'Login to an existing account',
            busy: _isOpening,
            onLogin: _openExistingAccount,
            onCreate: _createAccount,
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    super.key,
    required this.data,
    required this.activePage,
    required this.loginLabel,
    required this.busy,
    required this.onLogin,
    required this.onCreate,
  });

  final _OnboardingPageData data;
  final int activePage;
  final String loginLabel;
  final bool busy;
  final VoidCallback onLogin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final decodeWidth =
        (media.size.width * media.devicePixelRatio).round().clamp(540, 1440);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.055, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Image.asset(
              data.image,
              fit: BoxFit.cover,
              alignment: data.features.isEmpty
                  ? const Alignment(.18, 0)
                  : Alignment.center,
              cacheWidth: decodeWidth,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xB8000908),
                Color(0x52000908),
                Color(0x6B000807),
                Color(0xF0071210),
              ],
              stops: [0, .28, .64, 1],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              final horizontal = constraints.maxWidth >= 720;
              final content = _PageContent(
                data: data,
                activePage: activePage,
                compact: compact,
                loginLabel: loginLabel,
                busy: busy,
                onLogin: onLogin,
                onCreate: onCreate,
              );
              if (!horizontal) return content;
              return Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: constraints.maxWidth * .56,
                  child: content,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.data,
    required this.activePage,
    required this.compact,
    required this.loginLabel,
    required this.busy,
    required this.onLogin,
    required this.onCreate,
  });

  final _OnboardingPageData data;
  final int activePage;
  final bool compact;
  final String loginLabel;
  final bool busy;
  final VoidCallback onLogin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(32, compact ? 16 : 30, 32, compact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CoopXWordmark(),
          SizedBox(height: compact ? 22 : 34),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeOutCubic,
            builder: (_, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: child,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 27 : 31,
                    height: 1.05,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .94),
                    fontSize: compact ? 14 : 15.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (data.features.isEmpty) const Spacer(),
          if (data.features.isNotEmpty) ...[
            SizedBox(height: compact ? 18 : 34),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.18,
                ),
                itemCount: data.features.length,
                itemBuilder: (_, index) => _FeatureCard(
                  feature: data.features[index],
                  delay: Duration(milliseconds: 90 * index),
                ),
              ),
            ),
          ],
          _PageIndicator(activePage: activePage),
          SizedBox(height: compact ? 12 : 17),
          _OnboardingActions(
            loginLabel: loginLabel,
            busy: busy,
            compact: compact,
            onLogin: onLogin,
            onCreate: onCreate,
          ),
        ],
      ),
    );
  }
}

class _CoopXWordmark extends StatelessWidget {
  const _CoopXWordmark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'CoopX',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/coopx_launcher_source.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              cacheWidth: 132,
            ),
          ),
          const SizedBox(width: 11),
          const Text(
            'CoopX',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              letterSpacing: -1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.delay});
  final _Feature feature;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delay.inMilliseconds),
      curve: Curves.easeOutBack,
      builder: (_, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.scale(scale: .92 + (.08 * value), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .34),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .78)),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 18),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(feature.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 12),
            Text(
              feature.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              feature.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .92),
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.activePage});
  final int activePage;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final selected = index == activePage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: selected ? 22 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.white38,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.loginLabel,
    required this.busy,
    required this.compact,
    required this.onLogin,
    required this.onCreate,
  });
  final String loginLabel;
  final bool busy;
  final bool compact;
  final VoidCallback onLogin;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: compact ? 49 : 56,
          child: OutlinedButton.icon(
            onPressed: busy ? null : onLogin,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.account_circle_rounded, size: 21),
            label: Text(loginLabel),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _OnboardingScreenState.green,
              disabledBackgroundColor: Colors.white70,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: compact ? 49 : 56,
          child: FilledButton.icon(
            onPressed: busy ? null : onCreate,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Create a new account'),
            style: FilledButton.styleFrom(
              backgroundColor: _OnboardingScreenState.green,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SizedBox(height: compact ? 9 : 14),
        Text.rich(
          TextSpan(
            text: 'Creating a CoopX account means you agree to the\n',
            children: [
              TextSpan(
                text: 'Privacy Policy',
                style: const TextStyle(decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push('/privacy'),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Terms of Service.',
                style: const TextStyle(decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push('/terms'),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .94),
            fontSize: compact ? 11 : 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.features,
  });
  final String image;
  final String title;
  final String subtitle;
  final List<_Feature> features;
}

class _Feature {
  const _Feature(this.title, this.subtitle, this.emoji);
  final String title;
  final String subtitle;
  final String emoji;
}
