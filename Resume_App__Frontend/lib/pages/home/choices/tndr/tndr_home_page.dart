// lib/screens/tndr_home_page.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tndr_job_card.dart';
import '../../../../../app/styles/app_colors.dart';
import '../components/job_card/model/job.dart';

// PREMIUM: Hypothetical classes to illustrate "big budget" features.
class PremiumJobScraper {
  Future<List<Job>> scrapeLatestJobs() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Job(
        id: 101,
        title: 'Senior Flutter Developer',
        company: 'LuxTech Global',
        location: 'Remote USA',
        salary: '\$180,000/year',
        companyLogo: 'https://picsum.photos/seed/101/200/200',
        isPremium: true,
        description:
            'Join our elite team to build gorgeous Flutter apps with elegance and style. This is a premium role with unmatched benefits.',
      ),
      Job(
        id: 102,
        title: 'AI Engineer',
        company: 'DeepFuture Inc.',
        location: 'San Francisco, CA',
        salary: '\$220,000/year + Equity',
        companyLogo: 'https://picsum.photos/seed/102/200/200',
        description:
            'Work on cutting-edge ML and AI pipelines. Automated data flows, advanced model training, everything you dream of in AI.',
      ),
    ];
  }
}

// PREMIUM: A class that automatically fills out job applications
class AutoJobFiller {
  Future<void> fillApplication(Job job) async {
    await Future.delayed(const Duration(seconds: 1));
    // Imagine hooking into real forms, etc.
  }
}

// Combine sample jobs with newly scraped jobs
Future<List<Job>> fetchJobs() async {
  final premiumScraper = PremiumJobScraper();
  final localJobs = <Job>[
    Job(
      id: 1,
      title: 'Flutter Developer',
      company: 'CoolApps Inc.',
      location: 'Remote',
      salary: '\$85,000/year',
      companyLogo: 'https://picsum.photos/seed/1/200/200',
      description:
          'Build cross-platform mobile apps using Flutter. Work closely with a team of developers and designers.',
    ),
    Job(
      id: 2,
      title: 'Frontend Engineer',
      company: 'Webify',
      location: 'New York, NY',
      salary: '\$100,000/year',
      companyLogo: 'https://picsum.photos/seed/2/200/200',
      description:
          'Implement responsive UIs with React and TypeScript. Collaborate with designers to deliver polished user experiences.',
    ),
    Job(
      id: 3,
      title: 'DevOps Specialist',
      company: 'CloudOps',
      location: 'Seattle, WA',
      salary: '\$135,000/year',
      companyLogo: 'https://picsum.photos/seed/3/200/200',
      description:
          'Manage CI/CD pipelines, optimize Kubernetes clusters, and maintain cloud infrastructure for high-traffic applications.',
    ),
  ];

  final scrapedJobs = await premiumScraper.scrapeLatestJobs();
  return [...localJobs, ...scrapedJobs];
}

class TndrHomePage extends StatefulWidget {
  const TndrHomePage({super.key});

  @override
  State<TndrHomePage> createState() => _TndrHomePageState();
}

class _TndrHomePageState extends State<TndrHomePage>
    with TickerProviderStateMixin {
  // Make this nullable, so we can show a loading state until it's ready.
  List<Job>? _jobs;

  // Which job we're currently showing
  int _currentIndex = 0;

  // Horizontal drag offset
  Offset _dragOffset = Offset.zero;

  // Swipe thresholds
  final double _swipeThreshold = 150.0;
  final double _minimalDrag = 20.0;

  bool _canMove = false;
  bool _isAnimating = false;

  // Animations for snapping back or swiping off-screen
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;

  // Background animations
  late AnimationController _bubblesController;
  late AnimationController _sparkleController;

  // Maximum rotation angle (~14 degrees)
  final double _maxRotation = 0.25;

  // Premium auto-filler
  final AutoJobFiller _autoFiller = AutoJobFiller();

  // Overlays for LIKE/NOPE
  late AnimationController _likeFadeController;
  late AnimationController _nopeFadeController;
  late Animation<double> _likeOpacity;
  late Animation<double> _nopeOpacity;

  @override
  void initState() {
    super.initState();

    // Start loading jobs
    _initializeJobs();

    // Swipe animations
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
          // Reset
          _dragOffset = Offset.zero;
          _canMove = false;
          _isAnimating = false;
        });
        _swipeController.reset();
      }
    });

    // Background animations
    _bubblesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Fade animations for LIKE/NOPE
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
    _bubblesController.dispose();
    _sparkleController.dispose();
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
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));

    _swipeController.forward().then((_) async {
      if (swipeRight && _jobs != null && _currentIndex < _jobs!.length) {
        // Auto-fill if liked
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
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));
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
    // If jobs haven't loaded yet, show a loading spinner
    if (_jobs == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (_, constraints) {
          // If there's no space to paint, just show an empty Container
          if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
            return Container();
          }
          return Stack(
            children: [
              AnimatedBuilder(
                animation:
                    Listenable.merge([_bubblesController, _sparkleController]),
                builder: (_, __) => CustomPaint(
                  painter: PremiumBackgroundPainter(
                    bubbleValue: _bubblesController.value,
                    sparkleValue: _sparkleController.value,
                  ),
                  child: SizedBox(
                    // Ensure the child has the full available size
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                ),
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
        builder: (context, child) {
          final swipeOffset = _swipeAnimation.value;
          return Transform.translate(
            offset: _dragOffset + swipeOffset,
            child: Transform.rotate(
              angle: rotation,
              child: child,
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
            "End of the Line!",
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
            "No more premium jobs at the moment. Check back soon for more opportunities!",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Premium background painter that draws floating bubbles and sparkles
class PremiumBackgroundPainter extends CustomPainter {
  final double bubbleValue;
  final double sparkleValue;
  PremiumBackgroundPainter({
    required this.bubbleValue,
    required this.sparkleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      // If there's literally no size to paint, just return.
      return;
    }

    _drawBubbles(canvas, size);
    _drawSparkles(canvas, size);
  }

  void _drawBubbles(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.06);
    final rng = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final dx = rng.nextDouble() * size.width;
      final baseDy = rng.nextDouble() * size.height;
      final dy = baseDy - (bubbleValue * 50 * (i % 5));
      final radius = 15 + 25.0 * rng.nextDouble();
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final sparklePaint = Paint()..color = Colors.amber.withOpacity(0.3);
    final rng = math.Random(84);
    for (int i = 0; i < 10; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      // Flicker in size
      final sparkleSize =
          5 + 20 * (0.5 + 0.5 * math.sin(sparkleValue * math.pi * 2));
      canvas.drawCircle(Offset(dx, dy), sparkleSize, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PremiumBackgroundPainter oldDelegate) {
    return oldDelegate.bubbleValue != bubbleValue ||
        oldDelegate.sparkleValue != sparkleValue;
  }
}
