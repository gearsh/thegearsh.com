import 'package:flutter/material.dart';
import 'package:gearsh_app/models/user_role.dart';
import 'package:gearsh_app/providers/user_role_provider.dart';

export 'package:gearsh_app/models/user_role.dart' show UserRole;

/// Legacy singleton kept for router redirects and gradual migration.
/// Source of truth: [userRoleProvider]. Wired in [main] via [bindUserRoleNotifier].
class UserRoleService extends ChangeNotifier {
  static final UserRoleService _instance = UserRoleService._internal();
  factory UserRoleService() => _instance;
  UserRoleService._internal();

  UserRoleNotifier? _notifier;

  UserRole _currentRole = UserRole.client;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String _userName = 'Guest User';
  String _userEmail = 'guest@gearsh.com';

  UserRole get currentRole => _currentRole;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  bool get hasSelectedRole => _isGuest || _isLoggedIn;
  bool get requiresSignUp => _isGuest && !_isLoggedIn;
  bool get isClient => _currentRole == UserRole.client;
  bool get isArtist => _currentRole == UserRole.artist;
  bool get isFan => _currentRole == UserRole.fan;
  String get userName => _userName;
  String get userEmail => _userEmail;

  void bindUserRoleNotifier(UserRoleNotifier notifier) {
    _notifier = notifier;
  }

  void syncFromState(UserRoleState state) {
    _currentRole = state.role;
    _isLoggedIn = state.isLoggedIn;
    _isGuest = state.isGuest;
    _userName = state.userName;
    _userEmail = state.userEmail;
    notifyListeners();
  }

  void setRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void setGuestRole(UserRole role) {
    if (_notifier != null) {
      _notifier!.setGuestRole(role);
      return;
    }
    _applyGuestRole(role);
  }

  void _applyGuestRole(UserRole role) {
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
    if (_notifier != null) {
      _notifier!.login(role: role, name: name, email: email);
      return;
    }
    _isLoggedIn = true;
    _isGuest = false;
    _currentRole = role;
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    notifyListeners();
  }

  void logout() {
    if (_notifier != null) {
      _notifier!.logout();
      return;
    }
    _applyLogout();
  }

  void _applyLogout() {
    _isLoggedIn = false;
    _isGuest = false;
    _currentRole = UserRole.client;
    _userName = 'Guest User';
    _userEmail = 'guest@gearsh.com';
    notifyListeners();
  }

  void switchRole() {
    if (_notifier != null) {
      _notifier!.switchRole();
      return;
    }
    _applySwitchRole();
  }

  void _applySwitchRole() {
    _currentRole =
        _currentRole == UserRole.client ? UserRole.artist : UserRole.client;
    notifyListeners();
  }
}

final userRoleService = UserRoleService();

void bindUserRoleNotifier(UserRoleNotifier notifier) {
  userRoleService.bindUserRoleNotifier(notifier);
}
