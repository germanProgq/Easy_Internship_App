import 'package:flutter/material.dart';
import '../app/transitions/types/transition_types.dart';
import '../app/transitions/wave_transition.dart';

class TransitionLayout extends StatefulWidget {
  final List<Widget> children;

  const TransitionLayout({
    super.key,
    required this.children,
  });

  @override
  State<TransitionLayout> createState() => TransitionLayoutState();
}

class TransitionLayoutState extends State<TransitionLayout> {
  int _currentPageIndex = 0;
  TransitionTypes _transitionType = TransitionTypes.none;

  /// Called from AppRouter
  void navigateTo(int pageIndex,
      {TransitionTypes transitionType = TransitionTypes.slide}) {
    setState(() {
      _currentPageIndex = pageIndex;
      _transitionType = transitionType;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If wave, we do a wave overlay. Otherwise, we do an AnimatedSwitcher
    // to animate between pages with fade/slide/scale transitions as a demonstration.
    return Stack(
      children: [
        // We'll place an AnimatedSwitcher for transitions that are not wave:
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: _buildTransition,
          child: _buildPage(widget.children[_currentPageIndex]),
        ),

        // If wave is requested, overlay wave on top
        if (_transitionType == TransitionTypes.wave)
          WavePageTransition(
            duration: const Duration(seconds: 3),
            onTransitionComplete: () {
              // Once wave finishes, we remove it by setting transition to none
              setState(() {
                _transitionType = TransitionTypes.none;
              });
            },
          ),
      ],
    );
  }

  Widget _buildPage(Widget page) {
    // Give each child a unique key so AnimatedSwitcher can distinguish them
    return Container(
      key: ValueKey<int>(_currentPageIndex),
      child: page,
    );
  }

  /// Decides how to transition between old child and new child.
  /// Called by AnimatedSwitcher.
  Widget _buildTransition(Widget child, Animation<double> animation) {
    switch (_transitionType) {
      case TransitionTypes.fade:
        return FadeTransition(opacity: animation, child: child);

      case TransitionTypes.slide:
        // A simple left-to-right slide.
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // start from right
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offsetAnimation, child: child);

      case TransitionTypes.scale:
        return ScaleTransition(scale: animation, child: child);

      // If wave is set, we’re ignoring AnimatedSwitcher’s transition
      // (since the wave is used).
      // But if you want a fallback, do "none" or fade, etc.
      case TransitionTypes.wave:
        return child;

      case TransitionTypes.none:
        return child;
    }
  }
}
