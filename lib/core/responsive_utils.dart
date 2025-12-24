import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Responsive utilities for unified mobile/web experience
class ResponsiveUtils {
  /// Breakpoints
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  /// Check if current screen is mobile-sized
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Check if current screen is tablet-sized
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Check if current screen is desktop-sized
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsive(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 16),
      tablet: const EdgeInsets.symmetric(horizontal: 32),
      desktop: const EdgeInsets.symmetric(horizontal: 64),
    );
  }

  /// Get maximum content width for centering on large screens
  static double maxContentWidth(BuildContext context) {
    return responsive(
      context,
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 500.0, // Keep mobile-like width even on desktop for app feel
    );
  }

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile web
  static bool isMobileWeb(BuildContext context) {
    return kIsWeb && isMobile(context);
  }

  /// Get safe area padding
  static EdgeInsets safeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get screen size
  static Size screenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Get device pixel ratio
  static double pixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }
}

/// A wrapper widget that constrains content for optimal mobile viewing on any device
class MobileOptimizedWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool centerOnLargeScreens;
  final double? maxWidth;

  const MobileOptimizedWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
    this.centerOnLargeScreens = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveUtils.maxContentWidth(context);

    // On mobile, just return the child
    if (ResponsiveUtils.isMobile(context)) {
      return child;
    }

    // On larger screens, constrain width for mobile-like experience
    if (centerOnLargeScreens) {
      return Container(
        color: backgroundColor ?? const Color(0xFF020617),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(77),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    return child;
  }
}

/// Extension for easier responsive access
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isMobileWeb => ResponsiveUtils.isMobileWeb(this);
  Size get screenSize => ResponsiveUtils.screenSize(this);
  EdgeInsets get safeArea => ResponsiveUtils.safeArea(this);

  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) => ResponsiveUtils.responsive(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
}

