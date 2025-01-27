import 'dart:ui'; // Needed for ImageFilter (backdrop blur)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/context/user.dart';

/// An enum for different notification types
enum NotificationType {
  interview,
  failure,
  invitation,
}

/// A simple model for a single notification
class AppNotification {
  final String title;
  final NotificationType type;

  AppNotification({
    required this.title,
    required this.type,
  });
}

/// A temporary function to simulate fetching notifications
List<AppNotification> getNotifications() {
  return [
    AppNotification(
      title: 'Your upcoming interview is scheduled for Monday',
      type: NotificationType.interview,
    ),
    AppNotification(
      title: 'Your recent application was unsuccessful',
      type: NotificationType.failure,
    ),
    AppNotification(
      title: 'You have been invited to apply for a new position',
      type: NotificationType.invitation,
    ),
  ];
}

/// A helper function to provide different highlight colors based on the notification type.
/// This still uses standard Flutter colors, but feel free to switch them to colorScheme if you prefer.
Color getNotificationColor(NotificationType type) {
  switch (type) {
    case NotificationType.interview:
      return Colors.blue.withOpacity(0.08);
    case NotificationType.failure:
      return Colors.red.withOpacity(0.08);
    case NotificationType.invitation:
      return Colors.green.withOpacity(0.08);
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  final List<AppNotification> _notifications = [];

  // We'll use an AnimationController to create a staggered entry effect for the list
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    // In a real app, you'd fetch notifications from an API or database.
    _notifications.addAll(getNotifications());

    // Prepare the animation controller for staggering fade-ins
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start the animation
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userContext = Provider.of<UserContext>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Use the theme's background color
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(colorScheme, textTheme),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final notification = _notifications[index];

                // We want to stagger each item’s animation
                final animationIntervalStart = index * 0.1;
                final animationIntervalEnd = animationIntervalStart + 0.9;
                final animation = CurvedAnimation(
                  parent: _listAnimationController,
                  curve: Interval(
                    animationIntervalStart.clamp(0.0, 1.0),
                    animationIntervalEnd.clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                );

                return AnimatedNotificationTile(
                  notification: notification,
                  animation: animation,
                );
              },
              childCount: _notifications.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme, TextTheme textTheme) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 240.0,
      // Use a fallback color if the gradient doesn’t fill the space
      backgroundColor: colorScheme.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Notifications',
          style: textTheme.titleLarge?.copyWith(
            // Match text color to onPrimary or whichever suits your design
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        centerTitle: true,
        background: Container(
          // Example of a multi-stop gradient using the color scheme
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.tertiary.withOpacity(0.7),
                colorScheme.secondary,
              ],
              stops: const [0.0, 0.6, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}

/// A specialized tile that animates into view with a fade + slide + subtle 3D tilt on tap.
class AnimatedNotificationTile extends StatefulWidget {
  final AppNotification notification;
  final Animation<double> animation;

  const AnimatedNotificationTile({
    super.key,
    required this.notification,
    required this.animation,
  });

  @override
  State<AnimatedNotificationTile> createState() =>
      _AnimatedNotificationTileState();
}

class _AnimatedNotificationTileState extends State<AnimatedNotificationTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        // Fade in
        final opacity = widget.animation.value;
        // Slide up from 20px below
        final slideOffset = 20 * (1.0 - widget.animation.value);

        if (opacity == 0) {
          // Not ready to display yet
          return const SizedBox.shrink();
        }

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slideOffset),
            child: child,
          ),
        );
      },
      child: _build3DTappableTile(context, colorScheme, textTheme),
    );
  }

  /// Build the tile with a 3D rotation on press.
  Widget _build3DTappableTile(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final backgroundColor = getNotificationColor(widget.notification.type);
    // We'll do a subtle 3D rotation around the X-axis
    final tiltAngle = _isPressed ? 0.08 : 0.0; // ~4.58 degrees in radians

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTap: () {
        // Optionally handle tap event
      },
      child: Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(tiltAngle),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background blur
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(),
                ),
                // Semi-transparent overlay + shadow
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                    // Add a subtle box shadow to elevate the tile
                    boxShadow: [
                      BoxShadow(
                        // Could also use colorScheme.shadow.withOpacity(0.15)
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      widget.notification.title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    leading: Icon(
                      _getNotificationIcon(widget.notification.type),
                      color:
                          _getNotificationIconColor(widget.notification.type),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pick an icon based on notification type
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.interview:
        return Icons.work;
      case NotificationType.failure:
        return Icons.close;
      case NotificationType.invitation:
        return Icons.email;
    }
  }

  /// Pick an icon color based on notification type
  Color _getNotificationIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.interview:
        return Colors.blue.shade400;
      case NotificationType.failure:
        return Colors.red.shade400;
      case NotificationType.invitation:
        return Colors.green.shade400;
    }
  }
}
