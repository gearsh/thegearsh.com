// lib/features/discover/discover_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/artist_provider.dart'; // Adjust based on your structure
import 'package:go_router/go_router.dart';

import '../../widgets/bottom_nav_bar.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: artistsAsync.when(
          data: (artists) => Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.cyanAccent,
                                    Colors.blueAccent
                                  ],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text('⚡',
                                  style: TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Gearsh',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.white),
                          onPressed: () => context
                              .go('/profile/ava'), // Or dynamic user profile
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Find Artists',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    const FilterTabs(),
                    const SizedBox(height: 24),
                    ...artists.map((artist) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ArtistCard(
                            name: artist['name'] ?? '',
                            genre: artist['genre'] ?? '',
                            icon: artist['emoji'] ??
                                '🎤', // Optional: Airtable emoji field
                            onTap: () {
                              final id = artist['id'] ?? '';
                              context.go('/profile/$id');
                            },
                          ),
                        )),
                  ],
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: BottomNavBar(),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
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

class ArtistCard extends StatelessWidget {
  final String name;
  final String genre;
  final String icon;
  final VoidCallback onTap;

  const ArtistCard({
    required this.name,
    required this.genre,
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [Colors.deepPurple, Colors.indigo]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 48)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(genre, style: const TextStyle(color: Colors.cyanAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
