import 'dart:async';
import 'package:flutter/foundation.dart';

/// Enum for real-time sync status
enum SyncStatus { idle, syncing, connected, error, offline }

/// Central service coordinating all real-time sync operations
/// Manages listener lifecycle, connection status, and error recovery
class RealTimeSyncService {
  static final RealTimeSyncService _instance = RealTimeSyncService._internal();

  factory RealTimeSyncService() => _instance;

  RealTimeSyncService._internal() {
    _initializeListeners();
  }

  final Map<String, StreamSubscription> _activeListeners = {};
  final ValueNotifier<SyncStatus> _statusNotifier =
      ValueNotifier<SyncStatus>(SyncStatus.idle);
  final ValueNotifier<String?> _errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<DateTime> _lastSyncNotifier = ValueNotifier<DateTime>(
    DateTime.now(),
  );

  // Getters for status streams
  ValueNotifier<SyncStatus> get statusNotifier => _statusNotifier;
  ValueNotifier<String?> get errorNotifier => _errorNotifier;
  ValueNotifier<DateTime> get lastSyncNotifier => _lastSyncNotifier;

  SyncStatus get currentStatus => _statusNotifier.value;
  String? get lastError => _errorNotifier.value;

  /// Initialize core listeners
  void _initializeListeners() {
    debugPrint('RealTimeSyncService initialized');
    _statusNotifier.value = SyncStatus.connected;
  }

  /// Register a new real-time listener
  void registerListener({
    required String listenerId,
    required StreamSubscription listener,
    String? context,
  }) {
    try {
      // Cancel existing listener if any
      _activeListeners[listenerId]?.cancel();

      // Register new listener
      _activeListeners[listenerId] = listener;
      _statusNotifier.value = SyncStatus.syncing;
      _errorNotifier.value = null;
      _lastSyncNotifier.value = DateTime.now();

      debugPrint(
        'Registered listener: $listenerId${context != null ? ' ($context)' : ''}',
      );
    } catch (e) {
      _handleError('Failed to register listener $listenerId: $e');
    }
  }

  /// Unregister a real-time listener
  void unregisterListener(String listenerId) {
    try {
      _activeListeners[listenerId]?.cancel();
      _activeListeners.remove(listenerId);
      debugPrint('Unregistered listener: $listenerId');

      if (_activeListeners.isEmpty) {
        _statusNotifier.value = SyncStatus.idle;
      }
    } catch (e) {
      debugPrint('Error unregistering listener $listenerId: $e');
    }
  }

  /// Unregister all listeners
  void unregisterAllListeners() {
    try {
      for (final listener in _activeListeners.values) {
        listener.cancel();
      }
      _activeListeners.clear();
      _statusNotifier.value = SyncStatus.idle;
      debugPrint('All listeners unregistered');
    } catch (e) {
      debugPrint('Error unregistering all listeners: $e');
    }
  }

  /// Handle sync errors
  void _handleError(String message) {
    _errorNotifier.value = message;
    _statusNotifier.value = SyncStatus.error;
    debugPrint('RealTimeSyncService Error: $message');
  }

  /// Mark successful sync
  void markSyncSuccess() {
    _statusNotifier.value = SyncStatus.connected;
    _errorNotifier.value = null;
    _lastSyncNotifier.value = DateTime.now();
  }

  /// Get listener count for monitoring
  int getActiveListenerCount() => _activeListeners.length;

  /// Dispose service (cleanup)
  void dispose() {
    unregisterAllListeners();
    _statusNotifier.dispose();
    _errorNotifier.dispose();
    _lastSyncNotifier.dispose();
  }
}

/// Model for real-time sync statistics
class RealTimeSyncStats {
  final int activeListeners;
  final SyncStatus status;
  final String? lastError;
  final DateTime lastSync;
  final Duration timeSinceLastSync;

  RealTimeSyncStats({
    required this.activeListeners,
    required this.status,
    this.lastError,
    required this.lastSync,
    required this.timeSinceLastSync,
  });

  /// Check if sync is healthy
  bool get isHealthy => status == SyncStatus.connected && lastError == null;

  /// Check if sync is stale (last update > 5 minutes ago)
  bool get isStale => timeSinceLastSync.inMinutes > 5;

  @override
  String toString() {
    return 'RealTimeSyncStats(listeners=$activeListeners, status=$status, '
        'healthy=$isHealthy, timeSince=${timeSinceLastSync.inSeconds}s)';
  }
}

/// Real-time data change model
class RealtimeDataChange<T> {
  final T data;
  final ChangeType changeType;
  final DateTime timestamp;

  RealtimeDataChange({
    required this.data,
    required this.changeType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'RealtimeDataChange<$T>(type=$changeType, timestamp=$timestamp)';
}

/// Type of change detected in real-time data
enum ChangeType { added, modified, removed }

/// Listener for real-time sync events
typedef RealTimeSyncListener = void Function(String eventType, dynamic data);
