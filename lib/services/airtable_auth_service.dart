// This handles Airtable REST calls (login, sign-up).
import 'dart:convert';
import 'package:http/http.dart' as http;

// ignore: constant_identifier_names
const String AIRTABLE_API_KEY =
    'pat9PYLZ3jMlj9AN2.d3ecc72334962e299bd9757bb7badbcf734de2fea1528186e112abfca9c4c4f1';
// ignore: constant_identifier_names
const String AIRTABLE_BASE_ID = 'appXVEAL5jETcjmaE';

class AirtableAuthService {
  static const String _baseUrl =
      'https://api.airtable.com/v0/$AIRTABLE_BASE_ID';
  static const String _usersTable = 'Users';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $AIRTABLE_API_KEY',
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(
        '$_baseUrl/$_usersTable?filterByFormula=AND({email}="$email",{password}="$password")');

    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final records = data['records'] as List;
      if (records.isNotEmpty) {
        return records.first['fields'];
      }
    }
    return null;
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/$_usersTable');

    final body = jsonEncode({
      'fields': {
        'name': name,
        'email': email,
        'password': password,
      },
    });

    final response = await http.post(url, headers: _headers, body: body);
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
