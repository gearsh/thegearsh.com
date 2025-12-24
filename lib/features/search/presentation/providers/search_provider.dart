import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/features/search/data/models/search_filters.dart';
import 'package:gearsh_app/features/search/data/models/search_result.dart';
import 'package:gearsh_app/features/search/data/services/search_service.dart';
import 'package:gearsh_app/providers/artist_provider.dart';

// Notifier for search query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;

  void clear() => state = '';
}

// Manages the raw search query input by the user
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// Notifier for search filters
class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => SearchFilters.defaults();

  void update(SearchFilters filters) => state = filters;

  void reset() => state = SearchFilters.defaults();
}

// Manages the active search filters
final searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(SearchFiltersNotifier.new);

// Performs the search and returns the results
final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(searchFiltersProvider);
  final allArtists = await ref.watch(artistListProvider.future);
  final searchService = ref.read(searchServiceProvider);

  if (query.isEmpty && filters.isDefault) {
    return [];
  }

  // In a real app, you'd add debouncing here
  return searchService.searchArtists(
    artists: allArtists,
    query: query,
    filters: filters,
  );
});
