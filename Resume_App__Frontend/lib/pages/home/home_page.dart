import 'package:flutter/material.dart';

// Import your other pages:
import 'choices/tndr/tndr_home_page.dart';
import 'choices/basic/basic_home_page.dart';
import '../pages/terms_of_service.dart';
import '../settings/settings_page.dart';
import '../settings/components/manage_account.dart';

/// A single HomePage widget that:
/// - Uses an IndexedStack with 4 tabs
/// - Has the same bottom nav items from your router
/// - Fades in on appearance
/// - The first tab chooses Tndr or Basic based on userPreference
class HomePage extends StatefulWidget {
  final String userPreference; // e.g. 'tndr' or 'basic'

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
  int _currentIndex = 0;

  // We'll build our IndexedStack pages in initState,
  // because the first tab depends on userPreference.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Decide which page to show in tab #0 (Home tab)
    final Widget firstTabWidget = (widget.userPreference == 'tndr')
        ? const TndrHomePage()
        : const BasicHomePage();

    // Build the 4 pages
    _pages = [
      firstTabWidget,
      const TermsOfServicePage(),
      const ManageAccountPage(),
      const SettingsPage(),
    ];

    // Fade in after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      // Fade the entire Scaffold from opacity 0 -> 1 over 500 ms
      opacity: _opacity,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeIn,
      child: Scaffold(
        // Use an IndexedStack so each tab preserves its state
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onBottomNavTap,
          // Same items you had in your router
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'Terms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Account',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
