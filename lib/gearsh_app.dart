import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'routes/app_router.dart';
import 'theme.dart';

/// Custom scroll behavior for ultra-smooth Gearsh scrolling
class GearshScrollBehavior extends MaterialScrollBehavior {
  const GearshScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Use bouncing physics with custom settings for smooth feel
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // No scrollbars for cleaner mobile look
    return child;
  }
}

/// Wrapper widget that enables swipe right to go back navigation
class SwipeBackNavigator extends StatefulWidget {
  final Widget child;

  const SwipeBackNavigator({super.key, required this.child});

  @override
  State<SwipeBackNavigator> createState() => _SwipeBackNavigatorState();
}

class _SwipeBackNavigatorState extends State<SwipeBackNavigator> {
  double _dragStartX = 0;
  double _dragCurrentX = 0;
  bool _isDragging = false;

  // Configuration
  static const double _edgeWidth = 40.0; // Width of edge detection zone
  static const double _minDragDistance = 80.0; // Minimum drag to trigger back
  static const double _velocityThreshold = 300.0; // Velocity to trigger back

  void _onHorizontalDragStart(DragStartDetails details) {
    // Only start drag if it begins from the left edge
    if (details.globalPosition.dx <= _edgeWidth) {
      setState(() {
        _isDragging = true;
        _dragStartX = details.globalPosition.dx;
        _dragCurrentX = details.globalPosition.dx;
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        _dragCurrentX = details.globalPosition.dx;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isDragging) {
      final dragDistance = _dragCurrentX - _dragStartX;
      final velocity = details.primaryVelocity ?? 0;

      // Go back if dragged far enough or with enough velocity
      if (dragDistance > _minDragDistance || velocity > _velocityThreshold) {
        _navigateBack();
      }

      setState(() {
        _isDragging = false;
        _dragStartX = 0;
        _dragCurrentX = 0;
      });
    }
  }

  void _navigateBack() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dragDistance = _isDragging ? (_dragCurrentX - _dragStartX).clamp(0.0, 100.0) : 0.0;
    final progress = dragDistance / 100.0;

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Main content with slight transform during drag
          AnimatedContainer(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(dragDistance * 0.3, 0, 0),
            child: widget.child,
          ),
          // Back indicator that appears during swipe
          if (_isDragging && dragDistance > 20)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: progress,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0EA5E9).withAlpha((progress * 200).toInt()),
                        const Color(0xFF06B6D4).withAlpha((progress * 200).toInt()),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withAlpha((progress * 100).toInt()),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GearshApp extends ConsumerWidget {
  const GearshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Gearsh',
      routerConfig: router,
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      // Use custom scroll behavior for smooth scrolling
      scrollBehavior: const GearshScrollBehavior(),
      // Disable text scaling to keep consistent UI across devices
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          // Wrap with swipe back navigator for edge swipe to go back
          child: SwipeBackNavigator(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
