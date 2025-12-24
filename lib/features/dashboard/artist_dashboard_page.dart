import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/widgets/auth_prompt.dart';

class ArtistDashboardPage extends StatefulWidget {
  const ArtistDashboardPage({super.key});

  @override
  State<ArtistDashboardPage> createState() => _ArtistDashboardPageState();
}

class _ArtistDashboardPageState extends State<ArtistDashboardPage> {
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

  // Mock data
  final List<Map<String, dynamic>> _bookingRequests = [
    {
      'id': 'req1',
      'clientName': 'Sarah Johnson',
      'clientImage': 'assets/images/artists/a-reece.png',
      'service': 'Club Night (4 hours)',
      'date': 'Dec 10, 2025',
      'time': '8:00 PM',
      'price': 500,
    },
    {
      'id': 'req2',
      'clientName': 'Michael Chen',
      'clientImage': 'assets/images/artists/nasty c.png',
      'service': 'Wedding DJ Package',
      'date': 'Dec 18, 2025',
      'time': '4:00 PM',
      'price': 800,
    },
  ];

  final List<Map<String, dynamic>> _upcomingEvents = [
    {'id': 'e1', 'date': '25', 'day': 'Mon', 'month': 'Nov', 'event': 'Corporate Event', 'time': '6:00 PM'},
    {'id': 'e2', 'date': '28', 'day': 'Thu', 'month': 'Nov', 'event': 'Wedding Reception', 'time': '5:00 PM'},
    {'id': 'e3', 'date': '3', 'day': 'Tue', 'month': 'Dec', 'event': 'Club Night', 'time': '9:00 PM'},
  ];

  final List<Map<String, dynamic>> _services = [
    {'id': 's1', 'name': 'Club Night (4 hours)', 'price': 500, 'status': 'active'},
    {'id': 's2', 'name': 'Wedding DJ Package', 'price': 800, 'status': 'active'},
    {'id': 's3', 'name': 'Corporate Event', 'price': 700, 'status': 'active'},
    {'id': 's4', 'name': 'Private Party (2 hours)', 'price': 300, 'status': 'inactive'},
  ];

  final List<Map<String, dynamic>> _recentActivity = [
    {'color': _green400, 'text': 'Payment received - R500', 'time': '2 hours ago'},
    {'color': _cyan400, 'text': 'New booking request', 'time': '5 hours ago'},
    {'color': _sky400, 'text': 'Booking confirmed for Dec 10', 'time': '1 day ago'},
  ];

  // Calendar state
  DateTime _currentMonth = DateTime(2025, 11, 1);
  final List<int> _eventDays = [25, 28];

  @override
  void initState() {
    super.initState();
    // Guest artists can view dashboard, but will be prompted to sign up for actions
    // No redirect needed - they selected artist role in onboarding
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
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Artist Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage your bookings & earnings',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(153),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/profile-settings'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _slate900.withAlpha(128),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _sky500.withAlpha(77)),
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 22,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Earnings Stats
        Row(
          children: [
            Expanded(child: _buildStatCard(
              icon: Icons.attach_money_rounded,
              label: 'This Month',
              value: 'R3,200',
              trend: '+24%',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              icon: Icons.calendar_today_rounded,
              label: 'Total Bookings',
              value: '47',
              trend: '+12%',
            )),
          ],
        ),
        const SizedBox(height: 16),

        // Quick Stats
        Row(
          children: [
            Expanded(child: _buildQuickStat(
              icon: Icons.access_time_rounded,
              iconColor: _yellow400,
              value: '2',
              label: 'Pending',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickStat(
              icon: Icons.check_circle_outline_rounded,
              iconColor: _green400,
              value: '8',
              label: 'Confirmed',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickStat(
              icon: Icons.people_outline_rounded,
              iconColor: _cyan400,
              value: '34',
              label: 'Clients',
            )),
          ],
        ),
        const SizedBox(height: 24),

        // Upcoming Events
        const Text(
          'Upcoming Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._upcomingEvents.map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildEventCard(event),
        )),
        const SizedBox(height: 16),

        // Recent Activity
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildActivityCard(),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _sky500.withAlpha(51),
            _cyan500.withAlpha(51),
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
              Icon(icon, color: _sky400, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withAlpha(153),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: _green400, size: 14),
              const SizedBox(width: 4),
              Text(
                trend,
                style: const TextStyle(
                  color: _green400,
                  fontSize: 13,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                    '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
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

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

