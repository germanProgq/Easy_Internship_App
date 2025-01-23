import 'package:flutter/material.dart';

/// Example custom colors/styles
class FancyColors {
  static const Color start = Color(0xFF00BFA5); // teal-ish
  static const Color end = Color(0xFF651FFF); // purple-ish
}

/// A fancy wave transition overlay that covers the screen and animates away.
class WavePageTransition extends StatefulWidget {
  final Duration duration;
  final VoidCallback onTransitionComplete;

  const WavePageTransition({
    super.key,
    this.duration = const Duration(seconds: 3),
    required this.onTransitionComplete,
  });

  @override
  State<WavePageTransition> createState() => _WavePageTransitionState();
}

class _WavePageTransitionState extends State<WavePageTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // How high the wave has progressed (0..1).
  late final Animation<double> _waveHeightAnimation;
  // Color tween from start to end.
  late final Animation<Color?> _colorAnimation;
  // Fade out at the end for a smooth premium finish (0..1).
  late final Animation<double> _alphaAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Primary wave animation that goes from 0..1
    _waveHeightAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic, // smooth wave motion
      ),
    );

    // Gradual color change from FancyColors.start to FancyColors.end
    _colorAnimation = ColorTween(
      begin: FancyColors.start,
      end: FancyColors.end,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    // We'll fade the wave out in the final 20% of the animation
    // for a smoother "exit."
    _alphaAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start the animation, then fire the callback
    _controller.forward().then((_) {
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
    // Positioned.fill so it covers the entire screen
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final waveColor = _colorAnimation.value ?? FancyColors.start;
          final progress = _waveHeightAnimation.value;
          final alpha = _alphaAnimation.value;

          return Opacity(
            // Fade out near the end
            opacity: alpha,
            // A stack with a subtle radial gradient behind the waves
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, -0.6), // slight offset
                  radius: 1.2,
                  colors: [
                    waveColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // 1) The layered waves
                  _buildWaveLayer(progress, waveColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds two wave layers for a richer “multi-wave” effect.
  Widget _buildWaveLayer(double progress, Color waveColor) {
    return Stack(
      children: [
        // Lower wave (slightly different amplitude & frequency)
        ClipPath(
          clipper: MultiWaveClipper(
            progress: progress,
            waveFrequency: 1.2,
            waveAmplitude: 1.0,
            verticalOffsetFactor: 1.3,
          ),
          child: Container(color: waveColor),
        ),

        // Another wave on top with slightly different shape & alpha
        ClipPath(
          clipper: MultiWaveClipper(
            progress: progress,
            waveFrequency: 1.4,
            waveAmplitude: 0.7,
            verticalOffsetFactor: 1.1,
          ),
          child: Container(color: waveColor.withOpacity(0.6)),
        ),
      ],
    );
  }
}

/// Custom clipper for multiple wave arcs.
class MultiWaveClipper extends CustomClipper<Path> {
  final double progress;
  final double waveFrequency;
  final double waveAmplitude;
  final double verticalOffsetFactor; // how "tall" the wave can be

  MultiWaveClipper({
    required this.progress,
    this.waveFrequency = 1.0,
    this.waveAmplitude = 1.0,
    this.verticalOffsetFactor = 1.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // The wave’s highest point, based on progress.
    final waveHeight = size.height * progress * verticalOffsetFactor;

    // We'll do 2 wave "bumps" across the width.
    const waveCount = 2;
    final segmentWidth = size.width / waveCount;

    // Start from bottom-left at waveHeight
    path.moveTo(0, waveHeight);

    for (int i = 0; i < waveCount; i++) {
      final startX = segmentWidth * i;
      final endX = segmentWidth * (i + 1);

      // control points for the cubic path
      final cp1X = startX + segmentWidth / 4;
      final cp1Y = waveHeight - 30 * waveAmplitude * (i.isEven ? 1 : -1);

      final cp2X = startX + segmentWidth * 3 / 4;
      final cp2Y = waveHeight + 30 * waveAmplitude * (i.isEven ? 1 : -1);

      path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, endX, waveHeight);
    }

    // Now close the path down to the bottom corners
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(MultiWaveClipper oldClipper) =>
      oldClipper.progress != progress;
}
