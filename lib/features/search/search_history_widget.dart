import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coop_commerce/theme/app_theme.dart';
import 'package:coop_commerce/providers/search_providers.dart';
import 'package:coop_commerce/models/search_history_model.dart';

/// Search History Widget
/// Displays recent searches with bookmarking, deletion, and statistics
class SearchHistoryWidget extends ConsumerWidget {
  final VoidCallback? onSearchSelected;

  const SearchHistoryWidget({
    super.key,
    this.onSearchSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSearches = ref.watch(recentSearchesProvider);

    return recentSearches.when(
      data: (searches) {
        if (searches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No search history yet',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Clear Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Searches',
                      style: AppTextStyles.titleLarge,
                    ),
                    if (searches.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          _showClearConfirmation(context, ref);
                        },
                        child: Text(
                          'Clear All',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Saved/Bookmarked Searches Section
              _buildBookmarkedSearches(context, ref, searches),

              const SizedBox(height: 16),

              // Recent Searches List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searches.length,
                itemBuilder: (context, index) {
                  final search = searches[index];
                  return _buildSearchHistoryItem(
                    context,
                    ref,
                    search,
                    index,
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading search history: $error',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkedSearches(
    BuildContext context,
    WidgetRef ref,
    List<SearchHistoryEntry> searches,
  ) {
    final bookmarked = searches.where((s) => s.isBookmarked).toList();

    if (bookmarked.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Saved Searches',
            style: AppTextStyles.subtitleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bookmarked
                .map((search) => _buildSearchChip(context, ref, search))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Divider(),
        ),
      ],
    );
  }

  Widget _buildSearchChip(
    BuildContext context,
    WidgetRef ref,
    SearchHistoryEntry search,
  ) {
    return FilterChip(
      label: Text(search.query),
      onSelected: (_) {
        ref.read(searchQueryProvider.notifier).setQuery(search.query);
        onSearchSelected?.call();
      },
      deleteIcon: const Icon(Icons.bookmark, size: 18),
      onDeleted: () {
        final actions = ref.read(searchActionsProvider);
        actions.removeBookmark(search.id);
        ref.refresh(recentSearchesProvider);
      },
    );
  }

  Widget _buildSearchHistoryItem(
    BuildContext context,
    WidgetRef ref,
    SearchHistoryEntry search,
    int index,
  ) {
    final actions = ref.read(searchActionsProvider);

    return ListTile(
      leading: const Icon(
        Icons.search,
        color: AppColors.textLight,
      ),
      title: Text(
        search.query,
        style: AppTextStyles.bodyMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${search.resultsCount} results • ${_formatDate(search.timestamp)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
          if (search.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                children: search.tags
                    .take(2)
                    .map((tag) => Text(
                          '#$tag',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'bookmark':
              if (search.isBookmarked) {
                actions.removeBookmark(search.id);
              } else {
                actions.bookmarkSearch(search.id);
              }
              ref.refresh(recentSearchesProvider);
              break;
            case 'delete':
              actions.deleteSearch(search.id);
              ref.refresh(recentSearchesProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Search removed from history'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              break;
          }
        },
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            value: 'bookmark',
            child: Row(
              children: [
                Icon(
                  search.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(search.isBookmarked ? 'Unsave' : 'Save'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 20),
                const SizedBox(width: 12),
                const Text('Delete'),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        ref.read(searchQueryProvider.notifier).setQuery(search.query);
        onSearchSelected?.call();
      },
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Search History?'),
        content: const Text(
          'This will delete all your search history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final actions = ref.read(searchActionsProvider);
              actions.clearHistory();
              ref.refresh(recentSearchesProvider);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search history cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
