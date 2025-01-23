import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'app/context/user.dart';
import 'app/run_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Read the system’s platformBrightness (dark or light).
  final brightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;
  final bool systemIsDark = brightness == Brightness.dark;

  // Create the user context with that initial darkMode value.
  // In a real app, you might also check SharedPreferences or other storage
  // to see if the user has *overridden* the system preference. For now,
  // we’ll just assume we use systemIsDark if there’s no stored preference.
  final userContext = UserContext()..darkMode = systemIsDark;

  runApp(
    ChangeNotifierProvider<UserContext>(
      create: (_) => userContext,
      child: const MyApp(),
    ),
  );
}
