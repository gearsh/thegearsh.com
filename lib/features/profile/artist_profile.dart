import 'package:flutter/material.dart';
import '../booking/booking_flow_page.dart';

class ArtistProfile extends StatefulWidget {
  final String artistId;
  final VoidCallback onBack;
  final void Function(String) onBook;

  const ArtistProfile({
    super.key,
    required this.artistId,
    required this.onBack,
    required this.onBook,
  });

  @override
  State<ArtistProfile> createState() => _ArtistProfileState();
}

class _ArtistProfileState extends State<ArtistProfile> {
  String _activeTab = 'services';
  String? _selectedServiceId;

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  // Mock artist data based on ID
  Map<String, dynamic> get _artistData {
    final artists = {
      '1': {
        'name': 'A-Reece',
        'category': 'Hip Hop',
        'location': 'Pretoria, SA',
        'rating': 4.9,
        'reviewCount': 127,
        'headerImage': 'assets/images/artists/a-reece.png',
        'avatar': 'assets/images/artists/a-reece.png',
        'about': 'Award-winning Hip Hop artist known for lyrical prowess and authentic storytelling. With multiple platinum records, A-Reece delivers unforgettable live performances that captivate audiences.',
        'discography': [
          {'title': 'Paradise', 'type': 'Album', 'year': '2018', 'tracks': 14, 'image': 'assets/images/artists/a-reece.png'},
          {'title': 'Reece Effect', 'type': 'Album', 'year': '2017', 'tracks': 12, 'image': 'assets/images/artists/a-reece.png'},
          {'title': 'From Me to You & Only You', 'type': 'Album', 'year': '2016', 'tracks': 16, 'image': 'assets/images/artists/a-reece.png'},
          {'title': 'Today\'s Tragedy, Tomorrow\'s Memory', 'type': 'EP', 'year': '2021', 'tracks': 7, 'image': 'assets/images/artists/a-reece.png'},
          {'title': 'Couldn\'t Have Said It Better, Pt. 3', 'type': 'Single', 'year': '2020', 'tracks': 1, 'image': 'assets/images/artists/a-reece.png'},
          {'title': 'MeanWhile in Honeydew', 'type': 'Single', 'year': '2019', 'tracks': 1, 'image': 'assets/images/artists/a-reece.png'},
        ],
        'services': [
          {'id': 's1', 'name': 'Live Performance (2 hours)', 'price': 15000.0, 'description': 'Full live performance with DJ support'},
          {'id': 's2', 'name': 'Festival Set (1 hour)', 'price': 25000.0, 'description': 'High-energy festival performance'},
          {'id': 's3', 'name': 'Private Event', 'price': 35000.0, 'description': 'Exclusive private event performance'},
        ],
      },
      '2': {
        'name': 'Nasty C',
        'category': 'Rap',
        'location': 'Durban, SA',
        'rating': 5.0,
        'reviewCount': 156,
        'headerImage': 'assets/images/artists/nasty c.png',
        'avatar': 'assets/images/artists/nasty c.png',
        'about': 'International rap sensation with a global fanbase. Known for chart-topping hits and electrifying stage presence. Nasty C brings world-class entertainment to every event.',
        'discography': [
          {'title': 'Zulu Man With Some Power', 'type': 'Album', 'year': '2020', 'tracks': 21, 'image': 'assets/images/artists/nasty c.png'},
          {'title': 'Strings and Bling', 'type': 'Album', 'year': '2018', 'tracks': 15, 'image': 'assets/images/artists/nasty c.png'},
          {'title': 'Bad Hair', 'type': 'Album', 'year': '2016', 'tracks': 14, 'image': 'assets/images/artists/nasty c.png'},
          {'title': 'I Love It Here', 'type': 'Album', 'year': '2023', 'tracks': 16, 'image': 'assets/images/artists/nasty c.png'},
          {'title': 'There They Go', 'type': 'Single', 'year': '2019', 'tracks': 1, 'image': 'assets/images/artists/nasty c.png'},
          {'title': 'Black and White', 'type': 'Single', 'year': '2020', 'tracks': 1, 'image': 'assets/images/artists/nasty c.png'},
        ],
        'services': [
          {'id': 's1', 'name': 'Live Performance (2 hours)', 'price': 20000.0, 'description': 'Full live performance with band'},
          {'id': 's2', 'name': 'Festival Headline', 'price': 40000.0, 'description': 'Headline festival performance'},
          {'id': 's3', 'name': 'Corporate Event', 'price': 30000.0, 'description': 'Professional corporate entertainment'},
        ],
      },
      '3': {
        'name': 'Emtee',
        'category': 'Hip Hop',
        'location': 'Johannesburg, SA',
        'rating': 4.8,
        'reviewCount': 98,
        'headerImage': 'assets/images/artists/emtee.webp',
        'avatar': 'assets/images/artists/emtee.webp',
        'about': 'Multi-platinum artist known for trap-influenced sound and hit singles. Emtee brings raw energy and authentic vibes to every performance.',
        'discography': [
          {'title': 'Avery', 'type': 'Album', 'year': '2017', 'tracks': 18, 'image': 'assets/images/artists/emtee.webp'},
          {'title': 'Manando', 'type': 'Album', 'year': '2017', 'tracks': 16, 'image': 'assets/images/artists/emtee.webp'},
          {'title': 'DIY 3', 'type': 'Album', 'year': '2021', 'tracks': 14, 'image': 'assets/images/artists/emtee.webp'},
          {'title': 'Logan', 'type': 'Album', 'year': '2022', 'tracks': 12, 'image': 'assets/images/artists/emtee.webp'},
          {'title': 'Roll Up', 'type': 'Single', 'year': '2015', 'tracks': 1, 'image': 'assets/images/artists/emtee.webp'},
          {'title': 'Pearl Thusi', 'type': 'Single', 'year': '2016', 'tracks': 1, 'image': 'assets/images/artists/emtee.webp'},
        ],
        'services': [
          {'id': 's1', 'name': 'Club Performance', 'price': 12000.0, 'description': 'High-energy club set'},
          {'id': 's2', 'name': 'Festival Set', 'price': 18000.0, 'description': 'Festival stage performance'},
          {'id': 's3', 'name': 'Private Party', 'price': 25000.0, 'description': 'Exclusive private party performance'},
        ],
      },
    };

    return artists[widget.artistId] ?? {
      'name': 'Artist',
      'category': 'Music',
      'location': 'South Africa',
      'rating': 4.5,
      'reviewCount': 50,
      'headerImage': 'assets/images/gearsh_logo.png',
      'avatar': 'assets/images/gearsh_logo.png',
      'about': 'Professional artist available for bookings.',
      'discography': [],
      'services': [
        {'id': 's1', 'name': 'Standard Performance', 'price': 5000.0, 'description': 'Standard performance package'},
      ],
    };
  }

  final List<Map<String, String>> _tabs = [
    {'id': 'services', 'label': 'Services'},
    {'id': 'discography', 'label': 'Discography'},
    {'id': 'about', 'label': 'About'},
    {'id': 'reviews', 'label': 'Reviews'},
  ];

  Map<String, dynamic>? get _selectedService {
    if (_selectedServiceId == null) return null;
    final services = _artistData['services'] as List<dynamic>;
    try {
      return services.firstWhere((s) => s['id'] == _selectedServiceId) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  void _startBooking() {
    if (_selectedService != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingFlowPage(
            artistId: widget.artistId,
            artistName: _artistData['name'],
            serviceName: _selectedService!['name'],
            servicePrice: _selectedService!['price'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final data = _artistData;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              child: Column(
                children: [
                  // Header image
                  Stack(
                    children: [
                      // Header image
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: Image.asset(
                          data['headerImage'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _slate800,
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: _sky500,
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                _slate950.withAlpha(102),
                                _slate950,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Top bar
                      Positioned(
                        top: padding.top + 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildIconButton(
                              Icons.arrow_back_rounded,
                              onTap: widget.onBack,
                            ),
                            Row(
                              children: [
                                _buildIconButton(Icons.share_rounded, onTap: () {}),
                                const SizedBox(width: 8),
                                _buildIconButton(Icons.favorite_border_rounded, onTap: () {}),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Artist info overlay
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _slate950, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(77),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  data['avatar'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: _slate800,
                                    child: const Icon(
                                      Icons.person,
                                      color: _sky500,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      Text(
                                        data['category'],
                                        style: const TextStyle(
                                          color: _sky400,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Color(0xFFFACC15), size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${data['rating']}',
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                          Text(
                                            ' (${data['reviewCount']})',
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(153),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.location_on_outlined, color: Colors.white.withAlpha(179), size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            data['location'],
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(179),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: _slate950.withAlpha(242),
                      border: Border(
                        bottom: BorderSide(color: _sky500.withAlpha(51)),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: _tabs.map((tab) {
                          final isActive = _activeTab == tab['id'];
                          return GestureDetector(
                            onTap: () => setState(() => _activeTab = tab['id']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isActive ? _sky500 : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                tab['label']!,
                                style: TextStyle(
                                  color: isActive ? _sky400 : Colors.white.withAlpha(153),
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Tab content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTabContent(),
                  ),

                  // Bottom padding for sticky bar
                  SizedBox(height: _selectedServiceId != null ? 140 : 20),
                ],
              ),
            ),

            // Sticky bottom bar (only shows when service selected)
            if (_selectedServiceId != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: _slate950.withAlpha(242),
                    border: Border(
                      top: BorderSide(color: _sky500.withAlpha(77)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _sky500.withAlpha(51),
                        blurRadius: 30,
                        spreadRadius: 0,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white.withAlpha(153),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'R${_selectedService!['price'].toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _startBooking,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_sky500, _cyan500],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _sky500.withAlpha(102),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Request Booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _slate950.withAlpha(204),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _sky500.withAlpha(77)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'services':
        return _buildServicesTab();
      case 'discography':
        return _buildDiscographyTab();
      case 'about':
        return _buildAboutTab();
      case 'reviews':
        return _buildReviewsTab();
      default:
        return _buildServicesTab();
    }
  }

  Widget _buildServicesTab() {
    final services = _artistData['services'] as List;
    return Column(
      children: services.map((service) {
        final isSelected = _selectedServiceId == service['id'];
        return GestureDetector(
          onTap: () => setState(() {
            _selectedServiceId = isSelected ? null : service['id'];
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? _sky500.withAlpha(25) : _slate900.withAlpha(102),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _sky500 : _sky500.withAlpha(51),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _sky500.withAlpha(51),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service['description'],
                            style: TextStyle(
                              color: Colors.white.withAlpha(153),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'R${service['price'].toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: _sky400,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _sky500.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _sky400,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _sky400.withAlpha(204),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Selected',
                          style: TextStyle(
                            color: _sky400,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiscographyTab() {
    final discography = _artistData['discography'] as List<dynamic>? ?? [];

    if (discography.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.album_outlined,
              color: Colors.white.withAlpha(77),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No discography available',
              style: TextStyle(
                color: Colors.white.withAlpha(128),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Group by type
    final albums = discography.where((d) => d['type'] == 'Album').toList();
    final eps = discography.where((d) => d['type'] == 'EP').toList();
    final singles = discography.where((d) => d['type'] == 'Single').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Albums section
        if (albums.isNotEmpty) ...[
          _buildDiscographySection('Albums', albums),
          const SizedBox(height: 24),
        ],
        // EPs section
        if (eps.isNotEmpty) ...[
          _buildDiscographySection('EPs', eps),
          const SizedBox(height: 24),
        ],
        // Singles section
        if (singles.isNotEmpty) ...[
          _buildDiscographySection('Singles', singles),
        ],
      ],
    );
  }

  Widget _buildDiscographySection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              title == 'Albums'
                  ? Icons.album_rounded
                  : title == 'EPs'
                      ? Icons.library_music_rounded
                      : Icons.music_note_rounded,
              color: _sky400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _sky500.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  color: _sky400,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildDiscographyItem(item as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildDiscographyItem(Map<String, dynamic> item) {
    final isAlbum = item['type'] == 'Album';
    final isEP = item['type'] == 'EP';

    return GestureDetector(
      onTap: () => _showAlbumDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _slate900.withAlpha(102),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _sky500.withAlpha(51)),
        ),
        child: Row(
          children: [
            // Album art
            Container(
              width: isAlbum ? 72 : 60,
              height: isAlbum ? 72 : 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _sky500.withAlpha(77)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      item['image'] ?? _artistData['avatar'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _slate800,
                        child: Icon(
                          Icons.album,
                          color: _sky500.withAlpha(128),
                          size: 32,
                        ),
                      ),
                    ),
                    // Vinyl effect for albums
                    if (isAlbum)
                      Positioned(
                        right: -8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.black87,
                                  Colors.black54,
                                  Colors.grey.shade800,
                                ],
                              ),
                              border: Border.all(color: Colors.grey.shade600, width: 0.5),
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Untitled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAlbum
                              ? _sky500.withAlpha(38)
                              : isEP
                                  ? const Color(0xFF8B5CF6).withAlpha(38)
                                  : const Color(0xFF10B981).withAlpha(38),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAlbum
                                ? _sky500.withAlpha(77)
                                : isEP
                                    ? const Color(0xFF8B5CF6).withAlpha(77)
                                    : const Color(0xFF10B981).withAlpha(77),
                          ),
                        ),
                        child: Text(
                          item['type'] ?? 'Album',
                          style: TextStyle(
                            color: isAlbum
                                ? _sky400
                                : isEP
                                    ? const Color(0xFFA78BFA)
                                    : const Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['year'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withAlpha(128),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.queue_music_rounded,
                        color: Colors.white.withAlpha(102),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['tracks'] ?? 0} ${(item['tracks'] ?? 0) == 1 ? 'track' : 'tracks'}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(128),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Play button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_sky500, Color(0xFF06B6D4)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _sky500.withAlpha(77),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlbumDetails(Map<String, dynamic> album) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _slate900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _sky500.withAlpha(51)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large album art
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _sky500.withAlpha(77)),
                            boxShadow: [
                              BoxShadow(
                                color: _sky500.withAlpha(51),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              album['image'] ?? _artistData['avatar'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: _slate800,
                                child: const Icon(
                                  Icons.album,
                                  color: _sky500,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _artistData['name'],
                                style: const TextStyle(
                                  color: _sky400,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildAlbumInfoChip(album['type'] ?? 'Album'),
                                  const SizedBox(width: 8),
                                  _buildAlbumInfoChip(album['year'] ?? ''),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${album['tracks'] ?? 0} tracks',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(128),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Play button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_sky500, Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _sky500.withAlpha(77),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Play Album',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Track list preview
                    Text(
                      'Track List',
                      style: TextStyle(
                        color: Colors.white.withAlpha(179),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Generate mock tracks
                    ...List.generate(
                      (album['tracks'] as int?) ?? 0,
                      (index) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: _sky500.withAlpha(25)),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(102),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Track ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              '${3 + (index % 2)}:${(index * 17 % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(102),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).take(5),
                    if ((album['tracks'] as int?) != null && (album['tracks'] as int) > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          '+ ${(album['tracks'] as int) - 5} more tracks',
                          style: TextStyle(
                            color: _sky400.withAlpha(179),
                            fontSize: 14,
                          ),
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

  Widget _buildAlbumInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _sky500.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _sky500.withAlpha(77)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _sky400,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _slate900.withAlpha(102),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${_artistData['name']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _artistData['about'],
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    // Mock reviews
    final reviews = [
      {'name': 'Sarah M.', 'rating': 5, 'text': 'Amazing performance! The crowd loved every moment.', 'date': '2 weeks ago'},
      {'name': 'John K.', 'rating': 5, 'text': 'Professional and talented. Highly recommend!', 'date': '1 month ago'},
      {'name': 'Lisa T.', 'rating': 4, 'text': 'Great energy, perfect for our event.', 'date': '2 months ago'},
    ];

    return Column(
      children: reviews.map((review) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _slate900.withAlpha(102),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _sky500.withAlpha(51)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            Icons.star,
                            size: 14,
                            color: i < (review['rating'] as int)
                                ? const Color(0xFFFACC15)
                                : _slate800,
                          );
                        }),
                      ),
                    ],
                  ),
                  Text(
                    review['date'] as String,
                    style: TextStyle(
                      color: Colors.white.withAlpha(102),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                review['text'] as String,
                style: TextStyle(
                  color: Colors.white.withAlpha(179),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

