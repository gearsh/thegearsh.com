import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';
import 'package:gearsh_app/features/search/presentation/widgets/filter_panel.dart';
import 'package:gearsh_app/providers/search_provider.dart';
import 'package:gearsh_app/providers/selection_provider.dart';
import 'package:gearsh_app/widgets/bottom_nav_bar.dart';
import 'package:gearsh_app/widgets/gearsh_background.dart';
import 'package:gearsh_app/widgets/gearsh_search_bar.dart';
import 'package:gearsh_app/widgets/cart_icon.dart';
import 'package:gearsh_app/theme.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchBar = false;

  // App theme colors
  static const Color _primaryColor = primaryColor; // Deep Sky Blue #00BFFF
  static const Color _darkBg = darkBackgroundColor; // #111111

  // Top 7 main categories that cover all artists
  static const Map<String, Color> mainCategories = {
    'Music': Color(0xFF8B5CF6), // Purple
    'Visual Arts': Color(0xFF0EA5E9), // Sky blue
    'Performance': Color(0xFFEF4444), // Red
    'Tech & Digital': Color(0xFF10B981), // Emerald
    'Content Creation': Color(0xFFEC4899), // Pink
    'Beauty & Fashion': Color(0xFFF472B6), // Pink
    'Events & Services': Color(0xFFF59E0B), // Amber
  };

  // Map subcategories to main categories
  static const Map<String, String> categoryMapping = {
    // Music
    'DJ': 'Music',
    'Amapiano': 'Music',
    'Hip Hop': 'Music',
    'Music Production': 'Music',
    'Afro-House': 'Music',
    'Pop & R&B': 'Music',
    'Afro-Pop': 'Music',
    'Rap': 'Music',
    'Afro-Soul': 'Music',
    'Gospel': 'Music',
    'Electronic': 'Music',
    'Jazz': 'Music',
    'Rock': 'Music',
    'Classical': 'Music',
    'Alternative': 'Music',
    'Pop': 'Music',
    'Producer': 'Music',
    'Sound Engineer': 'Music',
    'Songwriter': 'Music',

    // Visual Arts
    'Photography': 'Visual Arts',
    'Videography': 'Visual Arts',
    'Graphic Design': 'Visual Arts',
    'Illustration': 'Visual Arts',
    'Animation': 'Visual Arts',
    'Visual Art': 'Visual Arts',
    'Fine Art': 'Visual Arts',
    '3D Art': 'Visual Arts',

    // Performance
    'Acting': 'Performance',
    'Comedy': 'Performance',
    'Dance': 'Performance',
    'Theatre': 'Performance',
    'Voice Over': 'Performance',
    'MC/Host': 'Performance',
    'Modeling': 'Performance',

    // Tech & Digital
    'Developer': 'Tech & Digital',
    'Web Design': 'Tech & Digital',
    'UI/UX Design': 'Tech & Digital',
    'App Development': 'Tech & Digital',
    'Game Development': 'Tech & Digital',

    // Content Creation
    'Content Creator': 'Content Creation',
    'Influencer': 'Content Creation',
    'Podcaster': 'Content Creation',
    'YouTuber': 'Content Creation',
    'Blogger': 'Content Creation',
    'Streamer': 'Content Creation',
    'Writer': 'Content Creation',
    'Copywriter': 'Content Creation',

    // Beauty & Fashion
    'Makeup Artist': 'Beauty & Fashion',
    'Hair Stylist': 'Beauty & Fashion',
    'Fashion Designer': 'Beauty & Fashion',
    'Stylist': 'Beauty & Fashion',

    // Events & Services
    'Event Planner': 'Events & Services',
    'Decorator': 'Events & Services',
    'Caterer': 'Events & Services',
    'Baker': 'Events & Services',
  };

  // Get artists grouped by main category (deduplicated)
  Map<String, List<GearshArtist>> get artistsByMainCategory {
    final Map<String, List<GearshArtist>> grouped = {};
    for (final category in mainCategories.keys) {
      grouped[category] = [];
    }
    for (final artist in uniqueArtists()) {
      final mainCategory = categoryMapping[artist.category] ?? 'Music';
      grouped[mainCategory]?.add(artist);
    }
    return grouped;
  }

  // Get artists grouped by category (deduplicated)
  Map<String, List<GearshArtist>> get artistsByGenre {
    final Map<String, List<GearshArtist>> grouped = {};
    for (final artist in uniqueArtists()) {
      if (!grouped.containsKey(artist.category)) {
        grouped[artist.category] = [];
      }
      grouped[artist.category]!.add(artist);
    }
    return grouped;
  }

  // Get featured artists (high rating, verified) - deduplicated
  List<GearshArtist> get featuredArtists {
    return getUniqueFeaturedArtists(limit: 10);
  }

  // Get trending artists - deduplicated
  List<GearshArtist> get trendingArtists {
    final trending = getUniqueTrendingArtists(limit: 15);
    trending.shuffle();
    return trending;
  }

  // Get new additions (last items in list, assuming newer) - deduplicated
  List<GearshArtist> get newArtists {
    return getUniqueNewArtists(limit: 10);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_showSearchBar) {
      setState(() => _showSearchBar = true);
    } else if (_scrollController.offset <= 100 && _showSearchBar) {
      setState(() => _showSearchBar = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(searchQueryProvider);
    final sortedGenres = artistsByGenre.keys.toList()
      ..sort((a, b) => artistsByGenre[b]!.length.compareTo(artistsByGenre[a]!.length));

    final bool isSearching = searchQuery.length >= 2;

    return GearshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: (isSearching || _showSearchBar)
              ? const Color(0xFF0F172A).withValues(alpha: 0.95)
              : Colors.transparent,
          elevation: 0,
          leading: isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    ref.read(searchQueryProvider.notifier).update('');
                  },
                )
              : null,
          title: isSearching
              ? _buildActiveSearchBar(theme)
              : (_showSearchBar ? _buildCompactSearchBar(theme) : null),
          actions: [
            IconButton(
              onPressed: () {
                // Open the shared FilterPanel (uses searchFiltersProvider for state)
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (ctx) => const FilterPanel(),
                );
              },
              icon: Icon(
                Icons.filter_list_rounded,
                color: ref.watch(searchFiltersProvider).isDefault ? Colors.white : _primaryColor,
              ),
            ),
            const SizedBox(width: 6),
            if (!isSearching) const CartIconButton(),
            IconButton(
              onPressed: () => context.go('/discover/map'),
              icon: const Icon(Icons.map_outlined, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: isSearching
            ? _buildSearchResultsBody(theme, searchQuery)
            : _buildMainContent(theme, sortedGenres),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }

  Widget _buildActiveSearchBar(ThemeData theme) {
    // Compact, robust active search bar used when the search is active
    const Color sky500 = Color(0xFF0EA5E9);
    const Color sky400 = Color(0xFF38BDF8);
    const Color cyan500 = Color(0xFF06B6D4);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        border: Border.all(color: sky500.withAlpha(77), width: 1),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [sky400, cyan500],
            ).createShader(bounds),
            child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search artists...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(77), fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).update('');
              },
              child: Icon(Icons.close_rounded, color: Colors.white.withAlpha(128), size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsBody(ThemeData theme, String query) {
    final results = _searchArtists(query);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '${results.length} artist${results.length == 1 ? '' : 's'} found',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ),
          // Results grid
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
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
                          'No artists found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.grey[400],
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
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final artist = results[index];
                      return _buildSearchResultCircle(theme, artist);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSearchBar(ThemeData theme) {
    return GearshSearchBar(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Search artists...',
      onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
      onClear: () => ref.read(searchQueryProvider.notifier).update(''),
      compact: true,
    );
  }

  Widget _buildMainContent(ThemeData theme, List<String> sortedGenres) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Hero Header
        SliverToBoxAdapter(
          child: _buildHeroHeader(theme),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchBar(theme),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // Featured Artists - Large circular avatars
        SliverToBoxAdapter(
          child: _buildFeaturedSection(theme),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // Browse Genres Grid
        SliverToBoxAdapter(
          child: _buildBrowseGenresSection(theme, sortedGenres),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // Trending Now
        SliverToBoxAdapter(
          child: _buildCircularArtistSection(
            theme,
            'Trending Now 🔥',
            trendingArtists,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // Genre Sections
        ...sortedGenres.expand((genre) => [
          SliverToBoxAdapter(
            child: _buildGenreSection(theme, genre, artistsByGenre[genre]!),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),

        // New Additions
        SliverToBoxAdapter(
          child: _buildCircularArtistSection(
            theme,
            'New Additions ✨',
            newArtists,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF22D3EE)],
              ).createShader(bounds),
              child: Text(
                _getGreeting(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover ${gearshArtists.length}+ South African artists',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildSearchBar(ThemeData theme) {
    return GearshSearchBar(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Search artists, genres, locations...',
      onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
      onClear: () => ref.read(searchQueryProvider.notifier).update(''),
      autofocus: false,
      showClearButton: true,
    );
  }

  Widget _buildFeaturedSection(ThemeData theme) {
    if (featuredArtists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Featured Artists',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: featuredArtists.length,
            itemBuilder: (context, index) {
              final artist = featuredArtists[index];
              return _buildFeaturedArtistCircle(theme, artist);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedArtistCircle(ThemeData theme, GearshArtist artist) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedArtistIdProvider.notifier).selectArtist(artist.id);
        context.go('/artist/${artist.id}');
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            // Full circle avatar - same size as regular artist circles
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      artist.image,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[800],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 36,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Verified badge
                if (artist.isVerified)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _darkBg, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              artist.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              artist.category,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseGenresSection(ThemeData theme, List<String> genres) {
    final categories = mainCategories.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Browse Categories',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = mainCategories[category] ?? theme.primaryColor;
              final count = artistsByMainCategory[category]?.length ?? 0;

              return GestureDetector(
                onTap: () {
                  ref.read(searchQueryProvider.notifier).update(category);
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -8,
                        bottom: -8,
                        child: Icon(
                          _getMainCategoryIcon(category),
                          color: Colors.white.withValues(alpha: 0.15),
                          size: 60,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count artists',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getMainCategoryIcon(String category) {
    switch (category) {
      case 'Music':
        return Icons.music_note;
      case 'Visual Arts':
        return Icons.camera_alt;
      case 'Performance':
        return Icons.theater_comedy;
      case 'Tech & Digital':
        return Icons.code;
      case 'Content Creation':
        return Icons.play_circle;
      case 'Beauty & Fashion':
        return Icons.face_retouching_natural;
      case 'Events & Services':
        return Icons.event;
      default:
        return Icons.category;
    }
  }


  Widget _buildCircularArtistSection(
    ThemeData theme,
    String title,
    List<GearshArtist> artists,
  ) {
    if (artists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return _buildCircularArtistCard(theme, artist);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenreSection(ThemeData theme, String genre, List<GearshArtist> artists) {
    // Get color from main category
    final mainCat = _DiscoverPageState.categoryMapping[genre] ?? 'Music';
    final color = _DiscoverPageState.mainCategories[mainCat] ?? theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  genre,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to category page to show all artists in this genre
                  context.go('/category/${Uri.encodeComponent(genre)}');
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return _buildCircularArtistCard(theme, artist, accentColor: color);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircularArtistCard(ThemeData theme, GearshArtist artist, {Color? accentColor}) {
    final color = accentColor ?? _DiscoverPageState._primaryColor;

    return GestureDetector(
      onTap: () {
        ref.read(selectedArtistIdProvider.notifier).selectArtist(artist.id);
        GoRouter.of(context).go('/artist/${artist.id}');
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            // Full circle avatar
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      artist.image,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[800],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 36,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Availability overlay
                if (!artist.isAvailable)
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.event_busy,
                        color: Colors.white54,
                        size: 22,
                      ),
                    ),
                  ),
                // Verified badge
                if (artist.isVerified)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _darkBg,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              artist.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              artist.category,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  /// Optimized search with ranking and fuzzy matching
  List<GearshArtist> _searchArtists(String query) {
    if (query.isEmpty) return [];

    final filters = ref.watch(searchFiltersProvider);
    final searchTerms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final List<_SearchResult> scoredResults = [];

    for (final artist in gearshArtists) {
      // Apply shared provider filters (quick reject)
      if (filters.minRating > 0 && artist.rating < filters.minRating) continue;
      if (filters.showVerifiedOnly && !artist.isVerified) continue;
      if (artist.bookingFee < filters.priceRange.start || artist.bookingFee > filters.priceRange.end) continue;
      if (filters.categories.isNotEmpty) {
        // match if artist.category or any subcategory is in selected categories
        final matchesCategory = filters.categories.contains(artist.category) ||
            artist.subcategories.any((s) => filters.categories.contains(s));
        if (!matchesCategory) continue;
      }

      int score = 0;
      final nameLower = artist.name.toLowerCase();
      final categoryLower = artist.category.toLowerCase();
      final locationLower = artist.location.toLowerCase();
      final subcategoriesLower = artist.subcategories.map((s) => s.toLowerCase()).toList();
      final mainCategory = (categoryMapping[artist.category] ?? 'Music').toLowerCase();

      for (final term in searchTerms) {
        // Exact name match (highest priority)
        if (nameLower == term) {
          score += 100;
        }
        // Name starts with term
        else if (nameLower.startsWith(term)) {
          score += 80;
        }
        // Name contains term
        else if (nameLower.contains(term)) {
          score += 60;
        }
        // Word in name starts with term
        else if (nameLower.split(' ').any((word) => word.startsWith(term))) {
          score += 50;
        }

        // Main category match (e.g., "Music", "Visual Arts")
        if (mainCategory == term || mainCategory.contains(term)) {
          score += 80;
        }

        // Category exact match
        if (categoryLower == term) {
          score += 70;
        }
        // Category contains term
        else if (categoryLower.contains(term)) {
          score += 40;
        }

        // Subcategory match
        if (subcategoriesLower.any((s) => s == term)) {
          score += 50;
        } else if (subcategoriesLower.any((s) => s.contains(term))) {
          score += 30;
        }

        // Location match
        if (locationLower.contains(term)) {
          score += 20;
        }

        // Fuzzy match for typos (simple character matching)
        if (score == 0 && term.length >= 3) {
          if (_fuzzyMatch(nameLower, term)) {
            score += 25;
          } else if (_fuzzyMatch(categoryLower, term)) {
            score += 15;
          }
        }
      }

      // Boost verified artists slightly
      if (artist.isVerified && score > 0) {
        score += 5;
      }

      // Boost higher rated artists slightly
      if (score > 0) {
        score += (artist.rating * 2).round();
      }

      if (score > 0) {
        scoredResults.add(_SearchResult(artist, score));
      }
    }

    // Sort by score descending
    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    return scoredResults.map((r) => r.artist).toList();
  }

  /// Simple fuzzy matching for typo tolerance
  bool _fuzzyMatch(String text, String term) {
    if (term.length < 3) return false;

    // Check if at least 70% of characters match in sequence
    int matches = 0;
    int termIndex = 0;

    for (int i = 0; i < text.length && termIndex < term.length; i++) {
      if (text[i] == term[termIndex]) {
        matches++;
        termIndex++;
      }
    }

    return matches >= (term.length * 0.7);
  }


  Widget _buildSearchResultCircle(ThemeData theme, GearshArtist artist) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedArtistIdProvider.notifier).selectArtist(artist.id);
        context.go('/artist/${artist.id}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Full circle avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    artist.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[800],
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (artist.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _darkBg,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            artist.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            artist.category,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Helper class for ranked search results
class _SearchResult {
  final GearshArtist artist;
  final int score;

  _SearchResult(this.artist, this.score);
}
