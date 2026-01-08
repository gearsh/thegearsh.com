import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A wrapper widget that enables swipe-right-to-go-back gesture on any page.
/// Wraps the child widget and detects horizontal swipes from the left edge.
class SwipeBackWrapper extends StatelessWidget {
  final Widget child;
  final bool canPop;

  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.canPop = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!canPop) return child;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Check if swipe velocity is sufficient and direction is right (positive)
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          // Check if we can actually go back
          if (GoRouter.of(context).canPop()) {
            GoRouter.of(context).pop();
          } else if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: child,
    );
  }
}

/// A more iOS-like swipe back with edge detection
class EdgeSwipeBackWrapper extends StatefulWidget {
  final Widget child;
  final bool canPop;
  final double edgeWidth;

  const EdgeSwipeBackWrapper({
    super.key,
    required this.child,
    this.canPop = true,
    this.edgeWidth = 40.0,
  });

  @override
  State<EdgeSwipeBackWrapper> createState() => _EdgeSwipeBackWrapperState();
}

class _EdgeSwipeBackWrapperState extends State<EdgeSwipeBackWrapper> {
  bool _isSwipingFromEdge = false;

  void _handleDragStart(DragStartDetails details) {
    // Only track swipes that start from the left edge
    if (details.globalPosition.dx < widget.edgeWidth) {
      _isSwipingFromEdge = true;
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // Could add visual feedback here if needed
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isSwipingFromEdge && widget.canPop) {
      final velocity = details.primaryVelocity ?? 0;
      // Swipe right with sufficient velocity
      if (velocity > 300) {
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
    _isSwipingFromEdge = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canPop) return widget.child;

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

