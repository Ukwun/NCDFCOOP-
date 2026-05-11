import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_commerce/services/local_search_preferences_service.dart';
import 'package:coop_commerce/providers/auth_provider.dart';

/// Global instance of LocalSearchPreferencesService
final searchPreferencesServiceProvider =
    Provider<LocalSearchPreferencesService>((ref) {
  return LocalSearchPreferencesService();
});

/// Initialize search preferences service (called once at app startup)
final initSearchPreferencesProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(searchPreferencesServiceProvider);
  await service.init();
});

/// Recent searches for the current user's role
final recentSearchesForRoleProvider = FutureProvider<List<String>>((ref) {
  final service = ref.watch(searchPreferencesServiceProvider);
  final currentRole = ref.watch(currentRoleProvider);

  return service.getRecentSearches(currentRole);
});

/// Pinned intents for the current user's role
final pinnedIntentsForRoleProvider = FutureProvider<List<String>>((ref) {
  final service = ref.watch(searchPreferencesServiceProvider);
  final currentRole = ref.watch(currentRoleProvider);

  return service.getPinnedIntents(currentRole);
});

/// Save a recent search for the current role
final saveRecentSearchProvider =
    FutureProvider.family<void, String>((ref, query) async {
  final service = ref.watch(searchPreferencesServiceProvider);
  final currentRole = ref.watch(currentRoleProvider);

  await service.saveRecentSearch(currentRole, query);

  // Invalidate the recent searches provider to refresh the UI
  ref.invalidate(recentSearchesForRoleProvider);
});

/// Pin an intent for the current role
final pinIntentProvider =
    FutureProvider.family<void, String>((ref, intentTitle) async {
  final service = ref.watch(searchPreferencesServiceProvider);
  final currentRole = ref.watch(currentRoleProvider);

  await service.pinIntent(currentRole, intentTitle);

  // Invalidate the pinned intents provider to refresh the UI
  ref.invalidate(pinnedIntentsForRoleProvider);
});

/// Unpin an intent for the current role
final unpinIntentProvider =
    FutureProvider.family<void, String>((ref, intentTitle) async {
  final service = ref.watch(searchPreferencesServiceProvider);
  final currentRole = ref.watch(currentRoleProvider);

  await service.unpinIntent(currentRole, intentTitle);

  // Invalidate the pinned intents provider to refresh the UI
  ref.invalidate(pinnedIntentsForRoleProvider);
});

/// Check if an intent is pinned for the current role
final isIntentPinnedProvider =
    FutureProvider.family<bool, String>((ref, intentTitle) async {
  final service = ref.watch(searchPreferencesServiceProvider);
  final currentRole = ref.watch(currentRoleProvider);

  return service.isIntentPinned(currentRole, intentTitle);
});
