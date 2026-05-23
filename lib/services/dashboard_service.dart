import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gearsh_app/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardService {
  static const _tokenKey = 'gearsh_auth_token';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>?> fetchDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/dashboard'),
        headers: await _headers(),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      return Map<String, dynamic>.from(body['data'] as Map);
    } catch (_) {
      return null;
    }
  }
}
