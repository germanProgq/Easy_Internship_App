import 'dart:ui'; // For ImageFilter (frosted effect)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Example imports for your other pages
import 'notifications.dart';
import 'privacy_policy.dart';
import 'manage_account.dart';
import '../../../app/context/user.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // A slow pulse for the avatar
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Pulses from scale 1.0 to 1.05
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userContext = Provider.of<UserContext>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // -------------------------------------------------------------------
          //  A. SliverAppBar: gradient background + pinned "Settings" title
          // -------------------------------------------------------------------
          SliverAppBar(
            pinned: true,
            expandedHeight: 300.0,
            backgroundColor: colorScheme.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Settings',
                style: textTheme.titleLarge?.copyWith(
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
              background: LayoutBuilder(
                builder: (context, constraints) {
                  final currentHeight = constraints.biggest.height;
                  // SliverAppBar range: from ~56 (collapsed) to 300 (expanded)
                  const maxExtentValue = 300.0;
                  const minExtentValue = kToolbarHeight;

                  // Normalized 0.0 (collapsed) -> 1.0 (expanded)
                  final t = (currentHeight - minExtentValue) /
                      (maxExtentValue - minExtentValue);
                  final clampedT = t.clamp(0.0, 1.0);

                  // Fade out from 1.0 -> 0.0, scale from 1.0 -> 0.7
                  final opacity = clampedT;
                  final scale = 0.7 + (0.3 * clampedT);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Premium gradient background (primary -> secondary)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // The "frosted" user card, anchored near bottom
                      Positioned(
                        bottom: 20 + (1 - clampedT) * 40,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: _pulseAnimation.value * scale,
                            child: _buildFrostedUserCard(
                              context,
                              userContext,
                              colorScheme,
                              textTheme,
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

          // -------------------------------------------------------------------
          //  B. Main Settings Content
          // -------------------------------------------------------------------
          SliverToBoxAdapter(
            child: _buildSettingsList(
                context, userContext, colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------------
  //  (1) The "premium" frosted user card
  // ----------------------------------------------------------------------------
  Widget _buildFrostedUserCard(
    BuildContext context,
    UserContext userContext,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SizedBox(
      // Enough width to look nice on most devices
      width: MediaQuery.of(context).size.width * 0.85,
      height: 120,
      child: Stack(
        children: [
          // (a) Background blur & semi-transparent overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                // Subtle frosted overlay
                color: colorScheme.surface.withOpacity(0.3),
              ),
            ),
          ),

          // (b) Visible border and "premium" glow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                // Subtle glow behind the card
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // (1) Hero avatar with pulse
                Hero(
                  tag: 'profileAvatar',
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      userContext.userName != null
                          ? userContext.userName![0].toUpperCase()
                          : '?',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // (2) User details (name + email)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userContext.userName ?? 'Guest',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            // Subtle text glow
                            Shadow(
                              color: colorScheme.primary.withOpacity(0.5),
                              offset: const Offset(0, 0),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userContext.userEmail ?? 'No Email',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // (3) Log out icon button
                if (userContext.isLoggedIn)
                  IconButton(
                    icon: Icon(Icons.logout, color: colorScheme.onSurface),
                    onPressed: () async {
                      final shouldLogout = await _showConfirmDialog(
                        context,
                        colorScheme,
                        textTheme,
                        title: 'Confirm Logout',
                        content:
                            'Are you sure you want to log out? You will need to sign in again.',
                      );
                      if (shouldLogout == true) {
                        userContext.logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out successfully.'),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------------
  //  (2) The rest of your settings content
  // ----------------------------------------------------------------------------
  Widget _buildSettingsList(
    BuildContext context,
    UserContext userContext,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Dark Mode Toggle
        _buildFancyTile(
          context,
          colorScheme,
          textTheme,
          icon: Icons.dark_mode,
          title: 'Dark Mode',
          trailing: Switch(
            activeColor: colorScheme.primary,
            value: userContext.darkMode,
            onChanged: (bool value) async {
              final confirmDarkMode = await _showConfirmDialog(
                context,
                colorScheme,
                textTheme,
                title: value ? 'Enable Dark Mode?' : 'Disable Dark Mode?',
                content: 'Are you sure you want to switch themes?',
              );
              if (confirmDarkMode == true) {
                userContext.toggleDarkMode();
              }
            },
          ),
        ),

        // Manage Account
        _buildFancyTile(
          context,
          colorScheme,
          textTheme,
          icon: Icons.account_circle,
          title: 'Manage Account',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageAccountPage()),
            );
          },
        ),

        // Notifications
        _buildFancyTile(
          context,
          colorScheme,
          textTheme,
          icon: Icons.notifications,
          title: 'Notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
        ),

        // Privacy Policy
        _buildFancyTile(
          context,
          colorScheme,
          textTheme,
          icon: Icons.privacy_tip,
          title: 'Privacy Policy',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ----------------------------------------------------------------------------
  //  (3) Premium tile design for each setting
  // ----------------------------------------------------------------------------
  Widget _buildFancyTile(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // A luscious surface color
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
          // Subtle vertical gradient
          gradient: LinearGradient(
            colors: [
              colorScheme.surface.withOpacity(0.95),
              colorScheme.surface.withOpacity(0.80),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Icon bubble
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: colorScheme.onSurface,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Trailing widget (or arrow)
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------------
  //  (4) Strict confirmation dialog (for logout, theme change, etc.)
  // ----------------------------------------------------------------------------
  Future<bool?> _showConfirmDialog(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          content,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface.withOpacity(0.7),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
