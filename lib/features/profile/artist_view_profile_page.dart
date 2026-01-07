import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/providers/cart_provider.dart';
import 'package:gearsh_app/widgets/cart_icon.dart';

class ArtistViewProfilePage extends ConsumerStatefulWidget {
  final String artistId;

  const ArtistViewProfilePage({super.key, required this.artistId});

  @override
  ConsumerState<ArtistViewProfilePage> createState() => _ArtistViewProfilePageState();
}

class _ArtistViewProfilePageState extends ConsumerState<ArtistViewProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _yellow500 = Color(0xFFEAB308);
  static const Color _green500 = Color(0xFF22C55E);
  static const Color _red500 = Color(0xFFEF4444);

  // Get artist data - first check gearsh_artists, then fallback to mock data
  Map<String, dynamic> get _artistData {
    // First check the gearsh_artists database
    final gearshArtist = getArtistById(widget.artistId);
    if (gearshArtist != null) {
      return {
        'name': gearshArtist.name,
        'username': gearshArtist.username,
        'category': gearshArtist.category,
        'subcategories': gearshArtist.subcategories,
        'location': gearshArtist.location,
        'rating': gearshArtist.rating,
        'reviewCount': gearshArtist.reviewCount,
        'completedGigs': gearshArtist.completedGigs,
        'responseTime': gearshArtist.responseTime,
        'headerImage': gearshArtist.image,
        'avatar': gearshArtist.image,
        'isVerified': gearshArtist.isVerified,
        'isAvailable': gearshArtist.isAvailable,
        'bio': gearshArtist.bio,
        'highlights': gearshArtist.highlights,
        'equipment': [],
        'services': gearshArtist.services,
        'gallery': [],
        'reviews': [],
      };
    }

    // Fallback to mock data for legacy artist IDs
    final artists = {
      '1': {
        'name': 'DJ Maphorisa',
        'username': '@djmaphorisa',
        'category': 'DJ',
        'subcategories': ['Amapiano', 'House', 'Afrobeats'],
        'location': 'Johannesburg, SA',
        'rating': 4.9,
        'reviewCount': 156,
        'completedGigs': 324,
        'responseTime': '< 1 hour',
        'headerImage': 'assets/images/artists/kunye.png',
        'avatar': 'assets/images/artists/kunye.png',
        'isVerified': true,
        'isAvailable': true,
        'bio': 'Award-winning DJ and producer, pioneer of Amapiano music. Known for electrifying performances at major festivals and exclusive events worldwide. Creator of multiple platinum-selling albums.',
        'highlights': [
          'Grammy-nominated producer',
          '10+ years experience',
          'International tours',
          'Festival headliner',
        ],
        'equipment': [
          'Pioneer CDJ-3000',
          'Allen & Heath Xone:96',
          'Professional lighting',
          'Premium sound system',
        ],
        'services': [
          {
            'id': 's1',
            'name': 'Club Night (4 hours)',
            'price': 700.0,
            'description': 'High-energy club set with Amapiano, House & Afrobeats. Includes basic lighting.',
            'duration': '4 hours',
            'includes': ['DJ performance', 'Basic lighting', 'Sound check'],
          },
          {
            'id': 's2',
            'name': 'Festival Set (2 hours)',
            'price': 1500.0,
            'description': 'Premium festival performance with full production. Perfect for large crowds.',
            'duration': '2 hours',
            'includes': ['DJ performance', 'Premium lighting', 'Pyrotechnics', 'MC'],
          },
          {
            'id': 's3',
            'name': 'Private Event',
            'price': 2500.0,
            'description': 'Exclusive private event performance. Fully customizable setlist.',
            'duration': '3 hours',
            'includes': ['DJ performance', 'Custom setlist', 'Premium sound', 'Meet & greet'],
          },
        ],
        'gallery': [
          'assets/images/artists/kunye.png',
          'assets/images/artists/kunye.png',
          'assets/images/artists/kunye.png',
          'assets/images/artists/kunye.png',
        ],
        'reviews': [
          {
            'id': 'r1',
            'name': 'Sarah M.',
            'avatar': null,
            'rating': 5,
            'date': 'Dec 2025',
            'comment': 'Absolutely incredible! DJ Maphorisa had everyone dancing all night. Professional, punctual, and amazing energy!',
            'eventType': 'Birthday Party',
          },
          {
            'id': 'r2',
            'name': 'Michael K.',
            'avatar': null,
            'rating': 5,
            'date': 'Nov 2025',
            'comment': 'Best decision we made for our wedding. The music selection was perfect and he read the crowd beautifully.',
            'eventType': 'Wedding',
          },
          {
            'id': 'r3',
            'name': 'Corporate Events SA',
            'avatar': null,
            'rating': 5,
            'date': 'Oct 2025',
            'comment': 'Highly professional. Arrived early, set up quickly, and delivered an amazing performance for our annual gala.',
            'eventType': 'Corporate Event',
          },
        ],
      },
      '2': {
        'name': 'Kabza De Small',
        'username': '@kababorhla',
        'category': 'DJ',
        'subcategories': ['Amapiano', 'Deep House'],
        'location': 'Pretoria, SA',
        'rating': 4.9,
        'reviewCount': 203,
        'completedGigs': 456,
        'responseTime': '< 2 hours',
        'headerImage': 'assets/images/artists/P9-Kabza-de-Small.webp',
        'avatar': 'assets/images/artists/P9-Kabza-de-Small.webp',
        'isVerified': true,
        'isAvailable': true,
        'bio': 'The King of Amapiano. Multiple award-winning producer and DJ who has revolutionized South African music. Known for sold-out shows and chart-topping collaborations.',
        'highlights': [
          'King of Amapiano',
          'SAMA Award winner',
          'Sold-out tours',
          '500+ produced tracks',
        ],
        'equipment': [
          'Pioneer DDJ-1000',
          'Full PA system',
          'LED lighting rig',
          'Backup equipment',
        ],
        'services': [
          {
            'id': 's1',
            'name': 'Standard Set (3 hours)',
            'price': 800.0,
            'description': 'Premium Amapiano set perfect for any event. Crowd favourites guaranteed.',
            'duration': '3 hours',
            'includes': ['DJ performance', 'Sound system', 'Basic lighting'],
          },
          {
            'id': 's2',
            'name': 'Premium Package (5 hours)',
            'price': 1800.0,
            'description': 'Extended performance with full production value.',
            'duration': '5 hours',
            'includes': ['DJ performance', 'Premium sound', 'LED lighting', 'MC support'],
          },
        ],
        'gallery': [
          'assets/images/artists/P9-Kabza-de-Small.webp',
        ],
        'reviews': [
          {
            'id': 'r1',
            'name': 'Events Pro',
            'avatar': null,
            'rating': 5,
            'date': 'Dec 2025',
            'comment': 'Kabza brought the house down! Incredible energy and professionalism.',
            'eventType': 'Festival',
          },
        ],
      },
      '3': {
        'name': 'Cassper Nyovest',
        'username': '@casspernyovest',
        'category': 'Hip Hop',
        'subcategories': ['Rap', 'Kwaito', 'Amapiano'],
        'location': 'Johannesburg, SA',
        'rating': 4.8,
        'reviewCount': 178,
        'completedGigs': 289,
        'responseTime': '< 24 hours',
        'headerImage': 'assets/images/artists/Cassper Nyovest Fill Up FNB Station 1.jpg',
        'avatar': 'assets/images/artists/Cassper Nyovest Fill Up FNB Station 1.jpg',
        'isVerified': true,
        'isAvailable': false,
        'bio': 'Multi-platinum selling artist and entrepreneur. Known for Fill Up concerts and hit records. One of Africa\'s biggest hip hop artists.',
        'highlights': [
          'Fill Up FNB Stadium',
          'Multi-platinum artist',
          'Brand ambassador',
          'Award-winning rapper',
        ],
        'equipment': [
          'Full stage production',
          'Live band available',
          'Professional lighting',
          'Pyrotechnics',
        ],
        'services': [
          {
            'id': 's1',
            'name': 'Concert Performance',
            'price': 5000.0,
            'description': 'Full concert experience with hit songs and crowd interaction.',
            'duration': '1.5 hours',
            'includes': ['Live performance', 'Hit songs', 'Meet & greet option'],
          },
        ],
        'gallery': [],
        'reviews': [],
      },
      '4': {
        'name': 'Kendrick Lamar',
        'username': '@kendricklamar',
        'category': 'Rap',
        'subcategories': ['Hip Hop', 'Conscious Rap'],
        'location': 'Compton, USA',
        'rating': 5.0,
        'reviewCount': 320,
        'completedGigs': 500,
        'responseTime': 'Via management',
        'headerImage': 'assets/images/artists/kendrick.png',
        'avatar': 'assets/images/artists/kendrick.png',
        'isVerified': true,
        'isAvailable': true,
        'bio': 'Pulitzer Prize-winning rapper and one of the greatest lyricists of all time. Grammy Award winner with critically acclaimed albums.',
        'highlights': [
          'Pulitzer Prize winner',
          '17 Grammy Awards',
          'Global icon',
          'Critically acclaimed',
        ],
        'equipment': [
          'Full touring production',
          'Live band',
          'World-class sound',
          'Immersive visuals',
        ],
        'services': [
          {
            'id': 's1',
            'name': 'Private Concert',
            'price': 50000.0,
            'description': 'Exclusive private performance. Subject to availability.',
            'duration': '1 hour',
            'includes': ['Live performance', 'VIP experience'],
          },
        ],
        'gallery': [],
        'reviews': [],
      },
    };

    return artists[widget.artistId] ?? _getDefaultArtist();
  }

  Map<String, dynamic> _getDefaultArtist() {
    return {
      'name': 'Artist',
      'username': '@artist',
      'category': 'Music',
      'subcategories': ['Entertainment'],
      'location': 'South Africa',
      'rating': 4.5,
      'reviewCount': 0,
      'completedGigs': 0,
      'responseTime': '< 24 hours',
      'headerImage': 'assets/images/gearsh_logo.png',
      'avatar': 'assets/images/gearsh_logo.png',
      'isVerified': false,
      'isAvailable': true,
      'bio': 'Professional artist available for bookings.',
      'highlights': [],
      'equipment': [],
      'services': [],
      'gallery': [],
      'reviews': [],
    };
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Check if artist is saved
    _isSaved = true; // Mock - replace with actual saved state
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSaved() {
    if (userRoleService.isGuest && !userRoleService.isLoggedIn) {
      _showSignUpPrompt('Saved Artists');
      return;
    }
    setState(() => _isSaved = !_isSaved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? 'Added to saved artists' : 'Removed from saved'),
        backgroundColor: _slate800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _bookService(Map<String, dynamic> service) {
    if (userRoleService.isGuest && !userRoleService.isLoggedIn) {
      _showSignUpPrompt('Booking');
    } else {
      context.go('/booking-flow/${widget.artistId}?service=${service['id']}');
    }
  }

  void _contactArtist() {
    if (userRoleService.isGuest && !userRoleService.isLoggedIn) {
      _showSignUpPrompt('Messages');
    } else {
      context.go('/messages');
    }
  }

  void _showSignUpPrompt(String feature) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _slate900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _sky500.withAlpha(51), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _sky500.withAlpha(26),
                shape: BoxShape.circle,
                border: Border.all(color: _sky500.withAlpha(51), width: 1),
              ),
              child: Icon(
                feature == 'Booking'
                    ? Icons.calendar_today
                    : feature == 'Saved Artists'
                        ? Icons.favorite
                        : Icons.chat_bubble,
                color: _sky400,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'Sign Up to Access $feature',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              feature == 'Booking'
                  ? 'Create an account to book artists and manage your events.'
                  : feature == 'Saved Artists'
                      ? 'Create an account to save your favourite artists.'
                      : 'Create an account to message artists directly.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Sign Up Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.go('/signup');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha(77),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Sign Up Free',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Login Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.go('/login');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _slate800, width: 1),
                ),
                child: Center(
                  child: Text(
                    'Already have an account? Log In',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Continue exploring
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continue Exploring',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _artistData;
    final isAvailable = data['isAvailable'] as bool;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            CustomScrollView(
              slivers: [
                // App Bar with Header Image
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: _slate950,
                  leading: GestureDetector(
                    onTap: () {
                      if (!mounted) return;
                      try {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      } catch (e) {
                        // Fallback navigation
                        context.go('/');
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _slate900.withAlpha(200),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  actions: [
                    // Cart icon
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _slate900.withAlpha(200),
                        shape: BoxShape.circle,
                      ),
                      child: const CartIconButton(size: 22),
                    ),
                    GestureDetector(
                      onTap: _toggleSaved,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _slate900.withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isSaved ? Icons.favorite : Icons.favorite_border,
                          color: _isSaved ? _red500 : Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Share functionality
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _slate900.withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share, color: Colors.white),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          data['headerImage'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _slate800,
                            child: const Icon(Icons.person, size: 80, color: _sky500),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                _slate950.withAlpha(200),
                                _slate950,
                              ],
                              stops: const [0.3, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Artist Info Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Verified Badge
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        data['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (data['isVerified'] == true) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: _sky500,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['username'],
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(128),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Availability badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isAvailable ? _green500.withAlpha(51) : _red500.withAlpha(51),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isAvailable ? _green500 : _red500,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isAvailable ? _green500 : _red500,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAvailable ? 'Available' : 'Unavailable',
                                    style: TextStyle(
                                      color: isAvailable ? _green500 : _red500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Category Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildTag(data['category'], isPrimary: true),
                            ...(data['subcategories'] as List).map(
                              (sub) => _buildTag(sub),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Location and Response Time
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: Colors.white.withAlpha(153), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              data['location'],
                              style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 13),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, color: Colors.white.withAlpha(153), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Response: ${data['responseTime']}',
                              style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Stats Row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _slate800.withAlpha(128),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _sky500.withAlpha(51)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('${data['rating']}', 'Rating', Icons.star, _yellow500),
                              _buildDivider(),
                              _buildStatItem('${data['reviewCount']}', 'Reviews', Icons.chat_bubble_outline, _sky400),
                              _buildDivider(),
                              _buildStatItem('${data['completedGigs']}', 'Gigs', Icons.celebration_outlined, _green500),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: isAvailable && (data['services'] as List).isNotEmpty
                                    ? () => _showServicesBottomSheet(data)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: isAvailable
                                        ? const LinearGradient(colors: [_sky500, _cyan500])
                                        : null,
                                    color: isAvailable ? null : _slate800,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAvailable ? 'Book Now' : 'Not Available',
                                      style: TextStyle(
                                        color: isAvailable ? Colors.white : _slate400,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _contactArtist,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _slate800,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _sky500.withAlpha(77)),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.chat_bubble_outline, color: _sky400),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: _sky400,
                      unselectedLabelColor: _slate400,
                      indicatorColor: _sky500,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Services'),
                        Tab(text: 'About'),
                        Tab(text: 'Gallery'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                ),

                // Tab Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildServicesTab(data),
                      _buildAboutTab(data),
                      _buildGalleryTab(data),
                      _buildReviewsTab(data),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? _sky500.withAlpha(51) : _slate800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPrimary ? _sky500.withAlpha(128) : _sky500.withAlpha(51)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isPrimary ? _sky400 : Colors.white.withAlpha(179),
          fontSize: 12,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: _sky500.withAlpha(51),
    );
  }

  Widget _buildServicesTab(Map<String, dynamic> data) {
    final services = data['services'] as List;

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, color: _slate400, size: 48),
            const SizedBox(height: 16),
            Text(
              'No services listed yet',
              style: TextStyle(color: Colors.white.withAlpha(128)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index] as Map<String, dynamic>;
        return _buildServiceCard(service, data['isAvailable'] as bool);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isAvailable) {
    final double price = service['price'] as double;
    final double serviceFee = price * 0.126; // 12.6% service fee
    final double total = price + serviceFee;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate800.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  service['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _sky400,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '+ R${serviceFee.toStringAsFixed(0)} fee',
                    style: TextStyle(
                      color: Colors.white.withAlpha(128),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            service['description'],
            style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 14),
          ),
          const SizedBox(height: 12),
          // Duration
          Row(
            children: [
              Icon(Icons.schedule, color: _slate400, size: 16),
              const SizedBox(width: 6),
              Text(
                service['duration'],
                style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Includes
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (service['includes'] as List).map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _slate900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: _green500, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      item,
                      style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Total Price Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _sky500.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (incl. 12.6% service fee)',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'R${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _sky400,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons Row
          Row(
            children: [
              // Add to Cart Button
              Expanded(
                child: _buildAddToCartButton(service, isAvailable),
              ),
              const SizedBox(width: 12),
              // Book Now Button
              Expanded(
                child: GestureDetector(
                  onTap: isAvailable ? () => _bookService(service) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isAvailable
                          ? const LinearGradient(colors: [_sky500, _cyan500])
                          : null,
                      color: isAvailable ? null : _slate800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        isAvailable ? 'Book Now' : 'Not Available',
                        style: TextStyle(
                          color: isAvailable ? Colors.white : _slate400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(Map<String, dynamic> service, bool isAvailable) {
    // Try to get artist from database, or create from mock data
    GearshArtist? foundArtist = getArtistById(widget.artistId);

    // If not found in database, create a GearshArtist from mock data
    final GearshArtist artist;
    if (foundArtist != null) {
      artist = foundArtist;
    } else {
      final data = _artistData;
      artist = GearshArtist(
        id: widget.artistId,
        name: data['name'] as String,
        username: data['username'] as String? ?? '@${(data['name'] as String).toLowerCase().replaceAll(' ', '')}',
        image: data['avatar'] as String? ?? 'assets/images/placeholder.png',
        category: data['category'] as String,
        subcategories: List<String>.from(data['subcategories'] ?? []),
        location: data['location'] as String? ?? 'Unknown',
        rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
        reviewCount: data['reviewCount'] as int? ?? 0,
        completedGigs: data['completedGigs'] as int? ?? 0,
        responseTime: data['responseTime'] as String? ?? '< 1 hour',
        isVerified: data['isVerified'] as bool? ?? false,
        isAvailable: data['isAvailable'] as bool? ?? true,
        bio: data['bio'] as String? ?? '',
        bookingFee: 500, // Default booking fee
        highlights: List<String>.from(data['highlights'] ?? []),
        services: List<Map<String, dynamic>>.from(data['services'] ?? []),
        discography: [],
        upcomingGigs: [],
        merch: [],
      );
    }

    if (!isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _slate800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _slate800),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, color: _slate400, size: 18),
              const SizedBox(width: 6),
              Text(
                'Add to Cart',
                style: TextStyle(color: _slate400, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final isInCart = ref.watch(cartProvider).hasItem(artist.id, service['id'] as String);

    return GestureDetector(
      onTap: () {
        if (isInCart) {
          // Go to cart
          context.go('/cart');
        } else {
          // Add to cart
          ref.read(cartActionsProvider).addFromArtistService(artist, service);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${service['name']} added to cart'),
                  ),
                ],
              ),
              backgroundColor: _sky500,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'View Cart',
                textColor: Colors.white,
                onPressed: () => context.go('/cart'),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isInCart ? _green500.withAlpha(26) : _slate900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isInCart ? _green500 : _sky500.withAlpha(77),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isInCart ? Icons.check_circle : Icons.add_shopping_cart,
                color: isInCart ? _green500 : _sky400,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isInCart ? 'In Cart' : 'Add to Cart',
                style: TextStyle(
                  color: isInCart ? _green500 : _sky400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          Text(
            data['bio'],
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Highlights
          if ((data['highlights'] as List).isNotEmpty) ...[
            const Text(
              'Highlights',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...((data['highlights'] as List).map((highlight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _sky500, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    highlight,
                    style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 15),
                  ),
                ],
              ),
            ))),
            const SizedBox(height: 24),
          ],

          // Equipment
          if ((data['equipment'] as List).isNotEmpty) ...[
            const Text(
              'Equipment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: (data['equipment'] as List).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _slate800,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _sky500.withAlpha(51)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speaker, color: _sky400, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        item,
                        style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 13),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryTab(Map<String, dynamic> data) {
    final gallery = data['gallery'] as List;

    if (gallery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: _slate400, size: 48),
            const SizedBox(height: 16),
            Text(
              'No photos yet',
              style: TextStyle(color: Colors.white.withAlpha(128)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: gallery.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            gallery[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: _slate800,
              child: const Icon(Icons.image, color: _slate400),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(Map<String, dynamic> data) {
    final reviews = data['reviews'] as List;

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, color: _slate400, size: 48),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(color: Colors.white.withAlpha(128)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index] as Map<String, dynamic>;
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate800.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _sky500.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (review['name'] as String).substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: _sky400,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${review['eventType']} • ${review['date']}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(128),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < (review['rating'] as int) ? Icons.star : Icons.star_border,
                  color: _yellow500,
                  size: 16,
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['comment'],
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showServicesBottomSheet(Map<String, dynamic> data) {
    final services = data['services'] as List;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: _slate900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _slate400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Select a Service',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: _slate400),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index] as Map<String, dynamic>;
                  return _buildServiceCard(service, true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _ArtistViewProfilePageState._slate950,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

