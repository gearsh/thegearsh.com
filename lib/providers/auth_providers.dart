// lib/providers/auth_providers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repos/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';

enum AuthState { unauthenticated, authenticated, loading }

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firebase Auth Service Provider
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);

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

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(ref.read(authServiceProvider)));

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
  final AuthRepository _repository;
  final AuthStateNotifier _authState;
  final FirebaseAuthService _firebaseAuth;

  AuthController(this._repository, this._authState, this._firebaseAuth);

  // Sign in with email/password using Firebase
  Future<FirebaseAuthResult> signInWithEmail(String identifier, String password) async {
    _authState.setLoading();
    try {
      final result = await _firebaseAuth.signInWithEmailPassword(identifier, password);
      if (result.success) {
        _authState.signIn();
      } else {
        _authState.signOut();
      }
      return result;
    } catch (e) {
      _authState.signOut();
      return FirebaseAuthResult.error(e.toString());
    }
  }

  // Sign up with email/password using Firebase
  Future<FirebaseAuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
  }) async {
    _authState.setLoading();
    try {
      final result = await _firebaseAuth.signUpWithEmailPassword(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
      );
      if (result.success) {
        _authState.signIn();
      } else {
        _authState.signOut();
      }
      return result;
    } catch (e) {
      _authState.signOut();
      return FirebaseAuthResult.error(e.toString());
    }
  }

  // Sign in with Google using Firebase
  Future<FirebaseAuthResult> signInWithGoogle() async {
    _authState.setLoading();
    try {
      final result = await _firebaseAuth.signInWithGoogle();
      if (result.success) {
        _authState.signIn();
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
    await _firebaseAuth.signOut();
    await _repository.signOut();
    _authState.signOut();
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final repository = ref.read(authRepositoryProvider);
  final authState = ref.read(authStateProvider.notifier);
  final firebaseAuth = ref.read(firebaseAuthServiceProvider);
  return AuthController(repository, authState, firebaseAuth);
});
