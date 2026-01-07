import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SavedArtistsPage extends ConsumerStatefulWidget {
  const SavedArtistsPage({super.key});

  @override
  ConsumerState<SavedArtistsPage> createState() => _SavedArtistsPageState();
}

class _SavedArtistsPageState extends ConsumerState<SavedArtistsPage> {
  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _yellow500 = Color(0xFFEAB308);
  static const Color _red500 = Color(0xFFEF4444);

  // Mock saved artists data - Replace with actual API data
  final List<Map<String, dynamic>> _savedArtists = [
    {
      'id': '1',
      'name': 'DJ Maphorisa',
      'image': 'assets/images/artists/kunye.png',
      'category': 'DJ',
      'rating': 4.9,
      'reviews': 156,
      'price': 700,
      'location': 'Johannesburg, SA',
      'isAvailable': true,
    },
    {
      'id': '2',
      'name': 'Kabza De Small',
      'image': 'assets/images/artists/P9-Kabza-de-Small.webp',
      'category': 'DJ',
      'rating': 4.9,
      'reviews': 203,
      'price': 800,
      'location': 'Pretoria, SA',
      'isAvailable': true,
    },
    {
      'id': '3',
      'name': 'Cassper Nyovest',
      'image': 'assets/images/artists/Cassper Nyovest Fill Up FNB Station 1.jpg',
      'category': 'Hip Hop',
      'rating': 4.8,
      'reviews': 178,
      'price': 1500,
      'location': 'Johannesburg, SA',
      'isAvailable': false,
    },
    {
      'id': '4',
      'name': 'Kendrick Lamar',
      'image': 'assets/images/artists/kendrick.png',
      'category': 'Rap',
      'rating': 5.0,
      'reviews': 320,
      'price': 5000,
      'location': 'Compton, USA',
      'isAvailable': true,
    },
  ];

  void _removeArtist(Map<String, dynamic> artist) {
    setState(() {
      _savedArtists.removeWhere((a) => a['id'] == artist['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${artist['name']} removed from saved'),
        backgroundColor: _slate800,
        action: SnackBarAction(
          label: 'Undo',
          textColor: _sky400,
          onPressed: () {
            setState(() {
              _savedArtists.add(artist);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: padding.top + 16,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: _slate950.withAlpha(242),
                border: Border(
                  bottom: BorderSide(color: _sky500.withAlpha(51)),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      try {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/profile-settings');
                        }
                      } catch (e) {
                        context.go('/profile-settings');
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _slate900.withAlpha(128),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _sky500.withAlpha(77)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved Artists',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_savedArtists.isNotEmpty)
                          Text(
                            '${_savedArtists.length} artists',
                            style: TextStyle(
                              color: Colors.white.withAlpha(128),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _savedArtists.isEmpty
                  ? _buildEmptyState()
                  : _buildArtistsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _slate800.withAlpha(128),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline,
                color: _slate400,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Saved Artists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the heart icon on any artist to save them here for quick access',
              style: TextStyle(
                color: Colors.white.withAlpha(128),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Discover Artists',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
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

  Widget _buildArtistsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _savedArtists.length,
      itemBuilder: (context, index) => _buildArtistCard(_savedArtists[index]),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist) {
    final isAvailable = artist['isAvailable'] as bool;

    return Dismissible(
      key: Key(artist['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _red500.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: _red500, size: 28),
            SizedBox(height: 4),
            Text(
              'Remove',
              style: TextStyle(color: _red500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      onDismissed: (_) => _removeArtist(artist),
      child: GestureDetector(
        onTap: () => context.go('/artist/${artist['id']}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _slate800.withAlpha(128),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _sky500.withAlpha(51)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Artist image
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _sky500.withAlpha(77)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              artist['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: _slate900,
                                child: const Icon(Icons.person, color: _sky400, size: 36),
                              ),
                            ),
                          ),
                        ),
                        // Availability indicator
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isAvailable ? const Color(0xFF22C55E) : _slate400,
                              shape: BoxShape.circle,
                              border: Border.all(color: _slate800, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Artist info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  artist['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Favorite button
                              GestureDetector(
                                onTap: () => _showRemoveDialog(artist),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _red500.withAlpha(51),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: _red500,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Category & Location
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _sky500.withAlpha(51),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  artist['category'],
                                  style: const TextStyle(
                                    color: _sky400,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.white.withAlpha(128),
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  artist['location'],
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(128),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Rating and Price
                          Row(
                            children: [
                              // Rating
                              Row(
                                children: [
                                  const Icon(Icons.star, color: _yellow500, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${artist['rating']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    ' (${artist['reviews']})',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(128),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Price
                              Text(
                                'From ',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(128),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'R${artist['price']}',
                                style: const TextStyle(
                                  color: _sky400,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _slate900.withAlpha(128),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/artist/${artist['id']}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _slate800,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _sky500.withAlpha(77)),
                          ),
                          child: const Center(
                            child: Text(
                              'View Profile',
                              style: TextStyle(
                                color: _sky400,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: isAvailable
                          ? () => context.go('/booking-flow/${artist['id']}')
                          : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isAvailable
                              ? const LinearGradient(colors: [_sky500, _cyan500])
                              : null,
                            color: isAvailable ? null : _slate800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              isAvailable ? 'Book Now' : 'Unavailable',
                              style: TextStyle(
                                color: isAvailable ? Colors.white : _slate400,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(Map<String, dynamic> artist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _sky500.withAlpha(51)),
        ),
        title: const Text(
          'Remove from Saved?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove ${artist['name']} from your saved artists?',
          style: TextStyle(color: Colors.white.withAlpha(179)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withAlpha(153)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeArtist(artist);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: _red500, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

