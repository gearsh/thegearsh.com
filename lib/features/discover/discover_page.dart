import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/providers/artist_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gearsh_app/widgets/custom_app_bar.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistListProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Discover'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discover',
                    style: theme.textTheme.displayMedium,
                  ),
                  IconButton(
                    onPressed: () => context.go('/discover/map'),
                    icon: const Icon(Icons.map_outlined, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SearchBar(),
              const SizedBox(height: 24),
              const _CategoryFilters(),
              const SizedBox(height: 24),
              const _TrendingArtists(),
              const SizedBox(height: 24),
              Text(
                'All Artists',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: artistsAsync.when(
                  data: (artists) {
                    final filteredArtists = artists.where((artist) {
                      final matchesCategory = selectedCategory == 'All' || artist.category == selectedCategory;
                      final matchesSearch = searchQuery.isEmpty ||
                          artist.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          artist.genre.toLowerCase().contains(searchQuery.toLowerCase());
                      return matchesCategory && matchesSearch;
                    }).toList();

                    if (filteredArtists.isEmpty) {
                      return Center(
                        child: Text(
                          'No artists found.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredArtists.length,
                      itemBuilder: (context, index) {
                        final artist = filteredArtists[index];
                        return _ArtistCard(artist: artist);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return TextField(
      onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Find Artists...',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
        prefixIcon: const Icon(Icons.search, color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withAlpha(25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryFilters extends ConsumerWidget {
  const _CategoryFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ['All', 'MC', 'DJ', 'Photographer', 'Producer', 'Videographer'];
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final bool isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(selectedCategoryProvider.notifier).state = category;
                }
              },
              backgroundColor: Colors.white.withAlpha(25),
              selectedColor: theme.primaryColor,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? theme.primaryColor : Colors.white.withAlpha(50),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrendingArtists extends ConsumerWidget {
  const _TrendingArtists();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artistsAsync = ref.watch(artistListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Artists',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        artistsAsync.when(
          data: (artists) {
            final trendingArtists = artists.where((a) => a.isTrending == true).toList();
            if (trendingArtists.isEmpty) {
              return const SizedBox.shrink();
            }
            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trendingArtists.length,
                itemBuilder: (context, index) {
                  final artist = trendingArtists[index];
                  return _TrendingArtistCard(artist: artist);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TrendingArtistCard extends StatelessWidget {
  const _TrendingArtistCard({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.go('/profile/${artist.id}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(artist.profilePictureUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                artist.name,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.go('/profile/${artist.id}'),
      child: Card(
        margin: const EdgeInsets.only(bottom: 24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: artist.profilePictureUrl,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artist.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(artist.category ?? 'N/A'),
                        backgroundColor: Color.fromARGB(
                          (0.2 * 255).round(),
                          ((theme.primaryColor.r * 255.0).round().clamp(0, 255)).toInt(),
                          ((theme.primaryColor.g * 255.0).round().clamp(0, 255)).toInt(),
                          ((theme.primaryColor.b * 255.0).round().clamp(0, 255)).toInt(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (artist.availability == true)
                        Chip(
                          label: const Text('Available'),
                          backgroundColor: Color.fromARGB(
                            (0.2 * 255).round(),
                            ((Colors.green.r * 255.0).round().clamp(0, 255)).toInt(),
                            ((Colors.green.g * 255.0).round().clamp(0, 255)).toInt(),
                            ((Colors.green.b * 255.0).round().clamp(0, 255)).toInt(),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
