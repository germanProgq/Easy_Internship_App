// lib/router/router.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your pages:
import '../app/context/user.dart';
import '../pages/login/login.dart';
import '../pages/login/resume_page.dart';
import 'package:resume_app/pages/home/home_page.dart';

// This widget decides which page to return based on UserContext.
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContext>();

    // 1) Still loading user data from SharedPreferences
    if (!userContext.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2) Not logged in => LoginPage
    if (!userContext.isLoggedIn) {
      return const LoginPage();
    }

    // 3) Logged in but resume incomplete => ResumeForm
    if (!userContext.isResumeComplete) {
      return const ResumeForm();
    }

    // 4) Logged in + resume complete => HomePage
    return const HomePage();
  }
}
