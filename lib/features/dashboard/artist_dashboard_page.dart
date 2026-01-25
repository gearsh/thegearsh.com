import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/global_config_service.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/data/gearsh_artists.dart';

class ArtistDashboardPage extends ConsumerStatefulWidget {
  const ArtistDashboardPage({super.key});

  @override
  ConsumerState<ArtistDashboardPage> createState() => _ArtistDashboardPageState();
}

class _ArtistDashboardPageState extends ConsumerState<ArtistDashboardPage> {
  String _activeTab = 'overview';

  // Color constants - Deep Sky Blue theme
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _green400 = Color(0xFF4ADE80);
  static const Color _yellow400 = Color(0xFFFACC15);
  static const Color _cyan400 = Color(0xFF22D3EE);

  final List<Map<String, String>> _tabs = [
    {'id': 'overview', 'label': 'Overview'},
    {'id': 'requests', 'label': 'Requests'},
    {'id': 'calendar', 'label': 'Calendar'},
    {'id': 'services', 'label': 'Services'},
  ];

  // Get artist data for the logged-in user
  GearshArtist? get _artistProfile {
    // Try to match by username or email
    final userName = userRoleService.userName.toLowerCase();
    final userEmail = userRoleService.userEmail.toLowerCase();

    for (final artist in gearshArtists) {
      final artistUsername = artist.username.replaceAll('@', '').toLowerCase();
      if (artistUsername == userName ||
          artistUsername == userEmail.split('@').first ||
          artist.name.toLowerCase() == userName) {
        return artist;
      }
    }
    return null;
  }

  // Demo booking requests (will be fetched from backend in production)
  List<Map<String, dynamic>> get _bookingRequests {
    final artist = _artistProfile;
    if (artist == null) {
      return [
        {
          'id': 'req1',
          'clientName': 'Thabo M.',
          'clientImage': 'assets/images/gearsh_logo.png',
          'service': 'Live Performance (1 hour)',
          'date': 'Jan 28, 2026',
          'time': '8:00 PM',
          'price': 2500,
          'status': 'pending',
        },
      ];
    }

    // Generate demo requests based on artist's services
    final services = artist.services;
    if (services.isEmpty) return [];

    return [
      {
        'id': 'req1',
        'clientName': 'Thabo M.',
        'clientImage': 'assets/images/gearsh_logo.png',
        'service': services.isNotEmpty ? services[0]['name'] : 'Booking',
        'date': 'Jan 28, 2026',
        'time': '8:00 PM',
        'price': services.isNotEmpty ? (services[0]['price'] as num).toInt() : artist.bookingFee,
        'status': 'pending',
      },
      {
        'id': 'req2',
        'clientName': 'Lerato K.',
        'clientImage': 'assets/images/gearsh_logo.png',
        'service': services.length > 1 ? services[1]['name'] : 'Booking',
        'date': 'Feb 5, 2026',
        'time': '6:00 PM',
        'price': services.length > 1 ? (services[1]['price'] as num).toInt() : artist.bookingFee,
        'status': 'pending',
      },
    ];
  }

  List<Map<String, dynamic>> get _upcomingEvents {
    final artist = _artistProfile;
    if (artist != null && artist.upcomingGigs.isNotEmpty) {
      return artist.upcomingGigs.map((gig) {
        final date = DateTime.tryParse(gig['date'] ?? '') ?? DateTime.now();
        return {
          'id': gig['title'],
          'date': date.day.toString(),
          'day': _getDayName(date.weekday),
          'month': _getMonthName(date.month),
          'event': gig['title'],
          'time': gig['time'] ?? 'TBA',
          'venue': gig['venue'],
        };
      }).toList();
    }

    return [
      {'id': 'e1', 'date': '28', 'day': 'Tue', 'month': 'Jan', 'event': 'Upcoming Booking', 'time': '8:00 PM'},
    ];
  }

  List<Map<String, dynamic>> get _services {
    final artist = _artistProfile;
    if (artist != null) {
      return artist.services.map((s) => {
        'id': s['id'],
        'name': s['name'],
        'price': (s['price'] as num).toInt(),
        'status': 'active',
      }).toList();
    }

    return [
      {'id': 's1', 'name': 'Standard Booking', 'price': 2500, 'status': 'active'},
    ];
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  // Get event days for calendar highlighting
  List<int> get _eventDays {
    return _upcomingEvents.map((e) {
      final dateStr = e['date'] as String?;
      return int.tryParse(dateStr ?? '') ?? 0;
    }).where((d) => d > 0).toList();
  }

  final List<Map<String, dynamic>> _recentActivity = [
    {'color': _green400, 'text': 'Profile created successfully!', 'time': 'Just now'},
    {'color': _cyan400, 'text': 'Welcome to Gearsh!', 'time': '1 min ago'},
  ];

  // Calendar state
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
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
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.only(
                    top: padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 0,
                  ),
                  decoration: BoxDecoration(
                    color: _slate950.withAlpha(242),
                    border: Border(
                      bottom: BorderSide(color: _sky500.withAlpha(51)),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Artist Profile Header
                      Row(
                        children: [
                          // Profile Avatar
                          GestureDetector(
                            onTap: () {
                              final artist = _artistProfile;
                              if (artist != null) {
                                context.go('/artist/${artist.id}');
                              }
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _sky500.withAlpha(128), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _sky500.withAlpha(51),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _artistProfile != null
                                    ? Image.asset(
                                        _artistProfile!.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(colors: [_sky500, _cyan500]),
                                          ),
                                          child: const Icon(Icons.person, color: Colors.white, size: 28),
                                        ),
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(colors: [_sky500, _cyan500]),
                                        ),
                                        child: const Icon(Icons.person, color: Colors.white, size: 28),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _artistProfile?.name ?? userRoleService.userName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_artistProfile?.isVerified == true) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: _sky500,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _artistProfile?.username ?? '@${userRoleService.userEmail.split('@').first}',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(153),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Mastery Badge
                          if (_artistProfile != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_sky500.withAlpha(51), _cyan500.withAlpha(51)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _sky500.withAlpha(77)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _artistProfile!.masteryInfo.icon,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _artistProfile!.masteryInfo.title,
                                    style: const TextStyle(
                                      color: _sky400,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          // Twitter Import button (admin only - for @gearsh)
                          if (userRoleService.userEmail.contains('gearsh') ||
                              _artistProfile?.username == '@gearsh')
                            GestureDetector(
                              onTap: () => context.go('/admin/import-twitter'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DA1F2).withAlpha(26),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF1DA1F2).withAlpha(77)),
                                ),
                                child: const Icon(
                                  Icons.people_alt_outlined,
                                  color: Color(0xFF1DA1F2),
                                  size: 20,
                                ),
                              ),
                            ),
                          if (userRoleService.userEmail.contains('gearsh') ||
                              _artistProfile?.username == '@gearsh')
                            const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.go('/profile-settings'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _slate900.withAlpha(128),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _sky500.withAlpha(77)),
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _tabs.map((tab) {
                            final isActive = _activeTab == tab['id'];
                            return GestureDetector(
                              onTap: () => setState(() => _activeTab = tab['id']!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
            // Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNav(padding),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(EdgeInsets padding) {
    return Container(
      height: 80 + padding.bottom,
      padding: EdgeInsets.only(bottom: padding.bottom),
      decoration: BoxDecoration(
        color: _slate950.withAlpha(242),
        border: Border(
          top: BorderSide(color: _sky500.withAlpha(51)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_outlined, 'Dashboard', true, () {}),
          _buildNavItem(Icons.message_outlined, 'Messages', false, () => context.go('/messages')),
          _buildNavItem(Icons.calendar_today_outlined, 'Calendar', false, () {}),
          _buildNavItem(Icons.person_outline, 'Profile', false, () => context.go('/profile-settings')),
          _buildNavItem(Icons.verified_user_outlined, 'Verification', false, () => context.go('/dashboard/verification')),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? _sky400 : Colors.white.withAlpha(102),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _sky400 : Colors.white.withAlpha(102),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha(179),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'overview':
        return _buildOverviewTab();
      case 'requests':
        return _buildRequestsTab();
      case 'calendar':
        return _buildCalendarTab();
      case 'services':
        return _buildServicesTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final artist = _artistProfile;

    // Calculate stats based on artist profile
    final hoursBooked = artist?.hoursBooked ?? 0;
    final pendingRequests = _bookingRequests.where((r) => r['status'] == 'pending').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mastery Progress Card (if artist exists)
        if (artist != null) ...[
          _buildMasteryProgressCard(artist),
          const SizedBox(height: 16),
        ],

        // Earnings Stats - Use Flexible layout for small screens
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 320) {
              // Stack vertically on very small screens
              return Column(
                children: [
                  _buildStatCard(
                    icon: Icons.access_time_filled_rounded,
                    label: 'Hours Booked',
                    value: hoursBooked.toString(),
                    trend: artist?.masteryInfo.title ?? 'Newcomer',
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.star_rounded,
                    label: 'Rating',
                    value: artist?.rating.toStringAsFixed(1) ?? '0.0',
                    trend: '${artist?.reviewCount ?? 0} reviews',
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: _buildStatCard(
                  icon: Icons.access_time_filled_rounded,
                  label: 'Hours Booked',
                  value: hoursBooked.toString(),
                  trend: artist?.masteryInfo.title ?? 'Newcomer',
                )),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard(
                  icon: Icons.star_rounded,
                  label: 'Rating',
                  value: artist?.rating.toStringAsFixed(1) ?? '0.0',
                  trend: '${artist?.reviewCount ?? 0} reviews',
                )),
              ],
            );
          },
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),

        // Quick Stats - Wrap for small screens
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: (screenWidth - 56) / 3,
              child: _buildQuickStat(
                icon: Icons.access_time_rounded,
                iconColor: _yellow400,
                value: pendingRequests.toString(),
                label: 'Pending',
              ),
            ),
            SizedBox(
              width: (screenWidth - 56) / 3,
              child: _buildQuickStat(
                icon: Icons.check_circle_outline_rounded,
                iconColor: _green400,
                value: _services.length.toString(),
                label: 'Services',
              ),
            ),
            SizedBox(
              width: (screenWidth - 56) / 3,
              child: _buildQuickStat(
                icon: Icons.attach_money_rounded,
                iconColor: _cyan400,
                value: globalConfigService.formatPrice((artist?.bookingFee ?? 0).toDouble()),
                label: 'Base Rate',
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 16 : 24),

        // Upcoming Events
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_upcomingEvents.isEmpty)
              Text(
                'No events yet',
                style: TextStyle(
                  color: Colors.white.withAlpha(102),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_upcomingEvents.isEmpty)
          _buildEmptyState('No upcoming events', 'Your bookings will appear here')
        else
          ..._upcomingEvents.map((event) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildEventCard(event),
          )),
        SizedBox(height: isSmallScreen ? 12 : 16),

        // Recent Activity
        Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildActivityCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String trend,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _sky500.withAlpha(51),
            _cyan500.withAlpha(51),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(color: _sky500.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _sky400, size: isSmallScreen ? 16 : 18),
              SizedBox(width: isSmallScreen ? 4 : 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withAlpha(153),
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 22 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: _green400, size: isSmallScreen ? 12 : 14),
              SizedBox(width: isSmallScreen ? 2 : 4),
              Text(
                trend,
                style: TextStyle(
                  color: _green400,
                  fontSize: isSmallScreen ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _slate900.withAlpha(102),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(153),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryProgressCard(GearshArtist artist) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _sky500.withAlpha(26),
            _cyan500.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                artist.masteryInfo.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '10,000 Hours Mastery',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${artist.hoursBooked.toStringAsFixed(0)} / 10,000 hours',
                      style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  artist.masteryInfo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: artist.masteryProgress,
              backgroundColor: _slate800,
              valueColor: const AlwaysStoppedAnimation<Color>(_sky500),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artist.isMaster
                ? '🏆 You have achieved LEGEND status!'
                : '${artist.hoursToMastery} hours to reach Legend status',
            style: TextStyle(
              color: artist.isMaster ? _yellow400 : Colors.white.withAlpha(128),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _slate900.withAlpha(77),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(26)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            color: Colors.white.withAlpha(77),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withAlpha(153),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withAlpha(102),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate900.withAlpha(102),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_sky500.withAlpha(51), _cyan500.withAlpha(51)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _sky500.withAlpha(77)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event['date'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  event['month'],
                  style: const TextStyle(
                    color: _sky400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['event'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event['day']} • ${event['time']}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(153),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate900.withAlpha(102),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Column(
        children: _recentActivity.map((activity) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: activity != _recentActivity.last ? 14 : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: activity['color'] as Color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (activity['color'] as Color).withAlpha(204),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['text'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity['time'] as String,
                        style: TextStyle(
                          color: Colors.white.withAlpha(102),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Column(
      children: _bookingRequests.map((request) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildRequestCard(request),
      )).toList(),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate900.withAlpha(102),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _sky500.withAlpha(77), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    request['clientImage'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _slate800,
                      child: const Icon(Icons.person, color: _sky400, size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['clientName'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request['service'],
                      style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: _sky400, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${request['date']} • ${request['time']}',
                          style: TextStyle(
                            color: Colors.white.withAlpha(179),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.attach_money_rounded, color: _sky400, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'R${request['price']}',
                          style: const TextStyle(
                            color: _sky400,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Accept booking
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_sky500, _cyan500],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _sky500.withAlpha(77),
                          blurRadius: 15,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
                  onTap: () {
                    // Decline booking
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _slate900.withAlpha(128),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _sky500.withAlpha(77)),
                    ),
                    child: Center(
                      child: Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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

  Widget _buildCalendarTab() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendar Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _slate900.withAlpha(102),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _sky500.withAlpha(51)),
          ),
          child: Column(
            children: [
              // Month header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getMonthNameFull(_currentMonth.month)} ${_currentMonth.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _slate900.withAlpha(128),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _sky500.withAlpha(77)),
                          ),
                          child: const Text('‹', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _slate900.withAlpha(128),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _sky500.withAlpha(77)),
                          ),
                          child: const Text('›', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Day headers
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: Colors.white.withAlpha(153),
                        fontSize: 12,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
              // Calendar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: firstDayOfWeek + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < firstDayOfWeek) {
                    return const SizedBox();
                  }
                  final day = index - firstDayOfWeek + 1;
                  final hasEvent = _eventDays.contains(day);
                  return Container(
                    decoration: BoxDecoration(
                      gradient: hasEvent
                          ? const LinearGradient(colors: [_sky500, _cyan500])
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: hasEvent
                          ? [BoxShadow(color: _sky500.withAlpha(102), blurRadius: 15)]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: hasEvent ? Colors.white : Colors.white.withAlpha(179),
                          fontSize: 14,
                          fontWeight: hasEvent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Scheduled Events
        const Text(
          'Scheduled Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._upcomingEvents.map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _slate900.withAlpha(102),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _sky500.withAlpha(51)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_sky500.withAlpha(51), _cyan500.withAlpha(51)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _sky500.withAlpha(77)),
                  ),
                  child: Center(
                    child: Text(
                      event['date'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
                        event['event'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event['time'],
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildServicesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Services',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Add service
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha(77),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Text(
                  'Add Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Services list
        ..._services.map((service) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildServiceCard(service),
        )),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isActive = service['status'] == 'active';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slate900.withAlpha(102),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _sky500.withAlpha(51)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'R${service['price']}',
                  style: const TextStyle(
                    color: _sky400,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? _green400.withAlpha(51)
                  : _slate800.withAlpha(128),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? _green400.withAlpha(77)
                    : Colors.white.withAlpha(51),
              ),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: isActive ? _green400 : Colors.white.withAlpha(153),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              // Edit service
            },
            child: Icon(
              Icons.settings_outlined,
              color: Colors.white.withAlpha(153),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthNameFull(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

