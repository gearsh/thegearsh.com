import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/features/messages/messages_screen.dart';
import 'package:gearsh_app/services/user_role_service.dart';

/// Full page wrapper for MessagesScreen with navigation
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  // Color constants
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
            // Main content with safe area
            Padding(
              padding: EdgeInsets.only(top: padding.top, bottom: 80),
              child: MessagesScreen(
                onViewProfile: (artistId) => context.go('/artist/$artistId'),
              ),
            ),
            // Bottom Navigation
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNav(context, padding),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, EdgeInsets padding) {
    final isArtist = userRoleService.isArtist;

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
        children: isArtist
            ? [
                _buildNavItem(context, Icons.dashboard_outlined, 'Dashboard', false, '/dashboard'),
                _buildNavItem(context, Icons.message_outlined, 'Messages', true, '/messages'),
                _buildNavItem(context, Icons.calendar_today_outlined, 'Calendar', false, '/dashboard'),
                _buildNavItem(context, Icons.person_outline, 'Profile', false, '/profile-settings'),
              ]
            : [
                _buildNavItem(context, Icons.explore_outlined, 'Explore', false, '/'),
                _buildNavItem(context, Icons.message_outlined, 'Messages', true, '/messages'),
                _buildNavItem(context, Icons.calendar_today_outlined, 'Bookings', false, '/'),
                _buildNavItem(context, Icons.person_outline, 'Profile', false, '/profile-settings'),
              ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isSelected, String route) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          context.go(route);
        }
      },
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
}

