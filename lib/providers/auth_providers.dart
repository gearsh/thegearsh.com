// lib/providers/auth_providers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/core/contracts/i_auth_repository.dart';
import 'package:gearsh_app/core/di/service_providers.dart';
import 'package:gearsh_app/core/queries/linked_queries.dart';
import '../services/auth_api_service.dart';
import '../services/firebase_auth_service.dart';

enum AuthState { unauthenticated, authenticated, loading }

// Stream of Firebase auth state changes
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  final firebaseAuthService = ref.watch(firebaseAuthServiceProvider);
  return firebaseAuthService.authStateChanges;
});

// Current Firebase user
final currentFirebaseUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Check Firebase auth state on build
    final firebaseUser = ref.watch(currentFirebaseUserProvider);
    return firebaseUser != null
        ? AuthState.authenticated
        : AuthState.unauthenticated;
  }

  void setLoading() => state = AuthState.loading;
  void signIn() => state = AuthState.authenticated;
  void signOut() => state = AuthState.unauthenticated;
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

class AuthController {
  final IAuthRepository _repository;
  final AuthStateNotifier _authState;
  final FirebaseAuthService _firebaseAuth;
  final AuthApiService _authApi;
  final void Function() _refreshSession;

  AuthController(
    this._repository,
    this._authState,
    this._firebaseAuth,
    this._authApi,
    this._refreshSession,
  );

  // Sign in with email/username + password (Cloudflare D1 API)
  Future<EmailAuthResult> signInWithEmail(String identifier, String password) async {
    _authState.setLoading();
    try {
      var result = await _authApi.login(identifier: identifier, password: password);
      if (!result.success) {
        result = await _authApi.loginLegacy(identifier: identifier, password: password);
      }
      if (result.success && result.user != null) {
        _authState.signIn();
        _refreshSession();
        return EmailAuthResult.success(result.user!);
      }
      _authState.signOut();
      return EmailAuthResult.error(result.error ?? 'Login failed');
    } catch (e) {
      _authState.signOut();
      return EmailAuthResult.error(e.toString());
    }
  }

  // Sign up with email/password (Cloudflare D1 API)
  Future<EmailAuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
    String userType = 'artist',
    String? phone,
    String? location,
    String? country,
    String? skillSet,
  }) async {
    _authState.setLoading();
    try {
      if (firstName == null || firstName.isEmpty || lastName == null || lastName.isEmpty) {
        return EmailAuthResult.error('First and last name are required');
      }

      final result = await _authApi.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        userType: userType,
        username: username,
        phone: phone,
        location: location,
        country: country,
        skillSet: skillSet,
      );

      if (result.success && result.user != null) {
        _authState.signIn();
        _refreshSession();
        return EmailAuthResult.success(result.user!);
      }
      _authState.signOut();
      return EmailAuthResult.error(result.error ?? 'Sign up failed');
    } catch (e) {
      _authState.signOut();
      return EmailAuthResult.error(e.toString());
    }
  }

  // Sign in with Google using Firebase
  Future<FirebaseAuthResult> signInWithGoogle() async {
    _authState.setLoading();
    try {
      final result = await _firebaseAuth.signInWithGoogle();
      if (result.success) {
        _authState.signIn();
        _refreshSession();
      } else if (!result.cancelled) {
        _authState.signOut();
      }
      return result;
    } catch (e) {
      _authState.signOut();
      return FirebaseAuthResult.error(e.toString());
    }
  }

  // Sign in with Apple using Firebase
  Future<FirebaseAuthResult> signInWithApple() async {
    _authState.setLoading();
    try {
      final result = await _firebaseAuth.signInWithApple();
      if (result.success) {
        _authState.signIn();
        _refreshSession();
      } else if (!result.cancelled) {
        _authState.signOut();
      }
      return result;
    } catch (e) {
      _authState.signOut();
      return FirebaseAuthResult.error(e.toString());
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    return await _firebaseAuth.sendPasswordResetEmail(email);
  }

  // Legacy methods for backward compatibility
  Future<void> signIn(String email, String password) async {
    await signInWithEmail(email, password);
  }

  Future<void> signUp(String email, String password) async {
    await signUpWithEmail(email: email, password: password);
  }

  Future<void> signOut() async {
    await _authApi.logout();
    await _firebaseAuth.signOut();
    await _repository.signOut();
    _authState.signOut();
    _refreshSession();
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final repository = ref.read(authRepositoryProvider);
  final authState = ref.read(authStateProvider.notifier);
  final firebaseAuth = ref.read(firebaseAuthServiceProvider);
  final authApi = ref.read(authApiServiceProvider);
  return AuthController(
    repository,
    authState,
    firebaseAuth,
    authApi,
    () => invalidateSessionQueries(ref),
  );
});

/// Result of email/password authentication via backend API
class EmailAuthResult {
  final bool success;
  final String? error;
  final AuthUser? user;

  EmailAuthResult._({required this.success, this.error, this.user});

  factory EmailAuthResult.success(AuthUser user) =>
      EmailAuthResult._(success: true, user: user);

  factory EmailAuthResult.error(String message) =>
      EmailAuthResult._(success: false, error: message);
}
