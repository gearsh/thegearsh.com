// The Gearsh App - lib/pages/discover_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/providers/artist_provider.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistListProvider); // ✅

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.cyanAccent, Colors.blueAccent],
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/gearsh_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Gearsh',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Find Artists',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const FilterTabs(),
              const SizedBox(height: 24),
              Expanded(
                child: artistsAsync.when(
                  data: (artists) => ListView.builder(
                    itemCount: artists.length,
                    itemBuilder: (context, index) {
                      final artist = artists[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.05 * 255).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 25,
                            child: ClipOval(
                              child: artist.profilePictureUrl.isNotEmpty
                                  ? Image.network(
                                      artist.profilePictureUrl,
                                      fit: BoxFit.cover,
                                      width: 50,
                                      height: 50,
                                      errorBuilder: (context, error, stack) {
                                        return const Icon(Icons.person,
                                            color: Colors.white);
                                      },
                                    )
                                  : const Icon(Icons.person,
                                      color: Colors.white),
                            ),
                          ),
                          title: Text(
                            artist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            artist.genre,
                            style: const TextStyle(color: Colors.cyanAccent),
                          ),
                          onTap: () => context.go('/profile/${artist.id}'),
                        ),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
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

class FilterTabs extends StatelessWidget {
  const FilterTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        FilterTab(label: 'Genre', isActive: true),
        FilterTab(label: 'Location'),
        FilterTab(label: 'Availability'),
      ],
    );
  }
}

class FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  const FilterTab({required this.label, this.isActive = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.cyanAccent : Colors.white60,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
