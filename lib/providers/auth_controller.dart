import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'global_providers.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthControllerNotifier extends Notifier<AuthState> {
  late AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    return AuthState.unauthenticated;
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signIn(email, password);
      state = AuthState.authenticated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _authService.signUp(email, password);
      state = AuthState.authenticated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState.unauthenticated;
  }
}

final authControllerProvider = NotifierProvider<AuthControllerNotifier, AuthState>(
  AuthControllerNotifier.new,
);
