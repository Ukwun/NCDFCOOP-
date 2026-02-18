import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Loading state - skeleton loaders and progress indicators
class AppLoadingState extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const AppLoadingState({
    this.message,
    this.fullScreen = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (fullScreen) {
      return Scaffold(
        body: widget,
      );
    }

    return widget;
  }
}

/// Skeleton loader for product cards
class ProductSkeletonLoader extends StatelessWidget {
  final int itemCount;

  const ProductSkeletonLoader({this.itemCount = 6, super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => _SkeletonCard(),
    );
  }
}

/// Generic skeleton card
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title skeleton
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Price skeleton
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when no data available
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with recovery options
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onContactSupport;
  final String? errorCode;

  const AppErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
    this.onContactSupport,
    this.errorCode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Error: $errorCode',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 12),
                if (onContactSupport != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onContactSupport,
                      child: const Text('Get Help'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Network error state
class NetworkErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const NetworkErrorState({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'No Internet Connection',
      message: 'Please check your connection and try again.',
      onRetry: onRetry,
      errorCode: 'NETWORK_ERROR',
    );
  }
}

/// Permission denied state
class PermissionDeniedState extends StatelessWidget {
  final String permission;
  final VoidCallback onRetry;

  const PermissionDeniedState({
    required this.permission,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'Permission Required',
      message: 'This feature requires $permission permission to work.',
      onRetry: onRetry,
      errorCode: 'PERMISSION_DENIED',
    );
  }
}

/// Timeout state
class TimeoutState extends StatelessWidget {
  final VoidCallback onRetry;

  const TimeoutState({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'Request Timeout',
      message: 'The request took too long. Please try again.',
      onRetry: onRetry,
      errorCode: 'TIMEOUT',
    );
  }
}

/// Offline state with cached data option
class OfflineState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool hasCachedData;
  final VoidCallback? onUseCached;

  const OfflineState({
    required this.message,
    required this.onRetry,
    this.hasCachedData = false,
    this.onUseCached,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'Offline',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasCachedData && onUseCached != null) ...[
              ElevatedButton(
                onPressed: onUseCached,
                child: const Text('Use Cached Data'),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Success state with message
class AppSuccessState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;
  final Duration duration;

  const AppSuccessState({
    required this.message,
    this.icon = Icons.check_circle,
    this.onDismiss,
    this.duration = const Duration(seconds: 3),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (onDismiss != null) {
        onDismiss!();
      }
    });

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
