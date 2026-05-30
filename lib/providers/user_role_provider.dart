import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/models/user_role.dart';

/// Immutable user role state for Riverpod-driven UI.
class UserRoleState {
  final UserRole role;
  final bool isLoggedIn;
  final bool isGuest;
  final String userName;
  final String userEmail;

  const UserRoleState({
    this.role = UserRole.client,
    this.isLoggedIn = false,
    this.isGuest = false,
    this.userName = 'Guest User',
    this.userEmail = 'guest@gearsh.com',
  });

  bool get hasSelectedRole => isGuest || isLoggedIn;
  bool get requiresSignUp => isGuest && !isLoggedIn;
  bool get isClient => role == UserRole.client;
  bool get isArtist => role == UserRole.artist;
  bool get isFan => role == UserRole.fan;

  UserRoleState copyWith({
    UserRole? role,
    bool? isLoggedIn,
    bool? isGuest,
    String? userName,
    String? userEmail,
  }) {
    return UserRoleState(
      role: role ?? this.role,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isGuest: isGuest ?? this.isGuest,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

/// Notifies GoRouter when role/auth changes (router has no [Ref]).
final userRoleRouterRefreshProvider = Provider<UserRoleRouterRefresh>((ref) {
  final refresh = UserRoleRouterRefresh();
  ref.onDispose(refresh.dispose);
  return refresh;
});

class UserRoleRouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class UserRoleNotifier extends Notifier<UserRoleState> {
  @override
  UserRoleState build() => const UserRoleState();

  void _notifyRouter() {
    ref.read(userRoleRouterRefreshProvider).refresh();
  }

  void setGuestRole(UserRole role) {
    state = UserRoleState(role: role, isGuest: true, isLoggedIn: false);
    _notifyRouter();
  }

  void login({
    required UserRole role,
    String? name,
    String? email,
  }) {
    state = state.copyWith(
      isLoggedIn: true,
      isGuest: false,
      role: role,
      userName: name ?? state.userName,
      userEmail: email ?? state.userEmail,
    );
    _notifyRouter();
  }

  void logout() {
    state = const UserRoleState();
    _notifyRouter();
  }

  void switchRole() {
    state = state.copyWith(
      role: state.role == UserRole.client ? UserRole.artist : UserRole.client,
    );
    _notifyRouter();
  }
}

final userRoleProvider =
    NotifierProvider<UserRoleNotifier, UserRoleState>(UserRoleNotifier.new);
