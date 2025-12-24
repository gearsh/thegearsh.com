import 'package:flutter/material.dart';

/// Enum representing the user role types
enum UserRole {
  client,
  artist,
}

/// Service for managing the current user's role and authentication state
class UserRoleService extends ChangeNotifier {
  static final UserRoleService _instance = UserRoleService._internal();
  factory UserRoleService() => _instance;
  UserRoleService._internal();

  UserRole _currentRole = UserRole.client;
  bool _isLoggedIn = false;
  bool _isGuest = false; // User selected a role but hasn't signed up
  String _userName = 'Guest User';
  String _userEmail = 'guest@gearsh.com';

  UserRole get currentRole => _currentRole;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  bool get hasSelectedRole => _isGuest || _isLoggedIn; // User has selected a role (guest or logged in)
  bool get requiresSignUp => _isGuest && !_isLoggedIn;
  bool get isClient => _currentRole == UserRole.client;
  bool get isArtist => _currentRole == UserRole.artist;
  String get userName => _userName;
  String get userEmail => _userEmail;

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  /// Set user as guest with selected role (browsing mode)
  void setGuestRole(UserRole role) {
    _isGuest = true;
    _isLoggedIn = false;
    _currentRole = role;
    _userName = 'Guest User';
    _userEmail = 'guest@gearsh.com';
    notifyListeners();
  }

  void login({
    required UserRole role,
    String? name,
    String? email,
  }) {
    _isLoggedIn = true;
    _isGuest = false;
    _currentRole = role;
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _isGuest = false;
    _currentRole = UserRole.client;
    _userName = 'Guest User';
    _userEmail = 'guest@gearsh.com';
    notifyListeners();
  }

  void switchRole() {
    _currentRole = _currentRole == UserRole.client ? UserRole.artist : UserRole.client;
    notifyListeners();
  }
}

/// Global instance for easy access
final userRoleService = UserRoleService();

