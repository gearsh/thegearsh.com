import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentLocation = GoRouter.of(context).routerDelegate.currentConfiguration.last.matchedLocation;
    final theme = Theme.of(context);
    // Extract RGB components using component accessors (.r/.g/.b)
    final surfaceColor = theme.colorScheme.surface;
    // `surfaceColor.r/g/b` are normalized doubles in [0.0, 1.0]; convert to 0-255 ints
    final int _sr = ((surfaceColor.r * 255.0).round().clamp(0, 255)).toInt();
    final int _sg = ((surfaceColor.g * 255.0).round().clamp(0, 255)).toInt();
    final int _sb = ((surfaceColor.b * 255.0).round().clamp(0, 255)).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color.fromRGBO(_sr, _sg, _sb, 0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            label: 'Discover',
            icon: Icons.search,
            isActive: currentLocation == '/',
            onTap: () => context.go('/'),
          ),
          _NavItem(
            label: 'Profile',
            icon: Icons.person,
            isActive: currentLocation.contains('/profile'),
            onTap: () => context.go('/profile/1'), // Navigate to DJ Khalid's profile for demo
          ),
          _NavItem(
            label: 'Dashboard',
            icon: Icons.dashboard,
            isActive: currentLocation.contains('/dashboard'),
            onTap: () => context.go('/dashboard'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? theme.primaryColor : Colors.white60, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? theme.primaryColor : Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
