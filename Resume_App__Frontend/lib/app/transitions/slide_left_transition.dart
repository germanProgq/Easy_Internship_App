import 'package:flutter/material.dart';

/// A slide overlay that moves from right to left, revealing the page beneath.
class SlidePageTransition extends StatefulWidget {
  /// How long the overlay slides before revealing the page.
  final Duration duration;

  /// Callback to tell the parent to remove this overlay once done.
  final VoidCallback onTransitionComplete;

  const SlidePageTransition({
    super.key,
    this.duration = const Duration(milliseconds: 500),
    required this.onTransitionComplete,
  });

  @override
  State<SlidePageTransition> createState() => _SlidePageTransitionState();
}

class _SlidePageTransitionState extends State<SlidePageTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Slide from right to left: X goes from +1 to 0
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Optionally fade from 0 to 1
    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 0.8,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward().whenComplete(() {
      // Tell parent to remove this from the stack
      widget.onTransitionComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // Use an AnimatedBuilder to drive both slide + opacity
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // We’ll create a semi-transparent Container sliding in from the right.
          // The new page (from _currentIndex) is behind this overlay in TransitionLayout.
          return Opacity(
            opacity: _opacityAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              // This could be any color or design you want (e.g. a gradient).
              // We'll just use a solid color to indicate the overlay.
              child: Container(
                color: Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
}
