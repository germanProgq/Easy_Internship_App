import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/notifications.dart';
import 'components/privacy_policy.dart';
import 'components/manage_account.dart';
import 'components/edit_resume.dart';
import '../../app/context/user.dart';

class _SettingsTileData {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  _SettingsTileData({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _listController;
  late AnimationController _cardController;

  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];
  late Animation<Offset> _cardOffsetAnimation;
  late Animation<double> _cardOpacityAnimation;

  late List<_SettingsTileData> _tiles;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeInOut,
      ),
    );

    _cardOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeInOut,
      ),
    );

    _tiles = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userContext = Provider.of<UserContext>(context);

    _tiles = [
      _SettingsTileData(
        icon: Icons.dark_mode,
        title: 'Dark Mode',
        trailing: Switch(
          activeColor: Theme.of(context).colorScheme.primary,
          value: userContext.darkMode,
          onChanged: (bool value) async {
            final confirm = await _showConfirmDialog(
              context,
              title: value ? 'Enable Dark Mode?' : 'Disable Dark Mode?',
              content: 'Switch theme?',
            );
            if (confirm == true) {
              userContext.toggleDarkMode();
            }
          },
        ),
      ),
      _SettingsTileData(
        icon: Icons.account_circle,
        title: 'Manage Account',
        onTap: () {
          Navigator.push(context, _fadeScaleRoute(const ManageAccountPage()));
        },
      ),
      _SettingsTileData(
        icon: Icons.notifications,
        title: 'Notifications',
        onTap: () {
          Navigator.push(context, _fadeScaleRoute(const NotificationsPage()));
        },
      ),
      _SettingsTileData(
        icon: Icons.privacy_tip,
        title: 'Privacy Policy',
        onTap: () {
          Navigator.push(context, _fadeScaleRoute(const PrivacyPolicyPage()));
        },
      ),
      _SettingsTileData(
        icon: Icons.description,
        title: 'Edit Resume',
        onTap: () {
          Navigator.push(context, _fadeScaleRoute(const ResumePage()));
        },
      ),
    ];

    if (_slideAnimations.isEmpty && _fadeAnimations.isEmpty) {
      _prepareListAnimations(_tiles.length);
      _listController.forward();
    }
    _cardController.forward();
  }

  void _prepareListAnimations(int count) {
    for (int i = 0; i < count; i++) {
      final start = i * (1.0 / count);
      final end = start + (1.0 / count);

      final slideTween = Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      );
      final fadeTween = Tween<double>(begin: 0, end: 1);

      _slideAnimations.add(
        slideTween.animate(
          CurvedAnimation(
            parent: _listController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
      _fadeAnimations.add(
        fadeTween.animate(
          CurvedAnimation(
            parent: _listController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _listController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1) Gradient background so any area not covered by the wave
          // is still nicely colored (not black).
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // 2) Wave painter
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) => CustomPaint(
              painter: _WaterPainter(_waveController.value),
              size: MediaQuery.of(context).size,
            ),
          ),
          // 3) Main content with SliverAppBar
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300.0,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
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
                      const maxExtentValue = 300.0;
                      const minExtentValue = kToolbarHeight;
                      final t = (currentHeight - minExtentValue) /
                          (maxExtentValue - minExtentValue);
                      final clampedT = t.clamp(0.0, 1.0);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            bottom: 20 + (1 - clampedT) * 30,
                            left: 0,
                            right: 0,
                            child: SlideTransition(
                              position: _cardOffsetAnimation,
                              child: FadeTransition(
                                opacity: _cardOpacityAnimation,
                                child: _buildFrostedUserCard(context),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      for (int i = 0; i < _tiles.length; i++)
                        _buildStaggeredTile(i, colorScheme, textTheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedUserCard(BuildContext context) {
    final userContext = Provider.of<UserContext>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 120,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: colorScheme.surface.withOpacity(0.3),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userContext.userName ?? 'Guest',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
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
                if (userContext.isLoggedIn)
                  IconButton(
                    icon: Icon(Icons.logout, color: colorScheme.onSurface),
                    onPressed: () async {
                      final result = await _showConfirmDialog(
                        context,
                        title: 'Confirm Logout',
                        content: 'Are you sure you want to log out?',
                      );
                      if (result == true) {
                        userContext.logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out successfully.'),
                            duration: Duration(seconds: 1),
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

  Widget _buildStaggeredTile(
      int index, ColorScheme colorScheme, TextTheme textTheme) {
    final tileData = _tiles[index];
    final slideAnim = _slideAnimations[index];
    final fadeAnim = _fadeAnimations[index];

    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return Opacity(
          opacity: fadeAnim.value,
          child: Transform.translate(
            offset: slideAnim.value,
            child: child,
          ),
        );
      },
      child: _buildFancyTile(
        colorScheme,
        textTheme,
        icon: tileData.icon,
        title: tileData.title,
        trailing: tileData.trailing,
        onTap: tileData.onTap,
      ),
    );
  }

  Widget _buildFancyTile(
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
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
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
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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

  PageRouteBuilder _fadeScaleRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeTween = Tween<double>(begin: 0, end: 1);
        final scaleTween = Tween<double>(begin: 0.9, end: 1);
        return FadeTransition(
          opacity: animation
              .drive(CurveTween(curve: Curves.easeInOut))
              .drive(fadeTween),
          child: ScaleTransition(
            scale: animation
                .drive(CurveTween(curve: Curves.easeInOut))
                .drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double progress;
  _WaterPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = Colors.blue.withOpacity(0.2);
    final paint2 = Paint()..color = Colors.blue.withOpacity(0.35);

    final path1 = Path();
    final path2 = Path();

    const waveHeight = 20.0;
    const waveFrequency = 2.0;
    const waveSpeed = 360.0;

    for (double x = 0; x <= size.width; x++) {
      final sineValue =
          sin((x * waveFrequency + progress * waveSpeed) * pi / 180);
      final y1 = size.height * 0.4 + sineValue * waveHeight;
      final y2 = y1 + 20;

      if (x == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
      }
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_WaterPainter oldDelegate) => true;
}
