import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/artist_provider.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  final String artistId;
  const ProfilePage({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistByIdProvider(artistId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: artistAsync.when(
          data: (artist) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Text("Profile", style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              // Image
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.indigo],
                    ),
                  ),
                  child: ClipOval(
                    child: artist['image'] != null
                        ? Image.network(
                            artist['image'][0]['url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  artist['emoji'] ?? '🎧',
                                  style: const TextStyle(
                                      fontSize: 48, color: Colors.white),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              artist['emoji'] ?? '🎧',
                              style: const TextStyle(
                                  fontSize: 48, color: Colors.white),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                artist['name'] ?? 'Unknown',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                artist['genre'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.cyanAccent),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  artist['bio'] ?? 'No description available.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/booking/$artistId');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Request to Book'),
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
