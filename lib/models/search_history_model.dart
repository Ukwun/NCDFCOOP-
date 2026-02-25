// Search History Entry Model
// Represents a single search entry in user's search history

class SearchHistoryEntry {
  final String id;
  final String query;
  final int resultsCount;
  final List<String> tags;
  final DateTime timestamp;
  final bool isBookmarked;

  SearchHistoryEntry({
    required this.id,
    required this.query,
    required this.resultsCount,
    required this.tags,
    required this.timestamp,
    required this.isBookmarked,
  });

  factory SearchHistoryEntry.fromFirestore(Map<String, dynamic> data, String docId) {
    return SearchHistoryEntry(
      id: docId,
      query: data['query'] ?? '',
      resultsCount: data['resultsCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      isBookmarked: data['isBookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'query': query,
      'resultsCount': resultsCount,
      'tags': tags,
      'timestamp': timestamp,
      'isBookmarked': isBookmarked,
    };
  }

  SearchHistoryEntry copyWith({
    String? id,
    String? query,
    int? resultsCount,
    List<String>? tags,
    DateTime? timestamp,
    bool? isBookmarked,
  }) {
    return SearchHistoryEntry(
      id: id ?? this.id,
      query: query ?? this.query,
      resultsCount: resultsCount ?? this.resultsCount,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
