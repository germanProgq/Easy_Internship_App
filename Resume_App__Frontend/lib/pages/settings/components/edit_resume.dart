import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';

import '../../../app/context/user.dart';

/// A model representing each resume field.
class _FieldItem {
  final String label;
  final TextEditingController controller;
  _FieldItem(this.label, String initialValue)
      : controller = TextEditingController(text: initialValue);
}

/// A bubble for the background drifting effect.
class _Bubble {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final Color color;

  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.color,
  });
}

class ResumePage extends StatefulWidget {
  const ResumePage({Key? key}) : super(key: key);

  @override
  State<ResumePage> createState() => _ResumePageState();
}

class _ResumePageState extends State<ResumePage> with TickerProviderStateMixin {
  // Form
  final _formKey = GlobalKey<FormState>();
  // AnimatedList key
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // Internal list of fields
  late List<_FieldItem> _resumeFields;

  // Page entry animations (fade + subtle scale)
  late final AnimationController _pageEntryController;
  late final Animation<double> _pageFade;
  late final Animation<double> _pageScale;

  // Background animations
  late final AnimationController _bgController;
  late final Animation<double> _waveValue;
  late final Animation<double> _colorShiftValue;

  // Bubbles
  final List<_Bubble> _bubbles = [];

  // For 3D hover tilt on desktop only
  double _mouseX = 0.0;
  double _mouseY = 0.0;

  // Simple platform check: treat Android/iOS as mobile
  late bool _isMobile;

  @override
  void initState() {
    super.initState();

    // Safely read Provider in initState with listen: false
    final userContext = Provider.of<UserContext>(context, listen: false);
    // Convert userContext.resumeData into a list of _FieldItem
    _resumeFields = userContext.resumeData.entries
        .map((e) => _FieldItem(e.key, e.value))
        .toList();

    // Determine if mobile without using Theme.of(context)
    _isMobile = (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

    // Page entry: fade + subtle scale
    _pageEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _pageFade = CurvedAnimation(
      parent: _pageEntryController,
      curve: Curves.easeIn,
    );
    _pageScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pageEntryController, curve: Curves.easeOutCubic),
    );

    // Background wave / color shift
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _waveValue = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.linear),
    );
    _colorShiftValue = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.linear),
    );

    // Create bubbles, fewer if mobile
    final bubbleCount = _isMobile ? 6 : 12;
    _createBubbles(bubbleCount);

    // Start the page entry animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageEntryController.forward();
    });
  }

  @override
  void dispose() {
    _pageEntryController.dispose();
    _bgController.dispose();
    for (var field in _resumeFields) {
      field.controller.dispose();
    }
    super.dispose();
  }

  /// Creates random drifting bubbles
  void _createBubbles(int count) {
    final random = math.Random();
    for (int i = 0; i < count; i++) {
      _bubbles.add(
        _Bubble(
          x: random.nextDouble(),
          y: random.nextDouble(),
          radius: 10 + random.nextDouble() * 20,
          speed: 0.3 + random.nextDouble() * 0.7,
          color: Colors.white.withOpacity(0.15 + random.nextDouble() * 0.25),
        ),
      );
    }
  }

  /// Clear the text for a given field
  void _clearFieldText(int index) {
    _resumeFields[index].controller.clear();
  }

  /// Save the resume data back to the UserContext
  void _saveResume() {
    if (_formKey.currentState!.validate()) {
      final userContext = Provider.of<UserContext>(context, listen: false);

      final updatedData = <String, String>{};
      for (final field in _resumeFields) {
        final text = field.controller.text.trim();
        if (text.isNotEmpty) {
          updatedData[field.label] = text;
        }
      }
      userContext.updateResumeData(updatedData);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background radial gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.8),
                  radius: 1.2,
                  colors: [
                    colorScheme.primary.withOpacity(0.9),
                    colorScheme.secondary.withOpacity(0.9),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
          // Waves + bubbles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _WaveAndBubblesPainter(
                    waveProgress: _waveValue.value,
                    colorShift: _colorShiftValue.value,
                    baseColor: colorScheme.primary.withOpacity(0.25),
                    colorScheme: colorScheme,
                    bubbles: _bubbles,
                    isMobile: _isMobile,
                  ),
                );
              },
            ),
          ),
          // Frosted overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black26),
            ),
          ),
          // Page content
          SafeArea(
            child: AnimatedBuilder(
              animation: _pageEntryController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _pageFade,
                  child: Transform.scale(
                    scale: _pageScale.value,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _buildResumeCard(context),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // For desktop, compute 3D tilt angles based on pointer location
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final dx = (_mouseX - centerX) / centerX;
    final dy = (_mouseY - centerY) / centerY;
    final tiltX = dy * 0.06;
    final tiltY = -dx * 0.06;

    // If mobile, we skip the 3D transform
    final cardChild = Card(
      color: colorScheme.surface.withOpacity(0.75),
      elevation: 14,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Resume Fields',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // AnimatedList for dynamic display
              AnimatedList(
                key: _listKey,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                initialItemCount: _resumeFields.length,
                itemBuilder: (context, index, animation) {
                  final fieldData = _resumeFields[index];
                  return _FieldTile(
                    animation: animation,
                    label: fieldData.label,
                    controller: fieldData.controller,
                    onClear: () => _clearFieldText(index),
                  );
                },
              ),

              const SizedBox(height: 24),
              // Fancy button
              _FancyAnimatedButton(
                text: 'Save',
                onPressed: _saveResume,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );

    if (_isMobile) {
      return cardChild;
    } else {
      return MouseRegion(
        onHover: (event) {
          setState(() {
            _mouseX = event.position.dx;
            _mouseY = event.position.dy;
          });
        },
        onExit: (_) {
          setState(() {
            _mouseX = centerX;
            _mouseY = centerY;
          });
        },
        child: Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(tiltX)
            ..rotateY(tiltY),
          child: cardChild,
        ),
      );
    }
  }
}

/// Each field tile that animates in/out from the AnimatedList
/// but the trash button only clears the text now.
class _FieldTile extends StatelessWidget {
  final Animation<double> animation;
  final String label;
  final TextEditingController controller;
  final VoidCallback onClear;

  const _FieldTile({
    required this.animation,
    required this.label,
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.15),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: TextFormField(
                controller: controller,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  border: InputBorder.none,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete_forever, color: colorScheme.error),
                onPressed: onClear,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A fancier button with hover+press effects, plus a water-ripple
class _FancyAnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  const _FancyAnimatedButton({
    required this.text,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  State<_FancyAnimatedButton> createState() => _FancyAnimatedButtonState();
}

class _FancyAnimatedButtonState extends State<_FancyAnimatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;
  late final Animation<double> _rippleProgress;
  bool _hovering = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rippleProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutQuad),
    );

    // Animate button’s appearance ripple
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rippleController.forward();
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _handlePress() async {
    setState(() => _pressed = true);
    await _rippleController.forward(from: 0.0);
    setState(() => _pressed = false);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final baseColor =
        _hovering ? colorScheme.primary.withOpacity(0.9) : colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _handlePress,
        child: AnimatedBuilder(
          animation: _rippleProgress,
          builder: (context, child) {
            return CustomPaint(
              painter: _ButtonRipplePainter(
                progress: _rippleProgress.value,
                color: baseColor,
                isPressed: _pressed,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          colorScheme.shadow.withOpacity(_hovering ? 0.4 : 0.2),
                      offset: Offset(0, _hovering ? 6 : 4),
                      blurRadius: _hovering ? 12 : 8,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                transform: Matrix4.identity()
                  ..scale(_pressed ? 0.97 : 1.0, _pressed ? 0.97 : 1.0),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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

/// Paints the water ripple effect inside the fancy button
class _ButtonRipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPressed;

  _ButtonRipplePainter({
    required this.progress,
    required this.color,
    required this.isPressed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      math.pow(size.width / 2, 2) + math.pow(size.height / 2, 2),
    );
    final currentRadius = maxRadius * progress;
    final paint = Paint()
      ..color = isPressed
          ? color.withOpacity(0.35 * (1 - progress))
          : color.withOpacity(0.25 * (1 - progress));
    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(_ButtonRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPressed != isPressed;
  }
}

/// Draws waves and drifting bubbles in the background
class _WaveAndBubblesPainter extends CustomPainter {
  final double waveProgress;
  final double colorShift;
  final Color baseColor;
  final ColorScheme colorScheme;
  final List<_Bubble> bubbles;
  final bool isMobile;

  _WaveAndBubblesPainter({
    required this.waveProgress,
    required this.colorShift,
    required this.baseColor,
    required this.colorScheme,
    required this.bubbles,
    required this.isMobile,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWaves(canvas, size);

    // Draw drifting bubbles
    for (final bubble in bubbles) {
      final dx = bubble.x * size.width;
      final bubbleY =
          (bubble.y * size.height) - (waveProgress * 200.0 * bubble.speed);

      // If the bubble is off the top, skip
      if (bubbleY < -bubble.radius * 2) {
        continue;
      }
      final center = Offset(dx, bubbleY);
      final paint = Paint()..color = bubble.color;
      canvas.drawCircle(center, bubble.radius, paint);
    }
  }

  void _drawWaves(Canvas canvas, Size size) {
    // color shifting
    final shiftR = (math.sin(colorShift) + 1) / 2;
    final shiftG = (math.cos(colorShift) + 1) / 2;
    final shiftB = (math.sin(colorShift + math.pi / 2) + 1) / 2;
    final dynamicColor = Color.fromRGBO(
      (255 * shiftR).round(),
      (255 * shiftG).round(),
      (255 * shiftB).round(),
      0.18,
    );
    final tintedColor = Color.lerp(
      (colorScheme.tertiaryContainer ?? colorScheme.primaryContainer)
          .withOpacity(0.2),
      dynamicColor,
      0.6,
    )!;

    // Smaller wave amplitude if mobile
    final waveA1 = isMobile ? 10.0 : 18.0;
    final waveA2 = isMobile ? 8.0 : 15.0;
    final waveA3 = isMobile ? 14.0 : 25.0;

    _drawWave(
      canvas,
      size,
      amplitude: waveA1,
      phaseShift: 0,
      verticalShift: size.height * 0.4,
      color: baseColor,
    );
    _drawWave(
      canvas,
      size,
      amplitude: waveA2,
      phaseShift: 2,
      verticalShift: size.height * 0.45,
      color: baseColor.withOpacity(0.3),
    );
    _drawWave(
      canvas,
      size,
      amplitude: waveA3,
      phaseShift: 4,
      verticalShift: size.height * 0.53,
      color: tintedColor,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double amplitude,
    required double phaseShift,
    required double verticalShift,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, verticalShift);

    for (double x = 0; x <= size.width; x++) {
      final y = amplitude *
              math.sin(
                (x / size.width * 2 * math.pi) +
                    (waveProgress * 2 * math.pi) +
                    phaseShift,
              ) +
          verticalShift;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveAndBubblesPainter oldDelegate) => true;
}
