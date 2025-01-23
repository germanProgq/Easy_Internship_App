import 'package:flutter/material.dart';
import '../components/job_card/model/job.dart';

class TinderJobCard extends StatefulWidget {
  final Job job;
  final VoidCallback? onLike;
  final VoidCallback? onDecline;

  const TinderJobCard({
    super.key,
    required this.job,
    this.onLike,
    this.onDecline,
  });

  @override
  State<TinderJobCard> createState() => _TinderJobCardState();
}

class _TinderJobCardState extends State<TinderJobCard>
    with SingleTickerProviderStateMixin {
  /// Tracks the user’s drag along X-Y
  Offset _dragOffset = Offset.zero;

  /// Controls spring-back or fling animations
  late AnimationController _controller;
  late Animation<Offset> _animation;

  /// Distance beyond which a swipe is considered final
  final double _swipeThreshold = 120.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Reset drag offset when animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _dragOffset = Offset.zero);
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // SWIPE LOGIC
  // --------------------------------------------------------------------------
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final dx = _dragOffset.dx;

    if (dx > _swipeThreshold) {
      widget.onLike?.call();
      _animateCardAway(const Offset(500, 0));
    } else if (dx < -_swipeThreshold) {
      widget.onDecline?.call();
      _animateCardAway(const Offset(-500, 0));
    } else {
      _springBack();
    }
  }

  void _animateCardAway(Offset targetOffset) {
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(_controller);
    _controller.forward();
  }

  void _springBack() {
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(_controller);
    _controller.forward();
  }

  // --------------------------------------------------------------------------
  // BOTTOM SHEET (More Info)
  // --------------------------------------------------------------------------
  void _showMoreJobInfo() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Job title
                Text(
                  widget.job.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  widget.job.description ?? 'No Description Available',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),

                // Like button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onLike?.call();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("I'm Interested!"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Decline button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDecline?.call();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("Not a Fit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Keep aspect ratio, but cap the height to 80% of screen
    final double cardWidth = screenWidth > 600 ? 500 : screenWidth * 0.9;
    final double maxCardHeight = screenHeight * 0.8;
    final double cardHeight = (cardWidth * 16 / 9).clamp(0, maxCardHeight);

    // Tilt card slightly while dragging horizontally
    const double rotationFactor = 0.003;
    final double rotation = rotationFactor * _dragOffset.dx;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: _animation.value,
          child: Transform.rotate(
            angle: rotation,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: _showMoreJobInfo, // Tapping shows bottom sheet
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16.0),
            // If job is premium, add a subtle gold border
            border: widget.job.isPremium
                ? Border.all(
                    color: Colors.amberAccent.shade200,
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.4),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        // Company Logo
                        _buildCompanyLogo(colorScheme),
                        const SizedBox(height: 16.0),
                        // Job Details
                        _buildJobDetails(textTheme, colorScheme),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _showMoreJobInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // If premium, place a gold "PREMIUM" badge top-left
              if (widget.job.isPremium)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Decline button (bottom-left)
              Positioned(
                bottom: 16,
                left: 16,
                child: GestureDetector(
                  onTap: widget.onDecline,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.error,
                    child: Icon(
                      Icons.close,
                      color: colorScheme.onError,
                      size: 28,
                    ),
                  ),
                ),
              ),

              // Like button (bottom-right)
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: widget.onLike,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primary,
                    child: Icon(
                      Icons.check,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // COMPONENTS
  // --------------------------------------------------------------------------
  Widget _buildCompanyLogo(ColorScheme colorScheme) {
    return Container(
      width: 60.0,
      height: 60.0,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        image: widget.job.companyLogo != null
            ? DecorationImage(
                image: NetworkImage(widget.job.companyLogo!),
                fit: BoxFit.cover,
              )
            : null,
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: widget.job.companyLogo == null
          ? Icon(
              Icons.business,
              color: colorScheme.primary,
              size: 30.0,
            )
          : null,
    );
  }

  Widget _buildJobDetails(TextTheme textTheme, ColorScheme colorScheme) {
    // If job is premium, override salary with $1,000,000
    final displaySalary = (widget.job.salary ?? 'Salary Info Not Provided');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Job Title
        Text(
          widget.job.title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),

        // Company
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, color: colorScheme.primary, size: 18.0),
            const SizedBox(width: 6.0),
            Text(
              widget.job.company,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Location
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              color: colorScheme.outlineVariant,
              size: 18.0,
            ),
            const SizedBox(width: 6.0),
            Text(
              widget.job.location ?? 'Location Not Specified',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // Salary
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money,
              color: colorScheme.secondary,
              size: 18.0,
            ),
            const SizedBox(width: 6.0),
            Text(
              displaySalary,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
