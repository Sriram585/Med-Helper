import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      _currentUser = jsonDecode(userData);
      notifyListeners();
    }
  }

  Future<void> login(Map<String, dynamic> user, bool saveSession) async {
    _currentUser = user;
    if (saveSession) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user));
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }
}
