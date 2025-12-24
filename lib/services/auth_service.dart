//The Gearsh App - lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _apiBaseUrl = 'https://thegearsh-com.pages.dev/api';

  /// Sign in with username or email and password
  Future<Map<String, dynamic>> signIn(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'identifier': identifier, // Can be username or email
        'password': password,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/signup'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Sign up failed');
    }
  }

  Future<void> signOut() async {
    // Clear local session - no API call needed for now
  }
}
