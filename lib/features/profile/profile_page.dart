import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/providers/artist_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gearsh_app/widgets/custom_app_bar.dart';
import 'package:gearsh_app/widgets/bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  final String artistId;
  const ProfilePage({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistByIdProvider(artistId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile'),
      body: artistAsync.when(
        data: (artist) {
          if (artist == null) {
            return const Center(child: Text('Artist not found'));
          }
          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: CachedNetworkImageProvider(artist.profilePictureUrl),
                      ),
                      const SizedBox(height: 16),
                      Text(artist.name, style: theme.textTheme.displaySmall),
                      Text(artist.category ?? 'N/A', style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor)),
                      const SizedBox(height: 16),
                      // Themed blue "Book" button matching Gearsh color palette
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/booking/${artist.id}'),
                          icon: const Icon(Icons.book_online),
                          label: const Text('Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    const TabBar(
                      tabs: [
                        Tab(text: 'About'),
                        Tab(text: 'Portfolio'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ],
              body: TabBarView(
                children: [
                  _AboutTab(artist: artist),
                  _PortfolioTab(artist: artist),
                  _ReviewsTab(artist: artist),
                ],
              ),
            ),
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
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _AboutTab extends StatelessWidget {
  final Artist artist;
  const _AboutTab({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(artist.bio, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text('Availability', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                artist.availability == true ? Icons.check_circle : Icons.cancel,
                color: artist.availability == true ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                artist.availability == true ? 'Available for booking' : 'Not currently available',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioTab extends StatelessWidget {
  final Artist artist;
  const _PortfolioTab({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Safely handle nullable portfolioImageUrls by falling back to an empty list
    final images = artist.portfolioImageUrls ?? <String>[];
    if (images.isEmpty) {
      return Center(
        child: Text('No portfolio images yet.', style: theme.textTheme.bodyLarge),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: images[index],
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final Artist artist;
  const _ReviewsTab({required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (artist.reviews.isEmpty) {
      return Center(
        child: Text('No reviews yet.', style: theme.textTheme.bodyLarge),
      );
    }
    return ListView.builder(
      itemCount: artist.reviews.length,
      itemBuilder: (context, index) {
        final review = artist.reviews[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(review.reviewerImageUrl),
                    ),
                    const SizedBox(width: 16),
                    Text(review.reviewerName, style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber,)),
                ),
                const SizedBox(height: 8),
                Text(review.comment, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        );
      },
    );
  }
}
