// lib/app/context/user_context.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserContext extends ChangeNotifier {
  String? userId;
  String? userName;
  String? userEmail;
  String? token;
  bool darkMode = false;

  bool get isLoggedIn => userId != null && userId!.isNotEmpty;

  // The user's resume data (e.g. {"name": "...", "summary": "..."}).
  Map<String, String> resumeData = {};

  // True once we've finished loading from SharedPreferences
  bool isInitialized = false;

  bool get isResumeComplete => resumeData.isNotEmpty;

  UserContext() {
    _loadUserDataFromDisk();
  }

  Future<void> _loadUserDataFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    userName = prefs.getString('userName') ?? '';
    userEmail = prefs.getString('userEmail') ?? '';
    token = prefs.getString('token') ?? '';
    darkMode = prefs.getBool('darkMode') ?? true;

    final resumeFields = prefs.getString('resumeData') ?? '';
    if (resumeFields.isNotEmpty) {
      final entries = resumeFields.split(';;');
      final dataMap = <String, String>{};
      for (var entry in entries) {
        final split = entry.split('|');
        if (split.length == 2) {
          dataMap[split[0]] = split[1];
        }
      }
      resumeData = dataMap;
    }

    isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveUserDataToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId ?? '');
    await prefs.setString('userName', userName ?? '');
    await prefs.setString('userEmail', userEmail ?? '');
    await prefs.setString('token', token ?? '');
    await prefs.setBool('darkMode', darkMode);

    final resumeFields =
        resumeData.entries.map((e) => '${e.key}|${e.value}').join(';;');
    await prefs.setString('resumeData', resumeFields);
  }

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
    _saveUserDataToDisk();
  }

  void logout() {
    userId = null;
    userName = null;
    userEmail = null;
    token = null;
    resumeData.clear();
    notifyListeners();
    _clearUserDataFromDisk();
  }

  Future<void> _clearUserDataFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('token');
    await prefs.remove('darkMode');
    await prefs.remove('resumeData');
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
    _saveUserDataToDisk();
  }

  void updateResumeData(Map<String, String> newData) {
    resumeData = newData;
    notifyListeners();
    _saveUserDataToDisk();
  }

  /// A method to update *all* fields at once, including top-level user info
  /// and any new or existing resumeData key-value pairs.
  void updateAll({
    String? userId,
    String? userName,
    String? userEmail,
    String? token,
    bool? darkMode,
    Map<String, String>? resumeData,
  }) {
    // Only update what’s provided (null means leave as-is)
    if (userId != null) this.userId = userId;
    if (userName != null) this.userName = userName;
    if (userEmail != null) this.userEmail = userEmail;
    if (token != null) this.token = token;
    if (darkMode != null) this.darkMode = darkMode;
    if (resumeData != null) {
      this.resumeData = resumeData;
    }

    notifyListeners();
    _saveUserDataToDisk();
  }
}
