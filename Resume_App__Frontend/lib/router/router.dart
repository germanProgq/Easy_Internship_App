import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Some pages
import '../pages/pages/terms_of_service.dart';
import '../pages/home/home_page.dart';
import '../pages/pages/login/login.dart';
import '../pages/pages/settings/settings_page.dart';
import '../pages/pages/settings/manage_account.dart';

// Layout
import 'transition_layout.dart';
import '../app/transitions/types/transition_types.dart'; // The enum
import '../app/context/user.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final GlobalKey<TransitionLayoutState> _transitionKey =
      GlobalKey<TransitionLayoutState>();
  int _currentIndex = 0;

  void _navigateTo(
    int pageIndex, {
    TransitionTypes transitionType = TransitionTypes.slide,
  }) {
    setState(() {
      _currentIndex = pageIndex;
    });
    _transitionKey.currentState
        ?.navigateTo(pageIndex, transitionType: transitionType);
  }

  @override
  Widget build(BuildContext context) {
    final userContext = Provider.of<UserContext>(context);

    // If user is *NOT* logged in, show the login page.
    // Adjust this condition to match your actual login state.
    if (userContext.isLoggedIn) {
      return const LoginPage();
    }

    // Otherwise, user is logged in - show bottom nav with Home, Terms, Account, etc.
    return Scaffold(
      body: TransitionLayout(
        key: _transitionKey,
        children: const [
          HomePage(),
          TermsOfServicePage(),
          ManageAccountPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          final transitionType = index > _currentIndex
              ? TransitionTypes.slide
              : TransitionTypes.wave;
          _navigateTo(index, transitionType: transitionType);
        },
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
    );
  }
}
