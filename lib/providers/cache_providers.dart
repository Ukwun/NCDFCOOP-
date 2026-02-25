import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/core/cache/cache_manager.dart';

/// Cache manager singleton provider
final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager();
});

/// Offline sync manager provider
final offlineSyncManagerProvider = Provider<OfflineSyncManager>((ref) {
  return OfflineSyncManager();
});

/// Cache initialization provider
final cacheInitializeProvider = FutureProvider<void>((ref) async {
  final cacheManager = ref.watch(cacheManagerProvider);
  await cacheManager.initialize();
});

/// Offline sync initialization provider
final offlineSyncInitializeProvider = FutureProvider<void>((ref) async {
  final syncManager = ref.watch(offlineSyncManagerProvider);
  await syncManager.initialize();
});

/// Cache statistics provider
final cacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return cacheManager.getCacheStats();
});

/// Pending operations count provider
final pendingOperationsCountProvider = Provider<int>((ref) {
  final syncManager = ref.watch(offlineSyncManagerProvider);
  return syncManager.getPendingOperationsCount();
});

/// Generic cached data provider - automatically manages cache
///
/// Usage:
/// ```dart
/// final products = ref.watch(cachedDataProvider(
///   (
///     key: 'products',
///     ttl: Duration(minutes: 5),
///     fetcher: () => fetchProducts(),
///   )
/// ));
/// ```
final cachedDataProvider = FutureProvider.family<
    dynamic,
    (
      String key,
      Duration ttl,
      Future<dynamic> Function() fetcher,
    )>((ref, params) async {
  final cacheManager = ref.watch(cacheManagerProvider);

  // Extract parameters from record
  String key = params.$1;
  Duration ttl = params.$2;
  Future<dynamic> Function() fetcher = params.$3;

  // Check cache first
  final cached = await cacheManager.getCache(key);
  if (cached != null) {
    return cached;
  }

  // Fetch fresh data
  final data = await fetcher();

  // Save to cache
  await cacheManager.saveCache(key, data, ttl: ttl);

  return data;
});
