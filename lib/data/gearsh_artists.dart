// Gearsh App - Featured Artists Data
// These are verified artists preloaded into the platform
// Global marketplace - artists from around the world
// 10,000 Hours Mastery System - Gamified artist progression

// Mastery Levels based on hours booked
enum MasteryLevel {
  newcomer,      // 0-99 hours
  rising,        // 100-499 hours
  established,   // 500-1999 hours
  professional,  // 2000-4999 hours
  expert,        // 5000-7499 hours
  master,        // 7500-9999 hours
  legend,        // 10000+ hours
}

class MasteryInfo {
  final MasteryLevel level;
  final String title;
  final String icon;
  final int minHours;
  final int maxHours;
  final double progressToNext;

  const MasteryInfo({
    required this.level,
    required this.title,
    required this.icon,
    required this.minHours,
    required this.maxHours,
    required this.progressToNext,
  });
}

MasteryInfo getMasteryInfo(int hoursBooked) {
  if (hoursBooked >= 10000) {
    return MasteryInfo(
      level: MasteryLevel.legend,
      title: 'Legend',
      icon: 'ðŸ‘‘',
      minHours: 10000,
      maxHours: 10000,
      progressToNext: 1.0,
    );
  } else if (hoursBooked >= 7500) {
    return MasteryInfo(
      level: MasteryLevel.master,
      title: 'Master',
      icon: 'ðŸ†',
      minHours: 7500,
      maxHours: 9999,
      progressToNext: (hoursBooked - 7500) / 2500,
    );
  } else if (hoursBooked >= 5000) {
    return MasteryInfo(
      level: MasteryLevel.expert,
      title: 'Expert',
      icon: 'â­',
      minHours: 5000,
      maxHours: 7499,
      progressToNext: (hoursBooked - 5000) / 2500,
    );
  } else if (hoursBooked >= 2000) {
    return MasteryInfo(
      level: MasteryLevel.professional,
      title: 'Professional',
      icon: 'ðŸ’Ž',
      minHours: 2000,
      maxHours: 4999,
      progressToNext: (hoursBooked - 2000) / 3000,
    );
  } else if (hoursBooked >= 500) {
    return MasteryInfo(
      level: MasteryLevel.established,
      title: 'Established',
      icon: 'ðŸ”¥',
      minHours: 500,
      maxHours: 1999,
      progressToNext: (hoursBooked - 500) / 1500,
    );
  } else if (hoursBooked >= 100) {
    return MasteryInfo(
      level: MasteryLevel.rising,
      title: 'Rising',
      icon: 'ðŸš€',
      minHours: 100,
      maxHours: 499,
      progressToNext: (hoursBooked - 100) / 400,
    );
  } else {
    return MasteryInfo(
      level: MasteryLevel.newcomer,
      title: 'Newcomer',
      icon: 'ðŸŒ±',
      minHours: 0,
      maxHours: 99,
      progressToNext: hoursBooked / 100,
    );
  }
}

// Get hours remaining to reach 10,000 mastery
int getHoursToMastery(int hoursBooked) {
  return (10000 - hoursBooked).clamp(0, 10000);
}

// Get percentage progress to 10,000 hours
double getMasteryProgress(int hoursBooked) {
  return (hoursBooked / 10000).clamp(0.0, 1.0);
}

class GearshArtist {
  final String id;
  final String name;
  final String username;
  final String category;
  final List<String> subcategories;
  final String location;
  final String countryCode; // ISO country code (e.g., 'ZA', 'US', 'NG')
  final String currencyCode; // Currency code (e.g., 'ZAR', 'USD', 'NGN')
  final double rating;
  final int reviewCount;
  final int hoursBooked; // Hours booked - 10,000 hours to mastery!
  final String responseTime;
  final String image;
  final bool isVerified;
  final bool isAvailable;
  final String bio;
  final int bookingFee; // In local currency (discounted price if discount applies)
  final int? originalBookingFee; // Original price before discount
  final int? discountPercent; // Discount percentage (e.g., 80 for 80% off)
  final double? bookingFeeUSD; // Optional USD equivalent for global search
  final List<String> highlights;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> discography;
  final List<Map<String, dynamic>> upcomingGigs;
  final List<Map<String, dynamic>> merch;
  final bool availableWorldwide; // Whether artist accepts international bookings

  const GearshArtist({
    required this.id,
    required this.name,
    required this.username,
    required this.category,
    required this.subcategories,
    required this.location,
    this.countryCode = 'ZA', // Default to South Africa for existing data
    this.currencyCode = 'ZAR',
    required this.rating,
    required this.reviewCount,
    required this.hoursBooked,
    required this.responseTime,
    required this.image,
    required this.isVerified,
    required this.isAvailable,
    required this.bio,
    required this.bookingFee,
    this.originalBookingFee,
    this.discountPercent,
    this.bookingFeeUSD,
    required this.highlights,
    required this.services,
    this.discography = const [],
    this.upcomingGigs = const [],
    this.merch = const [],
    this.availableWorldwide = true, // Most artists available for international bookings
  });

  // Computed properties for mastery system
  MasteryInfo get masteryInfo => getMasteryInfo(hoursBooked);
  int get hoursToMastery => getHoursToMastery(hoursBooked);
  double get masteryProgress => getMasteryProgress(hoursBooked);
  bool get isMaster => hoursBooked >= 10000;

  // Computed properties for discount system
  bool get hasDiscount => discountPercent != null && discountPercent! > 0 && originalBookingFee != null;
  bool get isNewArtist => category == 'Emerging Artist' || hoursBooked < 100;

  // Auto-apply 80% discount for new/emerging artists
  int get displayOriginalPrice => originalBookingFee ?? (isNewArtist && bookingFee > 0 ? (bookingFee * 5).toInt() : bookingFee);
  int get displayDiscountPercent => discountPercent ?? (isNewArtist && bookingFee > 0 ? 80 : 0);
  int get displayPrice => bookingFee;
  bool get showDiscount => hasDiscount || (isNewArtist && bookingFee > 0);
}

// Featured verified artists on Gearsh
const List<GearshArtist> gearshArtists = [
  // FEATURED FIRST: Y.D.E (80% OFF - Emerging Artist)
  GearshArtist(
    id: 'yde',
    name: 'Y.D.E',
    username: '@yde',
    category: 'Emerging Artist',
    subcategories: ['Emerging Artist', 'Rap', 'Hip Hop'],
    location: 'Louis Trichardt, SA',
    rating: 4.0,
    reviewCount: 0,
    hoursBooked: 0,
    responseTime: '< 24 hours',
    image: 'assets/images/artists/yde.png',
    isVerified: true,
    isAvailable: true,
    bio: "Straight out of Louis Trichardt, SA rap artist Y.D.E is known for delivering street-rooted music with a strong commercial edge. Versatile in style and rooted in real-life experiences, his music is driven by purpose, vision and legacy. From hard bars to melodic vibes, Y.D.E reflects real experiences, ambition and growth. His sound is diversely known for movin' the culture, not chasin' it. The work speaks.",
    bookingFee: 2000,
    originalBookingFee: 10000,
    discountPercent: 80,
    bookingFeeUSD: 110.0,
    highlights: [
      '80% OFF - Limited Time',
      'Street-rooted sound',
      'Versatile style',
      'Purpose-driven music',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Live Performance (1 hour)',
        'price': 2000.0,
        'originalPrice': 10000.0,
        'discountPercent': 80,
        'description': 'High-energy live rap performance with original music.',
        'duration': '1 hour',
        'includes': ['Live performance', 'Original songs', 'Crowd interaction'],
      },
      {
        'id': 's2',
        'name': 'Event Appearance (2 hours)',
        'price': 3500.0,
        'originalPrice': 17500.0,
        'discountPercent': 80,
        'description': 'Full event appearance with performance and meet & greet.',
        'duration': '2 hours',
        'includes': ['Live performance', 'Meet & greet', 'Photo ops', 'Social media shoutout'],
      },
      {
        'id': 's3',
        'name': 'Studio Collaboration',
        'price': 1500.0,
        'originalPrice': 7500.0,
        'discountPercent': 80,
        'description': 'Feature verse or full collaboration on your track.',
        'duration': 'Flexible',
        'includes': ['Vocal feature', 'Songwriting', 'Recording session'],
      },
    ],
    discography: [
      {
        'title': 'First Steps',
        'type': 'EP',
        'year': '2025',
        'tracks': 4,
        'image': 'assets/images/artists/yde.png',
      },
      {
        'title': 'Dreams',
        'type': 'Single',
        'year': '2025',
        'tracks': 1,
        'image': 'assets/images/artists/yde.png',
      },
    ],
  ),
  // FEATURED: Rix Elton
  GearshArtist(
    id: 'rix-elton',
    name: 'Rix Elton',
    username: '@rixelton',
    category: 'Amapiano',
    subcategories: ['Amapiano', 'DJ', 'Producer'],
    location: 'Johannesburg, SA',
    rating: 4.3,
    reviewCount: 120,
    hoursBooked: 50,
    responseTime: '< 24 hours',
    image: 'assets/images/artists/rixelton.jpg',
    isVerified: true,
    isAvailable: true,
    bio: 'A rising Amapiano DJ and producer known for deep log drum grooves and crowd-moving sets. Available for clubs, festivals and private events.',
    bookingFee: 20000,
    bookingFeeUSD: 1100.0,
    highlights: [
      'Rising Amapiano talent',
      'Club & festival DJ',
      'Signature log-drums',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Club Set (2 hours)',
        'price': 20000.0,
        'description': 'High-energy Amapiano DJ set tailored for clubs.',
        'duration': '2 hours',
        'includes': ['DJ performance', 'Custom playlist', 'Crowd interaction'],
      },
      {
        'id': 's2',
        'name': 'Festival Slot (1 hour)',
        'price': 35000.0,
        'description': 'Packed festival set with full production support.',
        'duration': '1 hour',
        'includes': ['Festival performance', 'MC support', 'Back-to-back options'],
      },
    ],
  ),
  // FEATURED: ZJ90
  GearshArtist(
    id: 'zj90',
    name: 'ZJ90',
    username: '@zj90',
    category: 'DJ',
    subcategories: ['DJ', 'House', 'Amapiano'],
    location: 'Johannesburg, SA',
    rating: 4.5,
    reviewCount: 200,
    hoursBooked: 120,
    responseTime: '< 12 hours',
    image: 'assets/images/artists/ZJ90.jpg',
    isVerified: true,
    isAvailable: true,
    bio: 'Dynamic female DJ known for electrifying sets that blend house, amapiano and afrobeats. A crowd favourite at clubs and festivals across South Africa.',
    bookingFee: 25000,
    bookingFeeUSD: 1400.0,
    highlights: [
      'Electrifying DJ sets',
      'House & Amapiano specialist',
      'Festival performer',
      'Female DJ icon',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Club Set (2 hours)',
        'price': 25000.0,
        'description': 'High-energy DJ set blending house and amapiano.',
        'duration': '2 hours',
        'includes': ['DJ performance', 'Custom playlist', 'Crowd interaction'],
      },
      {
        'id': 's2',
        'name': 'Festival Performance',
        'price': 40000.0,
        'description': 'Premium festival set with full production.',
        'duration': '1.5 hours',
        'includes': ['Festival performance', 'Full production', 'Meet & greet'],
      },
      {
        'id': 's3',
        'name': 'Private Event',
        'price': 35000.0,
        'description': 'Exclusive private event DJ set.',
        'duration': '3 hours',
        'includes': ['DJ performance', 'Custom setlist', 'Photo ops'],
      },
    ],
    discography: [
      {
        'title': 'Queen of the Decks',
        'type': 'Album',
        'year': '2024',
        'tracks': 12,
        'image': 'assets/images/artists/ZJ90.jpg',
      },
      {
        'title': 'House Fusion Mix',
        'type': 'EP',
        'year': '2024',
        'tracks': 5,
        'image': 'assets/images/artists/ZJ90.jpg',
      },
      {
        'title': 'Afrobeats Fire',
        'type': 'Single',
        'year': '2023',
        'tracks': 1,
        'image': 'assets/images/artists/ZJ90.jpg',
      },
      {
        'title': 'Dancefloor Anthem',
        'type': 'Single',
        'year': '2023',
        'tracks': 1,
        'image': 'assets/images/artists/ZJ90.jpg',
      },
    ],
  ),
  // FEATURED: Empress Ngqama
  GearshArtist(
    id: 'empress-ngqama',
    name: 'Empress Ngqama',
    username: '@empressngqama',
    category: 'Afro-Soul',
    subcategories: ['Afro-Soul', 'Reggae', 'Soul'],
    location: 'Eastern Cape, SA',
    rating: 4.6,
    reviewCount: 180,
    hoursBooked: 95,
    responseTime: '< 24 hours',
    image: 'assets/images/artists/empress-ngqama.jpg',
    isVerified: true,
    isAvailable: true,
    bio: 'A soulful songstress blending Afro-soul with reggae influences. Her powerful vocals and uplifting lyrics create a unique sound that touches hearts and moves crowds.',
    bookingFee: 22000,
    bookingFeeUSD: 1200.0,
    highlights: [
      'Soulful vocalist',
      'Reggae-infused sound',
      'Uplifting performances',
      'Cultural storyteller',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Live Performance (1 hour)',
        'price': 22000.0,
        'description': 'Soulful live performance with full band.',
        'duration': '1 hour',
        'includes': ['Live performance', 'Original songs', 'Crowd interaction'],
      },
      {
        'id': 's2',
        'name': 'Festival Set',
        'price': 35000.0,
        'description': 'Premium festival performance with full production.',
        'duration': '1.5 hours',
        'includes': ['Live performance', 'Full band', 'Meet & greet'],
      },
      {
        'id': 's3',
        'name': 'Private Event',
        'price': 30000.0,
        'description': 'Intimate private event with acoustic or full band option.',
        'duration': '2 hours',
        'includes': ['Live performance', 'Custom setlist', 'Photo session'],
      },
    ],
    discography: [
      {
        'title': 'Soul Rising',
        'type': 'Album',
        'year': '2024',
        'tracks': 11,
        'image': 'assets/images/artists/empress-ngqama.jpg',
      },
      {
        'title': 'Reggae Roots',
        'type': 'EP',
        'year': '2023',
        'tracks': 5,
        'image': 'assets/images/artists/empress-ngqama.jpg',
      },
      {
        'title': 'Ubuntu',
        'type': 'Single',
        'year': '2024',
        'tracks': 1,
        'image': 'assets/images/artists/empress-ngqama.jpg',
      },
      {
        'title': 'African Queen',
        'type': 'Single',
        'year': '2023',
        'tracks': 1,
        'image': 'assets/images/artists/empress-ngqama.jpg',
      },
    ],
  ),
  // FEATURED: Dripmaker
  GearshArtist(
    id: 'dripmaker',
    name: 'Dripmaker',
    username: '@dripmaker',
    category: 'Fashion Designer',
    subcategories: ['Fashion Designer', 'Stylist', 'Clothing'],
    location: 'Thohoyandou, SA',
    rating: 4.5,
    reviewCount: 250,
    hoursBooked: 180,
    responseTime: '< 12 hours',
    image: 'assets/images/artists/dripmaker.png',
    isVerified: true,
    isAvailable: true,
    bio: 'Creative fashion designer crafting unique streetwear and custom pieces. Known for bold designs that make a statement. Clothing available for purchase starting from R300.',
    bookingFee: 300,
    bookingFeeUSD: 17.0,
    highlights: [
      'Custom streetwear',
      'Bold designs',
      'Affordable fashion',
      'Made-to-order pieces',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Custom T-Shirt',
        'price': 300.0,
        'description': 'Custom designed t-shirt with your choice of graphics.',
        'duration': '3-5 days',
        'includes': ['Custom design', 'Quality fabric', 'Delivery'],
      },
      {
        'id': 's2',
        'name': 'Custom Hoodie',
        'price': 550.0,
        'description': 'Premium custom hoodie with unique Dripmaker design.',
        'duration': '5-7 days',
        'includes': ['Custom design', 'Premium fabric', 'Embroidery option'],
      },
      {
        'id': 's3',
        'name': 'Full Outfit Design',
        'price': 1500.0,
        'description': 'Complete custom outfit design and creation.',
        'duration': '2-3 weeks',
        'includes': ['Consultation', 'Design', 'Multiple pieces', 'Fitting'],
      },
      {
        'id': 's4',
        'name': 'Styling Session',
        'price': 800.0,
        'description': 'Personal styling consultation and wardrobe advice.',
        'duration': '2 hours',
        'includes': ['Style assessment', 'Outfit recommendations', 'Shopping list'],
      },
    ],
    discography: [
      {
        'title': 'Summer Drip 2025',
        'type': 'Collection',
        'year': '2025',
        'pieces': 12,
        'image': 'assets/images/artists/dripmaker.png',
        'description': 'Bold summer streetwear collection featuring vibrant colors and comfortable fits.',
      },
      {
        'title': 'Winter Essentials',
        'type': 'Collection',
        'year': '2024',
        'pieces': 8,
        'image': 'assets/images/artists/dripmaker.png',
        'description': 'Cozy hoodies and layered looks for the cold season.',
      },
      {
        'title': 'Street Culture Tee',
        'type': 'Design',
        'year': '2025',
        'image': 'assets/images/artists/dripmaker.png',
        'description': 'Signature graphic tee with street art-inspired design.',
      },
      {
        'title': 'Drip Logo Hoodie',
        'type': 'Design',
        'year': '2024',
        'image': 'assets/images/artists/dripmaker.png',
        'description': 'Premium hoodie with embroidered Dripmaker logo.',
      },
      {
        'title': 'Festival Fit',
        'type': 'Design',
        'year': '2024',
        'image': 'assets/images/artists/dripmaker.png',
        'description': 'Limited edition festival outfit - shorts and matching top.',
      },
      {
        'title': 'VIP Custom Order',
        'type': 'Commission',
        'year': '2024',
        'image': 'assets/images/artists/dripmaker.png',
        'description': 'Custom tracksuit created for a celebrity client.',
      },
    ],
  ),
];

// Helper: get an artist by id
GearshArtist? getArtistById(String id) {
  try {
    return gearshArtists.firstWhere((a) => a.id == id);
  } catch (e) {
    return null;
  }
}

// Helper: sorted list of artists (by name)
List<GearshArtist> getSortedArtists() {
  final sorted = List<GearshArtist>.from(gearshArtists);
  sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return sorted;
}

// Helper: all available artists
List<GearshArtist> getAvailableArtists() {
  final available = gearshArtists.where((a) => a.isAvailable).toList();
  available.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return available;
}

// Helper: get artists by category or subcategory (case-insensitive)
List<GearshArtist> getArtistsByCategory(String category) {
  if (category == 'All') return List<GearshArtist>.from(gearshArtists);
  final filtered = gearshArtists.where((a) =>
    a.category.toLowerCase() == category.toLowerCase() ||
    a.subcategories.any((s) => s.toLowerCase() == category.toLowerCase())
  ).toList();
  filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return filtered;
}

// Helper: get a deduplicated list of artists (removes duplicates by ID)
List<GearshArtist> uniqueArtists([List<GearshArtist>? artists]) {
  final source = artists ?? gearshArtists;
  final seen = <String>{};
  final unique = <GearshArtist>[];
  for (final artist in source) {
    if (!seen.contains(artist.id)) {
      seen.add(artist.id);
      unique.add(artist);
    }
  }
  return unique;
}

// Helper: get unique featured artists (high rating, verified)
List<GearshArtist> getUniqueFeaturedArtists({int limit = 10}) {
  final featured = uniqueArtists()
      .where((a) => a.isVerified && a.rating >= 4.4)
      .take(limit)
      .toList();
  return featured;
}

// Helper: get unique trending artists
List<GearshArtist> getUniqueTrendingArtists({int limit = 15}) {
  final trending = uniqueArtists()
      .where((a) => a.isAvailable && a.rating >= 4.0)
      .take(limit)
      .toList();
  return trending;
}

// Helper: get unique new additions (last items in list)
List<GearshArtist> getUniqueNewArtists({int limit = 10}) {
  return uniqueArtists().reversed.take(limit).toList();
}
