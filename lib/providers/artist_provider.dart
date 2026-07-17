import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/artist.dart';

final artistListProvider = FutureProvider<List<Artist>>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return mockArtists;
});

final artistByIdProvider =
    FutureProvider.family<Artist?, String>((ref, id) async {
  final artists = await ref.watch(artistListProvider.future);
  try {
    return artists.firstWhere((artist) => artist.id == id);
  } catch (e) {
    return null;
  }
});

final mockArtists = [
  Artist(
    id: 'yde',
    name: 'Y.D.E',
    genre: 'Hip Hop',
    bio: 'Emerging hip hop artist from Louis Trichardt bringing a fresh voice to the scene.',
    image: 'assets/images/artists/yde.png',
    category: 'Rapper',
    hoursWorked: 0,
    location: 'Louis Trichardt, SA',
    availability: true,
    skills: ['Rapper', 'Songwriter'],
    isTrending: true,
    portfolioImageUrls: [
      'assets/images/artists/yde.png',
    ],
    reviews: [],
    baseRate: 3000,
  ),
  Artist(
    id: 'zj90',
    name: 'ZJ90',
    genre: 'House · Amapiano',
    bio: 'Johannesburg DJ blending house and amapiano into high-energy sets.',
    image: 'assets/images/artists/ZJ90.jpg',
    category: 'DJ',
    hoursWorked: 120,
    location: 'Johannesburg, SA',
    availability: true,
    skills: ['DJ', 'Live Performance'],
    isTrending: true,
    portfolioImageUrls: [
      'assets/images/artists/ZJ90.jpg',
    ],
    reviews: [],
    baseRate: 3500,
  ),
  Artist(
    id: 'rix-elton',
    name: 'Rix Elton',
    genre: 'Amapiano',
    bio: 'Amapiano DJ out of Johannesburg, built for club floors and private events.',
    image: 'assets/images/artists/rixelton.jpg',
    category: 'DJ',
    hoursWorked: 50,
    location: 'Johannesburg, SA',
    availability: true,
    skills: ['DJ', 'Amapiano'],
    isTrending: false,
    portfolioImageUrls: [
      'assets/images/artists/rixelton.jpg',
    ],
    reviews: [],
    baseRate: 2000,
  ),
  Artist(
    id: 'empress-ngqama',
    name: 'Empress Ngqama',
    genre: 'Afro-Soul',
    bio: 'Afro-soul and reggae vocalist from the Eastern Cape with a commanding live presence.',
    image: 'assets/images/artists/empress-ngqama.jpg',
    category: 'Vocalist',
    hoursWorked: 95,
    location: 'Eastern Cape, SA',
    availability: true,
    skills: ['Vocalist', 'Live Performance'],
    isTrending: false,
    portfolioImageUrls: [
      'assets/images/artists/empress-ngqama.jpg',
    ],
    reviews: [],
    baseRate: 4500,
  ),
  Artist(
    id: 'dripmaker',
    name: 'Dripmaker',
    genre: 'Fashion',
    bio: 'Fashion designer from Thohoyandou crafting standout looks for artists and events.',
    image: 'assets/images/artists/dripmaker.png',
    category: 'Fashion Designer',
    hoursWorked: 180,
    location: 'Thohoyandou, SA',
    availability: true,
    skills: ['Fashion Design', 'Styling'],
    isTrending: false,
    portfolioImageUrls: [
      'assets/images/artists/dripmaker.png',
    ],
    reviews: [],
    baseRate: 3500,
  ),
];
