// The Gearsh App - lib/services/airtable_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';
import '../models/artist.dart';

class AirtableService {
  static const _artistsTable = 'Artists';
  final http.Client _client = http.Client();

  Uri _buildTableUri(String table) {
    return Uri.https(
      'api.airtable.com',
      '/v0/${Secrets.airtableBaseId}/$table',
    );
  }

  Uri _buildRecordUri(String table, String id) {
    return Uri.https(
      'api.airtable.com',
      '/v0/${Secrets.airtableBaseId}/$table/$id',
    );
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${Secrets.airtableApiKey}',
        'Content-Type': 'application/json',
      };

  Future<List<Artist>> fetchArtists() async {
    final uri = _buildTableUri(_artistsTable);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final records = data['records'] as List<dynamic>;
      return records.map((record) => Artist.fromJson(record)).toList();
    } else {
      throw Exception('Failed to load artists: ${response.statusCode}');
    }
  }

  Future<Artist> fetchArtistById(String id) async {
    final uri = _buildRecordUri(_artistsTable, id);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final record = jsonDecode(response.body);
      return Artist.fromJson(record);
    } else {
      throw Exception('Failed to load artist $id: ${response.statusCode}');
    }
  }

  void dispose() {
    _client.close();
  }
}
