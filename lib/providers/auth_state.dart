/// Gearsh Auth State Management
/// Centralized authentication state with Riverpod

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/services/auth_api.dart';
import 'package:gearsh_app/services/error_handling.dart';

/// Auth state enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state class
class AuthState {
  final AuthStatus status;
  final GearshUser? user;
  final GearshException? error;
  final bool isLoading;

  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.isLoading = false,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading, isLoading: true);
  factory AuthState.authenticated(GearshUser user) => AuthState(
    status: AuthStatus.authenticated,
    user: user,
  );
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(GearshException error) => AuthState(
    status: AuthStatus.error,
    error: error,
  );

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isGuest => status == AuthStatus.unauthenticated;

  AuthState copyWith({
    AuthStatus? status,
    GearshUser? user,
    GearshException? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Auth state notifier using Notifier
class AuthStateNotifier extends Notifier<AuthState> {
  late AuthApiService _authService;
  StreamSubscription<User?>? _authSubscription;

  @override
  AuthState build() {
    _authService = ref.watch(authApiServiceProvider);
    _init();
    return AuthState.initial();
  }

  void _init() {
    // Listen to Firebase auth state changes
    _authSubscription?.cancel();
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
      onError: (error) {
        state = AuthState.error(ErrorHandler.fromException(error));
      },
    );
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      state = AuthState.unauthenticated();
    } else {
      // User is signed in, create GearshUser
      state = AuthState.authenticated(
        GearshUser.fromFirebaseUser(firebaseUser),
      );
    }
  }

  /// Sign up with email
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
    String role = 'client',
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _authService.signUpWithEmail(SignUpRequest(
      email: email,
      password: password,
      username: username,
      firstName: firstName,
      lastName: lastName,
      role: role,
    ));

    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }

    return result;
  }

  /// Sign in with email
  Future<AuthResult> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);

    final result = await _authService.signInWithEmail(email, password);

    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }

    return result;
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);

    final result = await _authService.signInWithGoogle();

    if (result.success && result.user != null) {
      state = AuthState.authenticated(result.user!);
    } else if (result.error?.code == 'cancelled') {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }

    return result;
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = AuthState.unauthenticated();
  }

  /// Update user role
  void updateUserRole(String role) {
    if (state.user != null) {
      state = AuthState.authenticated(state.user!.copyWith(role: role));
    }
  }

  /// Update user profile
  void updateUser(GearshUser user) {
    state = AuthState.authenticated(user);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth state provider
final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(() {
  return AuthStateNotifier();
});

/// Current user provider
final currentUserProvider = Provider<GearshUser?>((ref) {
  return ref.watch(authStateProvider).user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

/// Auth loading provider
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoading;
});

/// Auth error provider
final authErrorProvider = Provider<GearshException?>((ref) {
  return ref.watch(authStateProvider).error;
});

/// User role provider
final userRoleProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).user?.role ?? 'guest';
});

/// Is artist provider
final isArtistProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'artist';
});

/// Is client provider
final isClientProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'client';
});

