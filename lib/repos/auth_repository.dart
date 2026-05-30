// lib/repositories/auth_repository.dart

import 'package:gearsh_app/core/contracts/i_auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepository implements IAuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email, password);
  }

  Future<void> signUp(String email, String password) async {
    await _authService.signUp(email, password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
