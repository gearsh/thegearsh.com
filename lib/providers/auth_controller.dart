import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'global_providers.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = Provider<AuthController>((ref) {
  final repository = ref.read(authServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return AuthController(repository, authNotifier);
});

class AuthController {
  final AuthService _authService;
  final StateController<AuthState> _authNotifier;

  AuthController(this._authService, this._authNotifier);

  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signIn(email, password);
      _authNotifier.state = AuthState.authenticated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _authService.signUp(email, password);
      _authNotifier.state = AuthState.authenticated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _authNotifier.state = AuthState.unauthenticated;
  }
}
