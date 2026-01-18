import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/providers/search_provider.dart';
import 'package:gearsh_app/services/search_service.dart';
import 'package:gearsh_app/models/search_models.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';
import 'package:gearsh_app/features/search/presentation/widgets/filter_panel.dart';
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
  bool _showSuggestions = false;

  // Gearsh theme colors
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate700 = Color(0xFF334155);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _green500 = Color(0xFF22C55E);
  static const Color _yellow500 = Color(0xFFEAB308);
  static const Color _purple500 = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
      });
    });
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
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).update(_searchController.text);
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addSearchTerm(query);
      ref.read(searchQueryProvider.notifier).update(query);
      setState(() => _showSuggestions = false);
      _searchFocusNode.unfocus();
    }
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    _searchController.text = suggestion.text;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.text.length),
    );
    _submitSearch(suggestion.text);
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(gearshSearchResultsProvider);
    final suggestions = ref.watch(searchSuggestionsProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    final popularSearches = ref.watch(popularSearchesProvider);
    final filters = ref.watch(searchFiltersProvider);

    return Scaffold(
      backgroundColor: _slate950,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            _buildSearchHeader(filters),

            // Main Content
            Expanded(
              child: Stack(
                children: [
                  // Results or Empty State
                  _buildMainContent(searchResults, searchHistory, popularSearches),

                  // Autocomplete Suggestions Overlay
                  if (_showSuggestions && suggestions.isNotEmpty)
                    _buildSuggestionsOverlay(suggestions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(SearchFilters filters) {
    final hasActiveFilters = !filters.isDefault;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: _slate900,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _slate800,
                    shape: BoxShape.circle,
                    border: Border.all(color: _sky500.withAlpha(51)),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),

              // Search Input
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _slate800,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus ? _sky500 : _sky500.withAlpha(51),
                      width: _searchFocusNode.hasFocus ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_sky400, _cyan500],
                        ).createShader(bounds),
                        child: const Icon(Icons.search, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Search artists, categories, locations...',
                            hintStyle: TextStyle(color: _slate400, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: _submitSearch,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _slate700,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Filter Button
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const FilterPanel(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasActiveFilters ? _sky500.withAlpha(51) : _slate800,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasActiveFilters ? _sky500 : _sky500.withAlpha(51),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: hasActiveFilters ? _sky400 : Colors.white,
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _sky500,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Active Filters Pills
          if (hasActiveFilters) ...[
            const SizedBox(height: 12),
            _buildActiveFiltersPills(),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFiltersPills() {
    final filters = ref.watch(searchFiltersProvider);
    final pills = <Widget>[];

    // Category pills
    for (final category in filters.categories) {
      pills.add(_buildFilterPill(
        category,
        _purple500,
        () => ref.read(searchFiltersProvider.notifier).toggleCategory(category),
      ));
    }

    // Verified only pill
    if (filters.showVerifiedOnly) {
      pills.add(_buildFilterPill(
        'Verified',
        _green500,
        () => ref.read(searchFiltersProvider.notifier).toggleVerifiedOnly(),
      ));
    }

    // Rating pill
    if (filters.minRating > 0) {
      pills.add(_buildFilterPill(
        '${filters.minRating}+ Stars',
        _yellow500,
        () => ref.read(searchFiltersProvider.notifier).setMinRating(0),
      ));
    }

    // Clear all
    if (pills.isNotEmpty) {
      pills.add(
        GestureDetector(
          onTap: () => ref.read(searchFiltersProvider.notifier).reset(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _slate700),
            ),
            child: const Text(
              'Clear all',
              style: TextStyle(color: _slate400, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: pills.map((p) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: p,
        )).toList(),
      ),
    );
  }

  Widget _buildFilterPill(String label, Color color, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay(List<SearchSuggestion> suggestions) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _slate900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _sky500.withAlpha(51)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(102),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestions.map((suggestion) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectSuggestion(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: _slate800, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getSuggestionColor(suggestion.type).withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getSuggestionIcon(suggestion.type),
                            size: 18,
                            color: _getSuggestionColor(suggestion.type),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (suggestion.subtitle != null)
                                Text(
                                  suggestion.subtitle!,
                                  style: TextStyle(
                                    color: _slate400,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.north_west,
                          size: 16,
                          color: _slate400,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.artist:
        return Icons.person_rounded;
      case SuggestionType.category:
        return Icons.category_rounded;
      case SuggestionType.location:
        return Icons.location_on_rounded;
      case SuggestionType.recent:
        return Icons.history_rounded;
    }
  }

  Color _getSuggestionColor(SuggestionType type) {
    switch (type) {
      case SuggestionType.artist:
        return _sky500;
      case SuggestionType.category:
        return _purple500;
      case SuggestionType.location:
        return _green500;
      case SuggestionType.recent:
        return _slate400;
    }
  }

  Widget _buildMainContent(
    AsyncValue<List<GearshSearchResult>> searchResults,
    List<String> searchHistory,
    List<String> popularSearches,
  ) {
    final query = ref.watch(searchQueryProvider);

    if (query.isEmpty) {
      return _buildEmptyState(searchHistory, popularSearches);
    }

    return searchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return _buildNoResults(query);
        }
        return _buildSearchResults(results, query);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: _sky500),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.withAlpha(179)),
            const SizedBox(height: 16),
            Text('Error: $err', style: TextStyle(color: _slate400)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(List<String> searchHistory, List<String> popularSearches) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(searchHistoryProvider.notifier).clearHistory(),
                  child: Text(
                    'Clear all',
                    style: TextStyle(color: _sky400, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: searchHistory.take(10).map((term) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = term;
                    _submitSearch(term);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _slate800,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _sky500.withAlpha(51)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16, color: _slate400),
                        const SizedBox(width: 8),
                        Text(
                          term,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => ref.read(searchHistoryProvider.notifier).removeSearchTerm(term),
                          child: Icon(Icons.close, size: 14, color: _slate400),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Popular Searches
          const Text(
            'Popular Searches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: popularSearches.map((term) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = term;
                  _submitSearch(term);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_sky500.withAlpha(26), _cyan500.withAlpha(26)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _sky500.withAlpha(77)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 16, color: _sky400),
                      const SizedBox(width: 8),
                      Text(
                        term,
                        style: TextStyle(color: _sky400, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Quick Categories
          const Text(
            'Browse by Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'name': 'Emerging Artist', 'icon': Icons.star_rounded, 'color': _green500, 'badge': 'FREE'},
      {'name': 'DJ', 'icon': Icons.music_note, 'color': _sky500, 'badge': null},
      {'name': 'Amapiano', 'icon': Icons.piano, 'color': _purple500, 'badge': null},
      {'name': 'Hip Hop', 'icon': Icons.mic, 'color': _yellow500, 'badge': null},
      {'name': 'Gospel', 'icon': Icons.church, 'color': const Color(0xFFEC4899), 'badge': null},
      {'name': 'Fashion Designer', 'icon': Icons.checkroom, 'color': const Color(0xFFF97316), 'badge': null},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final badge = cat['badge'] as String?;
        return GestureDetector(
          onTap: () {
            _searchController.text = cat['name'] as String;
            _submitSearch(cat['name'] as String);
          },
          child: Container(
            decoration: BoxDecoration(
              color: (cat['color'] as Color).withAlpha(26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (cat['color'] as Color).withAlpha(77)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        size: 28,
                        color: cat['color'] as Color,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(
                          color: cat['color'] as Color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _green500,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _slate800,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: _slate400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results for "$query"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Try searching for a different artist name, category, or location',
              style: TextStyle(color: _slate400, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).clear();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Clear Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<GearshSearchResult> results, String query) {
    return Column(
      children: [
        // Results count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                '${results.length} result${results.length == 1 ? '' : 's'}',
                style: TextStyle(color: _slate400, fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _buildSortBottomSheet(),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 18, color: _sky400),
                    const SizedBox(width: 6),
                    Text(
                      'Sort',
                      style: TextStyle(color: _sky400, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return _buildSearchResultCard(results[index], query);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(GearshSearchResult result, String query) {
    final artist = result.artist;

    return GestureDetector(
      onTap: () => context.go('/artist/${artist.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _slate900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _sky500.withAlpha(51)),
        ),
        child: Row(
          children: [
            // Artist Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _sky500.withAlpha(77)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(
                  artist.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _slate800,
                    child: Icon(Icons.person, color: _sky500.withAlpha(128), size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Artist Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Verified
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (artist.isVerified)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: _sky500,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 10),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category & Location
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _purple500.withAlpha(38),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          artist.category,
                          style: TextStyle(
                            color: _purple500,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on_outlined, size: 12, color: _slate400),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          artist.location,
                          style: TextStyle(color: _slate400, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Rating, Hours & Price
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: _yellow500),
                      const SizedBox(width: 4),
                      Text(
                        artist.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        artist.masteryInfo.icon,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${_formatHours(artist.hoursBooked)}h',
                        style: TextStyle(color: _slate400, fontSize: 11),
                      ),
                      const Spacer(),
                      // Price with discount support
                      if (artist.showDiscount)
                        _buildDiscountPrice(artist)
                      else if (artist.bookingFee > 0)
                        Text(
                          'From R${artist.bookingFee}',
                          style: TextStyle(
                            color: _green500,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _green500.withAlpha(38),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'FREE',
                            style: TextStyle(
                              color: _green500,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Match indicator
                  if (result.matchedFields.isNotEmpty && result.matchType != MatchType.none) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 12, color: _sky400.withAlpha(179)),
                        const SizedBox(width: 4),
                        Text(
                          'Matched: ${result.matchedFields.take(2).join(', ')}',
                          style: TextStyle(color: _sky400.withAlpha(179), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: _slate400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSortBottomSheet() {
    final currentSort = ref.watch(searchFiltersProvider).sortOption;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _slate900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _slate700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sort By',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...SortOption.values.map((option) {
            final isSelected = currentSort == option;
            return GestureDetector(
              onTap: () {
                ref.read(searchFiltersProvider.notifier).setSortOption(option);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _sky500.withAlpha(26) : _slate800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _sky500 : _slate700,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getSortIcon(option),
                      color: isSelected ? _sky400 : _slate400,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _getSortLabel(option),
                      style: TextStyle(
                        color: isSelected ? _sky400 : Colors.white,
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle, color: _sky500, size: 20),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.relevance:
        return Icons.auto_awesome;
      case SortOption.highestRated:
        return Icons.star;
      case SortOption.priceLowToHigh:
        return Icons.arrow_upward;
      case SortOption.priceHighToLow:
        return Icons.arrow_downward;
      case SortOption.mostPopular:
        return Icons.trending_up;
    }
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.relevance:
        return 'Most Relevant';
      case SortOption.highestRated:
        return 'Highest Rated';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.mostPopular:
        return 'Most Popular';
    }
  }

  String _formatHours(int hours) {
    if (hours >= 1000) {
      return '${(hours / 1000).toStringAsFixed(1)}K';
    }
    return hours.toString();
  }

  Widget _buildDiscountPrice(GearshArtist artist) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Discount badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '-${artist.displayDiscountPercent}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Original price crossed out
        Text(
          'R${artist.displayOriginalPrice}',
          style: TextStyle(
            color: _slate400,
            fontSize: 10,
            decoration: TextDecoration.lineThrough,
            decorationColor: _slate400,
          ),
        ),
        const SizedBox(width: 4),
        // Discounted price
        Text(
          'R${artist.displayPrice}',
          style: TextStyle(
            color: _green500,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

