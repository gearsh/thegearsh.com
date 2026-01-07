import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';
import 'package:gearsh_app/widgets/bottom_nav_bar.dart';
import 'package:gearsh_app/widgets/gearsh_background.dart';

class GigsPage extends ConsumerStatefulWidget {
  const GigsPage({super.key});

  @override
  ConsumerState<GigsPage> createState() => _GigsPageState();
}

class _GigsPageState extends ConsumerState<GigsPage> {
  // Theme colors
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _pink500 = Color(0xFFEC4899);
  static const Color _amber500 = Color(0xFFF59E0B);

  // Get all upcoming gigs from artists
  List<Map<String, dynamic>> get allUpcomingGigs {
    final List<Map<String, dynamic>> gigs = [];
    for (final artist in gearshArtists) {
      for (final gig in artist.upcomingGigs) {
        gigs.add({
          ...gig,
          'artistName': artist.name,
          'artistImage': artist.image,
          'artistId': artist.id,
          'isVerified': artist.isVerified,
        });
      }
    }
    // Sort by date
    gigs.sort((a, b) => a['date'].compareTo(b['date']));
    return gigs;
  }

  @override
  Widget build(BuildContext context) {
    final gigs = allUpcomingGigs;

    return GearshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: _slate900.withAlpha(230),
          elevation: 0,
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_sky400, _cyan500],
            ).createShader(bounds),
            child: const Text(
              'Upcoming Gigs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {
                // TODO: Add filter functionality
              },
            ),
          ],
        ),
        body: gigs.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: gigs.length,
                itemBuilder: (context, index) {
                  return _buildGigCard(gigs[index]);
                },
              ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _slate800,
              shape: BoxShape.circle,
              border: Border.all(color: _sky500.withAlpha(51), width: 1),
            ),
            child: const Icon(
              Icons.event_busy,
              size: 48,
              color: _sky400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Upcoming Gigs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for new events!',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGigCard(Map<String, dynamic> gig) {
    final date = DateTime.parse(gig['date']);
    final month = _getMonthName(date.month);
    final day = date.day.toString();

    return GestureDetector(
      onTap: () => _showGigDetails(gig),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _slate800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _sky500.withAlpha(51), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date badge
            Stack(
              children: [
                // Artist image banner
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_sky500.withAlpha(77), _cyan500.withAlpha(51)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      // Artist image
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(gig['artistImage']),
                        onBackgroundImageError: (_, __) {},
                        child: const Icon(Icons.person, color: Colors.white54),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    gig['artistName'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (gig['isVerified'] == true)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: _sky500,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              gig['name'],
                              style: TextStyle(
                                color: Colors.white.withAlpha(179),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Date badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _pink500,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _pink500.withAlpha(102),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          month,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue
                  Row(
                    children: [
                      Icon(Icons.location_on, color: _sky400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gig['venue'],
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Time
                  Row(
                    children: [
                      Icon(Icons.access_time, color: _sky400, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        gig['time'],
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Ticket prices and button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From R${gig['ticketPrice'].toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: _amber500,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'VIP: R${gig['vipPrice'].toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Get Tickets button
                      GestureDetector(
                        onTap: () => _showGigDetails(gig),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _sky500.withAlpha(77),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.confirmation_number, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              const Text(
                                'Get Tickets',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  void _showGigDetails(Map<String, dynamic> gig) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _slate900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _sky500.withAlpha(51), width: 1),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event name
                    Text(
                      gig['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Artist
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/artist/${gig['artistId']}');
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(gig['artistImage']),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            gig['artistName'],
                            style: const TextStyle(
                              color: _sky400,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (gig['isVerified'] == true)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: _sky500,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 10),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Details
                    _buildDetailRow(Icons.calendar_today, 'Date', _formatDate(gig['date'])),
                    _buildDetailRow(Icons.access_time, 'Time', gig['time']),
                    _buildDetailRow(Icons.location_on, 'Venue', gig['venue']),
                    const SizedBox(height: 24),
                    // Ticket options
                    const Text(
                      'Select Tickets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Standard ticket
                    _buildTicketOption(
                      'Standard',
                      'General admission',
                      gig['ticketPrice'],
                      false,
                    ),
                    const SizedBox(height: 12),
                    // VIP ticket
                    _buildTicketOption(
                      'VIP',
                      'Priority access, meet & greet',
                      gig['vipPrice'],
                      true,
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _slate800,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _sky400, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketOption(String title, String description, double price, bool isVip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVip ? _amber500.withAlpha(128) : _sky500.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isVip ? _amber500.withAlpha(51) : _sky500.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isVip ? Icons.star : Icons.confirmation_number,
              color: isVip ? _amber500 : _sky400,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R${price.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isVip ? _amber500 : _sky400,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Implement ticket purchase
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title ticket added to cart!'),
                      backgroundColor: _sky500,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isVip
                          ? [_amber500, const Color(0xFFFBBF24)]
                          : [_sky500, _cyan500],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Buy',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day} ${_getMonthName(date.month)} ${date.year}';
  }
}

