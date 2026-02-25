import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Production caching strategy with cache invalidation
/// Handles local data persistence, offline sync, and cache management
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();

  factory CacheManager() {
    return _instance;
  }

  CacheManager._internal();

  late SharedPreferences _prefs;
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, Timer> _cacheTimers = {};

  static const String _cachePrefix = 'cache_';
  static const String _cacheMetaPrefix = 'cache_meta_';
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const int _maxCacheSize = 10 * 1024 * 1024; // 10MB

  /// Initialize cache manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cleanupExpiredCache();
  }

  /// Save data to cache with optional TTL
  Future<void> saveCache(
    String key,
    dynamic data, {
    Duration? ttl,
  }) async {
    try {
      ttl ??= _defaultCacheDuration;

      final jsonData = jsonEncode(data);
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      // Check cache size before saving
      if (!_willFitInCache(jsonData)) {
        debugPrint('⚠️ Cache size exceeded, clearing old entries...');
        await _clearOldestCache();
      }

      // Save to persistent storage
      await _prefs.setString(cacheKey, jsonData);

      // Save metadata (timestamp + ttl)
      final metadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'ttl': ttl.inSeconds,
        'size': jsonData.length,
      };
      await _prefs.setString(metaKey, jsonEncode(metadata));

      // Save to memory cache
      _memoryCache[key] = CacheEntry(
        data: data,
        timestamp: DateTime.now(),
        ttl: ttl,
      );

      // Set expiration timer
      _setExpirationTimer(key, ttl);

      debugPrint('✅ Cached $key (TTL: ${ttl.inMinutes}m)');
    } catch (e) {
      debugPrint('❌ Cache save error for $key: $e');
    }
  }

  /// Get data from cache
  Future<T?> getCache<T>(String key) async {
    try {
      // Check memory cache first (faster)
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;
        if (entry.isValid()) {
          debugPrint('✅ Memory cache hit: $key');
          return entry.data as T?;
        } else {
          // Expired, remove it
          await invalidateCache(key);
          return null;
        }
      }

      // Check persistent storage
      final cacheKey = '$_cachePrefix$key';
      final metaKey = '$_cacheMetaPrefix$key';

      final cachedJson = _prefs.getString(cacheKey);
      final metaJson = _prefs.getString(metaKey);

      if (cachedJson == null || metaJson == null) {
        return null;
      }

      // Check if cache is expired
      final metadata = jsonDecode(metaJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(metadata['timestamp'] as String);
      final ttl = Duration(seconds: metadata['ttl'] as int);

      if (DateTime.now().difference(timestamp) > ttl) {
        await invalidateCache(key);
        return null;
      }

      // Cache is valid
      final data = jsonDecode(cachedJson) as T;

      // Restore to memory cache
      _memoryCache[key] = CacheEntry(
        data: data,
        timestamp: timestamp,
        ttl: ttl,
      );

      debugPrint('✅ Persistent cache hit: $key');
      return data;
    } catch (e) {
      debugPrint('❌ Cache read error for $key: $e');
      return null;
    }
  }

  /// Check if specific cache exists and is valid
  Future<bool> isCacheValid(String key) async {
    final data = await getCache(key);
    return data != null;
  }

  /// Invalidate specific cache key
  Future<void> invalidateCache(String key) async {
    try {
      _memoryCache.remove(key);
      _cacheTimers[key]?.cancel();
      _cacheTimers.remove(key);

      await _prefs.remove('$_cachePrefix$key');
      await _prefs.remove('$_cacheMetaPrefix$key');

      debugPrint('🗑️ Invalidated cache: $key');
    } catch (e) {
      debugPrint('❌ Cache invalidation error: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      _memoryCache.clear();
      _cacheTimers.forEach((key, timer) => timer.cancel());
      _cacheTimers.clear();

      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheMetaPrefix)) {
          await _prefs.remove(key);
        }
      }

      debugPrint('🗑️ Cleared all cache');
    } catch (e) {
      debugPrint('❌ Clear cache error: $e');
    }
  }

  /// Get cache size in bytes
  int getCacheSize() {
    try {
      int totalSize = 0;
      final keys = _prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final data = _prefs.getString(key);
          if (data != null) {
            totalSize += data.length;
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('❌ Cache size calculation error: $e');
      return 0;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalSize': getCacheSize(),
      'maxSize': _maxCacheSize,
      'percentageUsed':
          (getCacheSize() / _maxCacheSize * 100).toStringAsFixed(2),
      'entriesCount': _memoryCache.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ==================== PRIVATE METHODS ====================

  /// Check if data will fit in cache
  bool _willFitInCache(String data) {
    return getCacheSize() + data.length < _maxCacheSize;
  }

  /// Clear oldest cache entries if cache is full
  Future<void> _clearOldestCache() async {
    try {
      final keys = _prefs.getKeys();
      final entries = <String, DateTime>{};

      for (final key in keys) {
        if (key.startsWith(_cacheMetaPrefix)) {
          final metaJson = _prefs.getString(key);
          if (metaJson != null) {
            final metadata = jsonDecode(metaJson) as Map<String, dynamic>;
            final timestamp = DateTime.parse(metadata['timestamp'] as String);
            final originalKey = key.replaceFirst(_cacheMetaPrefix, '');
            entries[originalKey] = timestamp;
          }
        }
      }

      // Sort by timestamp (oldest first)
      final sorted = entries.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      // Remove oldest 25% of entries
      final toRemove = (sorted.length * 0.25).ceil();
      for (int i = 0; i < toRemove && i < sorted.length; i++) {
        await invalidateCache(sorted[i].key);
      }

      debugPrint('🧹 Cleaned up $toRemove cache entries');
    } catch (e) {
      debugPrint('❌ Cache cleanup error: $e');
    }
  }

  /// Set timer for cache expiration
  void _setExpirationTimer(String key, Duration ttl) {
    _cacheTimers[key]?.cancel();

    _cacheTimers[key] = Timer(ttl, () {
      invalidateCache(key);
      debugPrint('⏰ Cache expired: $key');
    });
  }

  /// Cleanup expired cache on startup
  Future<void> _cleanupExpiredCache() async {
    try {
      final keys = _prefs.getKeys().toList();

      for (final key in keys) {
        if (key.startsWith(_cacheMetaPrefix)) {
          final metaJson = _prefs.getString(key);
          if (metaJson != null) {
            try {
              final metadata = jsonDecode(metaJson) as Map<String, dynamic>;
              final timestamp = DateTime.parse(metadata['timestamp'] as String);
              final ttl = Duration(seconds: metadata['ttl'] as int);

              if (DateTime.now().difference(timestamp) > ttl) {
                final originalKey = key.replaceFirst(_cacheMetaPrefix, '');
                await invalidateCache(originalKey);
              }
            } catch (e) {
              // Invalid metadata, remove it
              await _prefs.remove(key);
            }
          }
        }
      }

      debugPrint('✅ Cache cleanup completed');
    } catch (e) {
      debugPrint('❌ Initial cleanup error: $e');
    }
  }
}

/// Cache entry in memory
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool isValid() {
    return DateTime.now().difference(timestamp) < ttl;
  }
}

/// Cache synchronization manager for offline-first capability
class OfflineSyncManager {
  static final OfflineSyncManager _instance = OfflineSyncManager._internal();

  factory OfflineSyncManager() {
    return _instance;
  }

  OfflineSyncManager._internal();

  late SharedPreferences _prefs;
  final List<SyncOperation> _pendingOperations = [];
  final Map<String, Function> _syncHandlers = {};

  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Initialize sync manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPendingOperations();
  }

  /// Register a sync handler for a specific operation type
  void registerSyncHandler(String operationType, Function handler) {
    _syncHandlers[operationType] = handler;
    debugPrint('📝 Registered sync handler: $operationType');
  }

  /// Queue an operation for offline sync
  Future<void> queueOperation({
    required String type,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final operation = SyncOperation(
        id: id,
        type: type,
        data: data,
        queuedAt: DateTime.now(),
        retries: 0,
      );

      _pendingOperations.add(operation);
      await _savePendingOperations();

      debugPrint('📤 Queued operation: $type ($id) for offline sync');
    } catch (e) {
      debugPrint('❌ Queue operation error: $e');
    }
  }

  /// Sync pending operations when online
  Future<void> syncPendingOperations() async {
    if (_pendingOperations.isEmpty) {
      return;
    }

    debugPrint(
        '🔄 Starting offline sync (${_pendingOperations.length} operations)...');

    for (int i = 0; i < _pendingOperations.length; i++) {
      final operation = _pendingOperations[i];

      try {
        final handler = _syncHandlers[operation.type];
        if (handler != null) {
          await handler(operation.data);
          debugPrint('✅ Synced: ${operation.type} (${operation.id})');
          _pendingOperations.removeAt(i);
          i--;
        } else {
          debugPrint('⚠️ No handler for sync type: ${operation.type}');
        }
      } catch (e) {
        operation.retries++;
        if (operation.retries >= 3) {
          debugPrint('❌ Max retries reached for ${operation.id}');
          _pendingOperations.removeAt(i);
          i--;
        } else {
          debugPrint('⚠️ Retry ${operation.retries}/3 for ${operation.id}');
        }
      }
    }

    await _savePendingOperations();

    if (_pendingOperations.isEmpty) {
      await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      debugPrint('✅ All operations synced');
    }
  }

  /// Get pending operations count
  int getPendingOperationsCount() => _pendingOperations.length;

  /// Get pending operations
  List<SyncOperation> getPendingOperations() => List.from(_pendingOperations);

  // ==================== PRIVATE METHODS ====================

  Future<void> _savePendingOperations() async {
    try {
      final json = jsonEncode(
        _pendingOperations.map((op) => op.toJson()).toList(),
      );
      await _prefs.setString(_syncQueueKey, json);
    } catch (e) {
      debugPrint('❌ Error saving pending operations: $e');
    }
  }

  Future<void> _loadPendingOperations() async {
    try {
      final json = _prefs.getString(_syncQueueKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        _pendingOperations.clear();
        for (final item in list) {
          _pendingOperations.add(SyncOperation.fromJson(item));
        }
        debugPrint('📥 Loaded ${_pendingOperations.length} pending operations');
      }
    } catch (e) {
      debugPrint('❌ Error loading pending operations: $e');
    }
  }
}

/// Sync operation model
class SyncOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime queuedAt;
  int retries;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.queuedAt,
    required this.retries,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'data': data,
        'queuedAt': queuedAt.toIso8601String(),
        'retries': retries,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
        id: json['id'],
        type: json['type'],
        data: json['data'],
        queuedAt: DateTime.parse(json['queuedAt']),
        retries: json['retries'] ?? 0,
      );
}
