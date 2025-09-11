// lib/providers/auth_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repos/auth_repository.dart';
import '../services/auth_service.dart';

enum AuthState { unauthenticated, authenticated }

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(ref.read(authServiceProvider)));

final authStateProvider =
    StateProvider<AuthState>((ref) => AuthState.unauthenticated);

final authControllerProvider = Provider<AuthController>((ref) {
  final repository = ref.read(authRepositoryProvider);
  final authState = ref.read(authStateProvider.notifier);
  return AuthController(repository, authState);
});

class AuthController {
  final AuthRepository _repository;
  final StateController<AuthState> _authState;

  AuthController(this._repository, this._authState);

  Future<void> signIn(String email, String password) async {
    await _repository.signIn(email, password);
    _authState.state = AuthState.authenticated;
  }

  Future<void> signUp(String email, String password) async {
    await _repository.signUp(email, password);
    _authState.state = AuthState.authenticated;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _authState.state = AuthState.unauthenticated;
  }
}
