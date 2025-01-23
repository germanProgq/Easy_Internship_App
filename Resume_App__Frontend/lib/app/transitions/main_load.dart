import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A majestic, high-value wave transition animation that
/// rises, melts away, and gracefully recedes—complete
/// with bubbles, halos, and shimmering sparkles.
class WaveLoading extends StatefulWidget {
  /// Text displayed at the center of this premium animation.
  final String displayText;

  /// Callback that fires once the entire transition completes.
  final VoidCallback onTransitionComplete;

  const WaveLoading({
    super.key,
    required this.displayText,
    required this.onTransitionComplete,
  });

  @override
  State<WaveLoading> createState() => _WaveLoadingState();
}

class _WaveLoadingState extends State<WaveLoading>
    with TickerProviderStateMixin {
  // -----------------------------------------------------------------------
  //   I. Horizontal Oscillation (Wave Offset)
  // -----------------------------------------------------------------------
  late final AnimationController _horizontalOscillationController;
  late final Animation<double> _horizontalOscillation;

  // -----------------------------------------------------------------------
  //  II. Rise Animation: moves wave center from 1.0 -> 0.55
  // -----------------------------------------------------------------------
  late final AnimationController _riseController;
  late final Animation<double> _riseAnimation;

  // -----------------------------------------------------------------------
  // III. Meltdown Animation: moves wave center from 0.55 -> 1.2
  // -----------------------------------------------------------------------
  late final AnimationController _meltdownController;
  late final Animation<double> _meltdownAnimation;

  // -----------------------------------------------------------------------
  //  IV. Recession (Wave Down): 1.2 -> 2.0
  // -----------------------------------------------------------------------
  late final AnimationController _recessionController;
  late final Animation<double> _recessionAnimation;

  // -----------------------------------------------------------------------
  //  Bubbles & Halo Effects
  // -----------------------------------------------------------------------
  final math.Random _random = math.Random();
  final List<_Bubble> _bubbles = [];
  final List<_BubbleHalo> _haloEffects = [];

  // -----------------------------------------------------------------------
  //  Sparkles (on wave crest)
  // -----------------------------------------------------------------------
  final List<_Sparkle> _sparkles = [];

  // -----------------------------------------------------------------------
  //  Flags & States
  // -----------------------------------------------------------------------
  bool _stopBubbles = false;
  bool _meltdownComplete = false;
  bool _recessionStarted = false;
  bool _recessionComplete = false;
  bool _transitionComplete = false;
  bool _showWave = true;

  @override
  void initState() {
    super.initState();

    // -----------------------------
    // I. Horizontal Oscillation
    // -----------------------------
    _horizontalOscillationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _horizontalOscillation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _horizontalOscillationController,
        curve: Curves.linear,
      ),
    );

    // -----------------------------
    // II. Rise: 1.0 -> 0.55
    // -----------------------------
    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _riseAnimation = Tween<double>(begin: 1.0, end: 0.55).animate(
      CurvedAnimation(
        parent: _riseController,
        curve: Curves.easeInOut,
      ),
    );
    _riseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _stopBubbles = true;
        _meltdownController.forward();
      }
    });

    // -----------------------------
    // III. Meltdown: 0.55 -> 1.2
    // -----------------------------
    _meltdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _meltdownAnimation = Tween<double>(begin: 0.55, end: 1.2).animate(
      CurvedAnimation(
        parent: _meltdownController,
        curve: Curves.easeInOut,
      ),
    );
    _meltdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _meltdownComplete = true;
        _beginRecessionIfPossible();
      }
    });

    // -----------------------------
    // IV. Recession: 1.2 -> 2.0
    // -----------------------------
    _recessionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _recessionAnimation = Tween<double>(begin: 1.2, end: 2.0).animate(
      CurvedAnimation(
        parent: _recessionController,
        curve: Curves.easeInOut,
      ),
    );
    _recessionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _recessionComplete = true;
        _concludeTransitionIfPossible();
      }
    });

    // -----------------------------
    // Start the show with the rise
    // -----------------------------
    _riseController.forward();

    // Populate initial bubbles
    _seedBubbles();

    // Use horizontal oscillator to drive bubble movement ticks
    _horizontalOscillationController.addListener(_updateBubblesHalosSparkles);
  }

  @override
  void dispose() {
    _horizontalOscillationController
        .removeListener(_updateBubblesHalosSparkles);
    _horizontalOscillationController.dispose();
    _riseController.dispose();
    _meltdownController.dispose();
    _recessionController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  //  Bubble & Sparkle Setup
  // -----------------------------------------------------------------------
  void _seedBubbles() {
    for (int i = 0; i < 6; i++) {
      _bubbles.add(
        _Bubble(
          x: _random.nextDouble(),
          y: 1.0 + _random.nextDouble(),
          size: _random.nextDouble() * 20 + 10,
          speed: 0.008 + _random.nextDouble() * 0.01,
        ),
      );
    }

    // Create a few initial sparkles
    for (int i = 0; i < 4; i++) {
      _sparkles.add(
        _Sparkle.random(_random),
      );
    }
  }

  void _updateBubblesHalosSparkles() {
    if (_transitionComplete || !_showWave) return;

    // 1) Move each bubble upwards
    for (final bubble in _bubbles) {
      bubble.y -= bubble.speed;
      // Bubble crosses threshold => pop & halo
      if (!bubble.isPopped && bubble.y < 0.2) {
        bubble.isPopped = true;
        _haloEffects.add(
          _BubbleHalo(
            x: bubble.x,
            y: bubble.y,
            radius: bubble.size * 0.5,
            lifetime: 0.0,
          ),
        );
      }
    }

    // 2) Remove or recycle off-screen bubbles
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      if (_bubbles[i].y < -0.1 || _bubbles[i].isPopped) {
        if (_stopBubbles) {
          _bubbles.removeAt(i);
        } else {
          _respawnBubble(i);
        }
      }
    }

    // 3) Age halo effects
    for (final halo in _haloEffects) {
      halo.lifetime += 0.02;
    }
    _haloEffects.removeWhere((halo) => halo.lifetime > 1.0);

    // 4) Sparkles
    for (final sparkle in _sparkles) {
      sparkle.age += 0.01;
      sparkle.x += 0.001 * math.sin(_horizontalOscillation.value * 2 * math.pi);
      // Recycle sparkles if they expire
      if (sparkle.age > 1.2) {
        sparkle.reset(_random);
      }
    }

    // 5) Attempt to finalize if meltdown & bubbles are gone
    _concludeTransitionIfPossible();

    setState(() {});
  }

  void _respawnBubble(int index) {
    _bubbles.removeAt(index);
    _bubbles.add(
      _Bubble(
        x: _random.nextDouble(),
        y: 1.0 + _random.nextDouble(),
        size: _random.nextDouble() * 20 + 10,
        speed: 0.008 + _random.nextDouble() * 0.01,
      ),
    );
  }

  // -----------------------------------------------------------------------
  //  Flow Control: Recession & Finish
  // -----------------------------------------------------------------------
  void _beginRecessionIfPossible() {
    if (_meltdownComplete && !_recessionStarted) {
      _recessionStarted = true;
      _recessionController.forward();
    }
  }

  void _concludeTransitionIfPossible() {
    if (_meltdownComplete &&
        _recessionComplete &&
        _bubbles.isEmpty &&
        !_transitionComplete) {
      _transitionComplete = true;
      setState(() => _showWave = false);
      widget.onTransitionComplete();
    }
  }

  // -----------------------------------------------------------------------
  //  Build
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Grab colors & text styles from the current theme
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!_showWave) {
      // Display a “transition finished” placeholder
      return Center(
        child: Text(
          "Loading Complete!",
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 28,
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _horizontalOscillationController,
        _riseController,
        _meltdownController,
        _recessionController,
      ]),
      builder: (context, child) {
        final double verticalAnchor = _currentVerticalWaveCenter();
        return Stack(
          children: [
            // Wave layers & sparkles
            Positioned.fill(
              child: CustomPaint(
                painter: _LuxuriousWavePainter(
                  horizontalOffset: _horizontalOscillation.value,
                  waveCenterFactor: verticalAnchor,
                  sparkles: _sparkles,

                  // Supply theme-driven colors here
                  background1: colorScheme.surface,
                  background2: colorScheme.surface,
                  waveAccent1: colorScheme.primary,
                  waveAccent2: colorScheme.secondary,
                  waveSuccess: colorScheme.tertiary,
                  waveError: colorScheme.error,
                  // We'll use onBackground for wave outlines or sparkles
                  onBackground: colorScheme.onSurface,
                ),
              ),
            ),
            // Bubbles & Halos
            Positioned.fill(
              child: CustomPaint(
                painter: _BubbleHaloPainter(
                  bubbles: _bubbles,
                  halos: _haloEffects,
                  bubbleColor: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
            // Centered text
            Center(
              child: Text(
                widget.displayText,
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: colorScheme.onSurface.withOpacity(0.4),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _currentVerticalWaveCenter() {
    if (!_riseController.isCompleted) {
      return _riseAnimation.value;
    }
    if (!_meltdownController.isCompleted) {
      return _meltdownAnimation.value;
    }
    if (!_recessionController.isCompleted) {
      return _recessionAnimation.value;
    }
    return 2.0; // If all done, wave is off-screen
  }
}

// ---------------------------------------------------------------------------
//  LUXURIOUS WAVE PAINTER — now uses theme-driven colors
// ---------------------------------------------------------------------------
class _LuxuriousWavePainter extends CustomPainter {
  final double horizontalOffset; // 0..1
  final double waveCenterFactor; // typically 0..2
  final List<_Sparkle> sparkles;

  // Colors provided by the theme context
  final Color background1;
  final Color background2;
  final Color waveAccent1;
  final Color waveAccent2;
  final Color waveSuccess;
  final Color waveError;
  final Color onBackground;

  _LuxuriousWavePainter({
    required this.horizontalOffset,
    required this.waveCenterFactor,
    required this.sparkles,
    required this.background1,
    required this.background2,
    required this.waveAccent1,
    required this.waveAccent2,
    required this.waveSuccess,
    required this.waveError,
    required this.onBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1) Fill background with a subtle gradient
    _paintBackgroundGradient(canvas, size);

    // 2) Multi-layer wave
    _paintWaveLayer(
      canvas,
      size,
      baseHeightPct: waveCenterFactor,
      amplitude: 30,
      waveFrequency: 1.8,
      speedFactor: 1.0,
      color1: waveAccent1,
      color2: waveAccent2,
      opacity: 0.5,
    );
    _paintWaveLayer(
      canvas,
      size,
      baseHeightPct: waveCenterFactor + 0.03,
      amplitude: 20,
      waveFrequency: 2.2,
      speedFactor: 1.3,
      color1: waveSuccess,
      color2: waveError,
      opacity: 0.4,
    );
    _paintWaveLayer(
      canvas,
      size,
      baseHeightPct: waveCenterFactor - 0.03,
      amplitude: 25,
      waveFrequency: 2.0,
      speedFactor: 0.8,
      color1: waveAccent1.withOpacity(0.6),
      color2: waveAccent2.withOpacity(0.6),
      opacity: 0.6,
    );

    // 3) Sparkles
    _paintSparkles(canvas, size);
  }

  void _paintBackgroundGradient(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paintBg = Paint()
      ..shader = LinearGradient(
        colors: [background1, background2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, paintBg);
  }

  void _paintWaveLayer(
    Canvas canvas,
    Size size, {
    required double baseHeightPct,
    required double amplitude,
    required double waveFrequency,
    required double speedFactor,
    required Color color1,
    required Color color2,
    required double opacity,
  }) {
    final path = Path();
    final double baseHeight = baseHeightPct * size.height;
    final phase = horizontalOffset * 2 * math.pi * speedFactor;

    final paint = Paint()
      ..shader = LinearGradient(colors: [color1, color2])
          .createShader(Offset.zero & size)
      ..colorFilter = ColorFilter.mode(
        Colors.white.withOpacity(opacity),
        BlendMode.srcATop,
      )
      ..isAntiAlias = true;

    path.moveTo(0, baseHeight);

    final int steps = 40;
    final double dx = size.width / steps;
    for (int i = 0; i <= steps; i++) {
      final x = i * dx;
      final angle = (waveFrequency * x / size.width * 2 * math.pi) + phase;
      final y = baseHeight + amplitude * math.sin(angle);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _paintSparkles(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      final paint = Paint()
        ..color = onBackground.withOpacity(0.7 * (1.0 - sparkle.age))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final offset = Offset(
        sparkle.x * size.width,
        (waveCenterFactor - 0.15) * size.height + (sparkle.y * 100),
      );
      canvas.drawCircle(offset, sparkle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
//  Sparkle Model
// ---------------------------------------------------------------------------
class _Sparkle {
  double x; // 0..1
  double y; // 0..1
  double size;
  double age; // 0..1

  _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.age,
  });

  factory _Sparkle.random(math.Random rnd) {
    return _Sparkle(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      size: 2 + rnd.nextDouble() * 3,
      age: rnd.nextDouble() * 0.6,
    );
  }

  void reset(math.Random rnd) {
    x = rnd.nextDouble();
    y = rnd.nextDouble();
    size = 2 + rnd.nextDouble() * 3;
    age = 0.0;
  }
}

// ---------------------------------------------------------------------------
//  Bubble & Halo Painter — now also uses theme-driven color
// ---------------------------------------------------------------------------
class _BubbleHaloPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final List<_BubbleHalo> halos;

  // Pass in a color from the parent
  final Color bubbleColor;

  _BubbleHaloPainter({
    required this.bubbles,
    required this.halos,
    required this.bubbleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bubblePaint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    // 1) Draw bubbles
    for (final bubble in bubbles) {
      if (!bubble.isPopped) {
        final bubbleCenter = Offset(
          bubble.x * size.width,
          bubble.y * size.height,
        );
        final bubbleRadius = bubble.size * 0.5;
        canvas.drawCircle(bubbleCenter, bubbleRadius, bubblePaint);
      }
    }

    // 2) Draw halos (pop rings)
    for (final halo in halos) {
      // Fade out as lifetime approaches 1
      final alpha = ((1.0 - halo.lifetime) * 255).toInt();
      final haloPaint = Paint()
        ..color = bubbleColor.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + 6 * halo.lifetime;

      final center = Offset(halo.x * size.width, halo.y * size.height);
      final radius = halo.radius + 30 * halo.lifetime;
      canvas.drawCircle(center, radius, haloPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
//  Bubble & Halo Models
// ---------------------------------------------------------------------------
class _Bubble {
  double x; // 0..1
  double y; // 0..1
  double size; // bubble diameter in px
  double speed;
  bool isPopped = false;

  _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class _BubbleHalo {
  final double x; // 0..1
  final double y; // 0..1
  final double radius;
  double lifetime; // 0..1 => expands over time

  _BubbleHalo({
    required this.x,
    required this.y,
    required this.radius,
    required this.lifetime,
  });
}
