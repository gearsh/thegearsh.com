import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';

class ArtistDashboardPage extends StatefulWidget {
  const ArtistDashboardPage({super.key});

  @override
  State<ArtistDashboardPage> createState() => _ArtistDashboardPageState();
}

class _ArtistDashboardPageState extends State<ArtistDashboardPage> {
  String _activeTab = 'overview';

  static const Color _bg      = Color(0xFF020617);
  static const Color _surface = Color(0xFF111827);
  static const Color _sky     = Color(0xFF0EA5E9);
  static const Color _skyL    = Color(0xFF38BDF8);
  static const Color _cyan    = Color(0xFF06B6D4);
  static const Color _border  = Color(0x12FFFFFF);
  static const Color _amber   = Color(0xFFFBBF24);

  final List<Map<String, String>> _tabs = [
    {'id': 'overview', 'label': 'Overview'},
    {'id': 'bookings', 'label': 'Bookings'},
    {'id': 'calendar', 'label': 'Calendar'},
    {'id': 'services', 'label': 'Services'},
  ];

  Widget _click({required Widget child, VoidCallback? onTap}) =>
      MouseRegion(cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: child));

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 900;
    final hPad = isWide ? 80.0 : 20.0;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        Container(
          padding: EdgeInsets.only(top: padding.top + 16, left: hPad, right: hPad, bottom: 0),
          decoration: BoxDecoration(
            color: _bg.withAlpha(245),
            border: Border(bottom: BorderSide(color: _border))),
          child: Column(children: [
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${_firstName()}',
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 22,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    userRoleService.isLoggedIn
                        ? 'Your artist dashboard'
                        : 'Set up your artist profile to start getting booked',
                    style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(100))),
                ],
              )),
              _click(
                onTap: () => context.go('/profile-settings'),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _surface, shape: BoxShape.circle,
                    border: Border.all(color: _border)),
                  child: Center(child: Text(_initials(),
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 13,
                      fontWeight: FontWeight.w700, color: _skyL))),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _tabs.map((tab) {
                final isActive = _activeTab == tab['id'];
                return _click(
                  onTap: () => setState(() => _activeTab = tab['id']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(
                      color: isActive ? _sky : Colors.transparent, width: 2))),
                    child: Text(tab['label']!,
                      style: TextStyle(
                        color: isActive ? _skyL : Colors.white.withAlpha(80),
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              }).toList()),
            ),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 120),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
            child: _buildTabContent()),
        )),
      ]),
      bottomNavigationBar: _buildBottomNav(padding),
    );
  }

  String _firstName() {
    final name = userRoleService.userName;
    if (name == 'Guest User') { return 'Artist'; }
    return name.split(' ').first;
  }

  String _initials() {
    final name = userRoleService.userName;
    if (name == 'Guest User') { return 'A'; }
    final parts = name.split(' ');
    if (parts.length >= 2) { return '${parts[0][0]}${parts[1][0]}'.toUpperCase(); }
    return parts[0][0].toUpperCase();
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'overview': return _buildOverview();
      case 'bookings': return _buildBookings();
      case 'calendar': return _buildCalendar();
      case 'services': return _buildServices();
      default: return _buildOverview();
    }
  }

  Widget _buildOverview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!userRoleService.isLoggedIn) ...[
        _buildSignupPrompt(),
        const SizedBox(height: 20),
      ],
      _buildSetupChecklist(),
      const SizedBox(height: 28),
      Row(children: [
        Expanded(child: _statCard(Icons.calendar_today_rounded, 'Bookings', '0')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.attach_money_rounded, 'Earnings', 'R0')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(Icons.visibility_outlined, 'Views', '0')),
      ]),
      const SizedBox(height: 28),
      const Text('Recent Activity', style: TextStyle(fontFamily: 'Syne',
        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 12),
      _emptyState(Icons.notifications_none_rounded, 'No activity yet',
        'When clients view your profile, send booking requests, or leave reviews \u2014 it\'ll show up here.'),
    ],
  );

  Widget _buildSignupPrompt() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_sky.withAlpha(20), _cyan.withAlpha(10)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _sky.withAlpha(64))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_sky, _cyan]),
            borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22)),
        const SizedBox(width: 14),
        const Expanded(child: Text('Create your account to go live',
          style: TextStyle(fontFamily: 'Syne', fontSize: 17,
            fontWeight: FontWeight.w700, color: Colors.white))),
      ]),
      const SizedBox(height: 12),
      Text('You\'re browsing as a guest. Sign up to create your artist profile, receive bookings, and start earning.',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300,
          color: Colors.white.withAlpha(140), height: 1.6)),
      const SizedBox(height: 16),
      _click(
        onTap: () => context.go('/join'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_sky, _cyan]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: _sky.withAlpha(40), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Text('Sign up as an artist',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    ]),
  );

  Widget _buildSetupChecklist() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Get started', style: TextStyle(fontFamily: 'Syne', fontSize: 17,
          fontWeight: FontWeight.w700, color: Colors.white)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _sky.withAlpha(15),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _sky.withAlpha(40))),
          child: Text('0 / 4 complete', style: TextStyle(fontSize: 11,
            fontWeight: FontWeight.w500, color: _skyL.withAlpha(180))),
        ),
      ]),
      const SizedBox(height: 6),
      Text('Complete these steps to get your profile live and start receiving bookings.',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300,
          color: Colors.white.withAlpha(90), height: 1.5)),
      const SizedBox(height: 20),
      _checkItem(Icons.person_outline_rounded, 'Complete your profile',
        'Add your bio, photo, and contact details', 'Edit profile',
        () => context.go('/edit-profile')),
      _checkItem(Icons.photo_library_outlined, 'Upload portfolio',
        'Show clients your best work', 'Add photos',
        () => context.go('/edit-profile')),
      _checkItem(Icons.sell_outlined, 'Set your services & pricing',
        'Define what you offer and your rates', 'Add services',
        () => setState(() => _activeTab = 'services')),
      _checkItem(Icons.verified_outlined, 'Get verified',
        'Verified artists get 3x more bookings', 'Start verification',
        () => context.go('/dashboard/verification'), isLast: true),
    ]),
  );

  Widget _checkItem(IconData icon, String title, String desc, String action,
      VoidCallback onTap, {bool isLast = false}) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
            color: _sky.withAlpha(10), border: Border.all(color: _border)),
          child: Icon(icon, color: _skyL.withAlpha(160), size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14,
            fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300,
            color: Colors.white.withAlpha(80))),
        ])),
        const SizedBox(width: 10),
        _click(onTap: onTap, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _sky.withAlpha(64)), color: _sky.withAlpha(10)),
          child: Text(action, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w500, color: _skyL)),
        )),
      ]),
    ),
    if (!isLast) Container(height: 1, color: _border),
  ]);

  Widget _statCard(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: _skyL.withAlpha(120), size: 18),
      const SizedBox(height: 12),
      Text(value, style: const TextStyle(fontFamily: 'Syne', fontSize: 22,
        fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(80))),
    ]),
  );

  Widget _emptyState(IconData icon, String title, String desc) => Container(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border)),
    child: Center(child: Column(children: [
      Container(width: 56, height: 56,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _sky.withAlpha(10),
          border: Border.all(color: _sky.withAlpha(40))),
        child: Icon(icon, color: _skyL.withAlpha(100), size: 24)),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontFamily: 'Syne', fontSize: 16,
        fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 6),
      Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 13,
        fontWeight: FontWeight.w300, color: Colors.white.withAlpha(80), height: 1.5)),
    ])),
  );

  Widget _buildBookings() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Booking Requests', style: TextStyle(fontFamily: 'Syne',
        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 16),
      _emptyState(Icons.inbox_rounded, 'No booking requests',
        'When clients send you booking requests, they\'ll appear here. Complete your profile to start getting discovered.'),
    ],
  );

  Widget _buildCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfWeek = DateTime(now.year, now.month, 1).weekday % 7;
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${months[now.month - 1]} ${now.year}',
              style: const TextStyle(fontFamily: 'Syne', fontSize: 17,
                fontWeight: FontWeight.w600, color: Colors.white)),
            Row(children: [
              Icon(Icons.circle, size: 8, color: _sky),
              const SizedBox(width: 6),
              Text('Today', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(80))),
            ]),
          ]),
          const SizedBox(height: 16),
          Row(children: ['S','M','T','W','T','F','S'].map((d) => Expanded(
            child: Center(child: Text(d, style: TextStyle(
              fontSize: 12, color: Colors.white.withAlpha(60), fontWeight: FontWeight.w500)))
          )).toList()),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, childAspectRatio: 1, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemCount: firstDayOfWeek + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOfWeek) { return const SizedBox(); }
              final day = index - firstDayOfWeek + 1;
              final isToday = day == now.day;
              return Container(
                decoration: BoxDecoration(
                  gradient: isToday ? const LinearGradient(colors: [_sky, _cyan]) : null,
                  borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('$day', style: TextStyle(
                  color: isToday ? Colors.white : Colors.white.withAlpha(140),
                  fontSize: 13, fontWeight: isToday ? FontWeight.w600 : FontWeight.w400))),
              );
            },
          ),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('Upcoming Events', style: TextStyle(fontFamily: 'Syne',
        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 12),
      _emptyState(Icons.event_outlined, 'No upcoming events',
        'Confirmed bookings will appear on your calendar automatically.'),
    ]);
  }

  Widget _buildServices() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        const Text('My Services', style: TextStyle(fontFamily: 'Syne',
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const Spacer(),
        _click(onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_sky, _cyan]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: _sky.withAlpha(30), blurRadius: 12, offset: const Offset(0, 3))]),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text('Add Service', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      _emptyState(Icons.sell_outlined, 'No services listed',
        'Add your services and pricing so clients know what you offer.'),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _sky.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _sky.withAlpha(30))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.lightbulb_outline, color: _amber, size: 18),
            const SizedBox(width: 10),
            const Text('Service ideas', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
          const SizedBox(height: 12),
          _serviceIdea('Club Night DJ Set', '4 hours', 'R2,500'),
          _serviceIdea('Wedding Photography', 'Full day', 'R8,000'),
          _serviceIdea('Event Videography', '6 hours + edit', 'R5,000'),
          _serviceIdea('MC / Event Host', '3 hours', 'R3,000'),
        ]),
      ),
    ],
  );

  Widget _serviceIdea(String name, String dur, String price) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 4, height: 4,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _skyL.withAlpha(100))),
      const SizedBox(width: 10),
      Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(140)))),
      Text(dur, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(60))),
      const SizedBox(width: 12),
      Text(price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _skyL)),
    ]),
  );

  Widget _buildBottomNav(EdgeInsets padding) => Container(
    height: 72 + padding.bottom,
    padding: EdgeInsets.only(bottom: padding.bottom),
    decoration: BoxDecoration(color: _bg.withAlpha(245),
      border: Border(top: BorderSide(color: _border))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _navItem(Icons.dashboard_rounded, 'Dashboard', true, () {}),
      _navItem(Icons.chat_bubble_outline, 'Messages', false, () => context.go('/messages')),
      _navItem(Icons.person_outline, 'Profile', false, () => context.go('/profile-settings')),
      _navItem(Icons.verified_outlined, 'Verify', false, () => context.go('/dashboard/verification')),
    ]),
  );

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) =>
      _click(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? _skyL : Colors.white.withAlpha(60), size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: active ? _skyL : Colors.white.withAlpha(60),
          fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        if (active) ...[
          const SizedBox(height: 4),
          Container(width: 4, height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_sky, _cyan]), shape: BoxShape.circle)),
        ],
      ]));
}
