import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/providers/search_provider.dart';
import 'package:gearsh_app/features/search/presentation/widgets/filter_panel.dart';
import 'package:gearsh_app/features/search/presentation/widgets/search_results_list.dart';
import 'package:gearsh_app/widgets/gearsh_search_bar.dart';
import 'dart:async';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  // Gearsh theme colors
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).update(_searchController.text);
      if (_searchController.text.isNotEmpty) {
        ref.read(searchHistoryProvider.notifier).addSearchTerm(_searchController.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final searchHistory = ref.watch(searchHistoryProvider);

    return Scaffold(
      backgroundColor: _slate900,
      appBar: AppBar(
        backgroundColor: _slate900,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _slate800,
              shape: BoxShape.circle,
              border: Border.all(color: _sky500.withAlpha(51), width: 1),
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
          ),
          onPressed: () {
            try {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/');
              }
            } catch (e) {
              context.go('/');
            }
          },
        ),
        title: GearshSearchBar(
          controller: _searchController,
          focusNode: _searchFocusNode,
          hintText: 'Search artists, categories...',
          autofocus: true,
          compact: true,
          onClear: () {
            ref.read(searchQueryProvider.notifier).update('');
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _slate800,
                shape: BoxShape.circle,
                border: Border.all(color: _sky500.withAlpha(51), width: 1),
              ),
              child: const Icon(Icons.tune_rounded, size: 18, color: Colors.white),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: _slate900,
                builder: (context) => const FilterPanel(),
                isScrollControlled: true,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Active filters display could go here
          Expanded(
            child: searchResults.when(
              data: (results) {
                if (_searchController.text.isEmpty) {
                  return _buildHistoryAndTrending(searchHistory);
                }
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(13),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return SearchResultsList(results: results);
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: _sky500),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryAndTrending(List<String> history) {
    return ListView(
      children: [
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => ref.read(searchHistoryProvider.notifier).clearHistory(),
                  child: const Text('Clear'),
                )
              ],
            ),
          ),
          ...history.map((term) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(term),
                onTap: () {
                  _searchController.text = term;
                  _searchController.selection = TextSelection.fromPosition(TextPosition(offset: term.length));
                },
              )),
        ],
        // Trending searches could be added here
      ],
    );
  }
}

