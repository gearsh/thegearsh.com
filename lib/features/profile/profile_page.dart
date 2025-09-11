//The Gearsh App - Profile Page

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/services/artist_service.dart';
import 'package:gearsh_app/services/badge_service.dart';

final artistByIdProvider =
    FutureProvider.family<Artist, String>((ref, id) async {
  final service = ArtistService(); // Use
  return (await service.fetchArtists()).firstWhere((a) => a.id == id);
});

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
          data: (artist) {
            final badges =
                BadgeService.getBadges((artist.hoursWorked ?? 0).toInt());
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          CachedNetworkImageProvider(artist.profilePictureUrl),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      artist.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      artist.genre,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "${NumberFormat.decimalPattern().format(artist.hoursWorked ?? 0)} Hours Earned",
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00BFFF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: badges.map((badge) {
                        final color = Color(int.parse(
                            badge.colorHex.replaceFirst('#', '0xff')));
                        return Chip(
                          label: Text(
                            "${badge.emoji} ${badge.name}",
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          backgroundColor:
                              color.withAlpha((0.85 * 255).toInt()),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.5 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        artist.bio,
                        style: GoogleFonts.montserrat(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/booking/${artist.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFFF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Book Me Now',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/leaderboard'),
                      child: Text(
                        "See the Leaderboard",
                        style: GoogleFonts.montserrat(
                            color: const Color(0xFF00BFFF)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: GoogleFonts.montserrat(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}
