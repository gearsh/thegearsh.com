import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/user_role_service.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  // Gearsh theme colors (matching login page)
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);

  void _showSignUpPrompt(BuildContext context, String feature) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _slate900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _sky500.withAlpha(51), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _sky500.withAlpha(26),
                shape: BoxShape.circle,
                border: Border.all(color: _sky500.withAlpha(51), width: 1),
              ),
              child: Icon(
                _getFeatureIcon(feature),
                color: _sky400,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'Sign Up to Access $feature',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              _getFeatureDescription(feature),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Sign Up Button - Gradient style like login page
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.go('/signup');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _sky500.withAlpha(77),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Sign Up Free',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Login Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.go('/login');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _slate800, width: 1),
                ),
                child: Center(
                  child: Text(
                    'Already have an account? Log In',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Continue exploring
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continue Exploring',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _getFeatureIcon(String feature) {
    switch (feature) {
      case 'Messages':
        return Icons.chat_bubble;
      case 'Bookings':
        return Icons.calendar_today;
      case 'Profile':
        return Icons.person;
      default:
        return Icons.lock;
    }
  }

  String _getFeatureDescription(String feature) {
    switch (feature) {
      case 'Messages':
        return 'Create an account to message artists directly and discuss your event details.';
      case 'Bookings':
        return 'Sign up to book artists, manage your events, and track your bookings.';
      case 'Profile':
        return 'Create your profile to save favourite artists and manage your account settings.';
      default:
        return 'Sign up to unlock all features and get the full Gearsh experience.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentLocation = GoRouter.of(context).routerDelegate.currentConfiguration.last.matchedLocation;
    final bool isLoggedIn = userRoleService.isLoggedIn;
    final bool isArtist = userRoleService.isArtist;
    final bool isFan = userRoleService.isFan;
    final bool isGuest = userRoleService.isGuest && !isLoggedIn;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _slate900,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _sky500.withAlpha(38), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _sky500.withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Explore - For all users (Clients & Fans discover artists, Artists browse competitors)
          _NavItem(
            label: 'Explore',
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            isActive: currentLocation == '/' || currentLocation == '/home',
            onTap: () => context.go('/'),
          ),

          // Role-specific second tab
          if (isArtist)
            // Artists: Dashboard to manage bookings & earnings
            _NavItem(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              isActive: currentLocation == '/artist-dashboard',
              onTap: () {
                if (isGuest) {
                  _showSignUpPrompt(context, 'Dashboard');
                } else {
                  context.go('/artist-dashboard');
                }
              },
            )
          else
            // Clients & Fans: Messages
            _NavItem(
              label: 'Messages',
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              isActive: currentLocation == '/messages',
              onTap: () {
                if (isGuest) {
                  _showSignUpPrompt(context, 'Messages');
                } else {
                  context.go('/messages');
                }
              },
            ),

          // Role-specific third tab
          if (isFan)
            // Fans: Browse Gigs & Events
            _NavItem(
              label: 'Gigs',
              icon: Icons.event_outlined,
              activeIcon: Icons.event,
              isActive: currentLocation == '/gigs',
              onTap: () => context.go('/gigs'),
            )
          else if (isArtist)
            // Artists: Messages from clients
            _NavItem(
              label: 'Messages',
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              isActive: currentLocation == '/messages',
              onTap: () {
                if (isGuest) {
                  _showSignUpPrompt(context, 'Messages');
                } else {
                  context.go('/messages');
                }
              },
            )
          else
            // Clients: My Bookings
            _NavItem(
              label: 'Bookings',
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              isActive: currentLocation == '/bookings' || currentLocation == '/my-bookings',
              onTap: () {
                if (isGuest) {
                  _showSignUpPrompt(context, 'Bookings');
                } else {
                  context.go('/my-bookings');
                }
              },
            ),

          // Profile - For all users
          _NavItem(
            label: 'Profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            isActive: currentLocation == '/profile-settings' || currentLocation == '/edit-profile' || currentLocation.startsWith('/profile'),
            onTap: () {
              if (isGuest) {
                _showSignUpPrompt(context, 'Profile');
              } else {
                context.go('/profile-settings');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      // Small delay for visual feedback before navigation
      Future.delayed(const Duration(milliseconds: 50), () {
        widget.onTap();
      });
    });
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Gearsh theme colors
    const Color sky500 = Color(0xFF0EA5E9);
    const Color cyan500 = Color(0xFF06B6D4);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 14 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: widget.isActive
                ? LinearGradient(
                    colors: [sky500.withAlpha(51), cyan500.withAlpha(38)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: widget.isActive
                ? Border.all(color: sky500.withAlpha(51), width: 1)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      widget.isActive ? widget.activeIcon : widget.icon,
                      key: ValueKey(widget.isActive),
                      color: widget.isActive ? sky500 : Colors.white54,
                      size: widget.isActive ? 26 : 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: widget.isActive ? sky500 : Colors.white54,
                  fontSize: widget.isActive ? 11 : 10,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: widget.isActive ? 0.3 : 0,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
