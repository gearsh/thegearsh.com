import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/search_models.dart';
import 'package:gearsh_app/services/search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notifier for search query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;

  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// Notifier for search filters
class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void setCategories(Set<String> categories) {
    state = state.copyWith(categories: categories);
  }

  void setMinRating(double rating) {
    state = state.copyWith(minRating: rating);
  }

  void toggleVerifiedOnly() {
    state = state.copyWith(showVerifiedOnly: !state.showVerifiedOnly);
  }

  void setPriceRange(RangeValues range) {
    state = state.copyWith(priceRange: range);
  }

  void setSortOption(SortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void reset() {
    state = const SearchFilters();
  }
}

final searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(SearchFiltersNotifier.new);

final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(searchFiltersProvider);
  final searchService = ref.read(searchServiceProvider);

  // Debouncing logic could be added here if not handled in the UI
  return searchService.searchArtists(query: query, filters: filters);
});

// Notifier for search history
class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _historyKey = 'gearsh_search_history';
  static const _maxHistory = 20;

  @override
  List<String> build() {
    _loadHistory();
    return [];
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> addSearchTerm(String term) async {
    final lowercasedTerm = term.toLowerCase();
    final newState = [
      lowercasedTerm,
      ...state.where((t) => t != lowercasedTerm),
    ];
    if (newState.length > _maxHistory) {
      newState.removeLast();
    }
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, state);
  }

  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}

final searchHistoryProvider = NotifierProvider<SearchHistoryNotifier, List<String>>(SearchHistoryNotifier.new);
