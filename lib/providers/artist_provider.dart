import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/artist.dart';
import 'package:gearsh_app/models/review.dart';
import 'package:collection/collection.dart';

final artistListProvider = FutureProvider<List<Artist>>((ref) async {
  await Future.delayed(const Duration(seconds: 1)); 
  return mockArtists;
});

final artistByIdProvider =
    FutureProvider.family<Artist?, String>((ref, id) async {
  final artists = await ref.watch(artistListProvider.future);
  return artists.firstWhereOrNull((artist) => artist.id == id);
});

final mockArtists = [
  Artist(
    id: '1',
    name: 'DJ Khalid',
    genre: 'Hip Hop',
    bio: 'A lyrical genius from the heart of the city, known for his energetic beats and electrifying performances.',
    image: 'https://i.scdn.co/image/ab6761610000e5eb190882a576a80537442f6805',
    category: 'DJ',
    hoursWorked: 120,
    location: 'New York, NY',
    availability: true,
    skills: ['DJ', 'Producer'],
    isTrending: true,
    portfolioImageUrls: [
      'https://i.scdn.co/image/ab6761610000e5eb190882a576a80537442f6805',
      'https://media.npr.org/assets/img/2016/07/28/dj-khaled-story_custom-81d3345711b156795a28a2b8e6144e1837699a16-s1100-c50.jpg',
      'https://www.rollingstone.com/wp-content/uploads/2018/06/rs-211989-dj-khaled.jpg?w=1581&h=1054&crop=1',
    ],
    reviews: [
      Review(reviewerName: 'John Doe', reviewerImageUrl: 'https://randomuser.me/api/portraits/men/1.jpg', rating: 5, comment: 'Absolutely amazing! DJ Khalid brought the house down.'),
      Review(reviewerName: 'Jane Smith', reviewerImageUrl: 'https://randomuser.me/api/portraits/women/1.jpg', rating: 4, comment: 'Great energy and a fantastic set. Would book again.'),
    ],
    baseRate: 500,
  ),
  Artist(
    id: '2',
    name: 'Cardi B',
    genre: 'Rap',
    bio: 'The queen of rap, known for her energetic performances, witty lyrics, and chart-topping hits.',
    image: 'https://i.scdn.co/image/ab6761610000e5eb8c3f2b5a6c0b3b3e8c1f3a24',
    category: 'MC',
    hoursWorked: 250,
    location: 'Los Angeles, CA',
    availability: false,
    skills: ['Rapper', 'Writer'],
    isTrending: true,
    portfolioImageUrls: [
       'https://i.scdn.co/image/ab6761610000e5eb8c3f2b5a6c0b3b3e8c1f3a24',
       'https://www.billboard.com/wp-content/uploads/2022/07/Cardi-B-press-photo-2022-billboard-1548.jpg',
       'https://media.glamour.com/photos/61b0f4922113a28114f6d193/master/w_2560%2Cc_limit/1356061294.jpg',
    ],
    reviews: [
      Review(reviewerName: 'Peter Jones', reviewerImageUrl: 'https://randomuser.me/api/portraits/men/2.jpg', rating: 5, comment: 'Cardi B was incredible! Best performance I have ever seen.'),
    ],
    baseRate: 1000,
  ),
  Artist(
    id: '3',
    name: 'Annie Leibovitz',
    genre: 'N/A',
    bio: 'Capturing moments that last a lifetime, Annie is a world-renowned photographer with an eye for detail.',
    image: 'https://media.vanityfair.com/photos/54caf535033a595066606623/master/w_2560%2Cc_limit/annie-leibovitz-author-photo.jpg',
    category: 'Photographer',
    hoursWorked: 500,
    location: 'San Francisco, CA',
    availability: true,
    skills: ['Photographer', 'Director'],
    isTrending: false,
    portfolioImageUrls: [
       'https://media.vanityfair.com/photos/54caf535033a595066606623/master/w_2560%2Cc_limit/annie-leibovitz-author-photo.jpg',
    ],
    baseRate: 800,
  ),
   Artist(
      id: '4',
      name: 'Dr. Dre',
      genre: 'Hip Hop',
      bio: 'Legendary producer and hip hop artist, Dr. Dre has shaped the sound of West Coast rap for decades.',
      image: 'https://i.scdn.co/image/ab6761610000e5eb13a53c65e38153a1d4a864e3',
      category: 'Producer',
      hoursWorked: 1000,
      location: 'Compton, CA',
      availability: true,
      skills: ['Producer', 'Engineer'],
      isTrending: false,
      baseRate: 1200,
    ),
    Artist(
      id: '5',
      name: 'Hype Williams',
      genre: 'N/A',
      bio: 'Iconic music video director, known for his visually stunning and innovative work.',
      image: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Hype_Williams_2009.jpg/1200px-Hype_Williams_2009.jpg',
      category: 'Videographer',
      hoursWorked: 800,
      location: 'New York, NY',
      availability: false,
      skills: ['Videographer', 'Director'],
      isTrending: true,
      baseRate: 1500,
    ),
];
