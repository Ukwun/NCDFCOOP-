import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Represents a single search history entry
class SearchHistoryEntry {
  final String id;
  final String query;
  final String? category;
  final int? resultsCount;
  final DateTime searchedAt;
  final String? userId;
  final bool isBookmarked;

  SearchHistoryEntry({
    required this.id,
    required this.query,
    this.category,
    this.resultsCount,
    required this.searchedAt,
    this.userId,
    this.isBookmarked = false,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'query': query,
      'category': category,
      'results_count': resultsCount,
      'searched_at': FieldValue.serverTimestamp(),
      'user_id': userId,
      'is_bookmarked': isBookmarked,
    };
  }

  /// Create from Firestore document
  factory SearchHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SearchHistoryEntry(
      id: doc.id,
      query: data['query'] ?? '',
      category: data['category'],
      resultsCount: data['results_count'],
      searchedAt:
          (data['searched_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['user_id'],
      isBookmarked: data['is_bookmarked'] ?? false,
    );
  }
}

/// Service for managing search history
///
/// Features:
/// - Save search history
/// - Retrieve recent searches
/// - Bookmark/save favorite searches
/// - Clear history
/// - Per-user search history
class SearchHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'search_history';
  static const int maxHistoryItems = 50;

  /// Save a search to history
  Future<void> saveSearch(
    String query, {
    String? userId,
    String? category,
    int? resultsCount,
  }) async {
    try {
      if (query.isEmpty) return;

      AppLogger.debug('Saving search: "$query" for user: $userId');

      final entry = SearchHistoryEntry(
        id: DateTime.now().toString(),
        query: query,
        category: category,
        resultsCount: resultsCount,
        searchedAt: DateTime.now(),
        userId: userId,
      );

      await _firestore.collection(_collection).add(entry.toFirestore());

      debugPrint('✅ Search saved: "$query"');

      // Cleanup old entries if exceeded max
      await _cleanupOldEntries(userId);
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Get recent search history
  Future<List<SearchHistoryEntry>> getRecentSearches({
    String? userId,
    int limit = 10,
  }) async {
    try {
      AppLogger.debug('Fetching recent searches for user: $userId');

      Query query = _firestore.collection(_collection);

      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      final snapshot = await query
          .orderBy('searched_at', descending: true)
          .limit(limit)
          .get();

      final searches = snapshot.docs
          .map((doc) => SearchHistoryEntry.fromFirestore(doc))
          .toList();

      debugPrint('✅ Retrieved ${searches.length} recent searches');
      return searches;
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      return [];
    }
  }

  /// Get saved/bookmarked searches
  Future<List<SearchHistoryEntry>> getSavedSearches({
    String? userId,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug('Fetching saved searches for user: $userId');

      Query query = _firestore
          .collection(_collection)
          .where('is_bookmarked', isEqualTo: true);

      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      final snapshot = await query.limit(limit).get();

      final searches = snapshot.docs
          .map((doc) => SearchHistoryEntry.fromFirestore(doc))
          .toList();

      debugPrint('✅ Retrieved ${searches.length} saved searches');
      return searches;
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      return [];
    }
  }

  /// Bookmark a search
  Future<void> bookmarkSearch(String entryId) async {
    try {
      AppLogger.debug('Bookmarking search: $entryId');

      await _firestore
          .collection(_collection)
          .doc(entryId)
          .update({'is_bookmarked': true});

      debugPrint('✅ Search bookmarked: $entryId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Remove bookmark from a search
  Future<void> removeBookmark(String entryId) async {
    try {
      AppLogger.debug('Removing bookmark from search: $entryId');

      await _firestore
          .collection(_collection)
          .doc(entryId)
          .update({'is_bookmarked': false});

      debugPrint('✅ Bookmark removed: $entryId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Delete a search history entry
  Future<void> deleteSearch(String entryId) async {
    try {
      AppLogger.debug('Deleting search: $entryId');

      await _firestore.collection(_collection).doc(entryId).delete();

      debugPrint('✅ Search deleted: $entryId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Clear all search history for a user
  Future<void> clearHistory({String? userId}) async {
    try {
      AppLogger.debug('Clearing search history for user: $userId');

      Query query = _firestore.collection(_collection);

      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ Search history cleared for user: $userId');
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Clean up old entries if exceeds max
  Future<void> _cleanupOldEntries(String? userId) async {
    try {
      Query query = _firestore.collection(_collection);

      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      final snapshot =
          await query.orderBy('searched_at', descending: true).get();

      if (snapshot.docs.length > maxHistoryItems) {
        final toDelete = snapshot.docs.skip(maxHistoryItems);
        for (var doc in toDelete) {
          await doc.reference.delete();
        }
        debugPrint(
            '✅ Cleaned up ${toDelete.length} old search history entries');
      }
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
    }
  }

  /// Get search history statistics
  Future<Map<String, dynamic>> getSearchStats({String? userId}) async {
    try {
      Query query = _firestore.collection(_collection);

      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      final snapshot = await query.get();
      final entries = snapshot.docs
          .map((doc) => SearchHistoryEntry.fromFirestore(doc))
          .toList();

      // Calculate stats
      final totalSearches = entries.length;
      final uniqueQueries =
          entries.map((e) => e.query.toLowerCase()).toSet().length;
      final categoriesSearched =
          entries.where((e) => e.category != null).length;
      final avgResultsCount = entries
              .where((e) => e.resultsCount != null)
              .fold<int>(0, (sum, e) => sum + (e.resultsCount ?? 0)) ~/
          (entries.where((e) => e.resultsCount != null).length.max(1));

      return {
        'total_searches': totalSearches,
        'unique_queries': uniqueQueries,
        'categories_searched': categoriesSearched,
        'avg_results_count': avgResultsCount,
        'oldest_search': entries.isNotEmpty ? entries.last.searchedAt : null,
        'latest_search': entries.isNotEmpty ? entries.first.searchedAt : null,
      };
    } catch (e, st) {
      AppLogger.logException(e, stackTrace: st);
      return {};
    }
  }
}

extension IntMin on int {
  int max(int other) => this > other ? this : other;
}
