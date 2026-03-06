import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { citizen, blueCollar, unknown }

UserRole mapRole(String role) {
  switch (role) {
    case 'Citizen':
      return UserRole.citizen;
    case 'Blue collar':
      return UserRole.blueCollar;
    default:
      return UserRole.unknown;
  }
}

class RoleProvider extends ChangeNotifier {
  UserRole _role = UserRole.unknown;
  String? _token;
  String? _userId;
  String? _email;

  UserRole get role => _role;
  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  bool get isLoggedIn => _token != null;

  Future<void> setUser({
    required String token,
    required UserRole role,
    required String userId,
    String? email,
  }) async {
    _token = token;
    _role = role;
    _userId = userId;
    _email = email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role.toString());
    await prefs.setString('userId', userId);
    if (email != null && email.trim().isNotEmpty) {
      await prefs.setString('email', email.trim());
    } else {
      await prefs.remove('email');
    }

    notifyListeners();
  }

  Future<bool> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final roleString = prefs.getString('role');
    final userId = prefs.getString('userId');
    final email = prefs.getString('email');

    if (token != null && roleString != null && userId != null) {
      _token = token;
      _userId = userId;
      _email = email;

      if (roleString == 'UserRole.citizen') {
        _role = UserRole.citizen;
      } else if (roleString == 'UserRole.blueCollar') {
        _role = UserRole.blueCollar;
      } else {
        _role = UserRole.unknown;
      }

      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> logout() async {
    _token = null;
    _role = UserRole.unknown;
    _userId = null;
    _email = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('email');

    notifyListeners();
  }
}