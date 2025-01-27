// lib/ui/pages/login_page.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/context/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // -----------------------------------------------------------------------
  //  Controllers & Focus
  // -----------------------------------------------------------------------
  final TextEditingController _signInEmail = TextEditingController();
  final TextEditingController _signInPassword = TextEditingController();

  final TextEditingController _signUpUsername = TextEditingController();
  final TextEditingController _signUpEmail = TextEditingController();
  final TextEditingController _signUpPassword = TextEditingController();
  final TextEditingController _signUpConfirmPassword = TextEditingController();

  final FocusNode _signInEmailFocus = FocusNode();
  final FocusNode _signInPasswordFocus = FocusNode();
  final FocusNode _signUpUsernameFocus = FocusNode();
  final FocusNode _signUpEmailFocus = FocusNode();
  final FocusNode _signUpPasswordFocus = FocusNode();
  final FocusNode _signUpConfirmPasswordFocus = FocusNode();

  bool _isSignUp = false;

  // -----------------------------------------------------------------------
  //  3D Flip
  // -----------------------------------------------------------------------
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  // -----------------------------------------------------------------------
  //  Staggered Form Animations
  // -----------------------------------------------------------------------
  late final AnimationController _staggeredController;
  late final Animation<double> _fieldFadeAnimation;
  late final Animation<Offset> _fieldSlideAnimation;
  late final Animation<double> _titleShimmerAnimation;
  late final Animation<double> _buttonGlowAnimation;

  final GlobalKey _shimmerKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // 3D Flip
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutBack,
    );

    // Staggered fields
    _staggeredController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _titleShimmerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _fieldFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    _fieldSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutExpo),
      ),
    );

    _buttonGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _staggeredController.dispose();

    _signInEmail.dispose();
    _signInPassword.dispose();
    _signUpUsername.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _signUpConfirmPassword.dispose();

    _signInEmailFocus.dispose();
    _signInPasswordFocus.dispose();
    _signUpUsernameFocus.dispose();
    _signUpEmailFocus.dispose();
    _signUpPasswordFocus.dispose();
    _signUpConfirmPasswordFocus.dispose();

    super.dispose();
  }

  void _toggleSignInSignUp() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSignUp = !_isSignUp;
      if (_isSignUp) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });
  }

  bool _mockSignInLogic(String email, String password) {
    // Replace with real server logic
    return email.isNotEmpty && password.isNotEmpty;
  }

  // -----------------------------------------------------------------------
  //  Sign In: calls userContext.login(...) if successful
  // -----------------------------------------------------------------------
  void _signIn() {
    final email = _signInEmail.text.trim();
    final password = _signInPassword.text.trim();
    debugPrint('Sign In => $email : $password');

    if (_mockSignInLogic(email, password)) {
      final userCtx = context.read<UserContext>();
      userCtx.login(
        userId: '123',
        userName: 'TestUser',
        userEmail: email,
        token: 'fakeToken',
      );
      // DO NOT Navigator.push(...) here. The RootPage will auto-redirect.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign In failed. Please try again.')),
      );
    }
  }

  // -----------------------------------------------------------------------
  //  Sign Up: (dummy example, no real logic)
  // -----------------------------------------------------------------------
  void _signUp() {
    final username = _signUpUsername.text.trim();
    final email = _signUpEmail.text.trim();
    final password = _signUpPassword.text.trim();
    final confirm = _signUpConfirmPassword.text.trim();
    debugPrint('Sign Up => $username, $email, $password, confirm: $confirm');

    // Example check
    if (username.isNotEmpty && email.isNotEmpty && password == confirm) {
      // Possibly create account on server, then auto-login:
      final userCtx = context.read<UserContext>();
      userCtx.login(
        userId: '999',
        userName: username,
        userEmail: email,
        token: 'fakeSignUpToken',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign Up failed. Check fields.')),
      );
    }
  }

  // -----------------------------------------------------------------------
  //  BUILD
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Billion-dollar wave background
          const Positioned.fill(child: BillionOceanBackground()),

          // Centered 3D Flip Card
          Center(
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                double angle = _flipAnimation.value * math.pi;
                bool showSignUp = angle > math.pi / 2;
                if (angle > math.pi / 2) {
                  angle = math.pi - angle;
                }

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 320,
                      maxWidth: 350,
                    ),
                    child: showSignUp ? _buildSignUpCard() : _buildSignInCard(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInCard() {
    return _buildCardBase(
      fields: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShimmerTitle('Sign In'),
          const SizedBox(height: 6),
          FadeTransition(
            opacity: _fieldFadeAnimation,
            child: SlideTransition(
              position: _fieldSlideAnimation,
              child: Column(
                children: [
                  _buildFormTextField(
                    label: 'Email',
                    controller: _signInEmail,
                    focusNode: _signInEmailFocus,
                  ),
                  const SizedBox(height: 12),
                  _buildFormTextField(
                    label: 'Password',
                    controller: _signInPassword,
                    focusNode: _signInPasswordFocus,
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      primaryButton: _buildGlowingButton(
        text: 'Sign In',
        onPressed: _signIn,
        animation: _buttonGlowAnimation,
      ),
      toggleText: "Don't have an account? Sign Up",
      toggleOnTap: _toggleSignInSignUp,
    );
  }

  Widget _buildSignUpCard() {
    return _buildCardBase(
      fields: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShimmerTitle('Sign Up'),
          const SizedBox(height: 6),
          FadeTransition(
            opacity: _fieldFadeAnimation,
            child: SlideTransition(
              position: _fieldSlideAnimation,
              child: Column(
                children: [
                  _buildFormTextField(
                    label: 'Username',
                    controller: _signUpUsername,
                    focusNode: _signUpUsernameFocus,
                  ),
                  const SizedBox(height: 12),
                  _buildFormTextField(
                    label: 'Email',
                    controller: _signUpEmail,
                    focusNode: _signUpEmailFocus,
                  ),
                  const SizedBox(height: 12),
                  _buildFormTextField(
                    label: 'Password',
                    controller: _signUpPassword,
                    focusNode: _signUpPasswordFocus,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  _buildFormTextField(
                    label: 'Confirm Password',
                    controller: _signUpConfirmPassword,
                    focusNode: _signUpConfirmPasswordFocus,
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      primaryButton: _buildGlowingButton(
        text: 'Sign Up',
        onPressed: _signUp,
        animation: _buttonGlowAnimation,
      ),
      toggleText: 'Already have an account? Sign In',
      toggleOnTap: _toggleSignInSignUp,
    );
  }

  Widget _buildCardBase({
    required Widget fields,
    required Widget primaryButton,
    required String toggleText,
    required VoidCallback toggleOnTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surface.withOpacity(0.85),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            fields,
            const SizedBox(height: 12),
            primaryButton,
            const SizedBox(height: 8),
            GestureDetector(
              onTap: toggleOnTap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  toggleText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerTitle(String text) {
    return CustomPaint(
      key: _shimmerKey,
      painter: ShimmerTextPainter(
        text: text,
        progress: _titleShimmerAnimation.value,
        baseColor: Theme.of(context).colorScheme.onSurface,
      ),
      size: const Size(double.infinity, 40),
    );
  }

  Widget _buildFormTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscureText = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        filled: true,
        fillColor: colorScheme.surface.withOpacity(0.25),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.primary.withOpacity(0.8),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildGlowingButton({
    required String text,
    required VoidCallback onPressed,
    required Animation<double> animation,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glowValue = (animation.value * 0.6) + 0.4; // 0.4..1.0

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(glowValue),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: textTheme.labelLarge,
            ),
            onPressed: onPressed,
            child: Text(text),
          ),
        );
      },
    );
  }
}

// ===========================================================================
//  Below this line are all your wave and shimmer painters unchanged
//  Just copy them from your original code (or the snippet below).
// ===========================================================================
class BillionOceanBackground extends StatefulWidget {
  const BillionOceanBackground({super.key});

  @override
  State<BillionOceanBackground> createState() => _BillionOceanBackgroundState();
}

class _BillionOceanBackgroundState extends State<BillionOceanBackground>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _riseController;

  static const int _fullCycleSeconds = 25;

  late final List<_StaticDecoration> _decorations;
  final math.Random _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _fullCycleSeconds),
    )..repeat();

    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _decorations = List.generate(5, (_) => _StaticDecoration.random(_rnd));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _riseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _riseController]),
      builder: (_, __) {
        return CustomPaint(
          painter: _BillionWavePainter(
            colorScheme: colorScheme,
            time: _waveController.value,
            rise: _riseController.value,
            decorations: _decorations,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _BillionWavePainter extends CustomPainter {
  final ColorScheme colorScheme;
  final double time;
  final double rise;
  final List<_StaticDecoration> decorations;

  _BillionWavePainter({
    required this.colorScheme,
    required this.time,
    required this.rise,
    required this.decorations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    _paintDeepGradient(canvas, size);

    _drawRealisticWaveLayer(
      canvas,
      size,
      baseHeightPct: 0.35,
      amplitude: 25,
      frequencyPrimary: 1.4,
      frequencySecondary: 2.8,
      color1: colorScheme.primary.withOpacity(0.85),
      color2: colorScheme.secondary.withOpacity(0.85),
    );

    _drawRealisticWaveLayer(
      canvas,
      size,
      baseHeightPct: 0.45,
      amplitude: 30,
      frequencyPrimary: 1.8,
      frequencySecondary: 3.0,
      color1: colorScheme.tertiary.withOpacity(0.55),
      color2: colorScheme.error.withOpacity(0.55),
    );

    _drawRealisticWaveLayer(
      canvas,
      size,
      baseHeightPct: 0.55,
      amplitude: 38,
      frequencyPrimary: 2.0,
      frequencySecondary: 3.2,
      color1: colorScheme.primary.withOpacity(0.5),
      color2: colorScheme.secondary.withOpacity(0.5),
    );

    _drawStaticDecorations(canvas, size);
  }

  void _paintDeepGradient(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surface,
          colorScheme.surface,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawRealisticWaveLayer(
    Canvas canvas,
    Size size, {
    required double baseHeightPct,
    required double amplitude,
    required double frequencyPrimary,
    required double frequencySecondary,
    required Color color1,
    required Color color2,
  }) {
    final wavePath = Path();
    final double baseHeight =
        size.height - rise * (size.height * (1 - baseHeightPct));
    final double actualAmplitude = amplitude * rise;

    const int waveCycles = 5;
    final double layerShift = waveCycles * time * size.width;

    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color1, color2],
      ).createShader(Offset.zero & size);

    wavePath.moveTo(0, baseHeight);

    final int steps = 50;
    final double dx = size.width / steps;

    for (int i = 0; i <= steps; i++) {
      final x = i * dx;
      final wave1 = math.sin(
        ((x + layerShift) / size.width) * frequencyPrimary * 2 * math.pi,
      );
      final wave2 = math.sin(
        ((x + layerShift) / size.width) * frequencySecondary * 2 * math.pi,
      );
      final combinedWave =
          actualAmplitude * 0.7 * wave1 + actualAmplitude * 0.3 * wave2;

      final y = baseHeight + combinedWave;
      wavePath.lineTo(x, y);
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, wavePaint);
  }

  void _drawStaticDecorations(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    if (shortest <= 0) return;

    for (final deco in decorations) {
      final offset = Offset(deco.x * size.width, deco.y * size.height);
      final angle = 2 * math.pi * time * deco.rotationSpeed;

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(angle);

      final scalePulse =
          0.9 + 0.2 * math.sin(time * 2 * math.pi * deco.scaleSpeed);
      canvas.scale(scalePulse);

      final paint = Paint()..color = deco.color.withOpacity(deco.opacity);

      switch (deco.shapeType) {
        case ShapeType.circle:
          final radius = deco.size * shortest;
          canvas.drawCircle(Offset.zero, radius, paint);
          break;
        case ShapeType.square:
          final half = deco.size * shortest / 2;
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: half * 2,
            height: half * 2,
          );
          canvas.drawRect(rect, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BillionWavePainter oldDelegate) {
    return (oldDelegate.time != time) ||
        (oldDelegate.rise != rise) ||
        (oldDelegate.decorations != decorations);
  }
}

enum ShapeType { circle, square }

class _StaticDecoration {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final Color color;
  final ShapeType shapeType;
  final double rotationSpeed;
  final double scaleSpeed;

  _StaticDecoration({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.color,
    required this.shapeType,
    required this.rotationSpeed,
    required this.scaleSpeed,
  });

  factory _StaticDecoration.random(math.Random rnd) {
    final shape = rnd.nextBool() ? ShapeType.circle : ShapeType.square;
    final randomColorChoices = [
      Colors.deepPurple,
      Colors.green,
      Colors.blue,
      Colors.pink,
      Colors.orange,
    ];
    final color = randomColorChoices[rnd.nextInt(randomColorChoices.length)];
    return _StaticDecoration(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      size: 0.03 + rnd.nextDouble() * 0.05,
      opacity: 0.3 + rnd.nextDouble() * 0.5,
      color: color,
      shapeType: shape,
      rotationSpeed: 0.2 + rnd.nextDouble() * 0.8,
      scaleSpeed: 0.5 + rnd.nextDouble() * 0.5,
    );
  }
}

class ShimmerTextPainter extends CustomPainter {
  final String text;
  final double progress;
  final Color baseColor;

  ShimmerTextPainter({
    required this.text,
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) return;

    final baseStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      foreground: Paint()..color = baseColor,
    );

    final textSpan = TextSpan(text: text, style: baseStyle);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;
    if (textWidth <= 0 || textHeight <= 0) {
      return;
    }

    final dx = (size.width - textWidth) / 2;
    final dy = (size.height - textHeight) / 2;
    final textOffset = Offset(dx, dy);

    textPainter.paint(canvas, textOffset);

    final shimmerRect = Rect.fromLTWH(dx, dy, textWidth, textHeight);
    if (shimmerRect.width <= 0 || shimmerRect.height <= 0) {
      return;
    }

    final shimmerWidth = shimmerRect.width * 0.7;
    final highlightX = dx + (shimmerRect.width + shimmerWidth) * progress;

    final highlightGradient = const LinearGradient(
      colors: [Colors.white10, Colors.white, Colors.white10],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final shiftAmount = highlightX - shimmerWidth;
    final shiftedRect = shimmerRect.shift(Offset(-shiftAmount, 0));

    final shimmerPaint = Paint()
      ..shader = highlightGradient.createShader(shiftedRect)
      ..blendMode = BlendMode.srcIn;

    canvas.saveLayer(shimmerRect, Paint());
    canvas.drawRect(shimmerRect, shimmerPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ShimmerTextPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.text != text ||
        oldDelegate.baseColor != baseColor;
  }
}
