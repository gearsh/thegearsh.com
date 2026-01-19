import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
/// Optimized for Android devices from small phones to tablets
class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late EdgeInsets padding;
  static late double textScaleFactor;

  /// Initialize responsive values - call this at the start of build methods
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    padding = _mediaQueryData.padding;
    textScaleFactor = _mediaQueryData.textScaler.scale(1.0).clamp(0.8, 1.3);

    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    safeAreaHorizontal = screenWidth - padding.left - padding.right;
    safeAreaVertical = screenHeight - padding.top - padding.bottom;
    safeBlockHorizontal = safeAreaHorizontal / 100;
    safeBlockVertical = safeAreaVertical / 100;
  }

  /// Device type detection
  static bool get isSmallPhone => screenWidth < 360;
  static bool get isPhone => screenWidth >= 360 && screenWidth < 600;
  static bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  static bool get isLargeTablet => screenWidth >= 900;

  /// Get responsive value based on screen width
  static double wp(double percentage) => screenWidth * percentage / 100;
  static double hp(double percentage) => screenHeight * percentage / 100;

  /// Safe area aware values
  static double swp(double percentage) => safeAreaHorizontal * percentage / 100;
  static double shp(double percentage) => safeAreaVertical * percentage / 100;

  /// Responsive font size (clamped for accessibility)
  static double fontSize(double size) {
    double scaledSize = size * (screenWidth / 375); // Base on iPhone 8 width
    return scaledSize.clamp(size * 0.8, size * 1.4);
  }

  /// Responsive spacing
  static double spacing(double value) {
    if (isSmallPhone) return value * 0.85;
    if (isTablet) return value * 1.2;
    if (isLargeTablet) return value * 1.4;
    return value;
  }

  /// Responsive icon size
  static double iconSize(double size) {
    if (isSmallPhone) return size * 0.9;
    if (isTablet) return size * 1.15;
    if (isLargeTablet) return size * 1.3;
    return size;
  }

  /// Get number of columns for grid based on screen width
  static int gridColumns({int phoneColumns = 2, int tabletColumns = 3, int largeColumns = 4}) {
    if (isSmallPhone) return phoneColumns;
    if (isPhone) return phoneColumns;
    if (isTablet) return tabletColumns;
    return largeColumns;
  }

  /// Responsive horizontal padding
  static double get horizontalPadding {
    if (isSmallPhone) return 12;
    if (isPhone) return 16;
    if (isTablet) return 24;
    return 32;
  }

  /// Responsive card padding
  static double get cardPadding {
    if (isSmallPhone) return 12;
    if (isPhone) return 16;
    if (isTablet) return 20;
    return 24;
  }

  /// Responsive border radius
  static double get borderRadius {
    if (isSmallPhone) return 12;
    if (isPhone) return 16;
    if (isTablet) return 20;
    return 24;
  }

  /// Max content width for tablets/large screens
  static double get maxContentWidth {
    if (isLargeTablet) return 800;
    if (isTablet) return 600;
    return screenWidth;
  }

  /// Constrain widget to max width for large screens
  static Widget constrainWidth({required Widget child, double? maxWidth}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? Responsive.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// Extension for responsive sizing on num types
extension ResponsiveNum on num {
  double get w => Responsive.wp(toDouble());
  double get h => Responsive.hp(toDouble());
  double get sp => Responsive.fontSize(toDouble());
  double get r => Responsive.spacing(toDouble());
}

/// Responsive widget wrapper that rebuilds on orientation/size changes
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Responsive.init(context);
        return builder(context, Responsive());
      },
    );
  }
}

/// Widget that adapts layout based on screen size
class AdaptiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? largeTablet;

  const AdaptiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.largeTablet,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    if (Responsive.isLargeTablet && largeTablet != null) {
      return largeTablet!;
    }
    if (Responsive.isTablet && tablet != null) {
      return tablet!;
    }
    return phone;
  }
}
