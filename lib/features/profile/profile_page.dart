// lib/features/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  final String artistId;
  const ProfilePage({required this.artistId, super.key});

  @override
  Widget build(BuildContext context) {
    // Mock artist data - replace with real data model later
    final artistName = artistId == 'ava' ? 'Ava Johnson' : 'Ethan Woods';
    final genre = artistId == 'ava' ? 'DJ' : 'Indie';
    final icon = artistId == 'ava' ? '🎧' : '🎸';
    final about = artistId == 'ava'
        ? 'Professional DJ with 5+ years experience in electronic music, house, and techno. Available for clubs, private events, and weddings.'
        : 'Indie singer-songwriter blending folk and pop vibes. Available for live gigs, intimate events, and festivals.';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Text('⚡', style: TextStyle(fontSize: 20)),
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Colors.deepPurple, Colors.indigo]),
                      ),
                      alignment: Alignment.center,
                      child: Text(icon, style: const TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(height: 16),
                    Text(artistName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('● $genre', style: const TextStyle(color: Colors.cyanAccent)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/booking/$artistId'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Request to Book'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(about, style: const TextStyle(color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Calendar (Static)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Performance Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(14, (index) {
                        final date = 15 + index;
                        return Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: date == 21 ? Colors.cyanAccent : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$date',
                            style: TextStyle(
                              color: date == 21 ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
