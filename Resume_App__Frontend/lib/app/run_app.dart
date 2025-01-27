// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:resume_app/pages/home/home_page.dart';

import 'styles/app_colors.dart';
import '../app/styles/theme_data.dart' show buildAppTheme;
import '../router/router.dart';
import 'transitions/main_load.dart';
import '../app/context/user.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userContext = Provider.of<UserContext>(context, listen: true);

    // Update colors & build theme
    AppColors.updateDarkMode(userContext.darkMode);
    final theme = buildAppTheme();

    return MaterialApp(
      title: 'Wave App',
      theme: theme,
      debugShowCheckedModeBanner: false,

      // The home is a splash screen that eventually shows AppRouter
      home: SplashScreenWrapper(
        child: const AppRouter(), // <--- AppRouter decides which page to show
      ),

      // If you still want named routes:
      routes: {
        '/home': (context) => SplashScreenWrapper(child: const AppRouter()),
        '/home_screen': (context) =>
            SplashScreenWrapper(child: const HomePage()),
      },
    );
  }
}

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

  Future<void> _initializeApp() async {
    try {
      final minimumDuration = Future.delayed(const Duration(seconds: 3));

      final initialization = Future(() async {
        final svgString =
            await rootBundle.loadString('assets/pages/footer_wave.svg');
        final loader = SvgStringLoader(svgString);
        await loader.loadPicture(const ImageConfiguration());
        await Future.delayed(const Duration(seconds: 1));
      });

      await Future.wait([minimumDuration, initialization]);

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: AppColors.background,
        child: WaveLoading(
          displayText: 'N',
          onTransitionComplete: () {},
        ),
      );
    }

    return widget.child;
  }
}

class SvgStringLoader {
  final String svgString;
  SvgStringLoader(this.svgString);

  Future<void> loadPicture(ImageConfiguration imageConfiguration) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
