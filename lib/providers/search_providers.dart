import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/algolia_search_service.dart';
import '../services/search_history_service.dart';
import '../utils/logger.dart';

/// Algolia service provider
final algoliaSearchServiceProvider = Provider((ref) {
  return AlgoliaSearchService(
    config: AlgoliaConfig(
      appId: 'YOUR_ALGOLIA_APP_ID',
      apiKey: 'YOUR_ALGOLIA_API_KEY',
      indexName: 'products',
    ),
  );
});

/// Search history service provider
final searchHistoryServiceProvider = Provider((ref) {
  return SearchHistoryService();
});

/// ============================================================================
/// SEARCH STATE PROVIDERS
/// ============================================================================

/// Current search query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

/// ============================================================================
/// SEARCH FILTER PROVIDERS
/// ============================================================================

/// Search filters state
class SearchFilters {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String sortBy;
  final bool? memberExclusive;

  SearchFilters({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sortBy = 'relevance',
    this.memberExclusive,
  });

  SearchFilters copyWith({
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
    bool? memberExclusive,
  }) {
    return SearchFilters(
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
      memberExclusive: memberExclusive ?? this.memberExclusive,
    );
  }

  bool get hasAnyFilters =>
      category != null ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      memberExclusive != null;

  void clearAll() {
    // This creates a new instance with all filters cleared
  }
}

/// Search filters notifier
class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() {
    return SearchFilters();
  }

  void setCategory(String? category) {
    state = state.copyWith(category: category);
  }

  void setPriceRange(double? minPrice, double? maxPrice) {
    state = state.copyWith(minPrice: minPrice, maxPrice: maxPrice);
  }

  void setMinRating(double? rating) {
    state = state.copyWith(minRating: rating);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setMemberExclusive(bool? exclusive) {
    state = state.copyWith(memberExclusive: exclusive);
  }

  void clearAllFilters() {
    state = SearchFilters();
  }
}

/// Track search filters
final searchFiltersProvider =
    NotifierProvider<SearchFiltersNotifier, SearchFilters>(() {
  return SearchFiltersNotifier();
});

/// ============================================================================
/// SEARCH RESULTS PROVIDERS
/// ============================================================================

/// Perform product search with filters
final searchResultsProvider =
    FutureProvider.family<AlgoliaSearchResult, String>(
  (ref, query) async {
    if (query.isEmpty) {
      return AlgoliaSearchResult(
        products: [],
        totalCount: 0,
        queryTimeMs: 0,
        processingTimeMs: 0,
      );
    }

    final searchService = ref.watch(algoliaSearchServiceProvider);
    final filters = ref.watch(searchFiltersProvider);

    try {
      final result = await searchService.search(
        query: query,
        category: filters.category,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        minRating: filters.minRating,
        sortBy: filters.sortBy,
        memberExclusive: filters.memberExclusive,
        limit: 50,
      );

      // Log search for analytics
      await searchService.logSearch(
        query,
        category: filters.category,
        resultsCount: result.totalCount,
      );

      return result;
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      return AlgoliaSearchResult(
        products: [],
        totalCount: 0,
        queryTimeMs: 0,
        processingTimeMs: 0,
      );
    }
  },
);

/// Get autocomplete suggestions as user types
final autocompleteSuggestionsProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final searchService = ref.watch(algoliaSearchServiceProvider);
  try {
    final suggestions = await searchService.getAutocompleteSuggestions(query);
    return suggestions.take(10).toList();
  } catch (e) {
    return [];
  }
});

/// Get trending searches
final trendingSearchesProvider = FutureProvider<List<String>>((ref) async {
  final searchService = ref.watch(algoliaSearchServiceProvider);
  try {
    return await searchService.getTrendingSearches(limit: 10);
  } catch (e) {
    return [];
  }
});

/// Get popular categories for filtering
final popularCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final searchService = ref.watch(algoliaSearchServiceProvider);
  try {
    return await searchService.getPopularCategories(limit: 10);
  } catch (e) {
    return [];
  }
});

/// ============================================================================
/// SEARCH HISTORY PROVIDERS
/// ============================================================================

/// Get recent searches for current user
final recentSearchesProvider =
    FutureProvider<List<SearchHistoryEntry>>((ref) async {
  final historyService = ref.watch(searchHistoryServiceProvider);
  try {
    // TODO: Get actual userId from auth provider
    return await historyService.getRecentSearches(limit: 10);
  } catch (e) {
    return [];
  }
});

/// Get saved/bookmarked searches
final savedSearchesProvider =
    FutureProvider<List<SearchHistoryEntry>>((ref) async {
  final historyService = ref.watch(searchHistoryServiceProvider);
  try {
    return await historyService.getSavedSearches(limit: 20);
  } catch (e) {
    return [];
  }
});

/// ============================================================================
/// SEARCH ACTIONS PROVIDERS
/// ============================================================================

/// Provider for search-related actions
final searchActionsProvider = Provider((ref) {
  final historyService = ref.read(searchHistoryServiceProvider);
  final searchService = ref.read(algoliaSearchServiceProvider);

  return SearchActions(
    historyService: historyService,
    searchService: searchService,
  );
});

/// Helper class for search-related actions
class SearchActions {
  final SearchHistoryService historyService;
  final AlgoliaSearchService searchService;

  SearchActions({
    required this.historyService,
    required this.searchService,
  });

  /// Save a search to history
  Future<void> saveSearch(
    String query, {
    String? userId,
    String? category,
    int? resultsCount,
  }) async {
    await historyService.saveSearch(
      query,
      userId: userId,
      category: category,
      resultsCount: resultsCount,
    );
  }

  /// Bookmark a search
  Future<void> bookmarkSearch(String entryId) async {
    await historyService.bookmarkSearch(entryId);
  }

  /// Remove bookmark
  Future<void> removeBookmark(String entryId) async {
    await historyService.removeBookmark(entryId);
  }

  /// Delete search from history
  Future<void> deleteSearch(String entryId) async {
    await historyService.deleteSearch(entryId);
  }

  /// Clear all search history
  Future<void> clearHistory({String? userId}) async {
    await historyService.clearHistory(userId: userId);
  }

  /// Get search statistics
  Future<Map<String, dynamic>> getSearchStats({String? userId}) async {
    return await historyService.getSearchStats(userId: userId);
  }

  /// Get search analytics
  Future<Map<String, dynamic>> getSearchAnalytics(String query) async {
    return await searchService.getSearchAnalytics(query: query);
  }

  /// Log search query
  Future<void> logSearch(
    String query, {
    String? category,
    int? resultsCount,
    String? userId,
  }) async {
    await searchService.logSearch(
      query,
      category: category,
      resultsCount: resultsCount,
      userId: userId,
    );
  }
}

/// ============================================================================
/// SEARCH STATE (Combined for convenience)
/// ============================================================================

/// Combined search state for easier consumption
class CombinedSearchState {
  final String query;
  final SearchFilters filters;
  final AlgoliaSearchResult? results;
  final List<String>? suggestions;
  final List<String>? trending;
  final List<SearchHistoryEntry>? recentSearches;
  final bool isLoading;
  final String? error;

  const CombinedSearchState({
    required this.query,
    required this.filters,
    this.results,
    this.suggestions,
    this.trending,
    this.recentSearches,
    this.isLoading = false,
    this.error,
  });
}

/// Combined provider for all search-related state
final combinedSearchStateProvider =
    FutureProvider<CombinedSearchState>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(searchFiltersProvider);
  final results = ref.watch(searchResultsProvider(query));
  final suggestions = ref.watch(autocompleteSuggestionsProvider(query));
  final trending = ref.watch(trendingSearchesProvider);
  final recentSearches = ref.watch(recentSearchesProvider);

  return await results.when(
    data: (resultsData) => suggestions.when(
      data: (suggestionsData) => trending.when(
        data: (trendingData) => recentSearches.when(
          data: (recentSearchesData) => CombinedSearchState(
            query: query,
            filters: filters,
            results: resultsData,
            suggestions: suggestionsData,
            trending: trendingData,
            recentSearches: recentSearchesData,
            isLoading: false,
          ),
          loading: () => CombinedSearchState(
            query: query,
            filters: filters,
            isLoading: true,
          ),
          error: (err, st) => CombinedSearchState(
            query: query,
            filters: filters,
            error: err.toString(),
          ),
        ),
        loading: () => CombinedSearchState(
          query: query,
          filters: filters,
          isLoading: true,
        ),
        error: (err, st) => CombinedSearchState(
          query: query,
          filters: filters,
          error: err.toString(),
        ),
      ),
      loading: () => CombinedSearchState(
        query: query,
        filters: filters,
        isLoading: true,
      ),
      error: (err, st) => CombinedSearchState(
        query: query,
        filters: filters,
        error: err.toString(),
      ),
    ),
    loading: () => CombinedSearchState(
      query: query,
      filters: filters,
      isLoading: true,
    ),
    error: (err, st) => CombinedSearchState(
      query: query,
      filters: filters,
      error: err.toString(),
    ),
  );
});
