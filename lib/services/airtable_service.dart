// lib/services/airtable_service.dart

//import 'dart:convert';
//import 'package:http/http.dart' as http;

//class AirtableService {
//static const String apiKey =
//   ''; // Replace this
// static const String baseId = ''; //
// static const String tableName =
//  'Artists'; // Replace with your Airtable table name

// static Future<List<Map<String, dynamic>>> fetchArtists() async {
//const url = 'https://api.airtable.com/v0/$baseId/$tableName';
// final response = await http.get(
//   Uri.parse(url),
// headers: {'Authorization': 'Bearer $apiKey'},
//   );

//   if (response.statusCode == 200) {
//  final jsonData = jsonDecode(response.body);
// final records = jsonData['records'] as List;
//  return records.map((r) => r['fields'] as Map<String, dynamic>).toList();
//   } else {
//    throw Exception('Failed to load artists: ${response.body}');
//  }
//}
//}

// lib/services/airtable_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class AirtableService {
  static const String _apiKey =
      'pat9PYLZ3jMlj9AN2.d3ecc72334962e299bd9757bb7badbcf734de2fea1528186e112abfca9c4c4f1';
  static const String _baseId = 'appXVEAL5jETcjmaE';
  static const String _tableName = 'Artists';

  Future<List<Map<String, dynamic>>> fetchArtists() async {
    const url = 'https://api.airtable.com/v0/$_baseId/$_tableName';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $_apiKey'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final records = jsonData['records'] as List;

      for (var record in records) {
        print('Record ID: ${record['id']}'); // ✅ Dynamic record ID
        print('Record fields: ${record['fields']}');
      }

      return records.map((record) {
        final fields = record['fields'] as Map<String, dynamic>;
        fields['id'] = record['id']; // ✅ Attach Airtable Record ID
        return fields;
      }).toList();
    } else {
      throw Exception('Failed to load artists: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchArtistById(String id) async {
    final url = 'https://api.airtable.com/v0/$_baseId/$_tableName/$id';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $_apiKey'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['fields'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load artist: ${response.body}');
    }
  }
}
