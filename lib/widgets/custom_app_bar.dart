import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({super.key, required this.title, this.actions, this.bottom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = GoRouter.of(context).canPop();
    // Safely obtain the current matched location from the router.
    // routerDelegate.currentConfiguration may be empty during app startup or tests,
    // so guard access and fall back to '/'.
    final router = GoRouter.of(context);
    String currentLocation = '/';
    try {
      final config = router.routerDelegate.currentConfiguration;
      if (config.isNotEmpty) {
        final last = config.last;
        currentLocation = last.matchedLocation;
      }
    } catch (_) {
      // On any unexpected error, fall back to root.
      currentLocation = '/';
    }

    // Helper to determine active state for a route prefix
    bool _isActive(String route) {
      if (route == '/') return currentLocation == '/' || currentLocation == '/landing';
      return currentLocation.startsWith(route);
    }

    // Topnav mode buttons: Discover, Login, Manager
    final modeButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(
          label: 'Discover',
          active: _isActive('/discover') || _isActive('/'),
          onPressed: () => context.go('/discover'),
        ),
        const SizedBox(width: 8),
        _NavButton(
          label: 'Login',
          active: _isActive('/login'),
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(width: 8),
        _NavButton(
          label: 'Manager',
          active: _isActive('/manager'),
          onPressed: () => context.go('/manager'),
        ),
      ],
    );

    return AppBar(
      title: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset('assets/images/gearsh_logo.png', height: 32),
            ),
          ),
          // Show the title when provided; otherwise show the topnav modes
          if (title.isNotEmpty) ...[
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(width: 16),
          ],
          // Always show mode buttons next to title for larger screens
          Expanded(child: Align(alignment: Alignment.centerLeft, child: modeButtons)),
        ],
      ),
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => context.pop(),
              color: theme.primaryColor,
            )
          : null,
      actions: actions ?? [
        // Keep a trailing login icon for quick access on small screens
        IconButton(
          icon: const Icon(Icons.login),
          onPressed: () => GoRouter.of(context).go('/login'),
          color: theme.primaryColor,
        ),
      ],
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

// Small reusable nav button used in the topnav
class _NavButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _NavButton({required this.label, required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: active ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: active
            ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : theme.textTheme.bodyMedium,
      ),
    );
  }
}
