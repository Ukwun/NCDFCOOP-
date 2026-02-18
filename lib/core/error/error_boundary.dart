import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'custom_error_screen.dart';

/// Error Boundary - Catches and displays runtime errors gracefully
class ErrorBoundary extends ConsumerWidget {
  final Widget child;

  const ErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return MaterialApp(
        home: CustomErrorScreen(errorDetails: errorDetails),
      );
    };
    return child;
  }
}
