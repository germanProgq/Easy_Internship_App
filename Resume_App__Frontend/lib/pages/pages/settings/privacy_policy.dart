import 'dart:ui'; // For ImageFilter (blur)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shimmer/shimmer.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with SingleTickerProviderStateMixin {
  String _privacyPolicyText = '';
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeScaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadPrivacyPolicy();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final text = await rootBundle.loadString('texts/privacy_policy.txt');
      setState(() {
        _privacyPolicyText = text;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _privacyPolicyText = 'Failed to load privacy policy.';
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Premium gradient background:
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.secondary.withOpacity(0.6),
              colorScheme.primary.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(colorScheme, textTheme),
            SliverFillRemaining(
              hasScrollBody: true, // Allows the content to scroll if needed
              child: Center(
                child: _buildContent(colorScheme, textTheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme, TextTheme textTheme) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 200.0,
      backgroundColor: colorScheme.primary.withOpacity(0.8),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Privacy Policy',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.4),
              radius: 1.2,
              colors: [
                colorScheme.secondary.withOpacity(0.8),
                colorScheme.primary.withOpacity(0.8),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: FadeTransition(
        opacity: _fadeScaleAnimation,
        child: ScaleTransition(
          scale: _fadeScaleAnimation,
          child: _buildFrostedStadium(
            colorScheme,
            child: _isLoading
                ? _buildShimmerPlaceholder(colorScheme)
                : _buildMarkdownBody(textTheme, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownBody(TextTheme textTheme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: MarkdownBody(
        data: _privacyPolicyText,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontSize: 16,
            height: 1.5,
          ),
          h1: textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          h2: textTheme.titleLarge?.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
          h3: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          blockquoteDecoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedStadium(
    ColorScheme colorScheme, {
    required Widget child,
  }) {
    return SizedBox(
      // Enough height for most screens, will scroll if needed
      height: MediaQuery.of(context).size.height * 0.7,
      child: Stack(
        children: [
          // Blurred background
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              color: colorScheme.surface.withOpacity(0.25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: colorScheme.surface.withOpacity(0.5),
        highlightColor: Colors.white.withOpacity(0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ),
    );
  }
}
