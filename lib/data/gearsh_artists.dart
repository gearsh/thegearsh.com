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
  final String? coverImage; // Profile cover/banner image
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
    this.coverImage, // Optional cover image
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

  // Get cover image with fallback to gradient
  String? get displayCoverImage => coverImage;
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

  // G.I.Y - Mural Artist from Polokwane
  GearshArtist(
    id: 'giy',
    name: 'G.I.Y',
    username: '@giy',
    category: 'Visual Artist',
    subcategories: ['Mural Artist', 'Street Art', 'Public Art', 'Painter'],
    location: 'Polokwane, SA',
    countryCode: 'ZA',
    currencyCode: 'ZAR',
    rating: 4.8,
    reviewCount: 24,
    hoursBooked: 856,
    responseTime: '< 24 hours',
    image: 'assets/images/artists/giy.png',
    isVerified: true,
    isAvailable: true,
    bio: 'Professional mural artist based in Polokwane, specializing in large-scale public art and community murals. Currently working with the municipality on various beautification projects. Transforming walls into stories, one mural at a time.',
    bookingFee: 2500,
    bookingFeeUSD: 135.0,
    highlights: [
      'Municipality Contract Artist',
      'Public Art Specialist',
      '50+ Murals Completed',
      'Community Art Projects',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Small Mural',
        'price': 2500.0,
        'description': 'Wall mural up to 3m x 3m. Perfect for homes and small businesses.',
        'duration': '2-3 days',
        'includes': ['Design consultation', 'All materials', 'Weather-resistant paint'],
      },
      {
        'id': 's2',
        'name': 'Medium Mural',
        'price': 6000.0,
        'description': 'Wall mural up to 6m x 4m. Ideal for storefronts and office spaces.',
        'duration': '4-6 days',
        'includes': ['Custom design', 'Premium materials', 'UV protection coating'],
      },
      {
        'id': 's3',
        'name': 'Large Public Mural',
        'price': 15000.0,
        'description': 'Large-scale mural for public spaces, buildings, and community projects.',
        'duration': '1-2 weeks',
        'includes': ['Full design process', 'Scaffolding', 'All materials', '5-year warranty'],
      },
      {
        'id': 's4',
        'name': 'Corporate Branding Mural',
        'price': 8000.0,
        'description': 'Custom branded mural for offices and corporate spaces.',
        'duration': '3-5 days',
        'includes': ['Brand integration', 'Color matching', 'Indoor/Outdoor options'],
      },
    ],
    discography: [
      {
        'title': 'Polokwane Heritage Wall',
        'type': 'Public Mural',
        'year': '2025',
        'image': 'assets/images/artists/giy.png',
        'description': 'Large-scale mural celebrating Polokwane history and culture.',
      },
      {
        'title': 'Youth Center Project',
        'type': 'Community Art',
        'year': '2024',
        'image': 'assets/images/artists/giy.png',
        'description': 'Collaborative mural project with local youth at community center.',
      },
      {
        'title': 'Municipal Building Art',
        'type': 'Government Commission',
        'year': '2024',
        'image': 'assets/images/artists/giy.png',
        'description': 'Official artwork for Polokwane municipal building entrance.',
      },
    ],
    upcomingGigs: [
      {
        'title': 'Library Mural Project',
        'date': '2026-02-15',
        'venue': 'Polokwane Public Library',
        'type': 'Commission',
      },
    ],
  ),

  // DJ Una - Louis Trichardt (Huge Discount!)
  GearshArtist(
    id: 'una',
    name: 'Una',
    username: '@una',
    category: 'DJ',
    subcategories: ['DJ', 'Hip Hop', 'Amapiano', 'House', 'Soul', 'Rock'],
    location: 'Louis Trichardt, SA',
    countryCode: 'ZA',
    currencyCode: 'ZAR',
    rating: 4.7,
    reviewCount: 38,
    hoursBooked: 420,
    responseTime: '< 2 hours',
    image: 'assets/images/artists/una.png',
    isVerified: true,
    isAvailable: true,
    bio: 'Versatile DJ based in Louis Trichardt, spinning everything from Hip Hop to Amapiano, House to Soul, and even Rock. Known for reading the crowd and keeping the energy high all night. Currently offering huge discounts for bookings - catch the vibe at an unbeatable price!',
    bookingFee: 3500,
    originalBookingFee: 12000,
    discountPercent: 70,
    bookingFeeUSD: 190.0,
    highlights: [
      '70% OFF - Huge Discount!',
      'All Genres Master',
      'Crowd Favorite',
      'Quick Response',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Club Night (4 hours)',
        'price': 3500.0,
        'originalPrice': 12000.0,
        'discountPercent': 70,
        'description': 'Full DJ set for club nights - all genres covered.',
        'duration': '4 hours',
        'includes': ['Full DJ set', 'All genres', 'Professional equipment', 'Light show coordination'],
      },
      {
        'id': 's2',
        'name': 'Private Party (3 hours)',
        'price': 3000.0,
        'originalPrice': 10000.0,
        'discountPercent': 70,
        'description': 'Intimate party vibes with personalized playlist.',
        'duration': '3 hours',
        'includes': ['Custom playlist', 'Professional sound', 'MC services available'],
      },
      {
        'id': 's3',
        'name': 'Wedding DJ Package',
        'price': 5000.0,
        'originalPrice': 15000.0,
        'discountPercent': 67,
        'description': 'Complete wedding entertainment from ceremony to reception.',
        'duration': '6 hours',
        'includes': ['Ceremony music', 'Reception DJ', 'First dance', 'All equipment'],
      },
      {
        'id': 's4',
        'name': 'Corporate Event',
        'price': 4500.0,
        'originalPrice': 14000.0,
        'discountPercent': 68,
        'description': 'Professional DJ services for corporate functions.',
        'duration': '4 hours',
        'includes': ['Background music', 'Announcements', 'Professional attire', 'Setup included'],
      },
    ],
    discography: [
      {
        'title': 'Limpopo Vibes Mix',
        'type': 'Mix',
        'year': '2025',
        'image': 'assets/images/artists/una.png',
        'description': 'A fusion of Amapiano and House celebrating Limpopo.',
      },
      {
        'title': 'Soul Sessions Vol. 1',
        'type': 'Mix',
        'year': '2024',
        'image': 'assets/images/artists/una.png',
        'description': 'Deep soul and R&B mix for the smooth listeners.',
      },
      {
        'title': 'Rock The Party',
        'type': 'Mix',
        'year': '2024',
        'image': 'assets/images/artists/una.png',
        'description': 'High-energy rock and hip hop crossover mix.',
      },
    ],
    upcomingGigs: [
      {
        'title': 'Friday Night Live',
        'date': '2026-01-31',
        'venue': 'Club 101, Louis Trichardt',
        'type': 'Residency',
      },
      {
        'title': 'Valentine\'s Special',
        'date': '2026-02-14',
        'venue': 'Private Venue',
        'type': 'Private Event',
      },
    ],
  ),

  // Ghxst - Fashion Designer from Njhakanjhaka, Limpopo / Based in Mayfair, JHB
  GearshArtist(
    id: 'ghxst',
    name: 'Ghxst',
    username: '@ghxst',
    category: 'Designer',
    subcategories: ['Fashion Designer', 'Streetwear', 'Stylist', 'Designer'],
    location: 'Mayfair, Johannesburg',
    countryCode: 'ZA',
    currencyCode: 'ZAR',
    rating: 4.9,
    reviewCount: 67,
    hoursBooked: 1240,
    responseTime: '< 6 hours',
    image: 'assets/images/artists/ghxst.png',
    isVerified: true,
    isAvailable: true,
    bio: 'Born in Njhakanjhaka, Limpopo and now based in Mayfair, Johannesburg. Ghxst is a street style fashion designer inspired by the legendary Nipsey Hussle and the LA street culture. Creating bold, authentic streetwear that tells a story of hustle, heritage, and hope. Every piece is a statement.',
    bookingFee: 1500,
    bookingFeeUSD: 82.0,
    highlights: [
      'Nipsey Hussle Inspired',
      'Street Culture Authentic',
      'Limpopo to Joburg Story',
      'Custom Streetwear',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Custom T-Shirt Design',
        'price': 450.0,
        'description': 'Unique streetwear t-shirt with custom graphics and messaging.',
        'duration': '3-5 days',
        'includes': ['Custom design', 'Premium cotton', 'Screen printing', 'One revision'],
      },
      {
        'id': 's2',
        'name': 'Custom Hoodie',
        'price': 850.0,
        'description': 'Premium street style hoodie with embroidery or print.',
        'duration': '5-7 days',
        'includes': ['Custom design', 'Premium fabric', 'Embroidery option', 'Unique sizing'],
      },
      {
        'id': 's3',
        'name': 'Full Outfit Design',
        'price': 2500.0,
        'description': 'Complete custom streetwear outfit - top, bottom, accessories.',
        'duration': '2-3 weeks',
        'includes': ['Consultation', 'Full design', 'Multiple pieces', 'Fitting session'],
      },
      {
        'id': 's4',
        'name': 'Brand Collection Design',
        'price': 8000.0,
        'description': 'Design a mini streetwear collection for your brand (5-8 pieces).',
        'duration': '4-6 weeks',
        'includes': ['Concept development', 'Design sketches', 'Sample production', 'Brand consultation'],
      },
      {
        'id': 's5',
        'name': 'Personal Styling Session',
        'price': 1500.0,
        'description': 'One-on-one styling consultation with wardrobe recommendations.',
        'duration': '2 hours',
        'includes': ['Style assessment', 'Outfit recommendations', 'Shopping guide', 'Streetwear tips'],
      },
    ],
    discography: [
      {
        'title': 'Marathon Collection',
        'type': 'Collection',
        'year': '2025',
        'image': 'assets/images/artists/ghxst.png',
        'description': 'Tribute collection inspired by Nipsey Hussle\'s Marathon spirit.',
      },
      {
        'title': 'Njhakanjhaka Roots',
        'type': 'Collection',
        'year': '2024',
        'image': 'assets/images/artists/ghxst.png',
        'description': 'Streetwear celebrating Limpopo heritage and culture.',
      },
      {
        'title': 'Mayfair Nights',
        'type': 'Collection',
        'year': '2024',
        'image': 'assets/images/artists/ghxst.png',
        'description': 'Urban night-inspired pieces for the Joburg streets.',
      },
      {
        'title': 'Victory Lap Hoodie',
        'type': 'Design',
        'year': '2025',
        'image': 'assets/images/artists/ghxst.png',
        'description': 'Signature hoodie with embroidered marathon motifs.',
      },
    ],
    upcomingGigs: [
      {
        'title': 'Pop-Up Shop',
        'date': '2026-02-08',
        'venue': 'Braamfontein, Johannesburg',
        'type': 'Pop-Up',
      },
      {
        'title': 'SA Fashion Week',
        'date': '2026-04-15',
        'venue': 'Sandton Convention Centre',
        'type': 'Showcase',
      },
    ],
  ),

  // DRT - Tsonga Rapper from Nkuzana Village
  GearshArtist(
    id: 'drt',
    name: 'DRT',
    username: '@drt',
    category: 'Rapper',
    subcategories: ['Rapper', 'Tsonga Rap', 'Xigaza', 'Hip Hop', 'Afro'],
    location: 'Nkuzana Village, Limpopo',
    countryCode: 'ZA',
    currencyCode: 'ZAR',
    rating: 4.6,
    reviewCount: 29,
    hoursBooked: 185,
    responseTime: '< 12 hours',
    image: 'assets/images/artists/drt.png',
    isVerified: true,
    isAvailable: true,
    bio: 'Tsonga rapper straight from Nkuzana Village, Limpopo. Known for authentic Xigaza music that celebrates Tsonga culture and language. Collaborated with producer Dr. Vanz on multiple tracks. Bringing the village sound to the world stage.',
    bookingFee: 1500,
    bookingFeeUSD: 82.0,
    highlights: [
      'Authentic Tsonga Sound',
      'Xigaza Music Pioneer',
      'Dr. Vanz Collaborations',
      'Cultural Ambassador',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Live Performance (1 hour)',
        'price': 1500.0,
        'description': 'High-energy Tsonga rap performance with original music.',
        'duration': '1 hour',
        'includes': ['Live performance', 'Original songs', 'Crowd interaction', 'Tsonga vibes'],
      },
      {
        'id': 's2',
        'name': 'Event Performance (2 hours)',
        'price': 2800.0,
        'description': 'Extended set for events, festivals, and cultural celebrations.',
        'duration': '2 hours',
        'includes': ['Full performance', 'Meet & greet', 'Photo ops', 'Xigaza experience'],
      },
      {
        'id': 's3',
        'name': 'Feature Verse',
        'price': 1200.0,
        'description': 'Tsonga rap verse for your track - add authentic flavor.',
        'duration': 'Flexible',
        'includes': ['Written verse', 'Studio recording', 'One revision'],
      },
      {
        'id': 's4',
        'name': 'Studio Session (Full Day)',
        'price': 3500.0,
        'description': 'Full day studio session for collaboration or recording.',
        'duration': '8 hours',
        'includes': ['Writing session', 'Recording', 'Basic mixing', 'Creative direction'],
      },
    ],
    discography: [
      {
        'title': 'Nkuzana Anthem',
        'type': 'Single',
        'year': '2025',
        'image': 'assets/images/artists/drt.png',
        'description': 'Tribute to the village that raised him - pure Xigaza vibes.',
      },
      {
        'title': 'Xigaza Wave (feat. Dr. Vanz)',
        'type': 'Single',
        'year': '2024',
        'image': 'assets/images/artists/drt.png',
        'description': 'Collaboration with producer Dr. Vanz - Tsonga meets modern beats.',
      },
      {
        'title': 'Village Stories',
        'type': 'EP',
        'year': '2024',
        'image': 'assets/images/artists/drt.png',
        'description': '5-track EP telling stories of village life through Tsonga rap.',
      },
      {
        'title': 'Mbila (feat. Dr. Vanz)',
        'type': 'Single',
        'year': '2025',
        'image': 'assets/images/artists/drt.png',
        'description': 'Xigaza anthem produced by Dr. Vanz - celebrating Tsonga heritage.',
      },
      {
        'title': 'Rihlampfu (prod. Dr. Vanz)',
        'type': 'Single',
        'year': '2024',
        'image': 'assets/images/artists/drt.png',
        'description': 'Hard-hitting track produced by Dr. Vanz.',
      },
    ],
    upcomingGigs: [
      {
        'title': 'Limpopo Cultural Festival',
        'date': '2026-03-21',
        'venue': 'Giyani Stadium',
        'type': 'Festival',
      },
      {
        'title': 'Village Vibes Tour',
        'date': '2026-04-05',
        'venue': 'Multiple Venues, Limpopo',
        'type': 'Tour',
      },
    ],
  ),

  // Hot Pepper - Rapper from Chavani Village
  GearshArtist(
    id: 'hotpepper',
    name: 'Hot Pepper',
    username: '@hotpepper',
    category: 'Rapper',
    subcategories: ['Rapper', 'Hip Hop', 'Travel Rap', 'Afro'],
    location: 'Chavani Village, Limpopo',
    countryCode: 'ZA',
    currencyCode: 'ZAR',
    rating: 4.5,
    reviewCount: 22,
    hoursBooked: 145,
    responseTime: '< 24 hours',
    image: 'assets/images/artists/hotpepper.png',
    isVerified: true,
    isAvailable: true,
    bio: 'Rapper from Chavani Village with a global perspective. Hot Pepper brings heat from the village to the world stage. Traveled to Vietnam, Mozambique, and beyond - every trip inspires new music. Spitting bars with international flavor while staying true to his roots.',
    bookingFee: 1800,
    bookingFeeUSD: 98.0,
    highlights: [
      'World Traveler',
      'Vietnam & Mozambique',
      'Chavani Village Rep',
      'International Sound',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Live Performance (1 hour)',
        'price': 1800.0,
        'description': 'High-energy rap performance with travel-inspired music.',
        'duration': '1 hour',
        'includes': ['Live performance', 'Original songs', 'Crowd interaction'],
      },
      {
        'id': 's2',
        'name': 'Event Performance (2 hours)',
        'price': 3200.0,
        'description': 'Extended set for events and festivals.',
        'duration': '2 hours',
        'includes': ['Full performance', 'Meet & greet', 'Photo ops'],
      },
      {
        'id': 's3',
        'name': 'Feature Verse',
        'price': 1500.0,
        'description': 'Fire verse for your track - international flavor guaranteed.',
        'duration': 'Flexible',
        'includes': ['Written verse', 'Studio recording', 'One revision'],
      },
      {
        'id': 's4',
        'name': 'Travel Vlog Collaboration',
        'price': 5000.0,
        'description': 'Music video or content collaboration during travels.',
        'duration': 'Project based',
        'includes': ['Music content', 'Travel footage', 'Social media promo'],
      },
    ],
    discography: [
      {
        'title': 'Saigon Dreams',
        'type': 'Single',
        'year': '2025',
        'image': 'assets/images/artists/hotpepper.png',
        'description': 'Inspired by his trip to Vietnam - East meets village.',
      },
      {
        'title': 'Maputo Nights',
        'type': 'Single',
        'year': '2024',
        'image': 'assets/images/artists/hotpepper.png',
        'description': 'Mozambique vibes - recorded during his Maputo trip.',
      },
      {
        'title': 'Chavani to the World',
        'type': 'EP',
        'year': '2024',
        'image': 'assets/images/artists/hotpepper.png',
        'description': '6-track EP documenting his journey from village to global.',
      },
      {
        'title': 'Passport Bars',
        'type': 'Single',
        'year': '2024',
        'image': 'assets/images/artists/hotpepper.png',
        'description': 'Anthem for travelers - stamps in the passport, bars on the track.',
      },
    ],
    upcomingGigs: [
      {
        'title': 'Chavani Homecoming Show',
        'date': '2026-02-28',
        'venue': 'Chavani Community Hall',
        'type': 'Homecoming',
      },
      {
        'title': 'Africa Tour - Tanzania',
        'date': '2026-05-10',
        'venue': 'Dar es Salaam',
        'type': 'International',
      },
    ],
  ),

  // GEARSH - The G.O.A.T - Greatest Of All Tech - Master Account (10,000 Hours)
  GearshArtist(
    id: 'gearsh',
    name: 'Gearsh',
    username: '@gearsh',
    category: 'Tech',
    subcategories: ['Tech', 'Software Developer', 'IT Consultant', 'App Developer', 'Web Developer', 'AI/ML'],
    location: 'South Africa',
    countryCode: 'ZA',
    currencyCode: 'ZAR',
    rating: 5.0,
    reviewCount: 500,
    hoursBooked: 10000,
    responseTime: '< 1 hour',
    image: 'assets/images/gearsh_logo.png',
    isVerified: true,
    isAvailable: true,
    bio: 'The G.O.A.T - Greatest Of All Tech. 10,000 hours of mastery. Founder of the Gearsh platform. Available for tech projects, software development, IT consulting, and any technology-related work. Building the future, one line of code at a time.',
    bookingFee: 3500,
    bookingFeeUSD: 190.0,
    highlights: [
      '🏆 10,000 Hours - LEGEND',
      'G.O.A.T of Tech',
      'Platform Founder',
      'Full-Stack Mastery',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Tech Consultation (1 hour)',
        'price': 3500.0,
        'description': 'One-on-one tech consultation for your project or startup.',
        'duration': '1 hour',
        'includes': ['Project assessment', 'Technical advice', 'Roadmap planning', 'Q&A session'],
      },
      {
        'id': 's2',
        'name': 'App Development',
        'price': 25000.0,
        'description': 'Custom mobile app development (iOS/Android/Cross-platform).',
        'duration': 'Project based',
        'includes': ['UI/UX design', 'Development', 'Testing', 'Deployment', '30-day support'],
      },
      {
        'id': 's3',
        'name': 'Website Development',
        'price': 15000.0,
        'description': 'Professional website development with modern technologies.',
        'duration': '2-4 weeks',
        'includes': ['Custom design', 'Responsive layout', 'SEO optimization', 'Hosting setup'],
      },
      {
        'id': 's4',
        'name': 'IT Support (Monthly)',
        'price': 8000.0,
        'description': 'Ongoing IT support and maintenance for your business.',
        'duration': 'Monthly',
        'includes': ['24/7 support', 'System maintenance', 'Security updates', 'Tech guidance'],
      },
      {
        'id': 's5',
        'name': 'AI/ML Integration',
        'price': 35000.0,
        'description': 'Integrate AI and machine learning into your product.',
        'duration': 'Project based',
        'includes': ['AI strategy', 'Model development', 'Integration', 'Training'],
      },
      {
        'id': 's6',
        'name': 'Tech Mentorship (Per Session)',
        'price': 2000.0,
        'description': 'Learn from the G.O.A.T - coding, tech career, or startup advice.',
        'duration': '1.5 hours',
        'includes': ['1-on-1 mentoring', 'Code review', 'Career guidance', 'Resources'],
      },
    ],
    discography: [
      {
        'title': 'Gearsh Platform',
        'type': 'Platform',
        'year': '2025',
        'image': 'assets/images/gearsh_logo.png',
        'description': 'The global marketplace for booking creative talent.',
      },
      {
        'title': 'Enterprise Solutions',
        'type': 'Portfolio',
        'year': '2024',
        'image': 'assets/images/gearsh_logo.png',
        'description': 'Custom software solutions for enterprise clients.',
      },
      {
        'title': 'AI-Powered Apps',
        'type': 'Portfolio',
        'year': '2024',
        'image': 'assets/images/gearsh_logo.png',
        'description': 'Machine learning integrated mobile applications.',
      },
      {
        'title': 'Cloud Infrastructure',
        'type': 'Portfolio',
        'year': '2023',
        'image': 'assets/images/gearsh_logo.png',
        'description': 'Scalable cloud solutions on AWS, GCP, and Azure.',
      },
    ],
    upcomingGigs: [
      {
        'title': 'Tech Conference Speaker',
        'date': '2026-03-15',
        'venue': 'Cape Town International Convention Centre',
        'type': 'Speaking',
      },
      {
        'title': 'Startup Bootcamp',
        'date': '2026-04-20',
        'venue': 'Johannesburg',
        'type': 'Workshop',
      },
    ],
  ),

  // Gold - Rapper from Nhlaneki Village, Former Dope Gang Member
  GearshArtist(
    id: 'gold',
    name: 'Gold',
    username: '@gold',
    category: 'Rapper',
    subcategories: ['Rapper', 'Hip Hop', 'Trap', 'Afro Rap'],
    location: 'Nhlaneki Village, Limpopo',
    countryCode: 'ZA',
    currencyCode: 'ZAR',
    rating: 4.7,
    reviewCount: 45,
    hoursBooked: 320,
    responseTime: '< 8 hours',
    image: 'assets/images/artists/gold.png',
    isVerified: true,
    isAvailable: true,
    bio: 'Rapper from Nhlaneki Village repping Limpopo to the fullest. Former member of the legendary Dope Gang, now on a solo journey bringing that raw, authentic sound. Gold bars, golden era - the streets raised a star.',
    bookingFee: 2000,
    bookingFeeUSD: 109.0,
    highlights: [
      'Former Dope Gang Member',
      'Nhlaneki Village Rep',
      'Solo Artist Rising',
      'Authentic Street Sound',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Live Performance (1 hour)',
        'price': 2000.0,
        'description': 'High-energy rap performance with hits from Dope Gang era and solo tracks.',
        'duration': '1 hour',
        'includes': ['Live performance', 'Original songs', 'Crowd interaction'],
      },
      {
        'id': 's2',
        'name': 'Event Performance (2 hours)',
        'price': 3800.0,
        'description': 'Extended set for events, parties, and festivals.',
        'duration': '2 hours',
        'includes': ['Full performance', 'Meet & greet', 'Photo ops'],
      },
      {
        'id': 's3',
        'name': 'Feature Verse',
        'price': 1500.0,
        'description': 'Gold verse on your track - bars guaranteed.',
        'duration': 'Flexible',
        'includes': ['Written verse', 'Studio recording', 'One revision'],
      },
      {
        'id': 's4',
        'name': 'Studio Session (Half Day)',
        'price': 2500.0,
        'description': 'Collaborative studio session for recording or writing.',
        'duration': '4 hours',
        'includes': ['Writing session', 'Recording', 'Creative input'],
      },
    ],
    discography: [
      {
        'title': 'Golden Era',
        'type': 'Album',
        'year': '2025',
        'image': 'assets/images/artists/gold.png',
        'description': 'Debut solo album marking a new chapter after Dope Gang.',
      },
      {
        'title': 'Nhlaneki Nights',
        'type': 'Single',
        'year': '2024',
        'image': 'assets/images/artists/gold.png',
        'description': 'Tribute to the village that shaped him.',
      },
      {
        'title': 'Dope Gang Classics',
        'type': 'Compilation',
        'year': '2023',
        'image': 'assets/images/artists/gold.png',
        'description': 'Best tracks from the Dope Gang era.',
      },
      {
        'title': 'Solo Dolo',
        'type': 'EP',
        'year': '2024',
        'image': 'assets/images/artists/gold.png',
        'description': 'First solo project - raw and unfiltered.',
      },
    ],
    upcomingGigs: [
      {
        'title': 'Nhlaneki Homecoming',
        'date': '2026-03-08',
        'venue': 'Nhlaneki Community Grounds',
        'type': 'Homecoming',
      },
      {
        'title': 'Limpopo Hip Hop Festival',
        'date': '2026-04-25',
        'venue': 'Polokwane',
        'type': 'Festival',
      },
    ],
  ),

  // Dr. Vanz - Venda Rapper & Producer from Ha-Maila
  GearshArtist(
    id: 'drvanz',
    name: 'Dr. Vanz',
    username: '@drvanz',
    category: 'Producer',
    subcategories: ['Producer', 'Rapper', 'Venda Rap', 'Hip Hop', 'Beatmaker'],
    location: 'Ha-Maila, Thohoyandou & Elim',
    countryCode: 'ZA',
    currencyCode: 'ZAR',
    rating: 4.8,
    reviewCount: 72,
    hoursBooked: 890,
    responseTime: '< 4 hours',
    image: 'assets/images/artists/drvanz.png',
    isVerified: true,
    isAvailable: true,
    bio: 'Venda rapper and producer from Ha-Maila, also active in Thohoyandou and Elim. Dr. Vanz is known for crafting authentic Venda-infused hip hop beats and delivering lyrical excellence. Produced hits for artists like DRT including "Mbila". The doctor is in the studio.',
    bookingFee: 2000,
    bookingFeeUSD: 109.0,
    highlights: [
      'Venda Sound Pioneer',
      'Hit Producer (Mbila)',
      'DRT Collaborator',
      'Multi-Talented Artist',
    ],
    services: [
      {
        'id': 's1',
        'name': 'Beat Production',
        'price': 2000.0,
        'description': 'Custom beat tailored to your style - Venda flavor available.',
        'duration': '3-5 days',
        'includes': ['Custom beat', 'Mixing', 'Stems included', 'One revision'],
      },
      {
        'id': 's2',
        'name': 'Full Track Production',
        'price': 4500.0,
        'description': 'Complete track production from beat to final mix.',
        'duration': '1-2 weeks',
        'includes': ['Beat production', 'Recording', 'Mixing', 'Mastering'],
      },
      {
        'id': 's3',
        'name': 'Live Performance (1 hour)',
        'price': 2500.0,
        'description': 'Dr. Vanz performing his own rap tracks live.',
        'duration': '1 hour',
        'includes': ['Live performance', 'Original songs', 'DJ set option'],
      },
      {
        'id': 's4',
        'name': 'Studio Session (Full Day)',
        'price': 5000.0,
        'description': 'Full day in the studio with Dr. Vanz producing and recording.',
        'duration': '8 hours',
        'includes': ['Beat making', 'Recording', 'Mixing', 'Creative direction'],
      },
      {
        'id': 's5',
        'name': 'Feature (Rap Verse + Production)',
        'price': 3500.0,
        'description': 'Get both a Dr. Vanz verse and production on your track.',
        'duration': 'Flexible',
        'includes': ['Custom beat', 'Rap verse', 'Mixing', 'Promotion support'],
      },
    ],
    discography: [
      {
        'title': 'Mbila (feat. DRT)',
        'type': 'Single',
        'year': '2025',
        'image': 'assets/images/artists/drvanz.png',
        'description': 'Hit collaboration with DRT - Xigaza meets Venda production.',
      },
      {
        'title': 'Xigaza Wave (with DRT)',
        'type': 'Single',
        'year': '2024',
        'image': 'assets/images/artists/drvanz.png',
        'description': 'Tsonga-Venda fusion produced for DRT.',
      },
      {
        'title': 'Rihlampfu (prod. for DRT)',
        'type': 'Production',
        'year': '2024',
        'image': 'assets/images/artists/drvanz.png',
        'description': 'Hard-hitting production for DRT.',
      },
      {
        'title': 'Venda Voltage',
        'type': 'Album',
        'year': '2024',
        'image': 'assets/images/artists/drvanz.png',
        'description': 'Solo album showcasing Venda rap and production skills.',
      },
      {
        'title': 'Ha-Maila Chronicles',
        'type': 'EP',
        'year': '2023',
        'image': 'assets/images/artists/drvanz.png',
        'description': 'Stories from the village through beats and bars.',
      },
    ],
    upcomingGigs: [
      {
        'title': 'Thohoyandou Beat Session',
        'date': '2026-02-15',
        'venue': 'Thohoyandou Studios',
        'type': 'Workshop',
      },
      {
        'title': 'Venda Music Festival',
        'date': '2026-03-29',
        'venue': 'Elim',
        'type': 'Festival',
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
