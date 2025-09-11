//The Gearsh App - Airtable API

import 'package:http/http.dart' as http;

class AirtableApi {
  static const _baseId = 'appXVEAL5jETcjmaE';
  static const _baseUrl = 'https://api.airtable.com/v0/$_baseId';

  static Future<http.Response> getRecords({
    required String tableName,
    String? filterFormula,
  }) async {
    final uri = Uri.parse('$_baseUrl/$tableName').replace(queryParameters: {
      if (filterFormula != null) 'filterByFormula': filterFormula,
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer \$airtableApiKey',
        'Content-Type': 'application/json',
      },
    );

    return response;
  }
}
