import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced app-wide animation and micro-interaction utilities
class AppAnimations {
  // Haptic feedback helper
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavyTap() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}

/// Smooth page transition animation from bottom
class SlideUpPageRoute extends PageRoute {
  final WidgetBuilder builder;
  final Duration duration;

  SlideUpPageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  Color? get barrierColor => null;

  @override
  String get barrierLabel => '';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

/// Fade transition route
class FadePageRoute extends PageRoute {
  final WidgetBuilder builder;
  final Duration duration;

  FadePageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Color? get barrierColor => null;

  @override
  String get barrierLabel => '';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
