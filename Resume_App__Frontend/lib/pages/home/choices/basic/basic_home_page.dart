import 'dart:async';
import 'package:flutter/material.dart';
import 'job_card.dart';
import '../../../../../app/styles/app_colors.dart';
import '../components/job_card/model/job.dart';

class BasicHomePage extends StatefulWidget {
  const BasicHomePage({super.key});

  @override
  BasicHomePageState createState() => BasicHomePageState();
}

class BasicHomePageState extends State<BasicHomePage> {
  static final List<Job> jobList = [
    Job(
      id: 1,
      title: 'Software Engineer',
      company: 'Tech Corp',
      location: 'Remote',
      salary: '\$120,000/year',
      companyLogo:
          'https://randomwordgenerator.com/img/picture-generator/53e2dc474b5ba414f1dc8460962e33791c3ad6e04e507440772d7cdd904ec4_640.jpg',
    ),
    Job(
      id: 2,
      title: 'Product Manager',
      company: 'Innovate LLC',
      location: 'San Francisco, CA',
      salary: '\$150,000/year',
      companyLogo:
          'https://randomwordgenerator.com/img/picture-generator/53e2dc474b5ba414f1dc8460962e33791c3ad6e04e507440772d7cdd904ec4_640.jpg',
    ),
    Job(
      id: 3,
      title: 'Data Scientist',
      company: 'Analytics Co.',
      location: 'New York, NY',
      salary: '\$130,000/year',
      companyLogo:
          'https://randomwordgenerator.com/img/picture-generator/53e2dc474b5ba414f1dc8460962e33791c3ad6e04e507440772d7cdd904ec4_640.jpg',
    ),
  ];

  final List<Job> _visibleJobs = [];
  Timer? _timer;

  /// Track how far we've scrolled to animate background shapes
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _startStaggeredAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Adds one item at a time to _visibleJobs with a small delay
  void _startStaggeredAnimation() {
    int index = 0;
    const delay = Duration(milliseconds: 400);

    _timer = Timer.periodic(delay, (timer) {
      if (index >= jobList.length) {
        timer.cancel();
      } else {
        setState(() => _visibleJobs.add(jobList[index]));
        index++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We put everything in a stack so we can have a dynamic background
      body: Stack(
        children: [
          // Subtle animated background
          _buildDynamicBackground(),

          // Main content (wave + job list)
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                // Update _scrollOffset as user scrolls to move background shapes
                if (scrollNotification.metrics.axis == Axis.vertical &&
                    scrollNotification is ScrollUpdateNotification) {
                  setState(() {
                    _scrollOffset = scrollNotification.metrics.pixels;
                  });
                }
                return false; // don't stop the notification from propagating
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: false,
                    snap: false,
                    stretch: true,
                    stretchTriggerOffset: 100,
                    onStretchTrigger: () async {
                      debugPrint('User stretched the scroll!');
                    },
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      centerTitle: true,
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Billion Dollar Jobs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Only the coolest, highest-paying gigs.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      background: ClipPath(
                        clipper: _TopWaveClipper(),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accentBlue,
                                AppColors.accentOrange
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // The list of jobs
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 48),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final job = _visibleJobs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: AnimatedJobCard(
                              key: ValueKey(job.id),
                              job: job,
                              onTap: () =>
                                  debugPrint('Applied for ${job.title}'),
                              delay: Duration(milliseconds: 300 * index),
                            ),
                          );
                        },
                        childCount: _visibleJobs.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build some subtle animated shapes in the background
  Widget _buildDynamicBackground() {
    // We'll place 2 or 3 gentle circles that shift slightly with scroll
    return Positioned.fill(
      child: Stack(
        children: [
          // Circle 1: near top-left
          Positioned(
            top: 100 - _scrollOffset * 0.1,
            left: -50,
            child: _FadingCircle(
              diameter: 160,
              color: AppColors.accentBlue.withOpacity(0.15),
            ),
          ),
          // Circle 2: near center-right
          Positioned(
            top: 400 - _scrollOffset * 0.2,
            right: -60,
            child: _FadingCircle(
              diameter: 200,
              color: AppColors.accentOrange.withOpacity(0.10),
            ),
          ),
          // Circle 3: near bottom-left
          // This one will come into view later
          Positioned(
            bottom: -100 + _scrollOffset * 0.05,
            left: 0,
            child: _FadingCircle(
              diameter: 240,
              color: AppColors.accentBlue.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

// A simple widget for our subtle circles
class _FadingCircle extends StatelessWidget {
  final double diameter;
  final Color color;

  const _FadingCircle({
    required this.diameter,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// The "fade + scale" animation for job cards
class AnimatedJobCard extends StatefulWidget {
  final Job job;
  final VoidCallback onTap;
  final Duration delay;

  const AnimatedJobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.delay = Duration.zero,
  });

  @override
  AnimatedJobCardState createState() => AnimatedJobCardState();
}

class AnimatedJobCardState extends State<AnimatedJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Delay the animation if specified
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: JobCard(
          job: widget.job,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

// A wave clipper for the top portion
class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left
    path.lineTo(0, size.height * 0.75);

    // First wave segment
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height * 0.70);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Second wave segment
    final secondControlPoint = Offset(size.width * 0.75, size.height * 0.40);
    final secondEndPoint = Offset(size.width, size.height * 0.70);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Close path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_TopWaveClipper oldClipper) => false;
}
