// user_context.dart
import 'package:flutter/foundation.dart';

class UserContext extends ChangeNotifier {
  String? userId;
  String? userName;
  String? userEmail;
  String? token;

  // Example preference
  bool darkMode = false;

  bool get isLoggedIn => userId != null && userId!.isNotEmpty;

  void login({
    required String userId,
    required String userName,
    required String userEmail,
    required String token,
  }) {
    this.userId = userId;
    this.userName = userName;
    this.userEmail = userEmail;
    this.token = token;
    notifyListeners();
  }

  void logout() {
    userId = null;
    userName = null;
    userEmail = null;
    token = null;
    notifyListeners();
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }
}
