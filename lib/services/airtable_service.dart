// lib/services/airtable_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class AirtableService {
  static const String apiKey =
      'pat9PYLZ3jMlj9AN2.d3ecc72334962e299bd9757bb7badbcf734de2fea1528186e112abfca9c4c4f1'; // Replace this
  static const String baseId = 'appXVEAL5jETcjmaE'; //
  static const String tableName =
      'Artists'; // Replace with your Airtable table name

  static Future<List<Map<String, dynamic>>> fetchArtists() async {
    final url = 'https://api.airtable.com/v0/$baseId/$tableName';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final records = jsonData['records'] as List;
      return records.map((r) => r['fields'] as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load artists: ${response.body}');
    }
  }
}
