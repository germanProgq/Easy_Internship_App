import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

// 1) Import your AppColors. If they're in app_colors.dart:
import 'styles/app_colors.dart';

// 2) Import the function buildAppTheme() from a separate file (e.g., app_theme.dart).
//    Adjust the path if your file is named/located differently.
import '../app/styles/theme_data.dart' show buildAppTheme;

import '../router/router.dart';
import 'transitions/main_load.dart';
import '../app/context/user.dart'; // The UserContext you created

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Read the existing UserContext from main()
    final userContext = Provider.of<UserContext>(context, listen: true);

    // 2. Update AppColors to dark or light
    AppColors.updateDarkMode(userContext.darkMode);

    // 3. Build the correct theme
    final theme = buildAppTheme();

    // 4. Return the MaterialApp
    return MaterialApp(
      title: 'Wave App',
      theme: theme,
      home: const SplashScreenWrapper(child: AppRouter()),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Wrapper for showing a splash screen before the main app.
class SplashScreenWrapper extends StatefulWidget {
  final Widget child;

  const SplashScreenWrapper({required this.child, super.key});

  @override
  SplashScreenWrapperState createState() => SplashScreenWrapperState();
}

class SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Simulates app initialization tasks & ensures the splash
  /// shows for a minimum duration.
  Future<void> _initializeApp() async {
    try {
      final minimumDuration = Future.delayed(const Duration(seconds: 3));

      final initialization = Future(() async {
        // Load SVG using rootBundle
        final svgString =
            await rootBundle.loadString('assets/pages/footer_wave.svg');
        final loader = SvgStringLoader(svgString);
        await loader.loadPicture(const ImageConfiguration());

        // Simulate other tasks
        await Future.delayed(const Duration(seconds: 1));
      });

      // Wait for both minimum duration & initialization
      await Future.wait([minimumDuration, initialization]);

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // Handle errors
      if (mounted) {
        setState(() {
          _isInitialized = true; // proceed on failure
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Splash screen while initializing
      return Container(
        color: AppColors.background, // uses the color from app_colors.dart
        child: WaveLoading(
          displayText: 'N',
          onTransitionComplete: () {},
        ),
      );
    }

    // Show the main app
    return widget.child;
  }
}

/// Mock SVG loader for demonstration.
class SvgStringLoader {
  final String svgString;

  SvgStringLoader(this.svgString);

  Future<void> loadPicture(ImageConfiguration imageConfiguration) async {
    // Placeholder for actual SVG loading logic
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
