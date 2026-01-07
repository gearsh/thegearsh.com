import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyBookingsPage extends ConsumerStatefulWidget {
  const MyBookingsPage({super.key});

  @override
  ConsumerState<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends ConsumerState<MyBookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _green500 = Color(0xFF22C55E);
  static const Color _yellow500 = Color(0xFFEAB308);
  static const Color _red500 = Color(0xFFEF4444);
  static const Color _purple500 = Color(0xFF8B5CF6);

  // Mock bookings data - Replace with actual API data
  final List<Map<String, dynamic>> _upcomingBookings = [
    {
      'id': 'b1',
      'artistName': 'DJ Maphorisa',
      'artistImage': 'assets/images/artists/kunye.png',
      'service': 'Club Night (4 hours)',
      'date': 'Dec 28, 2025',
      'time': '8:00 PM',
      'location': 'Zone 6 Venue, Soweto',
      'price': 700,
      'status': 'confirmed',
    },
    {
      'id': 'b2',
      'artistName': 'Kabza De Small',
      'artistImage': 'assets/images/artists/P9-Kabza-de-Small.webp',
      'service': 'Private Party (3 hours)',
      'date': 'Jan 5, 2026',
      'time': '6:00 PM',
      'location': 'Sandton City, Johannesburg',
      'price': 600,
      'status': 'pending',
    },
  ];

  final List<Map<String, dynamic>> _pastBookings = [
    {
      'id': 'b3',
      'artistName': 'Cassper Nyovest',
      'artistImage': 'assets/images/artists/Cassper Nyovest Fill Up FNB Station 1.jpg',
      'service': 'Concert Performance',
      'date': 'Nov 15, 2025',
      'time': '7:00 PM',
      'location': 'FNB Stadium, Johannesburg',
      'price': 1500,
      'status': 'completed',
      'rating': 5,
    },
    {
      'id': 'b4',
      'artistName': 'Nota Baloyi',
      'artistImage': 'assets/images/artists/NOTA.png',
      'service': 'Event Hosting',
      'date': 'Oct 20, 2025',
      'time': '2:00 PM',
      'location': 'Constitution Hill, Johannesburg',
      'price': 350,
      'status': 'completed',
      'rating': 4,
    },
    {
      'id': 'b5',
      'artistName': 'The Game',
      'artistImage': 'assets/images/artists/game.png',
      'service': 'Private Show',
      'date': 'Sep 10, 2025',
      'time': '9:00 PM',
      'location': 'Private Venue',
      'price': 2000,
      'status': 'cancelled',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return _green500;
      case 'pending':
        return _yellow500;
      case 'completed':
        return _purple500;
      case 'cancelled':
        return _red500;
      default:
        return _slate400;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
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
              child: Column(
                children: [
                  Row(
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
                      const Text(
                        'My Bookings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: _slate800.withAlpha(128),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: _slate400,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.upcoming_outlined, size: 18),
                              const SizedBox(width: 8),
                              const Text('Upcoming'),
                              if (_upcomingBookings.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _sky500,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_upcomingBookings.length}',
                                    style: const TextStyle(fontSize: 11, color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history, size: 18),
                              const SizedBox(width: 8),
                              const Text('Past'),
                            ],
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
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Upcoming Bookings Tab
                  _buildBookingsList(_upcomingBookings, isUpcoming: true),
                  // Past Bookings Tab
                  _buildBookingsList(_pastBookings, isUpcoming: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings, {required bool isUpcoming}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today_outlined : Icons.history,
              color: _slate400,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming bookings' : 'No past bookings',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming
                ? 'Book an artist to see your upcoming events here'
                : 'Your booking history will appear here',
              style: TextStyle(
                color: Colors.white.withAlpha(128),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Browse Artists',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _buildBookingCard(bookings[index], isUpcoming: isUpcoming),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, {required bool isUpcoming}) {
    final status = booking['status'] as String;
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _slate800.withAlpha(128),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artist info row
                Row(
                  children: [
                    // Artist image
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _sky500.withAlpha(77)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          booking['artistImage'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _slate900,
                            child: const Icon(Icons.person, color: _sky400, size: 28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Artist name and service
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking['artistName'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking['service'],
                            style: TextStyle(
                              color: Colors.white.withAlpha(153),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withAlpha(128)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(status), color: statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Divider
                Container(
                  height: 1,
                  color: _sky500.withAlpha(51),
                ),
                const SizedBox(height: 16),
                // Date, Time, Location row
                Row(
                  children: [
                    _buildInfoChip(Icons.calendar_today_outlined, booking['date']),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.access_time, booking['time']),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInfoChip(Icons.location_on_outlined, booking['location'], expanded: true),
                const SizedBox(height: 16),
                // Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'R${booking['price']}',
                      style: const TextStyle(
                        color: _sky400,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Rating (for completed bookings)
                if (status == 'completed' && booking['rating'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Your Rating:',
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(5, (i) => Icon(
                        i < (booking['rating'] as int) ? Icons.star : Icons.star_border,
                        color: _yellow500,
                        size: 18,
                      )),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Action buttons
          if (isUpcoming && status != 'cancelled')
            Container(
              padding: const EdgeInsets.all(16),
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
                      onTap: () => _showCancelDialog(booking),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _red500.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _red500.withAlpha(128)),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: _red500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _contactArtist(booking),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Message',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Rate button for completed bookings without rating
          if (!isUpcoming && status == 'completed' && booking['rating'] == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _slate900.withAlpha(128),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: GestureDetector(
                onTap: () => _showRatingDialog(booking),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Rate This Booking',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Book again for completed bookings
          if (!isUpcoming && status == 'completed')
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () => _bookAgain(booking),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _slate800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _sky500.withAlpha(77)),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.replay, color: _sky400, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Book Again',
                          style: TextStyle(
                            color: _sky400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {bool expanded = false}) {
    final widget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _slate900.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: _sky400, size: 14),
          const SizedBox(width: 6),
          expanded
            ? Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 13,
                ),
              ),
        ],
      ),
    );

    return expanded ? widget : widget;
  }

  void _showCancelDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _slate900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _sky500.withAlpha(51)),
        ),
        title: const Text(
          'Cancel Booking?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel your booking with ${booking['artistName']}?\n\nThis action cannot be undone.',
          style: TextStyle(color: Colors.white.withAlpha(179)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Booking',
              style: TextStyle(color: Colors.white.withAlpha(153)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement cancel API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled'),
                  backgroundColor: _red500,
                ),
              );
            },
            child: const Text(
              'Cancel Booking',
              style: TextStyle(color: _red500, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _contactArtist(Map<String, dynamic> booking) {
    // Navigate to messages with this artist
    context.go('/messages');
  }

  void _showRatingDialog(Map<String, dynamic> booking) {
    int selectedRating = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _slate900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _sky500.withAlpha(51)),
          ),
          title: const Text(
            'Rate Your Experience',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your experience with ${booking['artistName']}?',
                style: TextStyle(color: Colors.white.withAlpha(179)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setDialogState(() => selectedRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < selectedRating ? Icons.star : Icons.star_border,
                      color: _yellow500,
                      size: 36,
                    ),
                  ),
                )),
              ),
            ],
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
              onPressed: selectedRating > 0 ? () {
                Navigator.pop(ctx);
                // TODO: Implement rating API call
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thanks for your rating!'),
                    backgroundColor: _green500,
                  ),
                );
              } : null,
              child: Text(
                'Submit',
                style: TextStyle(
                  color: selectedRating > 0 ? _sky400 : _slate400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookAgain(Map<String, dynamic> booking) {
    // Navigate to booking flow with this artist
    // TODO: Get actual artist ID
    context.go('/home');
  }
}

