import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/providers/search_provider.dart';
import 'package:gearsh_app/features/search/presentation/widgets/filter_panel.dart';
import 'package:gearsh_app/features/search/presentation/widgets/search_results_list.dart';
import 'dart:async';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search artists, categories, locations...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const FilterPanel(),
                isScrollControlled: true,
              );
            },
          ),
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
                  return const Center(child: Text('No results found.'));
                }
                return SearchResultsList(results: results);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
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

