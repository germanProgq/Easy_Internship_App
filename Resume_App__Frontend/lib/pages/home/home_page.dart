import 'package:flutter/material.dart';
import 'choices/basic/basic_home_page.dart';
import 'choices/tndr/tndr_home_page.dart';

class HomePage extends StatefulWidget {
  final String userPreference;

  const HomePage({
    super.key,
    this.userPreference = 'tndr',
  });

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Delay the animation slightly to ensure widgets are built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.userPreference == 'tndr') {
      child = const TndrHomePage();
    } else {
      child = BasicHomePage();
    }

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeIn,
      child: child,
    );
  }
}
