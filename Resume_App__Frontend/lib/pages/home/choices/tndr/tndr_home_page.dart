import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tndr_job_card.dart';
import '../../../../../app/styles/app_colors.dart';
import '../components/job_card/model/job.dart';

/// Subtle job scraper (unchanged from original logic)
class DeepDiveJobScraper {
  Future<List<Job>> scrapeLatestJobs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Job(
        id: 101,
        title: 'Senior Flutter Developer',
        company: 'AquaTech Global',
        location: 'Remote Oceanic',
        salary: '\$180,000/year',
        companyLogo: 'https://picsum.photos/seed/101/200/200',
        isPremium: true,
        description:
            'Join our deep dive into Flutter’s ocean of possibilities. Build immersive, fluid UIs with advanced techniques.',
      ),
      Job(
        id: 102,
        title: 'AI Engineer',
        company: 'BlueFuture Inc.',
        location: 'San Francisco Bay',
        salary: '\$220,000/year + Equity',
        companyLogo: 'https://picsum.photos/seed/102/200/200',
        description:
            'Work on state-of-the-art ML pipelines, training models to track and analyze marine data flows.',
      ),
    ];
  }
}

class AquaJobFiller {
  Future<void> fillApplication(Job job) async {
    await Future.delayed(const Duration(seconds: 1));
    // In real life, this might fill forms automatically, etc.
  }
}

Future<List<Job>> fetchJobs() async {
  final deepDiveScraper = DeepDiveJobScraper();
  final localJobs = <Job>[
    Job(
      id: 1,
      title: 'Flutter Developer',
      company: 'CoralApps Inc.',
      location: 'Remote',
      salary: '\$85,000/year',
      companyLogo: 'https://picsum.photos/seed/1/200/200',
      description:
          'Build cross-platform mobile apps in Flutter. Collaborate on a team that cares about fluid UIs.',
    ),
    Job(
      id: 2,
      title: 'Frontend Engineer',
      company: 'Waveify',
      location: 'New York, NY',
      salary: '\$100,000/year',
      companyLogo: 'https://picsum.photos/seed/2/200/200',
      description:
          'Develop modern React-based UIs with an emphasis on wave-like transitions and watery animations.',
    ),
    Job(
      id: 3,
      title: 'DevOps Specialist',
      company: 'CloudOcean',
      location: 'Seattle, WA',
      salary: '\$135,000/year',
      companyLogo: 'https://picsum.photos/seed/3/200/200',
      description:
          'Manage CI/CD pipelines, optimize container orchestration, and navigate complex cloud “seas.”',
    ),
  ];

  final scrapedJobs = await deepDiveScraper.scrapeLatestJobs();
  return [...localJobs, ...scrapedJobs];
}

class TndrHomePage extends StatefulWidget {
  const TndrHomePage({super.key});

  @override
  State<TndrHomePage> createState() => _TndrHomePageState();
}

class _TndrHomePageState extends State<TndrHomePage>
    with TickerProviderStateMixin {
  List<Job>? _jobs;
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;

  final double _swipeThreshold = 150.0;
  final double _minimalDrag = 20.0;

  bool _canMove = false;
  bool _isAnimating = false;

  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;

  /// Slowed wave animations for subtle effect
  late AnimationController _waveController;
  late AnimationController _rippleController;

  final double _maxRotation = 0.25;

  final AquaJobFiller _autoFiller = AquaJobFiller();

  // Overlays for LIKE/NOPE
  late AnimationController _likeFadeController;
  late AnimationController _nopeFadeController;
  late Animation<double> _likeOpacity;
  late Animation<double> _nopeOpacity;

  @override
  void initState() {
    super.initState();
    _initializeJobs();

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );

    _swipeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          if (_jobs != null && _currentIndex < _jobs!.length) {
            _currentIndex++;
          }
          _dragOffset = Offset.zero;
          _canMove = false;
          _isAnimating = false;
        });
        _swipeController.reset();
      }
    });

    /// Slower, more subtle wave animations
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // slowed from 8 to 12
    )..repeat();

    /// Gentle ripple, also slowed
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // slowed from 5 to 8
    )..repeat(reverse: true);

    _likeFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0,
      upperBound: 1,
    );

    _nopeFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0,
      upperBound: 1,
    );

    _likeOpacity = CurvedAnimation(
      parent: _likeFadeController,
      curve: Curves.easeIn,
    );

    _nopeOpacity = CurvedAnimation(
      parent: _nopeFadeController,
      curve: Curves.easeIn,
    );
  }

  Future<void> _initializeJobs() async {
    final jobs = await fetchJobs();
    setState(() {
      _jobs = jobs;
    });
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _waveController.dispose();
    _rippleController.dispose();
    _likeFadeController.dispose();
    _nopeFadeController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating || _jobs == null || _currentIndex >= _jobs!.length) return;
    setState(() {
      _dragOffset = Offset.zero;
      _canMove = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating || _jobs == null || _currentIndex >= _jobs!.length) return;

    double totalDrag = _dragOffset.dx + details.delta.dx;
    if (!_canMove && totalDrag.abs() > _minimalDrag) {
      setState(() {
        _canMove = true;
      });
    }

    if (_canMove) {
      setState(() {
        _dragOffset += Offset(details.delta.dx, 0.0);
      });
      _updateLikeNopeOverlays();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating || _jobs == null || _currentIndex >= _jobs!.length) return;

    final dx = _dragOffset.dx;
    if (dx.abs() >= _swipeThreshold) {
      _animateSwipe(dx > 0);
    } else {
      _animateSnapBack();
    }
  }

  void _updateLikeNopeOverlays() {
    final dx = _dragOffset.dx;
    if (dx > _swipeThreshold / 2) {
      _likeFadeController.forward();
    } else {
      _likeFadeController.reverse();
    }
    if (dx < -_swipeThreshold / 2) {
      _nopeFadeController.forward();
    } else {
      _nopeFadeController.reverse();
    }
  }

  void _animateSwipe(bool swipeRight) {
    setState(() {
      _isAnimating = true;
    });
    final screenWidth = MediaQuery.of(context).size.width;
    final endOffset =
        swipeRight ? Offset(screenWidth * 2, 0) : Offset(-screenWidth * 2, 0);

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: endOffset,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );

    _swipeController.forward().then((_) async {
      if (swipeRight && _jobs != null && _currentIndex < _jobs!.length) {
        await _autoFiller.fillApplication(_jobs![_currentIndex]);
      }
    });
  }

  void _animateSnapBack() {
    setState(() {
      _isAnimating = true;
    });
    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );
    _swipeController.forward().then((_) {
      _likeFadeController.reverse();
      _nopeFadeController.reverse();
    });
  }

  double _calculateRotation() {
    if (_dragOffset.dx.abs() >= _minimalDrag) {
      return (_dragOffset.dx / MediaQuery.of(context).size.width) *
          _maxRotation;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_jobs == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
            return Container();
          }
          return Stack(
            children: [
              // Subtle watery background
              AnimatedBuilder(
                animation:
                    Listenable.merge([_waveController, _rippleController]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: AquaBackgroundPainter(
                      waveValue: _waveController.value,
                      rippleValue: _rippleController.value,
                    ),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                  );
                },
              ),
              Center(
                child: _currentIndex < _jobs!.length
                    ? _buildTopCard()
                    : _buildFinalCard(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopCard() {
    final job = _jobs![_currentIndex];
    final rotation = _calculateRotation();

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _swipeController,
        builder: (_, child) {
          final swipeOffset = _swipeAnimation.value;
          final scale = 1.0 - (_dragOffset.dx.abs() / 2000.0).clamp(0.0, 0.05);
          return Transform.translate(
            offset: _dragOffset + swipeOffset,
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            TinderJobCard(
              key: ValueKey(_currentIndex),
              job: job,
              onLike: () => _animateSwipe(true),
              onDecline: () => _animateSwipe(false),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: FadeTransition(
                opacity: _likeOpacity,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LIKE',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: FadeTransition(
                opacity: _nopeOpacity,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NOPE',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "You’ve reached the shore!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            "No more jobs in this ocean at the moment.\nCome back later for new waves!",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A more subtle background painter that draws gentle waves, fewer bubbles, and faint ripples.
class AquaBackgroundPainter extends CustomPainter {
  final double waveValue;
  final double rippleValue;

  const AquaBackgroundPainter({
    required this.waveValue,
    required this.rippleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    _drawWaves(canvas, size);
    _drawFewerBubbles(canvas, size);
    _drawSoftRipples(canvas, size);
  }

  /// Much smaller wave amplitude and more transparency
  void _drawWaves(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.07) // more subtle
      ..style = PaintingStyle.fill;

    // Draw only 2 wave layers with small amplitude
    for (int i = 0; i < 2; i++) {
      final path = Path();
      final waveHeight = 5.0 + i * 3.0; // very small wave amplitude
      final yOffset = size.height * 0.7 + i * 20.0; // slightly lower

      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 10) {
        final theta =
            (x / size.width * 2 * math.pi) + (waveValue * 2 * math.pi) + i;
        final y = yOffset + math.sin(theta) * waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, wavePaint);
    }
  }

  /// Reduced bubble count and less alpha
  void _drawFewerBubbles(Canvas canvas, Size size) {
    final bubblePaint = Paint()..color = Colors.white.withOpacity(0.03);
    final rng = math.Random(42);

    // Only 6 bubbles
    for (int i = 0; i < 6; i++) {
      final dx = rng.nextDouble() * size.width;
      final baseDy = rng.nextDouble() * size.height;
      // Even smaller vertical displacement
      final dy = baseDy - (waveValue * 50 * (i + 1) % (size.height + 50));
      final radius = 6 + 10.0 * rng.nextDouble(); // smaller radius

      canvas.drawCircle(Offset(dx, dy), radius, bubblePaint);
    }
  }

  /// Reduced ripple count and opacity
  void _drawSoftRipples(Canvas canvas, Size size) {
    final ripplePaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.1);
    final rng = math.Random(84);

    // Only 3 ripples
    for (int i = 0; i < 3; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final rippleSize = 10 +
          20 * (0.5 + 0.5 * math.sin(rippleValue * math.pi * 2)); // smaller

      canvas.drawCircle(Offset(dx, dy), rippleSize, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AquaBackgroundPainter oldDelegate) {
    return oldDelegate.waveValue != waveValue ||
        oldDelegate.rippleValue != rippleValue;
  }
}
