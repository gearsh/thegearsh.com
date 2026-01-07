import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Gearsh-themed animated background with floating glows
/// Used consistently throughout the app for a premium feel
class GearshBackground extends StatefulWidget {
  final Widget child;
  final bool showFloatingGlows;

  const GearshBackground({
    super.key,
    required this.child,
    this.showFloatingGlows = true,
  });

  @override
  State<GearshBackground> createState() => _GearshBackgroundState();
}

class _GearshBackgroundState extends State<GearshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatingGlowController;

  // Color constants - Deep Sky Blue theme (matching login page)
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _cyan500 = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _floatingGlowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    if (widget.showFloatingGlows) {
      _floatingGlowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatingGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_slate950, _slate900, _slate950],
            ),
          ),
          child: Stack(
            children: [
              // Animated floating glows
              if (widget.showFloatingGlows) ..._buildFloatingGlows(screenWidth, screenHeight),

              // Main content
              widget.child,
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingGlows(double screenWidth, double screenHeight) {
    return [
      // Top-right glow
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          final value = _floatingGlowController.value;
          return Positioned(
            top: -100 + (30 * math.sin(value * math.pi)),
            right: -80 + (20 * math.cos(value * math.pi)),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _sky500.withAlpha(40),
                    _sky500.withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Bottom-left glow
      AnimatedBuilder(
        animation: _floatingGlowController,
        builder: (context, child) {
          final value = _floatingGlowController.value;
          return Positioned(
            bottom: -120 + (25 * math.cos(value * math.pi)),
            left: -100 + (35 * math.sin(value * math.pi)),
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _cyan500.withAlpha(35),
                    _cyan500.withAlpha(10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }
}

/// Static version of the background without animations
/// Use this when you don't need the floating glow animations
class GearshBackgroundStatic extends StatelessWidget {
  final Widget child;

  const GearshBackgroundStatic({
    super.key,
    required this.child,
  });

  // Color constants
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_slate950, _slate900, _slate950],
        ),
      ),
      child: child,
    );
  }
}

