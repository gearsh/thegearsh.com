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
    id: '1',
    name: 'A-Reece',
    genre: 'Hip Hop',
    bio: 'A lyrical genius with a passion for storytelling through music.',
    image: 'assets/images/artists/a-reece.png',
    category: 'Rapper',
    hoursWorked: 120,
    location: 'Pretoria, SA',
    availability: true,
    skills: ['Rapper', 'Lyricist'],
    isTrending: true,
    portfolioImageUrls: [
      'assets/images/artists/a-reece.png',
      'assets/images/artists/revenge.jpg',
    ],
    reviews: [],
    baseRate: 400,
  ),
  Artist(
    id: '2',
    name: 'Nasty C',
    genre: 'Hip Hop',
    bio: 'A South African rapper known for his versatility and global appeal.',
    image: 'assets/images/artists/nastyc.png',
    category: 'Rapper',
    hoursWorked: 200,
    location: 'Durban, SA',
    availability: true,
    skills: ['Rapper', 'Songwriter'],
    isTrending: true,
    portfolioImageUrls: [
      'assets/images/artists/nastyc.png',
      'assets/images/artists/game.png',
    ],
    reviews: [],
    baseRate: 500,
  ),
  Artist(
    id: '3',
    name: 'Emtee',
    genre: 'Trap',
    bio: 'A pioneer of South African trap music with a unique sound.',
    image: 'assets/images/artists/emtee.png',
    category: 'Rapper',
    hoursWorked: 150,
    location: 'Durban, SA',
    availability: true,
    skills: ['Rapper', 'Songwriter'],
    isTrending: false,
    portfolioImageUrls: [
      'assets/images/artists/emtee.png',
      'assets/images/artists/sony.png',
    ],
    reviews: [],
    baseRate: 350,
  ),
  Artist(
    id: '4',
    name: 'Joyous Celebration',
    genre: 'Gospel Choir',
    bio: 'South African gospel choir known for energetic live performances and harmonies.',
    image: 'assets/images/artists/joyous.png',
    category: 'Choir',
    hoursWorked: 180,
    location: 'South Africa',
    availability: true,
    skills: ['Choir', 'Live Performance'],
    isTrending: false,
    portfolioImageUrls: [
      'assets/images/artists/joyous.png',
      'assets/images/artists/joyous.png',
    ],
    reviews: [],
    baseRate: 600,
  ),
];
