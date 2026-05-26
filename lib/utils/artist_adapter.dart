import 'package:gearsh_app/data/gearsh_artists.dart';
import 'package:gearsh_app/models/artist.dart';

GearshArtist apiArtistToGearsh(Artist artist) {
  final username = artist.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  return GearshArtist(
    id: artist.id,
    name: artist.name,
    username: username.isEmpty ? artist.id : username,
    category: artist.category ?? artist.genre,
    subcategories: artist.skills ?? const [],
    location: artist.location ?? 'South Africa',
    rating: artist.rating,
    reviewCount: artist.reviewCount,
    hoursBooked: (artist.hoursWorked ?? 0).round(),
    responseTime: 'Usually responds within 1 hour',
    image: artist.image.isNotEmpty
        ? artist.image
        : 'assets/images/artists/default.png',
    isVerified: artist.isVerified ?? false,
    isAvailable: artist.availability ?? true,
    bio: artist.bio,
    bookingFee: (artist.baseRate ?? 2000).round(),
    highlights: const [],
    services: const [],
  );
}

List<GearshArtist> mergeArtists(List<GearshArtist> live, List<GearshArtist> fallback) {
  final seen = <String>{};
  final merged = <GearshArtist>[];
  for (final artist in [...live, ...fallback]) {
    final key = artist.id.toLowerCase();
    if (seen.add(key)) merged.add(artist);
  }
  merged.sort((a, b) => b.hoursBooked.compareTo(a.hoursBooked));
  return merged;
}
