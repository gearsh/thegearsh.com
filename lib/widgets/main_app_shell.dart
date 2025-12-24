import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';
import 'package:gearsh_app/features/messages/messages_screen.dart';

/// Main app shell with role-based bottom navigation
class MainAppShell extends StatefulWidget {
  final UserRole userRole;

  const MainAppShell({
    super.key,
    required this.userRole,
  });

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;

  // Color constants
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                SizedBox(height: padding.top),
                Expanded(child: _buildCurrentScreen()),
                const SizedBox(height: 80),
              ],
            ),
            // Bottom navigation
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

  Widget _buildCurrentScreen() {
    if (widget.userRole == UserRole.client) {
      return _buildClientScreen();
    } else {
      return _buildArtistScreen();
    }
  }

  Widget _buildClientScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildClientExploreScreen();
      case 1:
        return MessagesScreen(
          onViewProfile: (artistId) => context.go('/artist/$artistId'),
        );
      case 2:
        return _buildClientBookingsScreen();
      case 3:
        context.go('/profile-settings');
        return const SizedBox();
      default:
        return _buildClientExploreScreen();
    }
  }

  Widget _buildArtistScreen() {
    switch (_currentIndex) {
      case 0:
        context.go('/dashboard');
        return const SizedBox();
      case 1:
        return MessagesScreen(
          onViewProfile: (artistId) => context.go('/artist/$artistId'),
        );
      case 2:
        return _buildArtistCalendarScreen();
      case 3:
        context.go('/profile-settings');
        return const SizedBox();
      default:
        context.go('/dashboard');
        return const SizedBox();
    }
  }

  Widget _buildBottomNav(EdgeInsets padding) {
    final isClient = widget.userRole == UserRole.client;

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
        children: isClient
            ? [
                _buildNavItem(Icons.explore_outlined, 'Explore', 0),
                _buildNavItem(Icons.message_outlined, 'Messages', 1),
                _buildNavItem(Icons.calendar_today_outlined, 'Bookings', 2),
                _buildNavItem(Icons.person_outline, 'Profile', 3),
              ]
            : [
                _buildNavItem(Icons.dashboard_outlined, 'Dashboard', 0),
                _buildNavItem(Icons.message_outlined, 'Messages', 1),
                _buildNavItem(Icons.calendar_today_outlined, 'Calendar', 2),
                _buildNavItem(Icons.person_outline, 'Profile', 3),
              ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
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

  // Placeholder screens - these will redirect to actual pages
  Widget _buildClientExploreScreen() {
    // Redirect to landing page explore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/');
    });
    return const Center(child: CircularProgressIndicator(color: _sky500));
  }

  Widget _buildClientBookingsScreen() {
    return const Center(
      child: Text('Bookings', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildArtistCalendarScreen() {
    return const Center(
      child: Text('Calendar', style: TextStyle(color: Colors.white)),
    );
  }
}

