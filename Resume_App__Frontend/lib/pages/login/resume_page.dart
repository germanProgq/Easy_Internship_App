// lib/ui/pages/resume_page.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/context/user.dart';
import 'resume_forms.dart';

class ResumeForm extends StatefulWidget {
  const ResumeForm({super.key});

  @override
  State<ResumeForm> createState() => _ResumeFormState();
}

class _ResumeFormState extends State<ResumeForm> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _waveController;

  late final List<List<TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    final userContext = Provider.of<UserContext>(context, listen: false);

    // Build text controllers for each section
    _controllers = premiumFormData.map((sectionMap) {
      final fieldsString = sectionMap.values.first;
      final fields = fieldsString.split(',').map((f) => f.trim()).toList();
      return fields.map((fieldName) {
        final existingValue = userContext.resumeData[fieldName] ?? '';
        return TextEditingController(text: existingValue);
      }).toList();
    }).toList();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    for (final group in _controllers) {
      for (final c in group) {
        c.dispose();
      }
    }
    _waveController.dispose();
    super.dispose();
  }

  bool _validatePage(int pageIndex) {
    for (final controller in _controllers[pageIndex]) {
      if (controller.text.trim().isEmpty) return false;
    }
    return true;
  }

  bool _validateAllPages() {
    for (final group in _controllers) {
      for (final controller in group) {
        if (controller.text.trim().isEmpty) return false;
      }
    }
    return true;
  }

  Map<String, String> _gatherAllData() {
    final Map<String, String> allData = {};
    for (int pageIndex = 0; pageIndex < premiumFormData.length; pageIndex++) {
      final sectionMap = premiumFormData[pageIndex];
      final sectionTitle = sectionMap.keys.first;
      final fieldsString = sectionMap[sectionTitle] ?? '';
      final fields = fieldsString.split(',').map((f) => f.trim()).toList();

      final controllersForPage = _controllers[pageIndex];
      for (int i = 0; i < fields.length; i++) {
        final fieldName = fields[i];
        allData[fieldName] = controllersForPage[i].text.trim();
      }
    }
    return allData;
  }

  void _onFormComplete(Map<String, String> allData) {
    final userContext = Provider.of<UserContext>(context, listen: false);
    userContext.updateResumeData(allData);

    debugPrint("=== FORM SUBMITTED ===");
    allData.forEach((k, v) => debugPrint("$k => $v"));

    // No Navigator call here; RootPage will detect resume completion.
  }

  void _onNextPressed() {
    if (!_validatePage(_currentPage)) {
      _showPremiumDialog(
        title: "Incomplete Fields",
        message: "Please fill all fields on this page before proceeding.",
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onBackPressed() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onSubmitPressed() {
    if (_validateAllPages()) {
      final allData = _gatherAllData();
      _onFormComplete(allData);
    } else {
      _showPremiumDialog(
        title: "Incomplete Fields",
        message: "Please fill all fields in every section before submitting.",
      );
    }
  }

  void _showPremiumDialog({
    required String title,
    required String message,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      pageBuilder: (_, __, ___) {
        return _RandomWormBackdrop(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: _DialogContent(
                title: title,
                message: message,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutBack,
        );
        final rotateValue = Tween<double>(begin: 0.2, end: 0.0).animate(curved);
        final scaleValue = Tween<double>(begin: 0.6, end: 1.0).animate(curved);

        return AnimatedBuilder(
          animation: curved,
          builder: (context, child2) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(rotateValue.value)
                ..scale(scaleValue.value, scaleValue.value),
              child: Opacity(
                opacity: curved.value,
                child: child2,
              ),
            );
          },
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final colorScheme = Theme.of(context).colorScheme;
              return CustomPaint(
                painter: _MultiWavePainter(
                  waveValue: _waveController.value * 2 * math.pi,
                  colorScheme: colorScheme,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: premiumFormData.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, sectionIndex) {
                      final sectionMap = premiumFormData[sectionIndex];
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double offset = 0;
                          if (_pageController.hasClients &&
                              _pageController.position.haveDimensions) {
                            offset = _pageController.page! - sectionIndex;
                          }
                          final scale =
                              (1 - offset.abs() * 0.2).clamp(0.85, 1.0);
                          return Transform.scale(
                            scale: scale,
                            child: _buildSectionPage(sectionMap),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        PremiumAnimatedButton(
                          text: "Back",
                          onPressed: _onBackPressed,
                        )
                      else
                        const SizedBox(),
                      PremiumAnimatedButton(
                        text: _currentPage == premiumFormData.length - 1
                            ? "Submit"
                            : "Next",
                        onPressed: _currentPage == premiumFormData.length - 1
                            ? _onSubmitPressed
                            : _onNextPressed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPage(Map<String, String> sectionMap) {
    final colorScheme = Theme.of(context).colorScheme;
    final sectionTitle = sectionMap.keys.first;
    final fieldsString = sectionMap[sectionTitle] ?? '';
    final fields = fieldsString.split(',').map((f) => f.trim()).toList();
    final controllers = _controllers[premiumFormData.indexOf(sectionMap)];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          color: colorScheme.surface.withOpacity(0.70),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _StaticWaterPainter(colorScheme: colorScheme),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sectionTitle.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < fields.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: controllers[i],
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: fields[i],
                            labelStyle: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface.withOpacity(0.4),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.outline.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================================
//  Additional painters & classes (unchanged from your snippet)
// =======================================================================
class _MultiWavePainter extends CustomPainter {
  final double waveValue;
  final ColorScheme colorScheme;

  _MultiWavePainter({
    required this.waveValue,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(
      canvas,
      size,
      amplitude: 30,
      speedOffset: 0,
      verticalShift: 0.55,
      color: colorScheme.primary.withOpacity(0.3),
    );
    _drawWave(
      canvas,
      size,
      amplitude: 25,
      speedOffset: 1,
      verticalShift: 0.60,
      color: colorScheme.secondary.withOpacity(0.25),
    );
    _drawWave(
      canvas,
      size,
      amplitude: 35,
      speedOffset: 2,
      verticalShift: 0.50,
      color: colorScheme.tertiary.withOpacity(0.20),
    );
    _drawWave(
      canvas,
      size,
      amplitude: 20,
      speedOffset: 3,
      verticalShift: 0.65,
      color: colorScheme.error.withOpacity(0.15),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double amplitude,
    required double speedOffset,
    required double verticalShift,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    final path = Path();
    final midHeight = size.height * verticalShift;
    path.moveTo(0, midHeight);

    for (double x = 0; x <= size.width; x++) {
      final y = amplitude *
              math.sin(
                  (x / size.width * 2 * math.pi) + (waveValue + speedOffset)) +
          midHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MultiWavePainter oldDelegate) => true;
}

class _StaticWaterPainter extends CustomPainter {
  final ColorScheme colorScheme;

  _StaticWaterPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.onSurface.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const numberOfLines = 5;
    for (int i = 0; i < numberOfLines; i++) {
      final path = Path();
      final yOffset = size.height * (0.2 + 0.15 * i);

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x += 15) {
        final waveHeight = 5 + i * 3;
        final y =
            waveHeight * math.sin((x / size.width) * 2 * math.pi) + yOffset;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StaticWaterPainter oldDelegate) => false;
}

class _RandomWormBackdrop extends StatefulWidget {
  final Widget child;
  const _RandomWormBackdrop({required this.child});

  @override
  State<_RandomWormBackdrop> createState() => _RandomWormBackdropState();
}

class _RandomWormBackdropState extends State<_RandomWormBackdrop>
    with TickerProviderStateMixin {
  late AnimationController _wormsController;
  late List<_WormParams> _worms;

  @override
  void initState() {
    super.initState();
    _wormsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _worms = _generateWorms(12);
  }

  @override
  void dispose() {
    _wormsController.dispose();
    super.dispose();
  }

  List<_WormParams> _generateWorms(int count) {
    final rand = math.Random();
    final worms = <_WormParams>[];
    for (int i = 0; i < count; i++) {
      final colorFactor = rand.nextDouble();
      final startX = rand.nextDouble();
      final startY = rand.nextDouble();
      final angle = rand.nextDouble() * 2 * math.pi;
      final speed = 0.02 + rand.nextDouble() * 0.05;
      final amplitude = 20 + rand.nextDouble() * 30;
      final freq = 1.0 + rand.nextDouble() * 3.0;
      final length = 7 + rand.nextInt(6);
      worms.add(_WormParams(
        colorFactor: colorFactor,
        startX: startX,
        startY: startY,
        angle: angle,
        speed: speed,
        amplitude: amplitude,
        frequency: freq,
        segmentCount: length,
      ));
    }
    return worms;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(color: colorScheme.surface.withOpacity(0.3)),
        AnimatedBuilder(
          animation: _wormsController,
          builder: (context, child) {
            final time = _wormsController.value;
            return CustomPaint(
              painter: _RandomWormPainter(
                colorScheme: colorScheme,
                worms: _worms,
                time: time,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _WormParams {
  final double colorFactor;
  final double startX;
  final double startY;
  final double angle;
  final double speed;
  final double amplitude;
  final double frequency;
  final int segmentCount;

  _WormParams({
    required this.colorFactor,
    required this.startX,
    required this.startY,
    required this.angle,
    required this.speed,
    required this.amplitude,
    required this.frequency,
    required this.segmentCount,
  });
}

class _RandomWormPainter extends CustomPainter {
  final ColorScheme colorScheme;
  final List<_WormParams> worms;
  final double time;

  _RandomWormPainter({
    required this.colorScheme,
    required this.worms,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final worm in worms) {
      final color = _pickColor(colorScheme, worm.colorFactor).withOpacity(0.25);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final segmentSpacing = 10.0;

      final distance = worm.speed * time * size.width * 4.0;
      final baseX = worm.startX * size.width + distance * math.cos(worm.angle);
      final baseY = worm.startY * size.height + distance * math.sin(worm.angle);

      final firstPt = _wormPoint(
        segmentIndex: 0,
        worm: worm,
        baseX: baseX,
        baseY: baseY,
        spacing: segmentSpacing,
        globalTime: time,
      );
      path.moveTo(firstPt.dx, firstPt.dy);

      for (int seg = 1; seg <= worm.segmentCount; seg++) {
        final pt = _wormPoint(
          segmentIndex: seg,
          worm: worm,
          baseX: baseX,
          baseY: baseY,
          spacing: segmentSpacing,
          globalTime: time,
        );
        path.lineTo(pt.dx, pt.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  Offset _wormPoint({
    required int segmentIndex,
    required _WormParams worm,
    required double baseX,
    required double baseY,
    required double spacing,
    required double globalTime,
  }) {
    final dist = segmentIndex * spacing;
    final dx = dist * math.cos(worm.angle);
    final dy = dist * math.sin(worm.angle);

    final wiggle = worm.amplitude *
        math.sin((globalTime * 10.0 + segmentIndex) * worm.frequency);

    final perp = worm.angle + math.pi / 2;
    final wx = wiggle * math.cos(perp);
    final wy = wiggle * math.sin(perp);

    return Offset(baseX + dx + wx, baseY + dy + wy);
  }

  Color _pickColor(ColorScheme scheme, double factor) {
    if (factor < 0.25) {
      return scheme.primary;
    } else if (factor < 0.5) {
      return scheme.secondary;
    } else if (factor < 0.75) {
      return scheme.error;
    } else {
      return scheme.tertiaryContainer ?? scheme.primaryContainer;
    }
  }

  @override
  bool shouldRepaint(_RandomWormPainter oldDelegate) => true;
}

class PremiumAnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const PremiumAnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<PremiumAnimatedButton> createState() => _PremiumAnimatedButtonState();
}

class _PremiumAnimatedButtonState extends State<PremiumAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  late Animation<Color?> _colorAnim;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final colorScheme = Theme.of(context).colorScheme;

      _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
      );

      _colorAnim = ColorTween(
        begin: colorScheme.primary,
        end: colorScheme.secondary ?? colorScheme.primary,
      ).animate(
        CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
      );

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = _initialized ? _scaleAnim.value : 1.0;
          final currentColor =
              _initialized ? _colorAnim.value : colorScheme.primary;

          return Transform.scale(
            scale: scale,
            child: CustomPaint(
              foregroundPainter: _ButtonWaterPainter(colorScheme: colorScheme),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      currentColor ?? colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (currentColor ?? colorScheme.primary)
                          .withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ButtonWaterPainter extends CustomPainter {
  final ColorScheme colorScheme;

  _ButtonWaterPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.onPrimary.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const waveCount = 3;
    for (int i = 0; i < waveCount; i++) {
      final path = Path();
      final yOffset = size.height * (0.3 + 0.2 * i);

      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 8) {
        final waveHeight = 4 + i * 2;
        final y =
            waveHeight * math.sin((x / size.width) * 2 * math.pi) + yOffset;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ButtonWaterPainter oldDelegate) => false;
}

class _DialogContent extends StatelessWidget {
  final String title;
  final String message;

  const _DialogContent({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            color: colorScheme.surface.withOpacity(0.8),
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.85),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: PremiumAnimatedButton(
                      text: "OK",
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
