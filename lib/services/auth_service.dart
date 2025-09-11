//The Gearsh App - lib/services/auth_service.dart
import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://your-api.com/api'));

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await _dio.post('/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    final response = await _dio.post('/register', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<void> signOut() async {
    await _dio.post('/logout');
  }
}
