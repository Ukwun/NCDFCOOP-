import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:coop_commerce/core/auth/role.dart';

/// Service for locally persisting role-specific search preferences
/// Handles recent searches and pinned intents per role
class LocalSearchPreferencesService {
  static const String _recentSearchesPrefix = 'recent_searches_';
  static const String _pinnedIntentsPrefix = 'pinned_intents_';
  static const int maxRecentSearches = 5;

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    debugPrint('✅ LocalSearchPreferencesService initialized');
  }

  /// Ensure initialized before use
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  /// Get role-specific storage key
  String _getRecentSearchesKey(UserRole role) =>
      '$_recentSearchesPrefix${role.name}';

  String _getPinnedIntentsKey(UserRole role) =>
      '$_pinnedIntentsPrefix${role.name}';

  /// Save a search for a specific role (deduplicates by moving to front)
  Future<void> saveRecentSearch(UserRole role, String query) async {
    await _ensureInitialized();
    if (query.trim().isEmpty) return;

    try {
      final key = _getRecentSearchesKey(role);
      final searches = _prefs.getStringList(key) ?? [];

      // Remove if already exists (to avoid duplicates)
      searches.removeWhere(
          (s) => s.trim().toLowerCase() == query.trim().toLowerCase());

      // Add to front
      searches.insert(0, query.trim());

      // Keep only max items
      if (searches.length > maxRecentSearches) {
        searches.removeRange(maxRecentSearches, searches.length);
      }

      await _prefs.setStringList(key, searches);
      debugPrint('✅ Saved search for ${role.displayName}: "$query"');
    } catch (e) {
      debugPrint('⚠️ Failed to save recent search: $e');
    }
  }

  /// Get recent searches for a role
  Future<List<String>> getRecentSearches(UserRole role) async {
    await _ensureInitialized();
    try {
      final key = _getRecentSearchesKey(role);
      final searches = _prefs.getStringList(key) ?? [];
      debugPrint(
          '✅ Retrieved ${searches.length} recent searches for ${role.displayName}');
      return searches;
    } catch (e) {
      debugPrint('⚠️ Failed to get recent searches: $e');
      return [];
    }
  }

  /// Clear recent searches for a role
  Future<void> clearRecentSearches(UserRole role) async {
    await _ensureInitialized();
    try {
      final key = _getRecentSearchesKey(role);
      await _prefs.remove(key);
      debugPrint('✅ Cleared recent searches for ${role.displayName}');
    } catch (e) {
      debugPrint('⚠️ Failed to clear recent searches: $e');
    }
  }

  /// Pin an intent for a role
  Future<void> pinIntent(UserRole role, String intentTitle) async {
    await _ensureInitialized();
    try {
      final key = _getPinnedIntentsKey(role);
      final pinned = _prefs.getStringList(key) ?? [];

      // Add if not already pinned (up to 3 pins)
      if (!pinned.contains(intentTitle) && pinned.length < 3) {
        pinned.add(intentTitle);
        await _prefs.setStringList(key, pinned);
        debugPrint('✅ Pinned intent for ${role.displayName}: "$intentTitle"');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to pin intent: $e');
    }
  }

  /// Unpin an intent for a role
  Future<void> unpinIntent(UserRole role, String intentTitle) async {
    await _ensureInitialized();
    try {
      final key = _getPinnedIntentsKey(role);
      final pinned = _prefs.getStringList(key) ?? [];

      pinned.removeWhere((p) => p == intentTitle);
      await _prefs.setStringList(key, pinned);
      debugPrint('✅ Unpinned intent for ${role.displayName}: "$intentTitle"');
    } catch (e) {
      debugPrint('⚠️ Failed to unpin intent: $e');
    }
  }

  /// Get pinned intents for a role
  Future<List<String>> getPinnedIntents(UserRole role) async {
    await _ensureInitialized();
    try {
      final key = _getPinnedIntentsKey(role);
      final pinned = _prefs.getStringList(key) ?? [];
      debugPrint(
          '✅ Retrieved ${pinned.length} pinned intents for ${role.displayName}');
      return pinned;
    } catch (e) {
      debugPrint('⚠️ Failed to get pinned intents: $e');
      return [];
    }
  }

  /// Check if an intent is pinned
  Future<bool> isIntentPinned(UserRole role, String intentTitle) async {
    final pinned = await getPinnedIntents(role);
    return pinned.contains(intentTitle);
  }

  /// Clear all pinned intents for a role
  Future<void> clearPinnedIntents(UserRole role) async {
    await _ensureInitialized();
    try {
      final key = _getPinnedIntentsKey(role);
      await _prefs.remove(key);
      debugPrint('✅ Cleared pinned intents for ${role.displayName}');
    } catch (e) {
      debugPrint('⚠️ Failed to clear pinned intents: $e');
    }
  }
}
