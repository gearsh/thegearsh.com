import 'package:flutter/material.dart';
import 'package:gearsh_app/features/messages/messages_screen.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/widgets/auth_prompt.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _currentIndex = 0;
  int _selectedCategoryIndex = 0;

  // Category list
  static const List<String> _categories = ['All', 'Pop & R&B', 'DJs', 'Hip Hop', 'Rap', 'Gospel', 'Amapiano', 'Comedy'];

  // Get combined artists list (gearsh_artists + legacy)
  List<Map<String, dynamic>> get _allArtists {
    // Convert gearsh_artists to map format
    final gearshList = gearshArtists.map((artist) => {
      'id': artist.id,
      'name': artist.name,
      'category': artist.category,
      'image': artist.image,
      'rating': artist.rating,
      'reviews': artist.reviewCount,
      'price': artist.bookingFee,
      'location': artist.location,
      'isVerified': artist.isVerified,
    }).toList();

    // Combine with legacy artists
    return [...gearshList, ..._legacyArtists];
  }

  // Legacy artist data (will be migrated to gearsh_artists)
  static const List<Map<String, dynamic>> _legacyArtists = [
    {
      'id': '4',
      'name': 'DJ Maphorisa',
      'category': 'DJ',
      'image': 'assets/images/artists/kunye.png',
      'rating': 4.7,
      'reviews': 156,
      'price': 700,
      'location': 'Johannesburg, SA',
    },
    {
      'id': '5',
      'name': 'Kabza De Small',
      'category': 'DJ',
      'image': 'assets/images/artists/P9-Kabza-de-Small.webp',
      'rating': 4.9,
      'reviews': 203,
      'price': 800,
      'location': 'Pretoria, SA',
    },
    {
      'id': '6',
      'name': 'Cassper Nyovest',
      'category': 'Hip Hop',
      'image': 'assets/images/artists/Cassper Nyovest Fill Up FNB Station 1.jpg',
      'rating': 4.8,
      'reviews': 178,
      'price': 550,
      'location': 'Johannesburg, SA',
    },
    {
      'id': '7',
      'name': 'The Game',
      'category': 'Hip Hop',
      'image': 'assets/images/artists/game.png',
      'rating': 4.6,
      'reviews': 145,
      'price': 900,
      'location': 'Los Angeles, USA',
    },
    {
      'id': '8',
      'name': 'Kendrick Lamar',
      'category': 'Rap',
      'image': 'assets/images/artists/kendrick.png',
      'rating': 5.0,
      'reviews': 320,
      'price': 1500,
      'location': 'Compton, USA',
    },
    {
      'id': '9',
      'name': 'Nota Baloyi',
      'category': 'Host',
      'image': 'assets/images/artists/NOTA.png',
      'rating': 4.5,
      'reviews': 89,
      'price': 350,
      'location': 'Johannesburg, SA',
    },
  ];

  // Color constants to avoid repetition and deprecation warnings
  static const Color _skyBlue = Color(0xFF38BDF8);
  static const Color _slateGray = Color(0xFF94A3B8);
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);

  // Pre-computed colors with opacity
  static final Color _slate950WithOpacity95 = const Color(0xF2020617);
  static final Color _whiteWithOpacity60 = Colors.white.withAlpha(153);
  static final Color _whiteWithOpacity50 = Colors.white.withAlpha(128);
  static final Color _whiteWithOpacity40 = Colors.white.withAlpha(102);
  static final Color _whiteWithOpacity30 = Colors.white.withAlpha(77);
  static final Color _whiteWithOpacity70 = Colors.white.withAlpha(179);
  static final Color _skyBlueWithOpacity30 = const Color(0x4D38BDF8);
  static final Color _skyBlueWithOpacity20 = const Color(0x3338BDF8);
  static final Color _skyBlueWithOpacity10 = const Color(0x1A38BDF8);
  static final Color _slate800WithOpacity50 = const Color(0x801E293B);
  static final Color _slate900WithOpacity80 = const Color(0xCC0F172A);
  static final Color _sky500WithOpacity10 = const Color(0x1A0EA5E9);

  @override
  Widget build(BuildContext context) {
    // Get actual screen dimensions for Redmi 12C (720x1650) or any device
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _slate950,
              _slate900,
              _slate950,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Main Content Area
            Column(
              children: [
                SizedBox(height: padding.top + 10), // Safe area top
                Expanded(
                  child: _buildCurrentScreen(),
                ),
                const SizedBox(height: 80), // Space for bottom nav
              ],
            ),
            // Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80 + padding.bottom,
                padding: EdgeInsets.only(bottom: padding.bottom),
                decoration: BoxDecoration(
                  color: _slate950WithOpacity95,
                  border: const Border(
                    top: BorderSide(
                      color: Color(0x330EA5E9), // sky-500/20
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: userRoleService.isArtist
                      ? [
                          _buildNavItem(
                            icon: Icons.dashboard_outlined,
                            label: 'Dashboard',
                            index: 0,
                            onTap: () => context.go('/dashboard'),
                          ),
                          _buildNavItem(
                            icon: Icons.message_outlined,
                            label: 'Messages',
                            index: 1,
                            onTap: () {
                              if (!checkAuthAndPrompt(context, featureName: 'access messages')) return;
                              setState(() => _currentIndex = 1);
                            },
                          ),
                          _buildNavItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'Calendar',
                            index: 2,
                            onTap: () {
                              if (!checkAuthAndPrompt(context, featureName: 'access your calendar')) return;
                              setState(() => _currentIndex = 2);
                            },
                          ),
                          _buildNavItem(
                            icon: Icons.person_outline,
                            label: 'Profile',
                            index: 3,
                            onTap: () {
                              if (!checkAuthAndPrompt(context, featureName: 'access your profile')) return;
                              context.go('/profile-settings');
                            },
                          ),
                        ]
                      : [
                          _buildNavItem(
                            icon: Icons.explore_outlined,
                            label: 'Explore',
                            index: 0,
                            onTap: () => setState(() => _currentIndex = 0),
                          ),
                          _buildNavItem(
                            icon: Icons.message_outlined,
                            label: 'Messages',
                            index: 1,
                            onTap: () {
                              if (!checkAuthAndPrompt(context, featureName: 'access messages')) return;
                              setState(() => _currentIndex = 1);
                            },
                          ),
                          _buildNavItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'Bookings',
                            index: 2,
                            onTap: () {
                              if (!checkAuthAndPrompt(context, featureName: 'view your bookings')) return;
                              setState(() => _currentIndex = 2);
                            },
                          ),
                          _buildNavItem(
                            icon: Icons.person_outline,
                            label: 'Profile',
                            index: 3,
                            onTap: () {
                              if (!checkAuthAndPrompt(context, featureName: 'access your profile')) return;
                              context.go('/profile-settings');
                            },
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? _skyBlue : _slateGray;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return MessagesScreen(
          onViewProfile: (artistId) => context.go('/artist/$artistId'),
        );
      case 2:
        return _buildBookingsScreen();
      case 3:
        return _buildProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 56) / 2.5; // Responsive card width

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        color: _whiteWithOpacity60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'The Gearsh App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _skyBlueWithOpacity30,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/gearsh_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.music_note,
                      color: _skyBlue,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          GestureDetector(
            onTap: () => context.go('/search'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _slate800WithOpacity50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _skyBlueWithOpacity20,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: _whiteWithOpacity50,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Search artists, genres...',
                    style: TextStyle(
                      color: _whiteWithOpacity50,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Featured Artists Section
          const Text(
            'Featured Artists',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildArtistCard('A-Reece', 'Hip Hop', 'assets/images/artists/a-reece.png', '1', cardWidth),
                _buildArtistCard('Nasty C', 'Rap', 'assets/images/artists/nasty c.png', '2', cardWidth),
                _buildArtistCard('Emtee', 'Hip Hop', 'assets/images/artists/emtee.webp', '3', cardWidth),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Category Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [_sky500, Color(0xFF22D3EE)],
                            )
                          : null,
                      color: isSelected ? null : _slate800WithOpacity50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : _skyBlueWithOpacity20,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _sky500.withAlpha(102),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : _slateGray,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Artist Grid - filtered by category
          Builder(
            builder: (context) {
              final allArtists = _allArtists;
              final filteredArtists = _selectedCategoryIndex == 0
                  ? allArtists
                  : allArtists.where((artist) {
                      final selectedCategory = _categories[_selectedCategoryIndex];
                      final artistCategory = artist['category'] as String;
                      // Match category
                      if (selectedCategory == 'DJs') {
                        return artistCategory == 'DJ';
                      } else if (selectedCategory == 'Pop & R&B') {
                        return artistCategory == 'Pop & R&B' || artistCategory.contains('Pop') || artistCategory.contains('R&B');
                      } else if (selectedCategory == 'Hip Hop') {
                        return artistCategory == 'Hip Hop';
                      } else if (selectedCategory == 'Rap') {
                        return artistCategory == 'Rap';
                      } else if (selectedCategory == 'Gospel') {
                        return artistCategory == 'Gospel';
                      } else if (selectedCategory == 'Amapiano') {
                        return artistCategory == 'Amapiano' || artistCategory == 'DJ';
                      } else if (selectedCategory == 'Comedy') {
                        return artistCategory == 'Comedy' || artistCategory.contains('Comedy');
                      }
                      return artistCategory == selectedCategory;
                    }).toList();

              if (filteredArtists.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: _whiteWithOpacity30,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No artists in this category',
                          style: TextStyle(
                            color: _whiteWithOpacity50,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: filteredArtists.length,
                itemBuilder: (context, index) {
                  final artist = filteredArtists[index];
                  return _buildArtistGridCard(artist);
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildArtistCard(String name, String genre, String imagePath, String artistId, double cardWidth) {
    return GestureDetector(
      onTap: () {
        if (!checkAuthAndPrompt(context, featureName: 'view artist profiles')) return;
        context.go('/artist/$artistId');
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _slate800,
              _slate900WithOpacity80,
            ],
          ),
          border: Border.all(
            color: _skyBlueWithOpacity10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                imagePath,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 90,
                  color: _slate800,
                  child: const Icon(
                    Icons.person,
                    color: _skyBlue,
                    size: 36,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    genre,
                    style: TextStyle(
                      color: _whiteWithOpacity60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistGridCard(Map<String, dynamic> artist) {
    return GestureDetector(
      onTap: () {
        if (!checkAuthAndPrompt(context, featureName: 'view artist profiles')) return;
        context.go('/artist/${artist['id']}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withAlpha(102), // slate-900/40
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _skyBlueWithOpacity20,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with category badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    artist['image'],
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: _slate800,
                      child: const Icon(
                        Icons.person,
                        color: _skyBlue,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                // Category badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _slate950.withAlpha(204), // slate-950/80
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      artist['category'],
                      style: const TextStyle(
                        color: _skyBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Rating
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFACC15), // yellow-400
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${artist['rating']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '(${artist['reviews']})',
                              style: TextStyle(
                                color: _whiteWithOpacity50,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Price and Book button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: TextStyle(
                                color: _whiteWithOpacity50,
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              'R${artist['price']}',
                              style: const TextStyle(
                                color: _skyBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            if (!checkAuthAndPrompt(context, featureName: 'book artists')) return;
                            context.go('/artist/${artist['id']}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_sky500, Color(0xFF22D3EE)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: _sky500.withAlpha(77),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Book',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }


  // Bookings tab state
  String _bookingsTab = 'upcoming';

  // Mock bookings data - Upcoming
  static const List<Map<String, dynamic>> _upcomingBookings = [
    {
      'id': 'b1',
      'artistId': '1',
      'artistName': 'A-Reece',
      'artistImage': 'assets/images/artists/a-reece.png',
      'service': 'Live Performance (2 hours)',
      'date': 'Dec 15, 2025',
      'time': '8:00 PM',
      'location': 'Constitution Hill, Johannesburg',
      'price': 15000,
      'status': 'confirmed',
    },
    {
      'id': 'b2',
      'artistId': '2',
      'artistName': 'Nasty C',
      'artistImage': 'assets/images/artists/nasty c.png',
      'service': 'Festival Headline Set',
      'date': 'Dec 20, 2025',
      'time': '6:00 PM',
      'location': 'FNB Stadium, Soweto',
      'price': 25000,
      'status': 'pending',
    },
  ];

  // Mock bookings data - Past
  static const List<Map<String, dynamic>> _pastBookings = [
    {
      'id': 'b3',
      'artistId': '3',
      'artistName': 'Emtee',
      'artistImage': 'assets/images/artists/emtee.webp',
      'service': 'Club Night Performance',
      'date': 'Oct 15, 2025',
      'price': 12000,
      'status': 'completed',
    },
    {
      'id': 'b4',
      'artistId': '4',
      'artistName': 'Cassper Nyovest',
      'artistImage': 'assets/images/artists/Cassper Nyovest Fill Up FNB Station 1.jpg',
      'service': 'Private Event',
      'date': 'Sep 28, 2025',
      'price': 35000,
      'status': 'completed',
    },
  ];

  // Mock payments data
  static const List<Map<String, dynamic>> _payments = [
    {
      'id': 'p1',
      'description': 'A-Reece - Live Performance',
      'date': 'Dec 15, 2025',
      'amount': 15000,
      'status': 'pending',
    },
    {
      'id': 'p2',
      'description': 'Emtee - Club Night',
      'date': 'Oct 15, 2025',
      'amount': 12000,
      'status': 'paid',
    },
    {
      'id': 'p3',
      'description': 'Cassper Nyovest - Private Event',
      'date': 'Sep 28, 2025',
      'amount': 35000,
      'status': 'paid',
    },
    {
      'id': 'p4',
      'description': 'Nasty C - Festival Set',
      'date': 'Pending',
      'amount': 25000,
      'status': 'pending',
    },
  ];

  Widget _buildBookingsScreen() {
    return Column(
      children: [
        // Header with stats and tabs
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: _slate950WithOpacity95,
            border: Border(
              bottom: BorderSide(color: _skyBlueWithOpacity20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Bookings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Stats
              Row(
                children: [
                  Expanded(child: _buildStatBox('Active', '2')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatBox('Completed', '12')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatBox('Spent', 'R87k')),
                ],
              ),
              const SizedBox(height: 16),
              // Tabs
              Row(
                children: [
                  _buildBookingsTabButton('upcoming', 'Upcoming'),
                  _buildBookingsTabButton('past', 'Past'),
                  _buildBookingsTabButton('payments', 'Payments'),
                ],
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildBookingsTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_sky500.withAlpha(51), const Color(0xFF22D3EE).withAlpha(51)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _skyBlueWithOpacity30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _whiteWithOpacity50,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTabButton(String tabId, String label) {
    final isActive = _bookingsTab == tabId;
    return GestureDetector(
      onTap: () => setState(() => _bookingsTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? _sky500 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? _skyBlue : _whiteWithOpacity50,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsTabContent() {
    switch (_bookingsTab) {
      case 'upcoming':
        return Column(
          children: _upcomingBookings.map((booking) => _buildUpcomingBookingCard(booking)).toList(),
        );
      case 'past':
        return Column(
          children: _pastBookings.map((booking) => _buildPastBookingCard(booking)).toList(),
        );
      case 'payments':
        return Column(
          children: _payments.map((payment) => _buildPaymentCard(payment)).toList(),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildUpcomingBookingCard(Map<String, dynamic> booking) {
    final isConfirmed = booking['status'] == 'confirmed';
    return GestureDetector(
      onTap: () => context.go('/artist/${booking['artistId']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _slate800WithOpacity50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _skyBlueWithOpacity20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist info row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artist image
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _skyBlueWithOpacity30, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      booking['artistImage'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _slate800,
                        child: const Icon(Icons.person, color: _skyBlue, size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking['artistName'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.more_vert_rounded, color: _whiteWithOpacity50, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['service'],
                        style: TextStyle(
                          color: _whiteWithOpacity60,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConfirmed
                              ? const Color(0xFF4ADE80).withAlpha(38)
                              : const Color(0xFFFACC15).withAlpha(38),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConfirmed
                                ? const Color(0xFF4ADE80).withAlpha(77)
                                : const Color(0xFFFACC15).withAlpha(77),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isConfirmed ? Icons.check_circle_outline : Icons.access_time_rounded,
                              color: isConfirmed ? const Color(0xFF4ADE80) : const Color(0xFFFACC15),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isConfirmed ? 'Confirmed' : 'Pending',
                              style: TextStyle(
                                color: isConfirmed ? const Color(0xFF4ADE80) : const Color(0xFFFACC15),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Booking details
            _buildBookingDetailRow(Icons.calendar_today_outlined, '${booking['date']} • ${booking['time']}'),
            const SizedBox(height: 8),
            _buildBookingDetailRow(Icons.location_on_outlined, booking['location']),
            const SizedBox(height: 8),
            _buildBookingDetailRow(Icons.attach_money_rounded, 'R${booking['price']}', isPrice: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailRow(IconData icon, String text, {bool isPrice = false}) {
    return Row(
      children: [
        Icon(icon, color: _skyBlue, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isPrice ? _skyBlue : _whiteWithOpacity70,
            fontSize: 13,
            fontWeight: isPrice ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPastBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate800WithOpacity50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _skyBlueWithOpacity20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artist image
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _skyBlueWithOpacity30, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                booking['artistImage'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _slate800,
                  child: const Icon(Icons.person, color: _skyBlue, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking['artistName'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'R${booking['price']}',
                      style: const TextStyle(
                        color: _skyBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  booking['service'],
                  style: TextStyle(
                    color: _whiteWithOpacity60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking['date'],
                      style: TextStyle(
                        color: _whiteWithOpacity40,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withAlpha(38),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4ADE80).withAlpha(77)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, color: Color(0xFF4ADE80), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final isPaid = payment['status'] == 'paid';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate800WithOpacity50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _skyBlueWithOpacity20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  payment['description'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'R${payment['amount']}',
                style: const TextStyle(
                  color: _skyBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                payment['date'],
                style: TextStyle(
                  color: _whiteWithOpacity50,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF4ADE80).withAlpha(38)
                      : const Color(0xFFFACC15).withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaid
                        ? const Color(0xFF4ADE80).withAlpha(77)
                        : const Color(0xFFFACC15).withAlpha(77),
                  ),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                    color: isPaid ? const Color(0xFF4ADE80) : const Color(0xFFFACC15),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _skyBlue,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/gearsh_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _slate800,
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: _skyBlue,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Guest User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'MVP Demo Mode',
            style: TextStyle(
              color: _whiteWithOpacity60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildProfileMenuItem(Icons.settings_outlined, 'Settings'),
          _buildProfileMenuItem(Icons.help_outline, 'Help & Support'),
          _buildProfileMenuItem(Icons.info_outline, 'About'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _sky500WithOpacity10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _skyBlueWithOpacity20,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  color: _skyBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MVP Demo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'FNB App of the Year 2025',
                        style: TextStyle(
                          color: _whiteWithOpacity60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate800WithOpacity50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: _whiteWithOpacity70, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: _whiteWithOpacity40,
          ),
        ],
      ),
    );
  }
}
