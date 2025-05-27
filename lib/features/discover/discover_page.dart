import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/artist_provider.dart';
import 'package:go_router/go_router.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // 🔥 Header (Logo + Title + Profile Icon)
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
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
                    color: Colors.white),
              ),

              const SizedBox(height: 24),

              // Filter Tabs Placeholder
              const FilterTabs(),

              const SizedBox(height: 24),

              // 🔥 Artists List
              Expanded(
                child: artistsAsync.when(
                  data: (artists) => ListView.builder(
                    itemCount: artists.length,
                    itemBuilder: (context, index) {
                      final artist = artists[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 25,
                            child: ClipOval(
                              child: artist['image'] != null
                                  ? Image.network(
                                      artist['image'][0]['url'],
                                      fit: BoxFit.cover,
                                      width: 50,
                                      height: 50,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            artist['emoji'] ?? '🎧',
                                            style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white),
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Text(
                                        artist['emoji'] ?? '🎧',
                                        style: const TextStyle(
                                            fontSize: 20, color: Colors.white),
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(
                            artist['name'] ?? 'Unknown',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            artist['genre'] ?? 'Unknown Genre',
                            style: const TextStyle(color: Colors.cyanAccent),
                          ),
                          //onTap: () {
                          // final id = artist['id'] ?? '';
                          // context.go('/profile/$id');
                          //  },
                          onTap: () {
                            final id = artist['id'] ?? '';
                            if (id.isNotEmpty) {
                              context.go('/profile/$id');
                            } else {
                              print('Error: Missing artist ID!');
                            }
                          },
                        ),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: Colors.red)),
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
