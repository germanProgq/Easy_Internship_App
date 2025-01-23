import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../../../../app/styles/app_colors.dart';

/// A premium 'Apply' button with a clean wave effect, sparkles, confetti,
/// a single-pass shimmer "blink" from left to right, and subtle 3D hover rotation.
class ApplyButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const ApplyButton({super.key, this.onPressed});

  @override
  State<ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<ApplyButton>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _isMobile = false;

  // Clean wave animation (Desktop)
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late AnimationController _waveController;

  // Mobile pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Sparkles
  final List<Sparkle> _sparkles = [];
  Timer? _sparkleTimer;
  final Random _random = Random();

  // Shimmer (Single-pass "blink")
  late AnimationController _shimmerController;
  Timer? _shimmerTimer; // to trigger periodic shimmer

  // Confetti
  final List<ConfettiPiece> _confetti = [];
  late AnimationController _confettiController;

  // 3D Hover Rotation
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // --- 1) Desktop "Fill" ---
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    );

    // --- 2) Desktop Wave ---
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // --- 3) Mobile Pulse ---
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });
    _pulseController.forward();

    // --- 4) Sparkles ---
    _startSparkleTimer();

    // --- 5) Shimmer (Blink) ---
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1200), // single pass
      vsync: this,
    );
    // On complete, reset so we can trigger again next time
    _shimmerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shimmerController.reset();
      }
    });
    // Periodically trigger shimmer every ~7 seconds
    _startShimmerTimer();

    // --- 6) Confetti ---
    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _confettiController.addListener(() {
      setState(() {});
    });

    // --- 7) 3D Rotation on Hover ---
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fillController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    _sparkleTimer?.cancel();
    for (var sparkle in _sparkles) {
      sparkle.animationController.dispose();
    }
    _shimmerController.dispose();
    _shimmerTimer?.cancel();
    _confettiController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // ------------------------------------
  // INTERACTIONS
  // ------------------------------------
  void _handleTap() {
    widget.onPressed?.call();
    _triggerConfetti();
  }

  void _onHover(bool hovering) {
    if (_isMobile) return; // No hover on mobile
    setState(() {
      _isHovered = hovering;
      if (_isHovered) {
        _fillController.forward();
        _waveController.repeat();
        _rotationController.forward();

        // Fire a shimmer pass on hover
        _shimmerController.forward(from: 0);
      } else {
        _fillController.reverse();
        _waveController.stop();
        _rotationController.reverse();
      }
    });
  }

  // ------------------------------------
  // TIMERS
  // ------------------------------------
  void _startSparkleTimer() {
    _sparkleTimer = Timer.periodic(
      Duration(milliseconds: 1000 + _random.nextInt(1000)),
      (timer) {
        // Sparkle if hovered or mobile
        if (_isHovered || _isMobile) {
          _addRandomSparkle();
        }
      },
    );
  }

  void _startShimmerTimer() {
    // Random periodic shimmer pass, e.g. every 7–10 seconds
    final seconds = 7 + _random.nextInt(4);
    _shimmerTimer = Timer.periodic(
      Duration(seconds: seconds),
      (timer) {
        // Just do a single pass
        _shimmerController.forward(from: 0);
      },
    );
  }

  // ------------------------------------
  // SPARKLES
  // ------------------------------------
  void _addRandomSparkle() {
    final sparkle = Sparkle(
      position: Offset(
        10 + _random.nextDouble() * 160,
        10 + _random.nextDouble() * 40,
      ),
      color: AppColors.accentOrange.withOpacity(0.9),
      size: 6 + _random.nextDouble() * 4,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: this,
      ),
    );

    sparkle.animationController.addListener(() {
      setState(() {});
    });
    sparkle.animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _sparkles.remove(sparkle);
        });
        sparkle.animationController.dispose();
      }
    });

    setState(() {
      _sparkles.add(sparkle);
    });

    sparkle.animationController.forward();
  }

  // ------------------------------------
  // CONFETTI
  // ------------------------------------
  void _triggerConfetti() {
    _confettiController.forward(from: 0);
    _confetti.clear();

    for (int i = 0; i < 20; i++) {
      _confetti.add(
        ConfettiPiece(
          position: const Offset(90, 30),
          color: (i % 2 == 0)
              ? AppColors.accentBlue
              : AppColors.accentOrange.withOpacity(0.8),
          direction:
              Offset(_random.nextDouble() * 2 - 1, -_random.nextDouble() - 1),
          speed: 60 + _random.nextDouble() * 40,
        ),
      );
    }
  }

  // ------------------------------------
  // BUILD
  // ------------------------------------
  @override
  Widget build(BuildContext context) {
    _isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _fillAnimation,
            _waveController,
            _shimmerController,
            _confettiController,
            _rotationController,
          ]),
          builder: (context, child) {
            final shimmerValue = _shimmerController.value;
            // Single-pass shimmer from left to right:
            final left = (shimmerValue * 1.3); // Move band outside
            final rotationAngle = _rotationAnimation.value * pi / 12;

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // subtle perspective
                ..rotateY(rotationAngle),
              alignment: Alignment.center,
              child: Transform.scale(
                scale: _isMobile
                    ? _pulseAnimation.value
                    : (_isHovered ? 1.05 : 1.0),
                child: Container(
                  width: _isMobile ? double.infinity : 180,
                  height: 60,
                  decoration: BoxDecoration(
                    // Premium multi-stop gradient
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentBlue,
                        AppColors.accentOrange,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.buttonShadow
                            .withOpacity(_isHovered && !_isMobile ? 0.8 : 0.3),
                        offset: _isHovered && !_isMobile
                            ? const Offset(4, 4)
                            : const Offset(2, 2),
                        blurRadius: _isHovered && !_isMobile ? 12 : 6,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Clean wave fill (Desktop-only)
                        if (!_isMobile)
                          CustomPaint(
                            painter: WavePainter(
                              fillPercent: _fillAnimation.value,
                              wavePhase: _waveController.value * 2 * pi,
                              isVisible: _isHovered,
                              fillColor: AppColors.accentBlue.withOpacity(0.2),
                              waveColor: AppColors.accentBlue.withOpacity(0.45),
                            ),
                            child: const SizedBox.expand(),
                          ),

                        // Sparkles
                        CustomPaint(
                          painter: SparklePainter(_sparkles),
                          child: const SizedBox.expand(),
                        ),

                        // Confetti
                        CustomPaint(
                          painter: ConfettiPainter(
                            _confetti,
                            _confettiController.value,
                          ),
                          child: const SizedBox.expand(),
                        ),

                        // Single-pass shimmer from left to right
                        Positioned.fill(
                          child: IgnorePointer(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final w = constraints.maxWidth;
                                final h = constraints.maxHeight;
                                final bandWidth = w * 0.3;
                                final shimmerLeft =
                                    left * (w + bandWidth) - bandWidth;

                                return Stack(
                                  children: [
                                    Positioned(
                                      left: shimmerLeft,
                                      top: 0,
                                      child: Transform.rotate(
                                        angle: -0.45,
                                        child: Container(
                                          width: bandWidth,
                                          height: h * 2,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0),
                                                AppColors.accentOrange
                                                    .withOpacity(0.4),
                                                Colors.white.withOpacity(0),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        // Button content
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Apply',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------
// WAVES
// ------------------------------------
class WavePainter extends CustomPainter {
  final double fillPercent; // 0..1
  final double wavePhase; // 0..2π
  final bool isVisible;
  final Color fillColor;
  final Color waveColor;

  WavePainter({
    required this.fillPercent,
    required this.wavePhase,
    required this.isVisible,
    required this.fillColor,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isVisible && fillPercent == 0) return;

    // Base fill
    final fillHeight = size.height * (1 - fillPercent);
    canvas.drawRect(
      Rect.fromLTRB(0, fillHeight, size.width, size.height),
      Paint()..color = fillColor,
    );

    // Clean wave overlay
    final wavePaint = Paint()..color = waveColor;
    final path = Path()..moveTo(0, fillHeight);

    // Lower amplitude for cleaner effect
    const amplitude = 4.0;
    final wavelength = size.width / 1.5;

    for (double x = 0; x <= size.width; x++) {
      final y =
          amplitude * sin((2 * pi / wavelength) * x + wavePhase) + fillHeight;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.fillPercent != fillPercent ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isVisible != isVisible;
  }
}

// ------------------------------------
// SPARKLES
// ------------------------------------
class Sparkle {
  final Offset position;
  final Color color;
  final double size;
  final AnimationController animationController;

  Sparkle({
    required this.position,
    required this.color,
    required this.size,
    required this.animationController,
  });
}

class SparklePainter extends CustomPainter {
  final List<Sparkle> sparkles;
  SparklePainter(this.sparkles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final progress = s.animationController.value;
      // Grow then shrink: 0..0.5..1
      final scale = (progress < 0.5 ? progress : 1 - progress) * 2;
      final paint = Paint()..color = s.color.withOpacity(1 - progress);

      _drawSparkle(canvas, s.position, s.size * scale, paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    // Diamond shape
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) => true;
}

// ------------------------------------
// CONFETTI
// ------------------------------------
class ConfettiPiece {
  Offset position;
  final Color color;
  final Offset direction;
  final double speed;

  ConfettiPiece({
    required this.position,
    required this.color,
    required this.direction,
    required this.speed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiPiece> confetti;
  final double animationValue; // 0..1

  ConfettiPainter(this.confetti, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final dt = animationValue;
      final offsetX = c.direction.dx * c.speed * dt;
      final offsetY = c.direction.dy * c.speed * dt;
      final newPos = Offset(c.position.dx + offsetX, c.position.dy + offsetY);

      final paint = Paint()..color = c.color;
      canvas.drawRect(
        Rect.fromCenter(center: newPos, width: 5, height: 8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
