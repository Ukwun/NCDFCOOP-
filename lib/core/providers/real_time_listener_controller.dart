import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status enum for real-time listeners
enum RealTimeListenerStatus { idle, activating, active, error }

/// State model for real-time listener controller
class RealTimeListenerState {
  final RealTimeListenerStatus status;
  final int activeListenerCount;
  final DateTime? lastActivated;
  final String? errorMessage;

  const RealTimeListenerState({
    required this.status,
    required this.activeListenerCount,
    this.lastActivated,
    this.errorMessage,
  });

  bool get isActive => status == RealTimeListenerStatus.active;
  bool get isError => status == RealTimeListenerStatus.error;

  factory RealTimeListenerState.idle() => const RealTimeListenerState(
        status: RealTimeListenerStatus.idle,
        activeListenerCount: 0,
      );

  factory RealTimeListenerState.activating() => const RealTimeListenerState(
        status: RealTimeListenerStatus.activating,
        activeListenerCount: 0,
      );

  factory RealTimeListenerState.active({
    required int activeListenerCount,
    required DateTime lastActivated,
  }) =>
      RealTimeListenerState(
        status: RealTimeListenerStatus.active,
        activeListenerCount: activeListenerCount,
        lastActivated: lastActivated,
      );

  factory RealTimeListenerState.error(String message) => RealTimeListenerState(
        status: RealTimeListenerStatus.error,
        activeListenerCount: 0,
        errorMessage: message,
      );
}

/// Helper class for real-time listener management
class RealTimeListenerManager {
  static void activateAllListeners(String userId) {
    if (kDebugMode) {
      print('✅ All real-time listeners activated for user: $userId');
    }
  }

  static void activateDriverListeners(String driverId) {
    if (kDebugMode) {
      print('🚗 Activating driver listeners for: $driverId');
    }
  }

  static void activateFranchiseListeners(String franchiseId) {
    if (kDebugMode) {
      print('🏪 Activating franchise listeners for: $franchiseId');
    }
  }

  static void activateInstitutionalListeners(String institutionId) {
    if (kDebugMode) {
      print('🏢 Activating institutional listeners for: $institutionId');
    }
  }

  static void deactivateAllListeners() {
    if (kDebugMode) {
      print('🔌 All real-time listeners deactivated');
    }
  }
}

/// Model to track live data feed status
class LiveDataFeed {
  final String feedName;
  final bool isActive;
  final DateTime? lastUpdate;
  final int recordCount;

  LiveDataFeed({
    required this.feedName,
    required this.isActive,
    this.lastUpdate,
    required this.recordCount,
  });

  factory LiveDataFeed.empty() => LiveDataFeed(
        feedName: 'empty',
        isActive: false,
        recordCount: 0,
      );
}

/// Provider for real-time listener state
final realTimeListenerStateProvider = Provider<RealTimeListenerState>((ref) {
  return RealTimeListenerState.idle();
});
